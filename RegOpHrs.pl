#!/usr/local/bin/perl -w
#
# RegOpHrs.pl
# --- Regional open hours analysis for Cabrillo contest logs ---
#
# Listing the number of QSOs each one half hour for 
# specific groups of countries
#
# rin fukuda, rin@jg1vgx.net, Feb 2006
# ver 0.02

use strict;
use Date::Simple('date');
use IO::Handle('autoflush');

# $|=1;	# force flush
STDOUT->autoflush(1);

# debugger
#open FF, ">debug.txt";
#FF->autoflush(1);

# setting bands
my @bands = qw/  160   80   40    20    15    10 /;
my @map_l = qw/ 1800 3500 7000 14000 21000 28000 /;
my @map_h = qw/ 2000 4000 7300 14350 21450 29700 /;

# Greetings
print "\n*** Open Hours By Countries ***\n\n";

# Reading country file
print "Reading cty.dat ... ";
my %ctyz;	# hash holding country zone, coord data, key=7th el of the first raw
my %ctyn;	# hash holding country prefixes, key=same
&read_cty;
print "done!\n\n";

# get Cabrillo log file
print "Enter Cabrillo log file name: ";
chomp(my $infile = <STDIN>);
print "\n";
open F, $infile or die "Can't open $infile!\n";

# get destination country file
print "Enter destination country file name: ";
chomp(my $destfile = <STDIN>);
print "\n";
open FD, $destfile or die "Can't open $destfile!\n";

# reading dest.cty
my $regnum = 0;		# holds number of regions
my @reg;		# region array
while(<FD>) {
	++$regnum;
	push @reg, $_;
}
close FD;

# open output files
open FO, ">result.txt" or die "Can't create output file!\n";
FO->autoflush(1);

my @qsos;	# original qso array read from source
my $qn = 0;	# the number of QSO

# skip headers
while(<F>) {
	# elementary info for result header
	if(/^CALLSIGN: ([\w\/]+)/) {
		print FO $1,'     ';
	}
	if(/^CONTEST: ([\w\- ]+)/) {
		print FO $1,'     ';
	}
	if(/^CATEGORY: ([\w\- ]+)/) {
		print FO $1,'     ';
	}

	# see if qso line?
	if(/^QSO: /) {
		++$qn;
		push @qsos, $_;
		last;
	}
}

# QSO contents
while(<F>) {
	# see if qso line?
	if(/^QSO: /) {
		++$qn;
		push @qsos, $_;
	}
}
close F;
# @qsos array is ready here

print FO "Total QSOs = ",$qn,"\n\n";

# band index
print FO "  ";
for(my $j = 0; $j < 6; ++$j) {	# band iterator
	print FO ' 'x(2*$regnum-2);
	print FO sprintf "%4s", $bands[$j];
	print FO ' 'x(2*$regnum-1);
}
print FO "\n";

# horizontal line
print FO "  ";
for(my $j = 0; $j < 6; ++$j) {	# band iterator
	print FO " ";
	for(my $i = 0; $i < $regnum; ++$i) {
		print FO "----";
	}
}
print FO "\n";

# region index
print FO "   ";
for(my $j = 0; $j < 6; ++$j) {	# band iterator
	print FO " ";
	for(my $i = 0; $i < $regnum; ++$i) {
		my @ridx = split /:/, $reg[$i];
		print FO $ridx[0];
		print FO ' 'x(4-length($ridx[0]));
	}
}
print FO "\n\n";

# header done here

# get start and end time
print "Enter starting date in format YYYY-MM-DD: ";
chomp(my $stadate = <STDIN>);

print "Enter starting time in format HHMM (default = 0000): ";
chomp(my $statime = <STDIN>);
$statime = 0 if($statime eq "");
$statime = sprintf "%04d", $statime;

print "Enter ending date in format YYYY-MM-DD: ";
chomp(my $enddate = <STDIN>);

print "Enter ending time in format HHMM (default = 2359): ";
chomp(my $endtime = <STDIN>);
$endtime = 2359 if($endtime eq "");
$endtime = sprintf "%04d", $endtime;
print "\n";

my $q;			# temp QSO line
my @hrline = ();	# output line for each hr
my($call, $band, $cty);	# callsign, band in meters, country of a call

$hrline[0] = $stadate;
$hrline[1] = $statime;

