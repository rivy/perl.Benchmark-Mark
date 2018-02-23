## no critic ( Documentation::RequirePodAtEnd Documentation::RequirePodSections )
#(emacs/sublime) -*- mode: perl; tab-width: 4; -*-
# Benchmark::Mark 0.001_1 ("lib/Benchmark/Mark.pm" from "PL.#no-dist/lib/Benchmark/Mark.pm.PL")

package Benchmark::Mark;

# Module Summary

=head1 NAME

Benchmark::Mark - Simple code benchmarking/timing

=head1 VERSION

=over

 $Benchmark::Mark::VERSION = "0.001_1";

=back

=cut

use strict;
use warnings;
#use diagnostics;   # invoke blabbermouth warning mode
use 5.008008;    # earliest tested perl version (v5.8.8); v5.6.1 is no longer testable/reportable

# VERSION: Major.minor[_alpha]  { minor is ODD => alpha/beta/experimental; minor is EVEN => stable/release }
# * NOTE: "boring" versions are preferred (see: http://www.dagolden.com/index.php/369/version-numbers-should-be-boring @@ https://archive.is/7PZQL)
## no critic ( RequireConstantVersion )
{
    our $VERSION = '0.001_1';
    $VERSION =~ s/_//msx; ## numify VERSION (needed for alpha versions)
}

# Module base/ISA and Exports

## ref: Good Practices/Playing Safe in 'perldoc Exporter'
## URLrefs: [base.pm vs @ISA: http://www.perlmonks.org/?node_id=643366]; http://search.cpan.org/perldoc?base; http://search.cpan.org/perldoc?parent; http://perldoc.perl.org/DynaLoader.html; http://perldoc.perl.org/Exporter.html
## TODO?: look into using Readonly::Array and Readonly::Hash for EXPORT_OK and EXPORT_TAGS; ? or Const::Fast

our ( @ISA, @EXPORT_OK, %EXPORT_TAGS ); ## no critic ( ProhibitExplicitISA )
BEGIN { require DynaLoader; require Exporter; @ISA = qw( DynaLoader Exporter ); } ## no critic ( ProhibitExplicitISA )
{
    no strict 'refs'; ## no critic ( ProhibitNoStrict )
    %EXPORT_TAGS = (
        'ALL' => [ ( grep { /^(?!bootstrap|dl_load_flags|import).*$/msx } grep { /^.*[[:lower:]].*$/msx } grep { /^([^_].*)$/msx } keys %{ __PACKAGE__ . q{::} } ) ], ## all non-internal symbols [Note: internal symbols are ALL_CAPS or start with a leading '_']
        '_INTERNAL' => [ ( grep { /^(([_].*)|([[:upper:]_]*))$/msx } keys %{ __PACKAGE__ . q{::} } ) ], ## all internal functions [Note: internal functions are ALL_CAPS or start with a leading '_']
        );
    @EXPORT_OK = ( map { @{$_} } $EXPORT_TAGS{'ALL'} );
}

# Module Interface

sub mark;    # ToDO: ...(eg, return Win32 command line string (already includes prior $ENV{} variable substitutions done by the shell))

####

# Module Implementation

# bootstrap Benchmark::Mark '0.001_1';    # load XS

require Benchmark;
Benchmark->import(':hireswallclock');

my %timers;

