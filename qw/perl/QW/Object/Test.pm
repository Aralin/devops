# QW Object Test;

package QW::Object::Test;

use strict;
use warnings;

do "QW/include/object.pl";
do "QW/include/db-attributes.pl";

sub attributes {
    return (
        'id'    => { db => {type => 'INT4', primary_key => 1, default => "nextval('qw_id_seq')"}, 
                     description => "Object ID", },
        'name'  => { db => {type => 'VARCHAR(32)', unique=> 1, required => 1}, 
                     description => "Test Name", },
        'value' => { db => {type => 'VARCHAR(128)'}, 
                     description => "Test Value", },
    );
}


1;
