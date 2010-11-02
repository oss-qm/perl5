/*    patchlevel.h
 *
 *    Copyright (C) 1993, 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002,
 *    2003, 2004, 2005, 2006, 2007, 2008, 2009, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifndef __PATCHLEVEL_H_INCLUDED__

/* do not adjust the whitespace! Configure expects the numbers to be
 * exactly on the third column */

#define PERL_REVISION	5		/* age */
#define PERL_VERSION	12		/* epoch */
#define PERL_SUBVERSION	2		/* generation */

/* The following numbers describe the earliest compatible version of
   Perl ("compatibility" here being defined as sufficient binary/API
   compatibility to run XS code built with the older version).
   Normally this should not change across maintenance releases.

   Note that this only refers to an out-of-the-box build.  Many non-default
   options such as usemultiplicity tend to break binary compatibility
   more often.

   This is used by Configure et al to figure out 
   PERL_INC_VERSION_LIST, which lists version libraries
   to include in @INC.  See INSTALL for how this works.
*/
#define PERL_API_REVISION	5	/* Adjust manually as needed.  */
#define PERL_API_VERSION	12	/* Adjust manually as needed.  */
#define PERL_API_SUBVERSION	0	/* Adjust manually as needed.  */
/*
   XXX Note:  The selection of non-default Configure options, such
   as -Duselonglong may invalidate these settings.  Currently, Configure
   does not adequately test for this.   A.D.  Jan 13, 2000
*/

#define __PATCHLEVEL_H_INCLUDED__
#endif

/*
	local_patches -- list of locally applied less-than-subversion patches.
	If you're distributing such a patch, please give it a name and a
	one-line description, placed just before the last NULL in the array
	below.  If your patch fixes a bug in the perlbug database, please
	mention the bugid.  If your patch *IS* dependent on a prior patch,
	please place your applied patch line after its dependencies. This
	will help tracking of patch dependencies.

	Please either use 'diff --unified=0' if your diff supports
	that or edit the hunk of the diff output which adds your patch
	to this list, to remove context lines which would give patch
	problems. For instance, if the original context diff is

	   *** patchlevel.h.orig	<date here>
	   --- patchlevel.h	<date here>
	   *** 38,43 ***
	   --- 38,44 ---
	     	,"FOO1235 - some patch"
	     	,"BAR3141 - another patch"
	     	,"BAZ2718 - and another patch"
	   + 	,"MINE001 - my new patch"
	     	,NULL
	     };
	
	please change it to 
	   *** patchlevel.h.orig	<date here>
	   --- patchlevel.h	<date here>
	   *** 41,43 ***
	   --- 41,44 ---
	   + 	,"MINE001 - my new patch"
	     	,NULL
	     };
	
	(Note changes to line numbers as well as removal of context lines.)
	This will prevent patch from choking if someone has previously
	applied different patches than you.

        History has shown that nobody distributes patches that also
        modify patchlevel.h. Do it yourself. The following perl
        program can be used to add a comment to patchlevel.h:

#!perl
die "Usage: perl -x patchlevel.h comment ..." unless @ARGV;
open PLIN, "patchlevel.h" or die "Couldn't open patchlevel.h : $!";
open PLOUT, ">patchlevel.new" or die "Couldn't write on patchlevel.new : $!";
my $seen=0;
while (<PLIN>) {
    if (/\t,NULL/ and $seen) {
       while (my $c = shift @ARGV){
            print PLOUT qq{\t,"$c"\n};
       }
    }
    $seen++ if /local_patches\[\]/;
    print PLOUT;
}
close PLOUT or die "Couldn't close filehandle writing to patchlevel.new : $!";
close PLIN or die "Couldn't close filehandle reading from patchlevel.h : $!";
close DATA; # needed to allow unlink to work win32.
unlink "patchlevel.bak" or warn "Couldn't unlink patchlevel.bak : $!"
  if -e "patchlevel.bak";
rename "patchlevel.h", "patchlevel.bak" or
  die "Couldn't rename patchlevel.h to patchlevel.bak : $!";
rename "patchlevel.new", "patchlevel.h" or
  die "Couldn't rename patchlevel.new to patchlevel.h : $!";
__END__

Please keep empty lines below so that context diffs of this file do
not ever collect the lines belonging to local_patches() into the same
hunk.

 */