sub mark
{
    # mark(): returns ...
    return ( wantarray ? %timers : \%timers ) if defined wantarray;
    if ( defined( my $name = shift ) ) {
        my $timer_ref = ( $timers{$name} ||= {} );
        ${$timer_ref}{stop} = ${$timer_ref}{start} ? ( ${$timer_ref}{stop} ||= Benchmark->new ) : 0;
        ${$timer_ref}{start} ||= Benchmark->new;
        ${$timer_ref}{diff}{raw} = ${$timer_ref}{stop} ? ( ${$timer_ref}{diff}{raw} ||= Benchmark::timediff( ${$timer_ref}{stop}, ${$timer_ref}{start} ) ) : 0;
        if ( ${$timer_ref}{diff}{raw} ) { my @times = @{ ${$timer_ref}{diff}{raw} }; ${$timer_ref}{diff}{calc} = [ $times[0], $times[1] + $times[3], $times[2] + $times[4], $times[1] + $times[3] + $times[2] + $times[4] ]; } ## no critic ( ProhibitMagicNumbers )
        ${$timer_ref}{duration} = ${$timer_ref}{diff}{raw} ? ( ${$timer_ref}{duration} ||= sprintf '%0.6f wallclock secs (%0.3f usr + %0.3f sys = %0.3f CPU)', @{ ${$timer_ref}{diff}{calc} } ) : 0;
    }
    return;
}

1;    # Magic true value required at end of module (for require)

####

=for readme continue

=head1 SYNOPSIS

=for author_to_fill_in
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exemplary as possible.

=over

 use Benchmark::Mark qw/ mark /;
 mark('timer_name');
 ...
 mark('timer_name');
 my @timers = mark();

=back

=head1 DESCRIPTION

=for author_to_fill_in
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.

This module is used to benchmark executing code.

=head1 INSTALLATION

To install this module, run the following commands:

=over

 perl Build.PL
 perl Build
 perl Build test
 perl Build install

=back

This is minor modification of the usual perl build idiom. This version of the idiom is portable across multiple platforms.

Alternatively, the standard make idiom is also available (although it is deprecated):

=over

 perl Makefile.PL
 make
 make test
 make install

=back

(On Windows platforms, you should use B<C<nmake>>or B<C<dmake>>, instead of B<C<make>>.)

Note that the Makefile.PL script is just a pass-through, and Module::Build is still ultimately required for installation.
Makefile.PL will throw an exception if Module::Build is missing from your current installation. C<cpan> will
notify the user of the build prerequisites (and install them for the build, if it is setup to do so [see the cpan
configuration option C<build_requires_install_policy>]).

