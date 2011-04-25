warn "Legacy library @{[(caller(0))[6]]} will be removed from the Perl core distribution in the next major release. Please install it from the CPAN distribution Perl4::CoreLibs. It is being used at @{[(caller)[1]]}, line @{[(caller)[2]]}.\n";

# By Brandon S. Allbery
#
# This library is no longer being maintained, and is included for backward
# compatibility with Perl 4 programs which may require it.
# This legacy library is deprecated and will be removed in a future
# release of perl.
# In particular, this should not be used as an example of modern Perl
# programming techniques.
#
# Suggested alternative: Cwd

#
# Usage: $cwd = &getcwd;

sub getcwd
{
    local($dotdots, $cwd, @pst, @cst, $dir, @tst);

    unless (@cst = stat('.'))
    {
	warn "stat(.): $!";
	return '';
    }
    $cwd = '';
    do
    {
	$dotdots .= '/' if $dotdots;
	$dotdots .= '..';
	@pst = @cst;
	unless (opendir(getcwd'PARENT, $dotdots))			#'))
	{
	    warn "opendir($dotdots): $!";
	    return '';
	}
	unless (@cst = stat($dotdots))
	{
	    warn "stat($dotdots): $!";
	    closedir(getcwd'PARENT);					#');
	    return '';
	}
	if ($pst[0] == $cst[0] && $pst[1] == $cst[1])
	{
	    $dir = '';
	}
	else
	{
	    do
	    {
		unless (defined ($dir = readdir(getcwd'PARENT)))        #'))
		{
		    warn "readdir($dotdots): $!";
		    closedir(getcwd'PARENT);				#');
		    return '';
		}
		unless (@tst = lstat("$dotdots/$dir"))
		{
		    # warn "lstat($dotdots/$dir): $!";
		    # closedir(getcwd'PARENT);				#');
		    # return '';
		}
	    }
	    while ($dir eq '.' || $dir eq '..' || $tst[0] != $pst[0] ||
		   $tst[1] != $pst[1]);
	}
	$cwd = "$dir/$cwd";
	closedir(getcwd'PARENT);					#');
    } while ($dir ne '');
    chop($cwd);
    $cwd;
}

1;
