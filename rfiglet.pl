use IPC::Open3;
use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
use Irssi::Irc;
$VERSION = "0.02";
%IRSSI = (
    authors	=> 'existemi',
    contact	=> 'existemi.no',
    name	=> 'Rainbow Figlet',
    description	=> 'Combining figlet.pl by Juerd (http://jured.nl/irssi/) with rainbow.pl by Jakub Jankowski (http://irssi.atn.pl/)',
    license	=> 'Public Domain',
    url		=> 'http://cloud.existemi.net/files/rfiglet.pl',
    changed	=> 'Thu 06 May 00:19 CET 2011',
    changes	=> 'Added make_colors per char in input not output, and fixed regex to accept colours with digits.',
);

# colors list
#  0 == white
#  4 == light red
#  8 == yellow
#  9 == light green
# 11 == light cyan
# 12 == light blue
# 13 == light magenta
my @colors = ('0', '4', '8', '9', '11', '12', '13');

# str make_colors($string)
# returns random-coloured string
sub make_colors {
        my ($string) = @_;
        my $newstr = "";
        my $last = 255;
        my $color = 0;

        for (my $c = 0; $c < length($string); $c++) {
                my $char = substr($string, $c, 1);
                if ($char eq ' ') {
                        $newstr .= $char;
                        next;
                }
                while (($color = int(rand(scalar(@colors)))) == $last) {};
                $last = $color;
                $newstr .= "\003";
                $newstr .= sprintf("%02d", $colors[$color]);
		# $newstr .= (($char eq ",") ? ",," : $char);
		$newstr .= $char;
        }

        return $newstr;
}

sub rfiglet {
	my ($msg, $server, $dest) = @_;
        my @figlet;
        my $prefix = '';
	$msg = make_colors($msg);
        while ($msg =~ s/^([^\cC\cB\cO\c_]+|(?:\cC(\d\d?(,\d\d?)?)?|[\cB\cO\c_])+)//x) {
            my $part = $1;
	    if ($part =~ /[\cC\cB\cO\c_]/) {
                if (@figlet) {
                    $_ .= $part for @figlet;
                } else {
                    $prefix = $part;
                }
            } else {
                my $i = 0;
                my $pid = open3(undef, *FIG, *FIG,  qw(figlet -k), $part);
                while (<FIG>) {
                    chomp;
                    $figlet[$i++] .= $_;
                }
                close FIG;
                waitpid $pid, 0;
            }
        }
        for (@figlet) {
	    (my $copy = $_) =~ s/\cC\d*(?:,\d*)?|[\cB\cO\c_]//g;
	    #(my $copy = $_) =~ s/[\cB\cO\c_]//g;
            next unless $copy =~ /\S/;
	    
	    if ($dest && ($dest->{type} eq "CHANNEL" || $dest->{type} eq "QUERY")) {
		    #$dest->command("/msg " . $dest->{name} . " " .  make_colors($prefix) . make_colors($_));
		    $dest->command("/msg " . $dest->{name} . " " . $prefix . $_);
	    }
        }
}


Irssi::command_bind("rfiglet", "rfiglet");
