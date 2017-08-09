package Tuning::Util;

use strict;
use Data::Dumper;
use 5.010;

use base qw(Exporter);
@Tuning::Util::EXPORT = qw(debug verbose logfile cd syslog index_of short_commit
			   print_array print_hash ssh_run cmd pwd cpus2list list2cpus
			   online_cpus isolcpus present_cpus prossible_cpus
			   system_cpus system_cpus_str);

my $DEBUG = 1;
my $VERBOSE = 0;

sub debug {
	my $v = shift;

	if (defined($v)) {
		$DEBUG = $v;
	}

	return $DEBUG;
}

sub verbose {
	my $v = shift;

	if (defined($v)) {
		$VERBOSE = $v;
	}

	return $VERBOSE;
}

my $LOGFILE = "/var/log/tuning.log";

sub logfile {
	my $file = shift;

	if ($file) {
		$LOGFILE = $file;
	}
	return $LOGFILE;
}

sub syslog {
	my @lines = @_;

	for (@lines) {
		chomp;
		system "echo `date \"+%Y-%m-%d %H:%M:%S\"` \"$_\" >> $LOGFILE";
		say "[SYSLOG]: $_" if ($VERBOSE);
	}
}

sub cd {
	my ($path) = @_;
	my $pwd = `pwd`; chomp $pwd;

	chdir $path;
	my $msg = sprintf("Change dir from %s to %s", $pwd, $path);
	syslog $msg;
}

# index_if (@array, $key);
sub index_of {
	my ($key) = pop @_;
	my $count = @_;

	for my $i (0 .. ($count - 1)) {
		if (($_[$i]) eq ($key)) {
			return $i;
		}
	}
}

sub print_hash {
	my $h = shift;

	while (my ($k, $v) = each %$h) {
		print "$k	=>	$v\n";
	}
}

sub print_array {
	my $a = shift;

	for (@$a) {
		print_hash($_);
	}
}

sub cmd {
	my $c = shift;

	$c =~ s/\n//g;
	if ($VERBOSE) {
		syslog "CMD: \'$c\'";
	}

	system("$c") unless($DEBUG);
}

sub pwd {
	my $pwd = `pwd`; chomp $pwd;

	if ($VERBOSE || $DEBUG) {
		syslog "CURRENT DIR IS $pwd";
	}

	return $pwd;
}

# sub ssh_run {
# 	my ($root, $ip, $cmd) = @_;
# 	my $pid;
# 
# 	syslog("$cmd\n");
# 
# 	$pid = open(OUT, "$cmd 2>&1 |" or die
# 		("unable to exec $cmd" and return 0);
# 
# 	while (<OUT>) {
# 		print $_;
# 		syslog($_);
# 	}
# 
# 	waitpid($pid, 0);
# 	my $failed = $?;
# 	close (OUT);
# 
# 	if ($failed) {
# 		syslog "FAILED!\n";
# 	} else {
# 		syslog "SUCCESS\n";
# 	}
# 
# 	return !$failed;
# }

# input: 1,2,3,5,6,7,9,12,13,14
# output: 1-3,5-7,9,12-14
sub cpus2list {
	my $line = shift;
	my @cpus = sort {$a <=> $b} map {split /,/} $line;

	my $p = shift @cpus;
	my $q = $p;
	my $res = undef;
	for (@cpus) {
		if ($q + 1 == $_) {
			$q++;
			next;
		} elsif ($p == $q) {
			$res .= defined($res) ? ",$p" : "$p";
			$p = $q = $_;
		} else {
			$res .= defined($res) ? ",$p-$q" : "$p-$q";
			$p = $q = $_;
		}
	}

	$res .= defined($res) ? ",$p" : "$p" if ($p == $q);
	$res .= defined($res) ? ",$p-$q" : "$p-$q" if ($p != $q);

	return $res;
}

# input: 1-3,5-7,9,12-14
# output: 1,2,3,5,6,7,9,12,13,14 (array)
sub list2cpus {
	my $cpus = shift;
	my @cpus = split(",", $cpus);

	my @c;
	for (@cpus) {
		my ($from, $to) = split ("-");
		$to = $from unless($to);

		for ($from .. $to) {
			@c = (@c, $_);

		}
	}

	return \@c;
}

sub online_cpus {
	my $cpus = shift;

	unless ($cpus) {
		$cpus = `cat /sys/devices/system/cpu/online`;
		chomp $cpus;
	}

	return list2cpus($cpus);
}

sub isolcpus {
	my $cpus = shift;

	unless ($cpus) {
		$cpus = `cat /sys/devices/system/cpu/isolated`;
		chomp $cpus;
	}

	return list2cpus($cpus);
}

sub present_cpus {
	my $cpus = shift;

	unless ($cpus) {
		$cpus = `cat /sys/devices/system/cpu/present`;
		chomp $cpus;
	}

	return list2cpus($cpus);
}

sub possible_cpus {
	my $cpus = shift;

	unless ($cpus) {
		$cpus = `cat /sys/devices/system/cpu/possible`;
		chomp $cpus;
	}

	return list2cpus($cpus);
}

sub system_cpus_str {
	my $attr = shift;
	my $cpus = "";

	my @valid_attrs = qw /possible present online isolated/;

	if (grep (/$attr/, @valid_attrs)) {
		$cpus = `cat /sys/devices/system/cpu/$attr`;
		chomp $cpus;
	}

	return $cpus;
}

# system_cpus("online")
sub system_cpus {
	my $attr = shift;

	return list2cpus(system_cpus_str($attr));
}

1;
