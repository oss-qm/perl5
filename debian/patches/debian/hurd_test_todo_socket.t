From 31b327f71e31280551ac9666d018b7a4d7b96e7c Mon Sep 17 00:00:00 2001
From: Dominic Hargreaves <dom@earth.li>
Date: Sun, 31 Aug 2014 00:42:47 +0000
Subject: Disable failing GNU/Hurd test in t/io/socket.t

According to Samuel Thibault this test is questionable and should be
discussed with upstream:

"The test seems fishy to me: it is making sure that the name as returned
by recv is *exactly* the same as what the server socket is bound to,
which is 0.0.0.0:some_port but I would expect recv to return the actual
IP address used in the socket, not 0.0.0.0.  It happens that Linux
doesn't return anything at all so it goes fine there, but that's not a
reason. The test should most probably be discussed with upstream."

Bug-Debian: http://bugs.debian.org/758718
Bug: https://rt.perl.org/Ticket/Display.html?id=122657
Patch-Name: debian/hurd_test_todo_socket.t
---
 t/io/socket.t | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/t/io/socket.t b/t/io/socket.t
index b723e3c..93a33bc 100644
--- a/t/io/socket.t
+++ b/t/io/socket.t
@@ -102,8 +102,12 @@ SKIP: {
 	    my $buf;
 	    my $recv_peer = recv($child, $buf, 1000, 0);
 	    # [perl #118843]
-	    ok_child($recv_peer eq '' || $recv_peer eq $bind_name,
-	       "peer from recv() should be empty or the remote name");
+	    if ($^O eq 'gnu') {
+		skip('fails on GNU/Hurd (Debian #758718)', 1);
+	    } else {
+		ok_child($recv_peer eq '' || $recv_peer eq $bind_name,
+	           "peer from recv() should be empty or the remote name");
+	    }
 	    while(defined recv($child, my $tmp, 1000, 0)) {
 		last if length $tmp == 0;
 		$buf .= $tmp;
