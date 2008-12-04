Remove a spurious undefined warning when using getopts.pl with -w.

diff -Naur --exclude=debian perl-5.8.4.orig/lib/getopts.pl perl-5.8.4/lib/getopts.pl
--- perl-5.8.4.orig/lib/getopts.pl	2000-10-13 10:58:43.000000000 +1100
+++ perl-5.8.4/lib/getopts.pl	2005-03-06 22:31:04.000000000 +1100
@@ -31,7 +31,7 @@
 				}
 				eval "
 				push(\@opt_$first, \$rest);
-				if(\$opt_$first eq '') {
+				if (!defined \$opt_$first or \$opt_$first eq '') {
 					\$opt_$first = \$rest;
 				}
 				else {
