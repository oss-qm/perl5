Debian bug #258618.

diff -Naur --exclude=debian perl-5.8.4.orig/hints/gnu.sh perl-5.8.4/hints/gnu.sh
--- perl-5.8.4.orig/hints/gnu.sh	2004-02-16 23:45:20.000000000 +1100
+++ perl-5.8.4/hints/gnu.sh	2004-09-28 01:04:37.000000000 +1000
@@ -18,6 +18,9 @@
 # Flags needed by programs that use dynamic linking.
 ccdlflags='-Wl,-E'
 
+# Debian bug #258618
+ccflags='-D_GNU_SOURCE'
+
 # The following routines are only available as stubs in GNU libc.
 # XXX remove this once metaconf detects the GNU libc stubs.
 d_msgctl='undef'
