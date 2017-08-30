use v5.24;

package Dist::Zilla::Plugin::LocalHTML::Pod2HTML;
# ABSTRACT: Pod::Simple::HTML wrapper to generate local links for project modules.

our $VERSION = 'v0.1.901';

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

=method C<do_pod_link>

Inherited from L<Pod::Simple::HTML>

=cut
around do_pod_link => sub {
    my $orig   = shift;
    my $this   = shift;
    my ($link) = @_;

    $this->log_debug( "do_pod_link:", Dumper($link) );

    if ( $link->tagname eq 'L' and $link->attr('type') eq 'pod' ) {
        my $lpRx = $this->prefixRx;
        my $to   = "" . $link->attr('to');
        if ( $to =~ /^$lpRx/n ) {
            my $toFile = File::Spec->catfile(split /::/, $to);
            my $ref = $this->callerPlugin->base_filename($toFile);
            $this->log_debug("Resulting link:", $ref);
            return $ref;
        }
    }
};

=method C<init_prefixRx>

Builder for C<prefixRx> attribute. Generates regexp from caller plugin
C<local_prefix> attribute.

=cut
sub init_prefixRx {
    my $this = shift;
    return
      "(?<prefix>" . join( "|", @{ $this->callerPlugin->local_prefix } ) . ")";
}

1;