#if !defined(PERL_PATCHLEVEL_H_IMPLICIT) && !defined(LOCAL_PATCH_COUNT)
#  if defined(PERL_IS_MINIPERL)
#    define PERL_PATCHNUM "UNKNOWN-miniperl"
#    define PERL_GIT_UNPUSHED_COMMITS /*leave-this-comment*/
#  elif defined(PERL_MICRO)
#    define PERL_PATCHNUM "UNKNOWN-microperl"
#    define PERL_GIT_UNPUSHED_COMMITS /*leave-this-comment*/
#  else
#include "git_version.h"
#  endif
static const char * const local_patches[] = {
	NULL
#ifdef PERL_GIT_UNCOMMITTED_CHANGES
	,"uncommitted-changes"
#endif
	PERL_GIT_UNPUSHED_COMMITS    	/* do not remove this line */
	,"DEBPKG:debian/arm_thread_stress_timeout - http://bugs.debian.org/501970 Raise the timeout of ext/threads/shared/t/stress.t to accommodate slower build hosts"
	,"DEBPKG:debian/cpan_config_path - Set location of CPAN::Config to /etc/perl as /usr may not be writable."
	,"DEBPKG:debian/cpan_definstalldirs - Provide a sensible INSTALLDIRS default for modules installed from CPAN."
	,"DEBPKG:debian/db_file_ver - http://bugs.debian.org/340047 Remove overly restrictive DB_File version check."
	,"DEBPKG:debian/doc_info - Replace generic man(1) instructions with Debian-specific information."
	,"DEBPKG:debian/enc2xs_inc - http://bugs.debian.org/290336 Tweak enc2xs to follow symlinks and ignore missing @INC directories."
	,"DEBPKG:debian/errno_ver - http://bugs.debian.org/343351 Remove Errno version check due to upgrade problems with long-running processes."
	,"DEBPKG:debian/extutils_hacks - Various debian-specific ExtUtils changes"
	,"DEBPKG:debian/fakeroot - Postpone LD_LIBRARY_PATH evaluation to the binary targets."
	,"DEBPKG:debian/instmodsh_doc - Debian policy doesn't install .packlist files for core or vendor."
	,"DEBPKG:debian/ld_run_path - Remove standard libs from LD_RUN_PATH as per Debian policy."
	,"DEBPKG:debian/libnet_config_path - Set location of libnet.cfg to /etc/perl/Net as /usr may not be writable."
	,"DEBPKG:debian/m68k_thread_stress - http://bugs.debian.org/495826 Disable some threads tests on m68k for now due to missing TLS."
	,"DEBPKG:debian/mod_paths - Tweak @INC ordering for Debian"
	,"DEBPKG:debian/module_build_man_extensions - http://bugs.debian.org/479460 Adjust Module::Build manual page extensions for the Debian Perl policy"
	,"DEBPKG:debian/prune_libs - http://bugs.debian.org/128355 Prune the list of libraries wanted to what we actually need."
	,"DEBPKG:fixes/net_smtp_docs - http://bugs.debian.org/100195 [rt.cpan.org #36038] Document the Net::SMTP 'Port' option"
	,"DEBPKG:fixes/processPL - http://bugs.debian.org/357264 [rt.cpan.org #17224] Always use PERLRUNINST when building perl modules."
	,"DEBPKG:debian/perlivp - http://bugs.debian.org/510895 Make perlivp skip include directories in /usr/local"
	,"DEBPKG:debian/disable-zlib-bundling - Disable zlib bundling in Compress::Raw::Zlib"
	,"DEBPKG:debian/cpanplus_definstalldirs - http://bugs.debian.org/533707 Configure CPANPLUS to use the site directories by default."
	,"DEBPKG:debian/cpanplus_config_path - Save local versions of CPANPLUS::Config::System into /etc/perl."
	,"DEBPKG:fixes/autodie-flock - http://bugs.debian.org/543731 Allow for flock returning EAGAIN instead of EWOULDBLOCK on linux/parisc"
	,"DEBPKG:debian/devel-ppport-ia64-optim - http://bugs.debian.org/548943 Work around an ICE on ia64"
	,"DEBPKG:fixes/cpanplus-without-home - http://bugs.debian.org/577011 [rt.cpan.org #52988] Fix CPANPLUS test failures when HOME doesn't exist"
	,"DEBPKG:debian/arm_optim - http://bugs.debian.org/580334 Downgrade the optimization of sv.c on arm due to a gcc-4.4 bug"
	,"DEBPKG:debian/deprecate-with-apt - http://bugs.debian.org/580034 Point users to Debian packages of deprecated core modules"
	,"DEBPKG:fixes/hurd-ccflags - http://bugs.debian.org/587901 Make hints/gnu.sh append to $ccflags rather than overriding them"
	,"DEBPKG:debian/squelch-locale-warnings - http://bugs.debian.org/508764 Squelch locale warnings in Debian package maintainer scripts"
	,"DEBPKG:fixes/lc-numeric-docs - http://bugs.debian.org/379329 [perl #78452] [903eb63] LC_NUMERIC documentation fixes"
	,"DEBPKG:fixes/lc-numeric-sprintf - http://bugs.debian.org/601549 [perl #78632] [b3fd614] Fix sprintf not to ignore LC_NUMERIC with constants"
	,"DEBPKG:fixes/concat-stack-corruption - http://bugs.debian.org/596105 [perl #78674] [e3393f5] Fix stack pointer corruption in pp_concat() with 'use encoding'"
	,"DEBPKG:fixes/h2ph-gcc-4.5 - http://bugs.debian.org/599933 [8d66b3f] h2ph fix for gcc 4.5"
	,"DEBPKG:patchlevel - http://bugs.debian.org/567489 List packaged patches for 5.12.2-2 in patchlevel.h"
	,NULL
};



/* Initial space prevents this variable from being inserted in config.sh  */
#  define	LOCAL_PATCH_COUNT	\
	((int)(sizeof(local_patches)/sizeof(local_patches[0])-2))

/* the old terms of reference, add them only when explicitly included */
#define PATCHLEVEL		PERL_VERSION
#undef  SUBVERSION		/* OS/390 has a SUBVERSION in a system header */
#define SUBVERSION		PERL_SUBVERSION
#endif
