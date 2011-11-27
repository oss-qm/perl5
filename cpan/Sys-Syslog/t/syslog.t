#!perl -T

use strict;
use Config;
use File::Spec;
use Test::More;

# we enable all Perl warnings, but we don't "use warnings 'all'" because 
# we want to disable the warnings generated by Sys::Syslog
no warnings;
use warnings qw(closure deprecated exiting glob io misc numeric once overflow
                pack portable recursion redefine regexp severe signal substr
                syntax taint uninitialized unpack untie utf8 void);

# if someone is using warnings::compat, the previous trick won't work, so we
# must manually disable warnings
$^W = 0 if $] < 5.006;

my $is_Win32  = $^O =~ /win32/i;
my $is_Cygwin = $^O =~ /cygwin/i;

# if testing in core, check that the module is at least available
if ($ENV{PERL_CORE}) {
    plan skip_all => "Sys::Syslog was not build" 
        unless $Config{'extensions'} =~ /\bSyslog\b/;
}

# we also need Socket
plan skip_all => "Socket was not build" 
    unless $Config{'extensions'} =~ /\bSocket\b/;

my $tests;
plan tests => $tests;

# any remaining warning should be severly punished
BEGIN { eval "use Test::NoWarnings"; $tests = $@ ? 0 : 1; }

BEGIN { $tests += 1 }
# ok, now loads them
eval 'use Socket';
use_ok('Sys::Syslog', ':standard', ':extended', ':macros');

BEGIN { $tests += 1 }
# check that the documented functions are correctly provided
can_ok( 'Sys::Syslog' => qw(openlog syslog syslog setlogmask setlogsock closelog) );


BEGIN { $tests += 4 }
# check the diagnostics
# setlogsock()
eval { setlogsock() };
like( $@, qr/^setlogsock\(\): Invalid number of arguments/, 
    "calling setlogsock() with no argument" );

eval { setlogsock(undef) };
like( $@, qr/^setlogsock\(\): Invalid type; must be one of /, 
    "calling setlogsock() with undef" );

eval { setlogsock(\"") };
like( $@, qr/^setlogsock\(\): Unexpected scalar reference/, 
    "calling setlogsock() with a scalar reference" );

eval { setlogsock({}) };
like( $@, qr/^setlogsock\(\): No argument given/, 
    "calling setlogsock() with an empty hash reference" );

BEGIN { $tests += 3 }
# syslog()
eval { syslog() };
like( $@, qr/^syslog: expecting argument \$priority/, 
    "calling syslog() with no argument" );

eval { syslog(undef) };
like( $@, qr/^syslog: expecting argument \$priority/, 
    "calling syslog() with one undef argument" );

eval { syslog('') };
like( $@, qr/^syslog: expecting argument \$format/, 
    "calling syslog() with one empty argument" );


my $test_string = "uid $< is testing Perl $] syslog(3) capabilities";
my $r = 0;

BEGIN { $tests += 8 }
# try to open a syslog using a Unix or stream socket
SKIP: {
    skip "can't connect to Unix socket: _PATH_LOG unavailable", 8
      unless -e Sys::Syslog::_PATH_LOG();

    # The only known $^O eq 'svr4' that needs this is NCR MP-RAS,
    # but assuming 'stream' in SVR4 is probably not that bad.
    my $sock_type = $^O =~ /^(solaris|irix|svr4|powerux)$/ ? 'stream' : 'unix';

    eval { setlogsock($sock_type) };
    is( $@, '', "setlogsock() called with '$sock_type'" );
    TODO: {
        local $TODO = "minor bug";
        SKIP: { skip "TODO $TODO", 1 if $] < 5.006002;
        ok( $r, "setlogsock() should return true: '$r'" );
        }
    }

    # open syslog with a "local0" facility
    SKIP: {
        # openlog()
        $r = eval { openlog('perl', 'ndelay', 'local0') } || 0;
        skip "can't connect to syslog", 6 if $@ =~ /^no connection to syslog available/;
        is( $@, '', "openlog() called with facility 'local0'" );
        ok( $r, "openlog() should return true: '$r'" );

        # syslog()
        $r = eval { syslog('info', "$test_string by connecting to a $sock_type socket") } || 0;
        is( $@, '', "syslog() called with level 'info'" );
        ok( $r, "syslog() should return true: '$r'" );

        # closelog()
        $r = eval { closelog() } || 0;
        is( $@, '', "closelog()" );
        ok( $r, "closelog() should return true: '$r'" );
    }
}


