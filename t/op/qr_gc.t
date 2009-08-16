#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    undef &Regexp::DESTROY;
}

plan tests => 2;

if ($] >= 5.011) { # doesn't leak on 5.10.x
    $TODO = "leaking since 32751";
}

my $destroyed;
{
    sub Regexp::DESTROY { $destroyed++ }
}

{
    my $rx = qr//;
}

is( $destroyed, 1, "destroyed regexp" );

undef $destroyed;

{
    my $var = bless {}, "Foo";
    my $rx = qr/(?{ $var })/;
}

is( $destroyed, 1, "destroyed regexp with closure capture" );

