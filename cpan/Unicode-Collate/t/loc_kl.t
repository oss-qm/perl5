
BEGIN {
    unless ("A" eq pack('U', 0x41)) {
	print "1..0 # Unicode::Collate " .
	    "cannot stringify a Unicode code point\n";
	exit 0;
    }
    if ($ENV{PERL_CORE}) {
	chdir('t') if -d 't';
	@INC = $^O eq 'MacOS' ? qw(::lib) : qw(../lib);
    }
}

use Test;
BEGIN { plan tests => 101 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $eth  = pack 'U', 0xF0;
my $ETH  = pack 'U', 0xD0;
my $thrn = pack 'U', 0xFE;
my $THRN = pack 'U', 0xDE;
my $uuml = pack 'U', 0xFC;
my $Uuml = pack 'U', 0xDC;
my $ae   = pack 'U', 0xE6;
my $AE   = pack 'U', 0xC6;
my $auml = pack 'U', 0xE4;
my $Auml = pack 'U', 0xC4;
my $ostk = pack 'U', 0xF8;
my $Ostk = pack 'U', 0xD8;
my $ouml = pack 'U', 0xF6;
my $Ouml = pack 'U', 0xD6;
my $arng = pack 'U', 0xE5;
my $Arng = pack 'U', 0xC5;

my $objKl = Unicode::Collate::Locale->
    new(locale => 'KL', normalization => undef);

ok($objKl->getlocale, 'kl');

$objKl->change(level => 1);

ok($objKl->lt('z', $ae));
ok($objKl->lt($ae, $ostk));
ok($objKl->lt($ostk, $arng));
ok($objKl->lt($arng, "\x{292}"));

# 6

ok($objKl->eq('d', "\x{111}"));
ok($objKl->eq("\x{111}", $eth));
ok($objKl->eq('q', "\x{138}"));
ok($objKl->eq('q', "K'"));
ok($objKl->eq('y', $uuml));
ok($objKl->eq($uuml, "\x{171}"));
ok($objKl->eq($ae, $auml));
ok($objKl->eq($auml, "\x{119}"));
ok($objKl->eq($ostk, $ouml));
ok($objKl->eq($ouml, "\x{151}"));
ok($objKl->eq("\x{151}", "\x{153}"));

# 17

$objKl->change(level => 2);

ok($objKl->lt('d', "\x{111}"));
ok($objKl->lt("\x{111}", $eth));
ok($objKl->lt('q', "\x{138}"));
ok($objKl->lt('q', "K'"));
ok($objKl->lt('y', $uuml));
ok($objKl->lt($uuml, "\x{171}"));
ok($objKl->lt($ae, $auml));
ok($objKl->lt($auml, "\x{119}"));
ok($objKl->lt($ostk, $ouml));
ok($objKl->lt($ouml, "\x{151}"));
ok($objKl->lt("\x{151}", "\x{153}"));

# 28

ok($objKl->eq("\x{111}", "\x{110}"));
ok($objKl->eq($eth,  $ETH));
ok($objKl->eq("\x{138}", "K'"));
ok($objKl->eq('th',  $thrn));
ok($objKl->eq($thrn, 'TH'));
ok($objKl->eq('TH',  $THRN));
ok($objKl->eq($uuml, $Uuml));
ok($objKl->eq("\x{171}", "\x{170}"));
ok($objKl->eq($ae,   $AE));
ok($objKl->eq($AE, "\x{1D2D}"));
ok($objKl->eq($auml, $Auml));
ok($objKl->eq("\x{119}", "\x{118}"));
ok($objKl->eq($ostk, $Ostk));
ok($objKl->eq($ouml, $Ouml));
ok($objKl->eq("\x{151}", "\x{150}"));
ok($objKl->eq("\x{153}", "\x{152}"));
ok($objKl->eq($arng, $Arng));

# 45

$objKl->change(level => 3);

ok($objKl->lt("\x{111}", "\x{110}"));
ok($objKl->lt($eth,  $ETH));
ok($objKl->lt("\x{138}", "K'"));
ok($objKl->lt('th',  $thrn));
ok($objKl->lt($thrn, 'TH'));
ok($objKl->lt('TH',  $THRN));
ok($objKl->lt($uuml, $Uuml));
ok($objKl->lt("\x{171}", "\x{170}"));
ok($objKl->lt($ae,   $AE));
ok($objKl->lt($AE, "\x{1D2D}"));
ok($objKl->lt($auml, $Auml));
ok($objKl->lt("\x{119}", "\x{118}"));
ok($objKl->lt($ostk, $Ostk));
ok($objKl->lt($ouml, $Ouml));
ok($objKl->lt("\x{151}", "\x{150}"));
ok($objKl->lt("\x{153}", "\x{152}"));
ok($objKl->lt($arng, $Arng));

# 62

ok($objKl->eq("d\x{335}", "\x{111}"));
ok($objKl->eq("D\x{335}", "\x{110}"));
ok($objKl->eq("u\x{308}", $uuml));
ok($objKl->eq("U\x{308}", $Uuml));
ok($objKl->eq("u\x{30B}", "\x{171}"));
ok($objKl->eq("U\x{30B}", "\x{170}"));
ok($objKl->eq("a\x{308}", $auml));
ok($objKl->eq("A\x{308}", $Auml));
ok($objKl->eq("e\x{328}", "\x{119}"));
ok($objKl->eq("E\x{328}", "\x{118}"));
ok($objKl->eq("o\x{338}", $ostk));
ok($objKl->eq("O\x{338}", $Ostk));
ok($objKl->eq("o\x{308}", $ouml));
ok($objKl->eq("O\x{308}", $Ouml));
ok($objKl->eq("o\x{30B}", "\x{151}"));
ok($objKl->eq("O\x{30B}", "\x{150}"));
ok($objKl->eq("a\x{30A}", $arng));
ok($objKl->eq("A\x{30A}", $Arng));

# 80

ok($objKl->eq("u\x{308}\x{300}", "\x{1DC}"));
ok($objKl->eq("U\x{308}\x{300}", "\x{1DB}"));
ok($objKl->eq("u\x{308}\x{301}", "\x{1D8}"));
ok($objKl->eq("U\x{308}\x{301}", "\x{1D7}"));
ok($objKl->eq("u\x{308}\x{304}", "\x{1D6}"));
ok($objKl->eq("U\x{308}\x{304}", "\x{1D5}"));
ok($objKl->eq("u\x{308}\x{30C}", "\x{1DA}"));
ok($objKl->eq("U\x{308}\x{30C}", "\x{1D9}"));
ok($objKl->eq("\x{1FD}", "$ae\x{301}"));
ok($objKl->eq("\x{1FC}", "$AE\x{301}"));
ok($objKl->eq("\x{1E3}", "$ae\x{304}"));
ok($objKl->eq("\x{1E2}", "$AE\x{304}"));
ok($objKl->eq("a\x{308}\x{304}", "\x{1DF}"));
ok($objKl->eq("A\x{308}\x{304}", "\x{1DE}"));
ok($objKl->eq("o\x{338}\x{301}", "\x{1FF}"));
ok($objKl->eq("O\x{338}\x{301}", "\x{1FE}"));
ok($objKl->eq("o\x{308}\x{304}", "\x{22B}"));
ok($objKl->eq("O\x{308}\x{304}", "\x{22A}"));
ok($objKl->eq("A\x{30A}", "\x{212B}"));
ok($objKl->eq("a\x{30A}\x{301}", "\x{1FB}"));
ok($objKl->eq("A\x{30A}\x{301}", "\x{1FA}"));

# 101
