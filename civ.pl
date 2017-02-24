#!/usr/bin/perl

use strict;
use Image::Magick;
use MIME::Base64;
use Getopt::Std;

# -------------------------------- #
# Version and Help Messages        #
# -------------------------------- #
$main::VERSION = "1.0.20170212";

sub main::VERSION_MESSAGE{
	print "CIV - Console Image Viewer v$main::VERSION\n";
}

sub main::HELP_MESSAGE{
	print <<'USAGE';

Usage:
	civ [-dg -c <N> -h <N> -h <N>] <file>

Options:
	-d   Dither image
	-g   Greyscale image
	-c <N>   Use N colors for output (typically 8,16, or 256)
	-w <N>   Print at most N columns of output
	-h <N>   Print at most N rows of output
	--help

USAGE
}

# -------------------------------- #
# Read commandline arguments       #
# -------------------------------- #
$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %Opts = (
	d => 0,
	g => 0,
	c => 256,
	w => int(`tput cols`/2),
	h => `tput lines`-1
);
exit main::HELP_MESSAGE() unless getopts('dgc:h:w:', \%Opts) && -f $ARGV[0];

# -------------------------------- #
# Load console color map           #
# -------------------------------- #
my %Map;
my $map = new Image::Magick(magick=>"bmp");
$map->BlobToImage(decode_base64(<DATA>));
$map->Crop(x=>0,y=>0,width=>$Opts{c},height=>1) if $Opts{c}<256;
my @P = $map->GetPixels(geometry=>join("x",$map->Get("width","height")));
for( my $i = 0; $i < scalar(@P); $i += 3 ){
	$Map{sprintf "#%02x%02x%02x", map {int(255*$_/Image::Magick->QuantumRange)} @P[$i..$i+2]} = $i/3;
}

# -------------------------------- #
# Read, process, and display image #
# -------------------------------- #
my $img = new Image::Magick;
$img->Read($ARGV[0]);
my ($W,$H) = $img->Get("width","height");
if( $Opts{w}/$Opts{h} > $W/$H ){ $Opts{w} = int($Opts{h}*$W/$H);}
else                           { $Opts{h} = int($Opts{w}*$H/$W);}
$img->Resize(geometry=>2*$Opts{w}."x".$Opts{h}."!");
$img->Quantize(colorspace=>'gray') if $Opts{g};
$img->Remap(image=>$map,dither=>$Opts{d});
($W,$H) = $img->Get("width","height");
my @P = $img->GetPixels(geometry=>$W."x".$H);
for( my $i = 0; $i < scalar(@P); $i += 3 ){
	print "\e[0m\n" if $i/3 % $W == 0;
	print "\e[48;5;".$Map{sprintf "#%02x%02x%02x", map {int(255*$_/Image::Magick->QuantumRange)} @P[$i..$i+2]}."m ";
}
print "\e[0m\n";
exit;

__DATA__
Qk02AwAAAAAAADYAAAAoAAAAAAEAAAEAAAABABgAAAAAAAADAAATCwAAEwsAAAAAAAAAAAAAAAAAAADNAM0AAM3N7gAAzQDNzc0A5eXlf39/AAD/AP8AAP///1xc/wD///8A////AAAAXwAAhwAArwAA1wAA/wAAAF8AX18Ah18Ar18A118A/18AAIcAX4cAh4cAr4cA14cA/4cAAK8AX68Ah68Ar68A168A/68AANcAX9cAh9cAr9cA19cA/9cAAP8AX/8Ah/8Ar/8A1/8A//8AAABfXwBfhwBfrwBf1wBf/wBfAF9fX19fh19fr19f119f/19fAIdfX4dfh4dfr4df14df/4dfAK9fX69fh69fr69f169f/69fANdfX9dfh9dfr9df19df/9dfAP9fX/9fh/9fr/9f1/9f//9fAACHXwCHhwCHrwCH1wCH/wCHAF+HX1+Hh1+Hr1+H11+H/1+HAIeHX4eHh4eHr4eH14eH/4eHAK+HX6+Hh6+Hr6+H16+H/6+HANeHX9eHh9eHr9eH19eH/9eHAP+HX/+Hh/+Hr/+H1/+H//+HAACvXwCvhwCvrwCv1wCv/wCvAF+vX1+vh1+vr1+v11+v/1+vAIevX4evh4evr4ev14ev/4evAK+vX6+vh6+vr6+v16+v/6+vANevX9evh9evr9ev19ev/9evAP+vX/+vh/+vr/+v1/+v//+vAADXXwDXhwDXrwDX1wDX/wDXAF/XX1/Xh1/Xr1/X11/X/1/XAIfXX4fXh4fXr4fX14fX/4fXAK/XX6/Xh6/Xr6/X16/X/6/XANfXX9fXh9fXr9fX19fX/9fXAP/XX//Xh//Xr//X1//X///XAAD/XwD/hwD/rwD/1wD//wD/AF//X1//h1//r1//11///1//AIf/X4f/h4f/r4f/14f//4f/AK//X6//h6//r6//16///6//ANf/X9f/h9f/r9f/19f//9f/AP//X///h///r///1///////CAgIEhISHBwcJiYmMDAwOjo6RERETk5OWFhYYmJibGxsdnZ2gICAioqKlJSUnp6eqKiosrKyvLy8xsbG0NDQ2tra5OTk7u7u