while($q = shift @qsos) {
	$call = &get_call($q);
	$band = &get_band($q);
	$cty = &get_cty($call);		# proper country string

	next if($cty eq "");		# skip if empty country like /MM, /AM

	if(&check_time($hrline[0], sprintf("%04d", $hrline[1]+30), $q)) {
		# within a segment of half hour

		for(my $i = 0; $i < $regnum; ++$i) {
			my @rega = split /\s+/, $reg[$i];
			shift @rega;	# remove index name

			my $hit = 0;	# 1 if match, 0 if not
			foreach(@rega) {

				# see if exclusion param
				if(/^-(.+)/) {
					# exclusion
					if($1 eq $cty) {
						$hit = 0;
						last;		# exit the foreach loop, disregarding other prefixes
					}
				}

				# see if continental param
				if(/^=(.+)/) {
					# continental param
					my $cont = $1;
					my @par = split /:/, $ctyz{$cty};
					$par[3] =~ s/\s+//g;
					if($par[3] eq $cont) {
						# match!
						# populate @hrline array
						$hit = 1;
					}
				} elsif($_ eq $cty) {
					# regular country prefix param
					# match!
					# populate @hrline array
					$hit = 1;
				}
			}
			# populate array if match
			++$hrline[2+&band_num($band)*$regnum+$i] if($hit);
		}
	} else {
		# new half hour segment

		# output a hrline
		&fo_hrline($regnum, @hrline);

		# resetting variables for next half hour
		my @newh = split /\s+/, &newhr(@hrline);
		@hrline = ();
		$hrline[0] = $newh[0];
		$hrline[1] = $newh[1];

		unshift @qsos, $q;
	}
}

# print last half hour
&fo_hrline($regnum, @hrline);

close FO;

print "\nDone!\n";

# debugger
#close FF;

exit 0;

### subroutines

# newhr
sub newhr {
	if($_[1] >= 2330) {
		$_[0] = date($_[0])->next;
		$_[1] = sprintf "%04d", $_[1]-2330;
	} elsif(substr($_[1], 2, 2) >= 30) {
		$_[1] = sprintf "%04d", $_[1]+70;
	} else {
		$_[1] = sprintf "%04d", $_[1]+30;
	}
	return $_[0].' '.$_[1];
}

# output a hrline to a file
sub fo_hrline {
	if(substr($_[1+1], 2, 2) ne "30") {
		print FO substr($_[1+1], 0, 2);
		print substr($_[1+1], 0, 2).".";
	} else {
		print FO "  ";
		print ".";
	}
		for(my $j = 0; $j < 6; ++$j) {	# band iterator
		for(my $i = 0; $i < $_[0]; ++$i) {
			if(defined($_[1+2+$j*$_[0]+$i])) {
				print FO sprintf "%4d", $_[1+2+$j*$_[0]+$i];
			} else {
				print FO "    ";
			}
		}
		print FO " ";
	}
	print FO "\n";
}

# band_num
# returns number accoring to band
# for column calculation
# 160 -> 0, 80 -> 1, 40 -> 2, 20 -> 3, 15 -> 4, 10 -> 5
sub band_num {
	return 0 if($_[0] == 160);
	return 1 if($_[0] == 80);
	return 2 if($_[0] == 40);
	return 3 if($_[0] == 20);
	return 4 if($_[0] == 15);
	return 5 if($_[0] == 10);
}

# remove parentheses
sub rm_par {
	$_[0] =~ s/\(.*\)//g;
	$_[0] =~ s/\[.*\]//g;
	return $_[0];	
}

