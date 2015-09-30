#!/usr/bin/perl

use strict;
use warnings;

use Cwd qw(realpath);
use File::Basename;
use lib &File::Basename::dirname(&Cwd::realpath($0))."/../perl";

use QW;

my $qw = QW->new;

$qw->init;
$qw->parse_cli(@ARGV) && &usage;

$qw->dump($qw) if $qw->option('debug');

eval { exit $qw->execute; };
warn $@ if $@;
&usage;
exit 1;

sub usage {
	my $p = &File::Basename::basename($0);
	print <<USAGE;
  Usage: $0 <system> <command> <options> <arguments>
         $0 <system> help
         $0 help
USAGE
	exit 1;
}
