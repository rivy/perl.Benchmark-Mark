#!perl -w   -- -*- tab-width: 4; mode: perl -*-     ## no critic ( RequireTidyCode RequireVersionVar )
## no critic ( Capitalization ProhibitStringyEval RequireArgUnpacking )

use strict;
use warnings;
use English qw/ -no_match_vars /;   # enable long form built-in variable names; '-no_match_vars' avoids regex performance penalty for perl versions <= 5.16

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars ProhibitPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;  # DISABLE buffering on STDIN, STDOUT, and STDERR
}

my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; };

use Test::More;

# configure 'lib' for command line testing, when needed
if ( !$ENV{HARNESS_ACTIVE} ) {
    # not executing under Test::Harness (eg, executing directly from command line)
    use lib qw{ blib/arch };   # only needed for dynamic module loads (eg, compiled XS) [ removable if no XS ]
    use lib qw{ lib };         # use 'lib' content (so 'blib/arch' version doesn't always have to be built/updated 1st)
    }

#

plan tests => 11 + ($haveTestNoWarnings ? 1 : 0);

#
{; ## no critic ( ProhibitBuiltinHomonyms ProhibitSubroutinePrototypes )
sub say  (@) { return print @_, "\n" }          # ( @:MSGS ) => $:success
sub sayf (@) { return say sprintf shift, @_ }   # ( @:MSGS ) => $:success
}
#

# Tests

use Test::Without;

run {
    my $success = eval q/require Benchmark::Mark/;
    isnt( $success, 1, q/importing Benchmark::Mark fails when Benchmark isn't available/);
} without 'Benchmark';

run {
    my $success = eval q/require Benchmark::Mark/;
    is  ( $success, 1, q/importing Benchmark::Mark succeeds when Benchmark is available/);
} with 'Benchmark';

#

use Benchmark;
Benchmark::Mark->import( qw/ mark / );

mark('tag#1');
mark('tag#repeated_stop');
mark('tag#repeated_stop');
mark('tag#3');
mark('tag#3');
mark('tag#4');
mark('tag#4');
mark('tag#repeated_stop');
mark('tag#1');

my $timers_ref = mark();
my %timers = mark();

is( ref $timers_ref, 'HASH', q{returned ref from mark() is HASH} );
is_deeply( $timers_ref, \%timers, q{returned HASH_ref and HASH from mark() are equivalent});

my $time_diff;

$time_diff = @{Benchmark::timediff($timers{'tag#1'}{stop}, $timers{'tag#1'}{start})}[0];
ok( $time_diff >= 0, q{start/stop times for a timer are correctly sequenced} );

$time_diff = @{Benchmark::timediff($timers{'tag#4'}{start}, $timers{'tag#1'}{start})}[0];
ok( $time_diff >= 0, q{start times for sequential timers are correctly sequenced} );

$time_diff = @{Benchmark::timediff($timers{'tag#repeated_stop'}{stop}, $timers{'tag#repeated_stop'}{start})}[0];
ok( $time_diff >= 0, q{start/stop times for a timer with repeated stops are correctly sequenced} );

$time_diff = @{$timers{'tag#1'}{diff}{calc}}[0];
ok( $time_diff > 0, q{timer has a non-zero calculated 'wall-clock' duration} );

$time_diff = @{$timers{'tag#1'}{diff}{calc}}[0] - @{$timers{'tag#3'}{diff}{calc}}[0];
ok( $time_diff > 0, q{timers "surrounding" other timers have longer 'wall-clock' durations} );

ok( defined $timers{'tag#1'}{duration}, q{timer has a defined duration string} );
ok( $timers{'tag#1'}{duration} ne q//,  q{timer duration string is not non-null} );

# () = say ref $timers_ref;
# () = sayf '%0.6fs', @{Benchmark::timediff($timers{'tag#2'}{start}, $timers{'tag#1'}{start})}[0];


#### SUBs ---------------------------------------------------------------------------------------##


sub _is_const { my $isVariable = eval { ($_[0]) = $_[0]; 1; }; return !$isVariable; }

sub untaint {
    # untaint( $|@ ): returns $|@
    # RETval: variable with taint removed

    # BLINDLY untaint input variables
    # ref: [Favorite method of untainting](http://www.perlmonks.org/?node_id=516577) @@ <http://archive.is/KvkF7>
    # ref: [Intro to Perl's Taint Mode](http://www.webreference.com/programming/perl/taint) @@ <http://archive.is/SQCLF>

    use Carp;

    #my $me = (caller(0))[3];
    #if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me.'($_) instead?)'; return; }
    #if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

    my $arg_ref;
    $arg_ref = \@_;
    $arg_ref = [ @_ ] if defined wantarray;     ## no critic (ProhibitPostfixControls)  ## break aliasing if non-void return context

    for my $arg ( @{$arg_ref} ) {
        if (defined $arg) {
            if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
            $arg = ( $arg =~ m/\A(.*)\z/msx ) ? $1 : undef;
            }
        }

    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
    }

sub is_tainted {
    ## no critic ( ProhibitStringyEval RequireCheckingReturnValueOfEval ) # ToDO: remove/revisit
    # ref: [perlsec - Laundering and Detecting Tainted Data](http://perldoc.perl.org/perlsec.html#Laundering-and-Detecting-Tainted-Data) @@ <http://archive.is/eWwJ3#35%>
    return ! eval { eval (q/#/ . substr join(q//, @_), 0, 0); 1 };
    }

sub in_taint_mode {
    ## no critic ( RequireBriefOpen RequireInitializationForLocalVars ProhibitStringyEval RequireCheckingReturnValueOfEval ProhibitBarewordFileHandles ProhibitTwoArgOpen ) # ToDO: remove/revisit
    # ref: ["Taint" source]<http://cpansearch.perl.org/src/PHOENIX/Taint-0.09/Taint.pm> @@ <http://archive.is/1O8s1>
    my $taint = q//;

    if (not is_tainted( $taint )) {
        $taint = substr "$PROGRAM_NAME $EXECUTABLE_NAME", 0, 0;
        }

    if (not is_tainted( $taint )) {
        $taint = substr join(q//, @ARGV, %ENV), 0, 0;
        }

    if (not is_tainted( $taint )) {
        local(*FILE);
        my $data = q{};
        for ( qw( /dev/null nul / . .. ), values %INC, $PROGRAM_NAME, $EXECUTABLE_NAME ) {
            # lots of possiblities to maximize the possibility of getting tainted data ## * yes, even reading from /dev/null works!
            last if open FILE, $_
                and defined sysread FILE, $data, 1
            }
        () = close FILE;
        $taint = substr $data, 0, 0;
        }

    return is_tainted( $taint );
    }
