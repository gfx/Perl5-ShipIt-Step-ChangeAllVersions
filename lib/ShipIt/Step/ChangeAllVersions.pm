package ShipIt::Step::ChangeAllVersions;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.002';

use parent qw(ShipIt::Step);
use ExtUtils::Manifest qw(maniread);
use Fatal qw(open close rename);

sub run {
    my ($self, $state) = @_;

    my $current_version = quotemeta $state->pt->{version};
    my $new_version     = $state->version;

    # get all modules
    my @modules =
        grep { -f && / \.(?: p[lm]c? | pod ) \z/xms } keys %{maniread()};

    foreach my $module (@modules) {
        open my $in,  '<', $module;
        open my $out, '>', "$module.tmp";

        my $need_replace = 0;

        while (<$in>) {

            # update $VERSION variable
            if (s/(\$VERSION .+) \b $current_version \b/$1$new_version/xms) {
                $self->{changed_version_variable}{$module}++;
                $self->log("Update \$VERSION in $module.");
                $need_replace++;
            }

            # update the VERSION section whic say,
            # "This is Foo version $ver.",
            # or "This document descrives Foo version $ver."
            if (/\A =head1 \s+ VERSION/xms ... /\A =\w+/xms) {
                if (s/(version \s+) $current_version/$1$new_version/xms) {
                    $self->{changed_version_section}{$module}++;
                    $self->log("Update the VERSION section in $module.");
                    $need_replace++;
                }
            }

            print $out $_;
        }

        close $in;
        close $out;

        if($need_replace){
            rename $module       => "$module~";
            rename "$module.tmp" => $module;

            unlink "$module~";
        }
        else{
            unlink "$module.tmp";
        }
    }

    return 1;
}

sub changed_version_variable {
    return $_[0]->{changed_version_variable};
}

sub changed_version_section {
    return $_[0]->{changed_version_section};
}

sub log {
    my $self = shift;
    print @_, "\n";
}

1;
__END__

=head1 NAME

ShipIt::Step::ChangeAllVersions - Changes versions in all the modules

=head1 VERSION

This document describes ShipIt::Step::ChangeAllVersions version 0.002.

=head1 SYNOPSIS

    # .shipit
    steps = FindVersion, ChangeAllVersions, ...

=head1 DESCRIPTION

C<ShipIt::Step::ChangeVersion> updates the version variable in the main module.
C<ShipIt::Step::ChangeAllVersions> provides another way to update versions not
only in the main module, but in all the modules and scripts in your
distribution. It will also updates versions in the VERSION sections in pods.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 SEE ALSO

L<ShipIt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
