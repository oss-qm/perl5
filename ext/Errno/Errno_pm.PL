use ExtUtils::MakeMaker;
use Config;
use strict;

our $VERSION = "1.11";

my %err = ();
my %wsa = ();

# Symbian cross-compiling environment.
my $IsSymbian = exists $ENV{SDK} && -d "$ENV{SDK}\\epoc32";

my $IsMSWin32 = $^O eq 'MSWin32' && !$IsSymbian;

unlink "Errno.pm" if -f "Errno.pm";
unlink "Errno.tmp" if -f "Errno.tmp";
open OUT, ">Errno.tmp" or die "Cannot open Errno.tmp: $!";
select OUT;
my $file;
my @files = get_files();
if ($Config{gccversion} ne '' && $^O eq 'MSWin32') {
    # MinGW complains "warning: #pragma system_header ignored outside include
    # file" if the header files are processed individually, so include them
    # all in .c file and process that instead.
    open INCS, '>includes.c' or
	die "Cannot open includes.c";
    foreach $file (@files) {
	next if $file eq 'errno.c';
	next unless -f $file;
	print INCS qq[#include "$file"\n];
    }
    close INCS;
    process_file('includes.c');
    unlink 'includes.c';
}
else {
    foreach $file (@files) {
	process_file($file);
    }
}
write_errno_pm();
unlink "errno.c" if -f "errno.c";
close OUT or die "Error closing Errno.tmp: $!";
select STDOUT;
rename "Errno.tmp", "Errno.pm" or die "Cannot rename Errno.tmp to Errno.pm: $!";

sub process_file {
    my($file) = @_;

    # for win32 perl under cygwin, we need to get a windows pathname
    if ($^O eq 'MSWin32' && $Config{cc} =~ /\B-mno-cygwin\b/ &&
        defined($file) && !-f $file) {
        chomp($file = `cygpath -w "$file"`);
    }

    return unless defined $file and -f $file;
#    warn "Processing $file\n";

    local *FH;
    if (($^O eq 'VMS') && ($Config{vms_cc_type} ne 'gnuc')) {
	unless(open(FH," LIBRARY/EXTRACT=ERRNO/OUTPUT=SYS\$OUTPUT $file |")) {
            warn "Cannot open '$file'";
            return;
	}     
    } elsif ($Config{gccversion} ne ''
             # OpenSTEP has gcc 2.7.2.1 which recognizes but
	     # doesn't implement the -dM flag.
	     && $^O ne 'openstep' && $^O ne 'next' && $^O ne 'darwin'
	     ) { 
	# With the -dM option, gcc outputs every #define it finds
	unless(open(FH,"$Config{cc} -E -dM $Config{cppflags} $file |")) {
            warn "Cannot open '$file'";
            return;
	}     
    } else {
	unless(open(FH,"< $file")) {
	    # This file could be a temporary file created by cppstdin
	    # so only warn under -w, and return
            warn "Cannot open '$file'" if $^W;
            return;
	}
    }
    
    if ($^O eq 'MacOS') {
	while(<FH>) {
	    $err{$1} = $2
		if /^\s*#\s*define\s+(E\w+)\s+(\d+)/;
	}
    } else {
	while(<FH>) {
	    $err{$1} = 1
		if /^\s*#\s*define\s+(E\w+)\s+/;
            if ($IsMSWin32) {
	        $wsa{$1} = 1
	    	    if /^\s*#\s*define\s+WSA(E\w+)\s+/;
            }
	}
    }

    close(FH);
}

my $cppstdin;

sub default_cpp {
    unless (defined $cppstdin) {
	use File::Spec;
	$cppstdin = $Config{cppstdin};
	my $upup_cppstdin = File::Spec->catfile(File::Spec->updir,
						File::Spec->updir,
						"cppstdin");
	my $cppstdin_is_wrapper =
	    ($cppstdin eq 'cppstdin'
		and -f $upup_cppstdin
		    and -x $upup_cppstdin);
	$cppstdin = $upup_cppstdin if $cppstdin_is_wrapper;
    }
    return "$cppstdin $Config{cppflags} $Config{cppminus}";
}

sub get_files {
    my %file = ();
    # VMS keeps its include files in system libraries (well, except for Gcc)
    if ($^O eq 'VMS') {
	if ($Config{vms_cc_type} eq 'decc') {
	    $file{'Sys$Library:DECC$RTLDEF.TLB'} = 1;
	} elsif ($Config{vms_cc_type} eq 'vaxc') {
	    $file{'Sys$Library:vaxcdef.tlb'} = 1;
	} elsif ($Config{vms_cc_type} eq 'gcc') {
	    $file{'gnu_cc_include:[000000]errno.h'} = 1;
	}
    } elsif ($^O eq 'os390') {
	# OS/390 C compiler doesn't generate #file or #line directives
	$file{'/usr/include/errno.h'} = 1;
    } elsif ($^O eq 'vmesa') {
	# OS/390 C compiler doesn't generate #file or #line directives
	$file{'../../vmesa/errno.h'} = 1;
    } elsif ($Config{archname} eq 'epoc') {
	# Watch out for cross compiling for EPOC (usually done on linux)
	$file{'/usr/local/epocemx/epocsdk/include/libc/sys/errno.h'} = 1;
    } elsif ($Config{archname} eq 'arm-riscos') {
	# Watch out for cross compiling for RISC OS
	my $dep = `echo "#include <errno.h>" | gcc -E -M -`;
	if ($dep =~ /(\S+errno\.h)/) {
	     $file{$1} = 1;
	}
    } elsif ($^O eq 'linux' &&
	      $Config{gccversion} ne '' && 
	      $Config{gccversion} !~ /intel/i
	      # might be using, say, Intel's icc
	     ) {
	# Some Linuxes have weird errno.hs which generate
	# no #file or #line directives
	my $linux_errno_h = -e '/usr/include/errno.h' ?
	    '/usr/include/errno.h' : '/usr/local/include/errno.h';
	$file{$linux_errno_h} = 1;
    } elsif ($^O eq 'MacOS') {
	# note that we are only getting the GUSI errno's here ...
	# we might miss out on compiler-specific ones
	$file{"$ENV{GUSI}include:sys:errno.h"} = 1;

    } elsif ($^O eq 'beos' || $^O eq 'haiku') {
	# hidden in a special place
	$file{'/boot/develop/headers/posix/errno.h'} = 1;

    } elsif ($^O eq 'vos') {
	# avoid problem where cpp returns non-POSIX pathnames
	$file{'/system/include_library/errno.h'} = 1;
    } elsif ($IsSymbian) {
        my $SDK = $ENV{SDK};
        $SDK =~ s!\\!/!g;
	$file{"$SDK/epoc32/include/libc/sys/errno.h"} = 1;
    } else {
	open(CPPI,"> errno.c") or
	    die "Cannot open errno.c";

	if ($^O eq 'NetWare') {
	    print CPPI "#include <nwerrno.h>\n";
	} else {
	    print CPPI "#include <errno.h>\n";
	    if ($IsMSWin32) {
		print CPPI "#define _WINSOCKAPI_\n"; # don't drag in everything
		print CPPI "#include <winsock.h>\n";
	    }
	}

	close(CPPI);

	# invoke CPP and read the output
	if ($IsMSWin32 || $^O eq 'NetWare') {
	    open(CPPO,"$Config{cpprun} $Config{cppflags} errno.c |") or
		die "Cannot run '$Config{cpprun} $Config{cppflags} errno.c'";
	} else {
	    my $cpp = default_cpp();
	    open(CPPO,"$cpp < errno.c |") or
		die "Cannot exec $cpp";
	}

	my $pat;
	if (($IsMSWin32 || $^O eq 'NetWare') and $Config{cc} =~ /^bcc/i) {
	    $pat = '^/\*\s+(.+)\s+\d+\s*:\s+\*/';
	}
	else {
	    $pat = '^#\s*(?:line)?\s*\d+\s+"([^"]+)"';
	}
	while(<CPPO>) {
	    if ($^O eq 'os2' or $IsMSWin32 or $^O eq 'NetWare') {
		if (/$pat/o) {
		   my $f = $1;
		   $f =~ s,\\\\,/,g;
		   $file{$f} = 1;
		}
	    }
	    else {
		$file{$1} = 1 if /$pat/o;
	    }
	}
	close(CPPO);
    }
    return keys %file;
}

sub write_errno_pm {
    my $err;

    # quick sanity check

    die "No error definitions found" unless keys %err;

    # create the CPP input

    open(CPPI,"> errno.c") or
	die "Cannot open errno.c";

    if ($^O eq 'NetWare') {
	print CPPI "#include <nwerrno.h>\n";
	} 
    else {
	print CPPI "#include <errno.h>\n";
    }
    if ($IsMSWin32) {
	print CPPI "#include <winsock.h>\n";
	foreach $err (keys %wsa) {
	    print CPPI "#ifndef $err\n";
	    print CPPI "#define $err WSA$err\n";
	    print CPPI "#endif\n";
	    $err{$err} = 1;
	}
    }
 
    foreach $err (keys %err) {
	print CPPI '"',$err,'" [[',$err,']]',"\n";
    }

    close(CPPI);

    unless ($^O eq 'MacOS' || $^O eq 'beos') {	# trust what we have / get later
    # invoke CPP and read the output

	if ($^O eq 'VMS') {
	    my $cpp = "$Config{cppstdin} $Config{cppflags} $Config{cppminus}";
	    $cpp =~ s/sys\$input//i;
	    open(CPPO,"$cpp  errno.c |") or
		die "Cannot exec $Config{cppstdin}";
	} elsif ($IsMSWin32 || $^O eq 'NetWare') {
	    open(CPPO,"$Config{cpprun} $Config{cppflags} errno.c |") or
		die "Cannot run '$Config{cpprun} $Config{cppflags} errno.c'";
	} elsif ($IsSymbian) {
            my $cpp = "gcc -E -I$ENV{SDK}\\epoc32\\include\\libc -";
	    open(CPPO,"$cpp < errno.c |")
		or die "Cannot exec $cpp";
        } else {
	    my $cpp = default_cpp();
	    open(CPPO,"$cpp < errno.c |")
		or die "Cannot exec $cpp";
	}

	%err = ();

	while(<CPPO>) {
	    my($name,$expr);
	    next unless ($name, $expr) = /"(.*?)"\s*\[\s*\[\s*(.*?)\s*\]\s*\]/;
	    next if $name eq $expr;
	    $expr =~ s/\(?\([a-z_]\w*\)([^\)]*)\)?/$1/i; # ((type)0xcafebabe) at alia
	    $expr =~ s/((?:0x)?[0-9a-fA-F]+)[LU]+\b/$1/g; # 2147483647L et alia
	    next if $expr =~ m/^[a-zA-Z]+$/; # skip some Win32 functions
	    if($expr =~ m/^0[xX]/) {
		$err{$name} = hex $expr;
	    }
	    else {
	    $err{$name} = eval $expr;
	}
	    delete $err{$name} unless defined $err{$name};
	}
	close(CPPO);
    }

    # Many of the E constants (including ENOENT, which is being
    # used in the Perl test suite a lot), are available only as
    # enums in BeOS, so compiling and executing some code is about
    # only way to find out what the numeric Evalues are. In fact above, we
    # didn't even bother to get the values of the ones that have numeric
    # values, since we can get all of them here, anyway.

    if ($^O eq 'beos') {
	if (open(C, ">errno.c")) {
	    my @allerrs = keys %err;
	    print C <<EOF;
#include <errno.h>
#include <stdio.h>
int main() {
EOF
            for (@allerrs) {
		print C qq[printf("$_ %d\n", $_);]
	    }
            print C "}\n";
            close C;
            system("cc -o errno errno.c");
            unlink("errno.c");
            if (open(C, "./errno|")) {
		while (<C>) {
		    if (/^(\w+) (-?\d+)$/) { $err{$1} = $2 }
		}
		close(C);
	    } else {
		die "failed to execute ./errno: $!\n";
	    }
            unlink("errno");
        } else {
	    die "failed to create errno.c: $!\n";
	}
    }

    # Write Errno.pm

    print <<"EDQ";
#
# This file is auto-generated. ***ANY*** changes here will be lost
#

package Errno;
our (\@EXPORT_OK,\%EXPORT_TAGS,\@ISA,\$VERSION,\%errno,\$AUTOLOAD);
use Exporter ();
use strict;

\$VERSION = "$VERSION";
\$VERSION = eval \$VERSION;
\@ISA = qw(Exporter);

EDQ
   
    my $len = 0;
    my @err = sort { $err{$a} <=> $err{$b} } keys %err;
    map { $len = length if length > $len } @err;

    my $j = "\@EXPORT_OK = qw(" . join(" ",keys %err) . ");\n";
    $j =~ s/(.{50,70})\s/$1\n\t/g;
    print $j,"\n";

print <<'ESQ';
%EXPORT_TAGS = (
    POSIX => [qw(
ESQ

    my $k = join(" ", grep { exists $err{$_} } 
	qw(E2BIG EACCES EADDRINUSE EADDRNOTAVAIL EAFNOSUPPORT
	EAGAIN EALREADY EBADF EBUSY ECHILD ECONNABORTED
	ECONNREFUSED ECONNRESET EDEADLK EDESTADDRREQ EDOM EDQUOT
	EEXIST EFAULT EFBIG EHOSTDOWN EHOSTUNREACH EINPROGRESS
	EINTR EINVAL EIO EISCONN EISDIR ELOOP EMFILE EMLINK
	EMSGSIZE ENAMETOOLONG ENETDOWN ENETRESET ENETUNREACH
	ENFILE ENOBUFS ENODEV ENOENT ENOEXEC ENOLCK ENOMEM
	ENOPROTOOPT ENOSPC ENOSYS ENOTBLK ENOTCONN ENOTDIR
	ENOTEMPTY ENOTSOCK ENOTTY ENXIO EOPNOTSUPP EPERM
	EPFNOSUPPORT EPIPE EPROCLIM EPROTONOSUPPORT EPROTOTYPE
	ERANGE EREMOTE ERESTART EROFS ESHUTDOWN ESOCKTNOSUPPORT
	ESPIPE ESRCH ESTALE ETIMEDOUT ETOOMANYREFS ETXTBSY
	EUSERS EWOULDBLOCK EXDEV));

    $k =~ s/(.{50,70})\s/$1\n\t/g;
    print "\t",$k,"\n    )]\n);\n\n";

    foreach $err (@err) {
	printf "sub %s () { %d }\n",,$err,$err{$err};
    }

    print <<'ESQ';

sub TIEHASH { bless [] }

sub FETCH {
    my ($self, $errname) = @_;
    my $proto = prototype("Errno::$errname");
    my $errno = "";
    if (defined($proto) && $proto eq "") {
	no strict 'refs';
	$errno = &$errname;
        $errno = 0 unless $! == $errno;
    }
    return $errno;
}

sub STORE {
    require Carp;
    Carp::confess("ERRNO hash is read only!");
}

*CLEAR = \&STORE;
*DELETE = \&STORE;

sub NEXTKEY {
    my($k,$v);
    while(($k,$v) = each %Errno::) {
	my $proto = prototype("Errno::$k");
	last if (defined($proto) && $proto eq "");
    }
    $k
}

sub FIRSTKEY {
    my $s = scalar keys %Errno::;	# initialize iterator
    goto &NEXTKEY;
}

sub EXISTS {
    my ($self, $errname) = @_;
    my $r = ref $errname;
    my $proto = !$r || $r eq 'CODE' ? prototype($errname) : undef;
    defined($proto) && $proto eq "";
}

tie %!, __PACKAGE__;

1;
__END__

=head1 NAME

Errno - System errno constants

=head1 SYNOPSIS

    use Errno qw(EINTR EIO :POSIX);

=head1 DESCRIPTION

C<Errno> defines and conditionally exports all the error constants
defined in your system C<errno.h> include file. It has a single export
tag, C<:POSIX>, which will export all POSIX defined error numbers.

C<Errno> also makes C<%!> magic such that each element of C<%!> has a
non-zero value only if C<$!> is set to that value. For example:

    use Errno;

    unless (open(FH, "/fangorn/spouse")) {
        if ($!{ENOENT}) {
            warn "Get a wife!\n";
        } else {
            warn "This path is barred: $!";
        } 
    } 

If a specified constant C<EFOO> does not exist on the system, C<$!{EFOO}>
returns C<"">.  You may use C<exists $!{EFOO}> to check whether the
constant is available on the system.

=head1 CAVEATS

Importing a particular constant may not be very portable, because the
import will fail on platforms that do not have that constant.  A more
portable way to set C<$!> to a valid value is to use:

    if (exists &Errno::EFOO) {
        $! = &Errno::EFOO;
    }

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT

Copyright (c) 1997-8 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

ESQ

}
