#
# File : QW/include/db-properties.pl
# Role : Database Object Properties
# 

# Include this file to add a database object the ability to have properties
# Depends on role defining $self->id

our $db_properties_table = 'qw$properties';
our $db_properties_view  = 'qw$view_properties';
our $db_properties_key   = '_db_properties';

sub p_query {
    my $self = shift;
    return if defined $self->get($db_properties_key);

    my %values = $self->app->select_col($self->sql_property_query, $self->id);
    $self->set($db_properties_key,\%values);
#   $self->set(\%values) if %values;
    return 0;
}

sub p_list {
    my $self = shift;
    $self->p_query;
    return unless defined $self->get($db_properties_key);
    return sort keys %{ $self->get($db_properties_key) };
}

sub p_each {
    my $self = shift;
    $self->p_query;
    my $rh_prop = $self->get($db_properties_key);
    return map { $_ => $rh_prop->{$_}  } grep { defined $rh_prop->{$_} } keys %$rh_prop;
}

sub p_get {
    my ($self,$key) = @_;
    $self->p_query;
    my $rh_prop = $self->get($db_properties_key);
    return unless defined $rh_prop;
    return unless exists $rh_prop->{$key};
    return $rh_prop->{$key};
}

sub p_set {
    my $self = shift;
    my %value = @_;
    map { 
        $self->get($db_properties_key)->{$_} = $value{$_}; 
#       $self->set($_,$value{$_});
    } keys %value;
}

sub p_update {
    my $self = shift;
    my %value = @_;
    my $username = $self->app->require_user;

    for my $key (keys %value) {
        my $rc = $self->app->execute($self->sql_property_update, $self->id, $key, $value{$key}, $username);
        delete $value{$key} unless defined $rc;
    }
    return undef unless %value;
    $self->p_set(%value);
}

sub p_remove {
    my $self = shift;
    $self->p_update( map { $_ => undef } @_ );
}

# XML property tag generator ; requires XML
sub p_xml {
    my ($self,$writer) = @_;
    my %value = $self->p_each;
    map { $writer->dataElement("property", $value{$_}, key => $_);  } sort keys %value;
}

# DB Specific - PostgreSQL

sub sql_property_update {
    return qq {
        INSERT INTO $db_properties_table (id,key,value,username) VALUES (?,?,?,?)
    };
}

sub sql_property_query {
    return qq{
        SELECT key, value FROM $db_properties_view WHERE id = ?
    };
}