PPM installation bundles should also be available in the standard PPM repositories (i.e. ActiveState, trouchelle.com [L<http://trouchelle.com/ppm/package.xml>]).

Note: On ActivePerl installations, 'C<perl Build install>' will do a full installation using B<C<ppm>> (see ppm).
During the installation, a PPM package is constructed locally and then subsequently used for the final module install.
This allows for uninstalls (using 'C<ppm uninstall >C<I<MODULE>>' and also keeps local HTML documentation current.

=for future_possibles
    Check into using the PPM perl module, if installed, for installation of this module (removes the ActiveState requirement).

=for readme stop

=head1 INTERFACE

=for author_to_fill_in
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=head2 C<mark( [$timer_name] ): @>

=over

=item * [in] : (optional) timer name/tag (timer (?alternate name) named "$timer_name" is created with start time == now(), if not present; stop time = now(), if present [can be used multiple times, resetting stop time])

=item * [out] : all timers ...

=back

 mark('TIMER_NAME');
 ...
 mark('TIMER_NAME');
 ...
 my @timers = mark();

Start/stop and retrive timers ...

=head1 SUBROUTINES/METHODS

=for author_to_fill_in
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=for readme continue

=head1 RATIONALE

... ToDO: PENDING ...

=for readme stop

=for readme continue

=head1 DEPENDENCIES

=for author_to_fill_in
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

C<Benchmark::Mark> requires C<Carp::Assert> for internal error checking and warnings.

The optional modules C<Win32>, C<Win32::Security::SID>, and C<Win32::TieRegistry> are recommended to allow full glob tilde expansions
for user home directories (eg, C<~administrator> expands to C<C:\Users\Administrator>). Expansion of the single tilde (C<~>) has a backup
implementation based on %ENV variables, and therefore will still work even without the optional modules.

=for readme stop

=head1 INCOMPATIBILITIES

=for author_to_fill_in
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.

=head1 BUGS AND LIMITATIONS

=for author_to_fill_in
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

Please report any bugs or feature requests to C<bug-@rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=>. The developers will be notified, and you'll automatically be notified of progress on your bug as any changes are made.

=head2 Operational Notes

... ToDO: PENDING

=head2 Bugs

No bugs have been reported.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

=over

 perldoc Benchmark::Mark

=back

You can also look for further information at:

=over

=item * CPAN

=over

L<https://metacpan.org/search?q=>

L<http://search.cpan.org/dist/>

L<http://kobesearch.cpan.org/dist/>

=back

=item * CPAN Ratings

=over

L<http://cpanratings.perl.org/dist/>

=back

=item * RT: CPAN's request tracker (aka buglist)

=over

L<http://rt.cpan.org/Public/Dist/Display.html?Name=>

=back

=item * CPANTESTERS: Test results

=over

L<http://www.cpantesters.org/show/.html>

=back

=item * CPANTS: CPAN Testing Service

=over

C<[kwalitee]> L<http://cpants.perl.org/dist/kwalitee/>

C<[ used by]> L<http://cpants.perl.org/dist/used_by/>

=back

=back

=for possible_future
    * AnnoCPAN: Annotated CPAN documentation
      http://annocpan.org/dist/
    * CPANFORUM: Forum discussing Benchmark::Mark
      http://www.cpanforum.com/dist/

=head1 TODO

Expand and polish the documentation.

=head1 TESTING

=for REFERENCE [good documentation/TESTING heading :: URLref: http://search.cpan.org/dist/Net-Amazon-S3/lib/Net/Amazon/S3.pm ]

=for REFERENCE [info re end-user/install vs automated vs release/author testing :: URLref: http://search.cpan.org/~adamk/Test-XT-0.02/lib/Test/XT.pm ]

For additional testing, set the following environment variables to a true value ("true" in the perl sense, meaning non-NULL, non-ZERO value):

=over

=item TEST_AUTHOR

Perform distribution correctness and quality tests, which are essential prior to a public release.

=item TEST_FRAGILE

Perform tests which have a specific (i.e., fragile) execution context (eg, network tests to named hosts).
These are tests that must be coddled with specific execution contexts or set up on specific machines to
complete correctly.

=item TEST_SIGNATURE

Verify signature is present and correct for the distribution.

=item TEST_ALL

Perform ALL (non-FRAGILE) additional/optional tests. Given the likelyhood of test failures without special handling,
tests marked as 'FRAGILE' are still NOT performed unless TEST_FRAGILE is also true. Additionally, note that
the 'build testall' command can be used as an equivalent to setting TEST_ALL to true temporarily, for the duration
of the build, followed by a 'build test'.

=back

=for TODO
    =head1 SEE ALSO

=for readme continue

=head1 LICENSE AND COPYRIGHT

 Copyright (c) 2017-2018, Roy Ivy III <rivy[at]cpan[dot]org>. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the
Perl Artistic License v2.0 (see L<http://opensource.org/licenses/artistic-license-2.0.php>).

=head1 DISCLAIMER OF WARRANTY

 THIS PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS"
 AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT
 ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED
 BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF
 THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 [REFER TO THE FULL LICENSE FOR EXPLICIT DEFINITIONS OF ALL TERMS.]

=head1 ACKNOWLEDGEMENTS

=for TODO
    ...

=head1 AUTHOR

Roy Ivy III <rivy[at]cpan[dot]org>

=head1 CONTRIBUTORS

    ... ToDO: PENDING (from log (using .mailmap, as neeeded); eg, `git log --pretty=short --format="%aN <%aE>" | sort | uniq`)

=for readme stop

=begin IMPLEMENTATION-NOTES

    ... ToDO: PENDING

=end IMPLEMENTATION-NOTES

=begin FUTURE-DOCUMENTATION

    ... ToDO: PENDING

=end FUTURE-DOCUMENTATION

=cut