BEGIN { $tests += 22 * 8 }
# try to open a syslog using all the available connection methods
my @passed = ();
for my $sock_type (qw(native eventlog unix pipe stream inet tcp udp)) {
    SKIP: {
        skip "the 'stream' mechanism because a previous mechanism with similar interface succeeded", 22 
            if $sock_type eq 'stream' and grep {/pipe|unix/} @passed;

        # setlogsock() called with an arrayref
        $r = eval { setlogsock([$sock_type]) } || 0;
        skip "can't use '$sock_type' socket", 22 unless $r;
        is( $@, '', "[$sock_type] setlogsock() called with ['$sock_type']" );
        ok( $r, "[$sock_type] setlogsock() should return true: '$r'" );

        # setlogsock() called with a single argument
        $r = eval { setlogsock($sock_type) } || 0;
        skip "can't use '$sock_type' socket", 20 unless $r;
        is( $@, '', "[$sock_type] setlogsock() called with '$sock_type'" );
        ok( $r, "[$sock_type] setlogsock() should return true: '$r'" );

        # openlog() without option NDELAY
        $r = eval { openlog('perl', '', 'local0') } || 0;
        skip "can't connect to syslog", 18 if $@ =~ /^no connection to syslog available/;
        is( $@, '', "[$sock_type] openlog() called with facility 'local0' and without option 'ndelay'" );
        ok( $r, "[$sock_type] openlog() should return true: '$r'" );

        # openlog() with the option NDELAY
        $r = eval { openlog('perl', 'ndelay', 'local0') } || 0;
        skip "can't connect to syslog", 16 if $@ =~ /^no connection to syslog available/;
        is( $@, '', "[$sock_type] openlog() called with facility 'local0' with option 'ndelay'" );
        ok( $r, "[$sock_type] openlog() should return true: '$r'" );

        # syslog() with negative level, should fail
        $r = eval { syslog(-1, "$test_string by connecting to a $sock_type socket") } || 0;
        like( $@, '/^syslog: invalid level\/facility: /', "[$sock_type] syslog() called with level -1" );
        ok( !$r, "[$sock_type] syslog() should return false: '$r'" );

        # syslog() with invalid level, should fail
        $r = eval { syslog("plonk", "$test_string by connecting to a $sock_type socket") } || 0;
        like( $@, '/^syslog: invalid level\/facility: /', "[$sock_type] syslog() called with level plonk" );
        ok( !$r, "[$sock_type] syslog() should return false: '$r'" );

        # syslog() with levels "info" and "notice" (as a strings), should fail
        $r = eval { syslog('info,notice', "$test_string by connecting to a $sock_type socket") } || 0;
        like( $@, '/^syslog: too many levels given: notice/', "[$sock_type] syslog() called with level 'info,notice'" );
        ok( !$r, "[$sock_type] syslog() should return false: '$r'" );

        # syslog() with facilities "local0" and "local1" (as a strings), should fail
        $r = eval { syslog('local0,local1', "$test_string by connecting to a $sock_type socket") } || 0;
        like( $@, '/^syslog: too many facilities given: local1/', "[$sock_type] syslog() called with level 'local0,local1'" );
        ok( !$r, "[$sock_type] syslog() should return false: '$r'" );

        # syslog() with level "info" (as a string), should pass
        $r = eval { syslog('info', "$test_string by connecting to a $sock_type socket") } || 0;
        is( $@, '', "[$sock_type] syslog() called with level 'info' (string)" );
        TODO: {
            local $TODO = 'fails on GNU/Hurd (Debian #650093)' if $^O eq 'gnu';
            ok( $r, "[$sock_type] syslog() should return true: '$r'" );
        }

        # syslog() with level "info" (as a macro), should pass
        { local $! = 1;
          $r = eval { syslog(LOG_INFO(), "$test_string by connecting to a $sock_type socket, setting a fake errno: %m") } || 0;
        }
        is( $@, '', "[$sock_type] syslog() called with level 'info' (macro)" );
        TODO: {
            local $TODO = 'fails on GNU/Hurd (Debian #650093)' if $^O eq 'gnu';
            ok( $r, "[$sock_type] syslog() should return true: '$r'" );
        }

        push @passed, $sock_type;

        SKIP: {
            skip "skipping closelog() tests for 'console'", 2 if $sock_type eq 'console';
            # closelog()
            $r = eval { closelog() } || 0;
            is( $@, '', "[$sock_type] closelog()" );
            TODO: {
                local $TODO = 'fails on GNU/Hurd (Debian #650093)' if $^O eq 'gnu';
                ok( $r, "[$sock_type] closelog() should return true: '$r'" );
            }
        }
    }
}


