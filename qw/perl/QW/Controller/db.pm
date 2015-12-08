package QW::Controller::db;

use strict;

sub sql_parse_cli { return ( "quiet|q", "file|f=s" ); }
sub sql { 
    my $qw = shift;

    my ($username,$password,$host,$port,$dbname) = $qw->dbinfo;
    
    my @args = ("/Applications/Postgres.app/Contents/Versions/9.4/bin/psql");

    push @args, ("-h",$host,"-p",$port,"-U",$username,$dbname);
    push @args, ("-q") if $qw->option('quiet');
    push @args, ("-f",$qw->option('file')) if $qw->option('file');

    exec(@args);

    return 0; 
}

sub version {
    my $qw = shift;

    printf "Application:\t%s\n",$qw->app;
    printf "Client Version:\t%s\n",$qw->version;
    printf "Server Version:\t%s\n",$qw->cached_cli_version;

    return 0;
}

sub now {
    my $qw = shift;

    $qw->connect;
    $qw->say( $qw->now );
    $qw->disconnect;
    return 0;
}

sub create {
    my $qw = shift;

    foreach my $object ($qw->objects) {
        my $o = $qw->create($object);
        if( $o->can("create_table") ) {
            $qw->say( "For object $object creating db model");
            $o->create_table;
        }
    }
    $qw->commit;
    $qw->say( "Schema created for application ".$qw->app. "!" );
    return 0; 
}

sub drop {
    my $qw = shift;

    foreach my $object (reverse $qw->objects) {
        my $o = $qw->create($object);
        if( $o->can("drop_table") ) {
            $qw->say( "For object $object dropping db model");
            $o->drop_table;
        }
    }
    $qw->commit;
    $qw->say( "Schema dropped for application ".$qw->app. "!" );
    return 0; 
}

1;
