package Tuning::Sched;

use strict;
# use Tuning::Util;
use Data::Dumper;
use 5.010;

use base qw(Exporter);

my $SCHED_DOMAIN_PATH = "/proc/sys/kernel/sched_domain";

#
# usage:
#   
sub new {
	my $type = shift;
	my $path = shift;
	my $this = {};

	$SCHED_DOMAIN_PATH = $path if ($path);
	$this = _init($this);

	bless $this, $type;
}

sub _init {
	return {};
}

# bit :NAME
# ARRAY:
# index -> name
sub print_flags {
	my ($base, $flags) = @_;

	for (@$base) {
		if ($_->{mask} & $flags) {
			printf("%04x: %-22s: %s\n", $_->{mask}, $_->{sym}, $_->{desc});
		}
	}
}

my @sd_flags = (
	{mask => 0x0001, sym => "SD_LOAD_BALANCE",	desc => ""},
	{mask => 0x0002, sym => "SD_BALANCE_NEWIDLE",	desc => ""},
	{mask => 0x0003, sym => "SD_BALANCE_EXEC",	desc => ""},
	{mask => 0x0008, sym => "SD_BALANCE_FORK",	desc => ""},
	{mask => 0x0010, sym => "SD_BALANCE_WAKE",	desc => ""},
	{mask => 0x0020, sym => "SD_WAKE_AFFINE",	desc => ""},
	{mask => 0x0080, sym => "SD_SHARE_CPUPOWER",	desc => ""},
	{mask => 0x0200, sym => "SD_SHARE_PKG_RESOURCES",	desc => ""},
	{mask => 0x0400, sym => "SD_SERIALIZE",		desc => ""},
	{mask => 0x0800, sym => "SD_ASYM_PACKING",	desc => ""},
	{mask => 0x1000, sym => "SD_PREFER_SIBLING",	desc => ""},
	{mask => 0x2000, sym => "SD_OVERLAP",		desc => ""},
	{mask => 0x4000, sym => "SD_NUMA",		desc => ""},
);

sub sched_domain_name {
	my $this = shift;
	my ($cpu, $domain) = @_;

	my $name = `cat $SCHED_DOMAIN_PATH/cpu$cpu/domain$domain/name`; chomp $name;
	return $name;
}

sub _sched_domain_flags {
	my $this = shift;
	my ($cpu, $domain) = @_;

	if (defined($domain)) {
		my $name = $this->sched_domain_name($cpu, $domain);
		my $flags = `cat $SCHED_DOMAIN_PATH/cpu$cpu/domain$domain/flags`; chomp $flags;
		say "CPU $cpu, DOMAIN $domain, NAME $name, FLAGS $flags";
		print_flags(\@sd_flags, $flags);
		print("\n");
	}
}

sub sched_domain_flags {
	my $this = shift;
	my ($cpu, $domain) = @_;

	if (defined($domain)) {
		_sched_domain_flags($cpu, $domain);
	}
	else {
		my $domains = `ls /proc/sys/kernel/sched_domain/cpu1/domain* -d |wc -l`; chomp $domains;
		for (0 .. $domains - 1) {
			$this->_sched_domain_flags($cpu, $_);
		}
	}
}

sub dump {
	my $this = shift;
	print Dumper ($this);
}

1;
