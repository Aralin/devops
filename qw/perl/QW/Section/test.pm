package QW::Section::test;

use strict;

sub hello_parse_cli { return ( "casual" ); }
sub hello { 
    my $qw = shift;
    my $greeting = "Hello";
    $greeting = "Hi" if $qw->option('casual');
    printf "$greeting %s\n",join(" ",@_); 
    return 0; 
}

1;
