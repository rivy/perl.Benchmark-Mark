#!perl -w   -- -*- tab-width: 4; mode: perl -*-

# t/02.exports.t - evaluate expected symbol table exports

# ToDO: Modify untaint() to allow UNDEF argument(s) [needs to be changed across all tests]

use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Test::Differences;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};
plan skip_all => 'TAINT mode not supported (Module::Build is eval tainted)' if in_taint_mode();

use Module::Build;

my $mb = Module::Build->current();

my $module_name = $mb->module_name;

plan skip_all => 'No symbol table exports specified' if not defined $mb->notes('exports_aref');

my @exports = @{$mb->notes('exports_aref')};

my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; };

plan tests => 3 + ($haveTestNoWarnings ? 1 : 0);

# _or_ use $ENV variables to exchange state
## untaint
#my $module_name = untaint( $ENV{_BUILD_module_name} );

use_ok( $module_name );

{; no strict 'refs'; ## no critic ( TestingAndDebugging::ProhibitNoStrict )

eq_or_diff (\@{$module_name}, [ ], '@EXPORT is empty');
eq_or_diff ([ sort (@{$module_name.'::EXPORT_OK'}) ], [ sort @exports ], '@EXPORT_OK has expected values');

}


#### SUBs ---------------------------------------------------------------------------------------##

sub _is_const { my $isVariable = eval { ($_[0]) = $_[0]; 1; }; return !$isVariable; }

sub untaint {
    # untaint( $|@ ): returns $|@
    # RETval: variable with taint removed

    # BLINDLY untaint input variables
    # URLref: [Favorite method of untainting] http://www.perlmonks.org/?node_id=516577
    # URLref: [Intro to Perl's Taint Mode] http://www.webreference.com/programming/perl/taint

    use Carp;

    #my $me = (caller(0))[3];
    #if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me.'($_) instead?)'; return; }
    #if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

    my $arg_ref;
    $arg_ref = \@_;
    $arg_ref = [ @_ ] if defined wantarray;     ## no critic (ProhibitPostfixControls)  ## break aliasing if non-void return context

    for my $arg ( @{$arg_ref} ) {
        if (defined($arg)) {
            if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
            $arg = ( $arg =~ m/\A(.*)\z/msx ) ? $1 : undef;
            }
        }

    return wantarray ? @{$arg_ref} : "@{$arg_ref}";
    }

sub is_tainted {
    ## no critic ( ProhibitStringyEval RequireCheckingReturnValueOfEval ) # ToDO: remove/revisit
    # URLref: [perlsec - Laundering and Detecting Tainted Data] http://perldoc.perl.org/perlsec.html#Laundering-and-Detecting-Tainted-Data
    return ! eval { eval(q{#} . substr(join(q{}, @_), 0, 0)); 1 };
    }

sub in_taint_mode {
    ## no critic ( RequireBriefOpen RequireInitializationForLocalVars ProhibitStringyEval RequireCheckingReturnValueOfEval ProhibitBarewordFileHandles ProhibitTwoArgOpen ) # ToDO: remove/revisit
    # modified from Taint source @ URLref: http://cpansearch.perl.org/src/PHOENIX/Taint-0.09/Taint.pm
    my $taint = q{};

    if (not is_tainted( $taint )) {
        $taint = substr("$0$^X", 0, 0);
        }

    if (not is_tainted( $taint )) {
        $taint = substr(join("", @ARGV, %ENV), 0, 0);
        }

    if (not is_tainted( $taint )) {
        local(*FILE);
        my $data = q{};
        for (qw(/dev/null nul / . ..), values %INC, $0, $^X) {
            # Why so many? Maybe a file was just deleted or moved;
            # you never know! :-)  At this point, taint checks
            # are probably off anyway, but this is the ironclad
            # way to get tainted data if it's possible.
            # (Yes, even reading from /dev/null works!)
            #
            last if open FILE, $_
            and defined sysread FILE, $data, 1
            }
        close( FILE );
        $taint = substr($data, 0, 0);
        }

    return is_tainted( $taint );
    }
