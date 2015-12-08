#
# File: QW/Object/List.pm
# Role: List of Objects
#

package QW::Object::List;

use strict;
use warnings;

sub new {
    my $self = shift;
    my $class = __PACKAGE__;

    $self = bless [], $class;

    $self->push(@_);

    return $self;
}

sub pop     { my $self = shift; return pop @{$self}; }
sub push    { my $self = shift; push @{$self}, @_; }
sub shift   { my $self = shift; return shift @{$self}; }
sub unshift { my $self = shift; unshift @{$self}, @_; }
sub list    { my $self = shift; return @{$self}; }
sub delete  { my $self = shift; my $index = shift; return splice(@{$self},$index,1); }

sub size      { return scalar @{$_[0]}; }
sub at:lvalue { return $_[0]->[$_[1]]; }

sub find  { my $self = shift; my $code = shift; for(my $i = 0..$#$self) { return $i if $self->[i]->$code(@_); } return -1; }
sub map   { my $self = shift; my $code = shift; return map { $_->$code(@_); } @$self; }


