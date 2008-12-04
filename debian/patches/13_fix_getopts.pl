Remove a spurious undefined warning when using getopts.pl with -w.

diff -Naur --exclude=debian perl-5.8.6.orig/lib/getopts.pl perl-5.8.6/lib/getopts.pl
--- perl-5.8.6.orig/lib/getopts.pl	2000-10-13 10:58:43.000000000 +1100
+++ perl-5.8.6/lib/getopts.pl	2005-05-21 14:48:18.000000000 +1000
@@ -31,7 +31,7 @@
 				}
 				eval "
 				push(\@opt_$first, \$rest);
-				if(\$opt_$first eq '') {
+				if (!defined \$opt_$first or \$opt_$first eq '') {
 					\$opt_$first = \$rest;
 				}
 				else {