BEGIN { $tests += 10 }
SKIP: {
    skip "not testing setlogsock('stream') on Win32", 10 if $is_Win32;
    skip "the 'unix' mechanism works, so the tests will likely fail with the 'stream' mechanism", 10 
        if grep {/unix/} @passed;

    skip "not testing setlogsock('stream'): _PATH_LOG unavailable", 10
        unless -e Sys::Syslog::_PATH_LOG();

    # setlogsock() with "stream" and an undef path
    $r = eval { setlogsock("stream", undef ) } || '';
    is( $@, '', "setlogsock() called, with 'stream' and an undef path" );
    if ($is_Cygwin) {
        if (-x "/usr/sbin/syslog-ng") {
            ok( $r, "setlogsock() on Cygwin with syslog-ng should return true: '$r'" );
        }
        else {
            ok( !$r, "setlogsock() on Cygwin without syslog-ng should return false: '$r'" );
        }
    }
    else  {
        ok( $r, "setlogsock() should return true: '$r'" );
    }

    # setlogsock() with "stream" and an empty path
    $r = eval { setlogsock("stream", '' ) } || '';
    is( $@, '', "setlogsock() called, with 'stream' and an empty path" );
    ok( !$r, "setlogsock() should return false: '$r'" );

    # setlogsock() with "stream" and /dev/null
    $r = eval { setlogsock("stream", '/dev/null' ) } || '';
    is( $@, '', "setlogsock() called, with 'stream' and '/dev/null'" );
    ok( $r, "setlogsock() should return true: '$r'" );

    # setlogsock() with "stream" and a non-existing file
    $r = eval { setlogsock("stream", 'test.log' ) } || '';
    is( $@, '', "setlogsock() called, with 'stream' and 'test.log' (file does not exist)" );
    ok( !$r, "setlogsock() should return false: '$r'" );

    # setlogsock() with "stream" and a local file
    SKIP: {
        my $logfile = "test.log";
        open(LOG, ">$logfile") or skip "can't create file '$logfile': $!", 2;
        close(LOG);
        $r = eval { setlogsock("stream", $logfile ) } || '';
        is( $@, '', "setlogsock() called, with 'stream' and '$logfile' (file exists)" );
        ok( $r, "setlogsock() should return true: '$r'" );
        unlink($logfile);
    }
}


BEGIN { $tests += 3 + 4 * 3 }
# setlogmask()
{
    my $oldmask = 0;

    $oldmask = eval { setlogmask(0) } || 0;
    is( $@, '', "setlogmask() called with a null mask" );
    $r = eval { setlogmask(0) } || 0;
    is( $@, '', "setlogmask() called with a null mask (second time)" );
    is( $r, $oldmask, "setlogmask() must return the same mask as previous call");

    my @masks = (
        LOG_MASK(LOG_ERR()), 
        ~LOG_MASK(LOG_INFO()), 
        LOG_MASK(LOG_CRIT()) | LOG_MASK(LOG_ERR()) | LOG_MASK(LOG_WARNING()), 
    );

    for my $newmask (@masks) {
        $r = eval { setlogmask($newmask) } || 0;
        is( $@, '', "setlogmask() called with a new mask" );
        is( $r, $oldmask, "setlogmask() must return the same mask as previous call");
        $r = eval { setlogmask(0) } || 0;
        is( $@, '', "setlogmask() called with a null mask" );
        is( $r, $newmask, "setlogmask() must return the new mask");
        setlogmask($oldmask);
    }
}

BEGIN { $tests += 4 }
SKIP: {
    # case: test the return value of setlogsock()

    # setlogsock("stream") on a non-existent file must fail
    eval { $r = setlogsock("stream", "plonk/log") };
    is( $@, '', "setlogsock() didn't croak");
    ok( !$r, "setlogsock() correctly failed with a non-existent stream path");

    # setlogsock("tcp") must fail if the service is not declared
    my $service = getservbyname("syslog", "tcp") || getservbyname("syslogng", "tcp");
    skip "can't test setlogsock() tcp failure", 2 if $service;
    eval { $r = setlogsock("tcp") };
    is( $@, '', "setlogsock() didn't croak");
    ok( !$r, "setlogsock() correctly failed when tcp services can't be resolved");
}

BEGIN { $tests += 3 }
SKIP: {
    # case: configure Sys::Syslog to use the stream mechanism on a
    #       given file, but remove the file before openlog() is called,
    #       so it fails.

    # create the log file
    my $log = "t/stream";
    open my $fh, ">$log" or skip "can't write file '$log': $!", 3;
    close $fh;

    # configure Sys::Syslog to use it
    $r = eval { setlogsock("stream", $log) };
    is( $@, "", "setlogsock('stream', '$log') -> $r" );
    skip "can't test openlog() failure with a missing stream", 2 if !$r;

    # remove the log and check that openlog() fails
    unlink $log;
    $r = eval { openlog('perl', 'ndelay', 'local0') };
    ok( !$r, "openlog() correctly failed with a non-existent stream" );
    like( $@, '/not writable/', "openlog() correctly croaked with a non-existent stream" );
}

