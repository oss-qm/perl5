# Test to perform udp protocol testing.

use strict;

sub isWindowsVista {
   return unless $^O eq 'MSWin32' or $^O eq "cygwin";
   return unless eval { require Win32 };
   return unless defined &Win32::GetOSVersion();

   #is this Vista or later?
   my ($string, $major, $minor, $build, $id) = Win32::GetOSVersion();
   return $build >= 6;

}

use Test::More tests => 2;
BEGIN {use_ok('Net::Ping')};

SKIP: {
    skip "No udp echo port", 1 unless getservbyname('echo', 'udp');
    skip "udp ping blocked by Window's default settings", 1 if isWindowsVista();
    skip "believed to be broken in Hurd (http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=709385)", 1 if $^O eq "gnu";
    my $p = new Net::Ping "udp";
    is($p->ping("127.0.0.1"), 1);
}
