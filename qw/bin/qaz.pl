#!/usr/bin/perl

use strict;
use warnings;

use Cwd qw(realpath);
use File::Basename;
use lib &File::Basename::dirname(&Cwd::realpath($0))."/../perl";

use QW;
#use QW::DB;

my $qw = QW->new;
#my $qw = QW::DB->new;

$qw->hash_controller(
    'test' => 'QW::Controller::test',
#    'db' => 'QW::Controller::db',
);

$qw->hash_model(
    'test' => 'QW::Object::Test',
);

eval { $qw->init('app'=>'QW', 'mode'=>'cli')->parse(@ARGV); };
warn $@ if $@;
&usage if $@;

#$qw->dump($qw) if $qw->option('debug');

eval { exit $qw->run; };
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