# deducting cty from a call
# two parameters
# $_[0] $call
sub get_cty {
	my @ctyn = %ctyn;	# unwinding the prefix hash

	# look for exact match
	for(my $i = 0; $i < $#ctyn; $i += 2) {
		my @pfx = split /[\s+,;]/, $ctyn[$i+1];
		foreach(@pfx) {
			$_ = &rm_par($_);		# remove (zn)[zn]
			if($_[0] eq $_) {
				return $ctyn[$i];
			}
		}
	}

	# slashed callsigns

	# first check if /M, /P
	my $sla = rindex($_[0], '/');
	if($sla != -1) {
		# ignore /MM, /AM
		if($sla+2+1 == length($_[0])) {
			if((substr($_[0], $sla, 3) eq "/MM") or (substr($_[0], $sla, 3) eq "/AM")) {
				return "";	# return no hit
			}
		}

		# remove /M, /P
		if($sla+1+1 == length($_[0])) {
			if((substr($_[0], $sla, 2) eq "/M") or (substr($_[0], $sla, 2) eq "/P")) {
				$_[0] = substr($_[0], 0, $sla);		# remove!
			}

		}
	}

	# check if slashed again after removal of /M, /P
	$sla = rindex($_[0], '/');
	if($sla != -1) {
		# remove /QRP
		if($sla+3+1 == length($_[0])) {
			if(substr($_[0], $sla, 4) eq "/QRP") {
				$_[0] = substr($_[0], 0, length($_[0])-4);
			}
		}

		# a single number should be replaced as W5ABC/3 -> W3ABC
		if($sla+1+1 == length($_[0])) {
			if(substr($_[0], $sla, 2) =~ /\/(\d)/) {
				# replacing the number
				my $num = $1;
				if($_[0] =~ /^(\w[A-Z]+)(\d)(.*)/) {
					# must be always true
					$_[0] = $1.$num.$3;
				}
				# get rid of /num
				$_[0] = substr($_[0], 0, length($_[0])-2);
			}
		}
	}

	# check if slashed again after removal of /QRP and /num
	$sla = rindex($_[0], '/');
	if($sla != -1) {
		# find the shorter side
		if($sla*2+1 == length($_[0])) {
			# / is in the middle
			$_[0] = substr($_[0], $sla+1, $sla);	# take the latter
		} elsif($sla*2+1 < length($_[0])) {
			# former is shorter
			$_[0] = substr($_[0], 0, $sla);		# take the former
		} else {
			# latter is shorter
			$_[0] = substr($_[0], $sla+1, length($_[0])-1-$sla);	# take the latter
		}
	}

	# $_[0](correct prefix in the call) is ready

	# searching matched country
	my($match, $matchcty) = ("", "");
	for(my $i = 0; $i < $#ctyn; $i += 2) {
		my @pfx = split /[\s+,;]/, $ctyn[$i+1];
		foreach(@pfx) {
			$_ = &rm_par($_);		# remove (zn)[zn]
			if($_[0] =~ /^$_/) {
				if(length($_) > length($match)) {
					$match = $_;
					$matchcty = $ctyn[$i];
				}
			}
		}
	}
	return $matchcty;
}

# getting band in a QSO: record
sub get_band {
	my @qs = split /\s+/, $_[0];

	for(my $i=0; $i<6; ++$i) {
		# 2nd field in a qso is the freq
		return $bands[$i] if($map_l[$i]<=$qs[1] && $qs[1]<=$map_h[$i]);
	}
	die "Inconsistent QSO Freq was found.\n>>> $q\n";
}

# getting callsign in a QSO: record
sub get_call {
	my @qs = split /\s+/, $_[0];
	return $qs[8];	
}

# check time
# take three param
# $_[0] date1
# $_[1] time1
# $_[2] QSO line containing date and time2
# return 1 when date/time1 is greater than date/time2
# otherwise 0
sub check_time {
	my $date1 = $_[0]." ".$_[1];
	my $date2 = &get_date($_[2])." ".&get_time($_[2]);

	if($date1 gt $date2) {
		return 1;
	} else {
		return 0;
	}
}

# getting date from a QSO: record
sub get_date {
	my @qs = split /\s+/, $_[0];
	return $qs[3];
}

# getting time from a QSO: record
sub get_time {
	my @qs = split /\s+/, $_[0];
	return $qs[4];
}

# reading cty.dat file and populate hash
sub read_cty {
	my $ctyfile = 'cty.dat';
	open FT, $ctyfile or die "Can't open $ctyfile!\n";

	my @linea;	# first line
	my $lineb;	# country names
	while(<FT>) {
		chomp;
		my $line = $_;
		if(/^\s*#/) {		# skip comments
			next;
		}
		if(/:\s*$/) {		# line ending : = first line
			@linea = split ":";
			$linea[7] =~ s/\s+//g;
			$ctyz{$linea[7]} = $line;
			$lineb = "";	# reset $lineb
			next;
		}
		if(/,\s*$/) {		# line ending , = a prefix line
			s/\s+//g;
			$lineb .= $_;
			next;
		}
		if(/;\s*$/) {		# line ending ; = last line
			s/\s+//g;
			$lineb .= $_;
			$ctyn{$linea[7]} = $lineb;
			next;
		}
	}
	close FT;
}
