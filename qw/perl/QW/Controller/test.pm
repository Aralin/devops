package QW::Controller::test;

use strict;

sub hello_parse_cli { return ( "casual" ); }
sub hello { 
    my $qw = shift;
    my $greeting = "Hello";
    $greeting = "Hi" if $qw->option('casual');
    $qw->say(sprintf("$greeting %s",join(" ",@_))); 
    return 0; 
}

sub sql {
    my $qw = shift;

    my $test = $qw->create_test('name'=>"My Test",'value'=>"Whatever");
    my @attr = $test->attributes;
    my %attr = @attr;
    require U;
    @attr = &U::even(@attr);

    $qw->dump(\@attr,\%attr);
    $qw->dump($test);

    $qw->say( join ",", @attr );
    $qw->say( $test->sql_create_table() );
    $qw->say( $test->sql_drop_table() );
    $qw->say( $test->sql_insert() );


    return 0;
}

1;
