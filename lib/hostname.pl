# From: asherman@fmrco.com (Aaron Sherman)
#
# This library is no longer being maintained, and is included for backward
# compatibility with Perl 4 programs which may require it.
# This legacy library is deprecated and will be removed in a future
# release of perl.
#
# In particular, this should not be used as an example of modern Perl
# programming techniques.
#
# Suggested alternative: Sys::Hostname

warn( "The 'hostname.pl' legacy library is deprecated and will be"
      . " removed in the next major release of perl. Please use the"
      . " Sys::Hostname module instead." );

sub hostname
{
	local(*P,@tmp,$hostname,$_);
	if (open(P,"hostname 2>&1 |") && (@tmp = <P>) && close(P))
	{
		chop($hostname = $tmp[$#tmp]);
	}
	elsif (open(P,"uname -n 2>&1 |") && (@tmp = <P>) && close(P))
	{
		chop($hostname = $tmp[$#tmp]);
	}
	else
	{
		die "$0: Cannot get hostname from 'hostname' or 'uname -n'\n";
	}
	@tmp = ();
	close P; # Just in case we failed in an odd spot....
	$hostname;
}

1;
