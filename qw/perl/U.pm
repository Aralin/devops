# Utility methods for missing perl features

package U;

use strict;
use warnings;
no warnings qw(experimental);
use feature qw(switch say);

# Log / Print / Dump
sub timestamp { require POSIX; return &POSIX::strftime("%Y-%m-%d %H:%M:%S",localtime); }
sub log { &say(&timestamp," : ",@_); }
sub say (@) { say @_; return join("",@_); }
sub dump (@) { require Data::Dumper; &say( &Data::Dumper::Dumper(@_) ); }

# Structure manipulation
sub hashpush { my ($rh_t, $rh_f) = @_; map { $rh_t->{$_} = $rh_f->{$_}; } keys %$rh_f; }
sub hashpurge { my $rh = &hash(@_); for(keys %$rh) { delete $rh->{$_} unless defined $rh->{$_}; } }
sub hash { my $rh = {}; while(my $key = shift(@_)) { if(ref($key) eq "HASH") { &hashpush($rh,$key) } else { $rh->{$key} = shift @_; } } return $rh; }
sub array { return map { ref($_) eq 'ARRAY' ? @{$_} : $_ } @_; }

sub odd { my $f=1; return grep {++$f%2} @_; }
sub even { my $f=0; return grep {++$f%2} @_; }

sub numeric ($) { return unless defined $_[0]; require Scalar::Util; return &Scalar::Util::looks_like_number($_[0]) }

# Execute code on nested structure values
sub on (&@) {
    my $code = shift;
    return map { 
        given(ref(my $arg=$_)) {
            when(/^ARRAY$/) { &on($code,@{$arg}); }
            when(/^HASH$/)  { &on($code,values %{$arg}); }
            default         { $code->($arg); }
        }
    } @_;
}

sub index (&@) {
    my $code = shift; 
    my $index = 0;
    return grep { defined $_ } map { $index++; $code->($_) ? $index : undef } &array(@_);
}

# String Array 
sub csv (@)     { return join(",",@_); }
sub quote (@)   { return map { '"'.$_.'"' } @_; }
sub indent ($@) { my $indent = shift; return map { $indent.$_ } @_; }
sub append ($@) { my $append = shift; return map { $_ . $append } @_; }
sub newline (@) { &append("\n",@_); }

sub progressive ($@) { # Progressive indentation of an array
    my $indent = shift; my $cnt = 0; 
    return map { $indent x $cnt++ . $_ } @_; 
}

# Stack methods
sub stack {
    my $skip = $_[0] || 0;
    my @stack = ();
    while( my ($package,$file,$line,$sub) = caller(++$skip) ) {
        last unless $sub;
        $package ||= "<package>";
        unshift @stack, "Call $sub from $package in $file at $line";
    }
    return @stack;
}

sub print_stack { print &newline( &progressive("--",&stack(1 + ($_[0] || 0))) ); }

1;
