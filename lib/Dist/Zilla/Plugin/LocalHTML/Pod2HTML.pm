package Dist::Zilla::Plugin::LocalHTML::Pod2HTML;

# ABSTRACT: Pod::Simple::HTML wrapper to generate local links for project modules.

our $VERSION = 'v0.2.2';

use File::Spec;
use Data::Dumper;
use Cwd;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends qw<Pod::Simple::HTML>;

=attr C<callerPlugin>

Points back to the parent plugin object.

=cut

has callerPlugin => (
    is      => 'ro',
    isa     => 'Dist::Zilla::Plugin::LocalHTML',
    handles => [qw<log log_debug>],
);

=attr prefixRx

Contains regexp for matching local modules.

=cut

has prefixRx => (
    is      => 'ro',
    lazy    => 1,
    builder => 'init_prefixRx',
);

=attr local_files

List of files to build docs for.

=cut
has local_files => (
    is      => 'ro',
    lazy    => 1,
    clearer => 'clear_local_files',
    builder => 'init_local_files',
);

=method C<do_pod_link>

Inherited from L<Pod::Simple::HTML>

=cut

sub _mod2file {
    my $this = shift;
    my $mod  = shift;
    my $file = File::Spec->catfile( split /::/, $mod );
    return $this->callerPlugin->base_filename($file);
}

around do_pod_link => sub {
    my $orig   = shift;
    my $this   = shift;
    my ($link) = @_;

    if (   ( $link->tagname eq 'L' )
        && ( $link->attr('type') eq 'pod' ) )
    {
        my $ref = "";
        if ( $link->attr('to') ) {
            my $lpRx   = $this->prefixRx;
            my $to     = "" . $link->attr('to');
            my $toFile = $this->_mod2file($to);
            $this->log_debug("'$to' matches local prefix")
              if defined($lpRx) && $to =~ /^$lpRx/;
            $this->log_debug("'$toFile' is in local_files map")
              if $this->local_files->{$toFile};
            if ( ( defined($lpRx) && $to =~ /^$lpRx/ )
                || $this->local_files->{$toFile} )
            {
                # Local link
                $ref .= $toFile;
            }
            else {
                # External link. Override default generator because
                # search.cpan.org seems to be down as for now.
                $ref .= "https://metacpan.org/pod/$to";
            }
        }
        if ( $link->attr('section') ) {
            my $section = "" . $link->attr('section');
            $ref .= "#" . $this->section_escape($section);
        }
        if ($ref) {
            $this->log_debug( "Resulting link:", $ref );
            return $ref;
        }
    }

    return $orig->( $this, @_ );
};

=method C<init_prefixRx>

Builder for C<prefixRx> attribute. Generates regexp from caller plugin
C<local_prefix> attribute.

=cut

sub init_prefixRx {
    my $this   = shift;
    my @pfList = @{ $this->callerPlugin->local_prefix };
    return @pfList
      ? "(?<prefix>" . join( "|", @pfList ) . ")"
      : undef;
}

=method C<init_local_files>

Builder for C<local_files> attribute. Records local files to be processed.

=cut
sub init_local_files {
    my $this = shift;

    my $files = $this->callerPlugin->found_files;
    my $map   = {};

    foreach my $file (@$files) {
        $map->{ $this->callerPlugin->base_filename( $file->name ) } = 1
          if $this->callerPlugin->is_interesting_file($file);
    }
    return $map;
}

1;
