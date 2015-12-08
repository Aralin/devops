#
# File : QW/include/object.pl
# Role : Object
# 

# Include this file to define basic object methods.

use strict;
use warnings;

sub new {
    my $self = shift;
    my $class = __PACKAGE__;

    $self = bless {}, $class;

    $self->set(@_);

    return $self;
}

sub default { $_[0]->{$_[1]} = $_[2] unless exists $_[0]->{$_[1]}; return $_[0]->{$_[1]}; }

sub attr { require U; return &U::even($_[0]->attributes); }

sub set       { my $self = shift; require U; my $rh = &U::hash(@_); @$self{keys %$rh} = values %$rh; }
sub get  ($$) { return undef unless exists $_[0]->{$_[1]}; return $_[0]->{$_[1]}; }
sub list ($$) { return @{$_[0]->get($_[1])}; }

sub pop     ($$)  :method { return pop   @{$_[0]->get($_[1])}; }
sub shift   ($$)  :method { return shift @{$_[0]->get($_[1])}; }
sub push    ($$@) :method { my $self = shift; my $key = shift; push    @{$self->{$key}}, @_; }
sub unshift ($$@) :method { my $self = shift; my $key = shift; unshift @{$self->{$key}}, @_; }
 
# Attribute Array  my ($id,$name) = $self->aa('id','name');
sub aa ($@) { my $self = shift; return map { $self->get($_); } @_; } 

sub app       { $_[0]->get('_app'); }
sub class     { $_[0]->get('_class'); }

# sub search {
#     my $self = shift; require U; my $rh_rules = &U::hash(@_);
# 
#     my @result = grep { 
#         my $object = $_; 
#         map { $object->get($_) eq $rh_values{$_} }  keys %$rh_values;
#     } @cache;
#     if(@result) {
#         return wantarray ? @result : $result[0];
#     }
#     return wantarray ? () : undef;
# }
# sub recent { return $cache[0] if @cache; return undef; }

1;
