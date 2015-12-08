#
# File : QW/include/db-attributes.pl
# Role : Database Object Attributes
# 

# Include this file to add a database object the have persistent properties
# Depends on role Object

sub key { return ('id') unless @key; return @key; }

sub id { $_[0]->get('id'); }

sub get_t { my $time = &get; return undef unless defined $time; ($time,) = split /\./,$time; return $time; }

sub update {
    my $self = shift;
    my $attr = shift;
    my $what = $#_ < 0 ? $self->get($attr) : shift;
 
    my $rc = $self->app->execute($self->sql_update($attr), $what, $self->aa($self->key));
    return undef unless defined $rc;
    $self->set($attr => $what);
    return 0;
}

sub update_t {
    my $self = shift;
    my $rc = $self->app->execute($self->sql_update_t(@_), $self->aa($self->key));
    return undef unless defined $rc;
    return undef unless defined $self->query;
    return 0;
}

sub query_by {
    my $self = shift;
    my $rh_table = $self->app->select_hash($self->sql_query_by(@_), $self->aa(@_) );
    return undef unless defined $rh_table;
    map { $self->{$_} = $rh_table->{$_} if defined $rh_table->{$_}; } keys %$rh_table;
    return 0;
}

sub query { my $self = shift; $self->query_by($self->key); }

sub insert {
    my $self = shift;
    return $self->get('id') if defined $self->get('id');
    my ($id) = $self->app->select_row( $self->sql_insert, $self->aa(@_) );
    return undef unless defined $id;
    $self->set('id' => $id);
    return 0;
}

sub create_table {
    my $self = shift;
    my $rc = $self->app->execute( $self->sql_create_table );
    return undef unless defined $rc;
    return 0;
}

sub drop_table {
    my $self = shift;
    my $rc = $self->app->execute( $self->sql_drop_table );
    return undef unless defined $rc;
    return 0;
}

# DB Specific - PostgreSQL
sub sql_table {
    my $self = shift;
    my $name = lc $self->app->app.'$'.$self->class;
}

sub sql_create_table {
    my $self = shift;

    my @a = $self->attributes;
    my %a = @a;
    my $a = join(",\n",map { 
        my $rh = $a{$_}->{'db'}; 
        $_ .= " ".$rh->{'type'}
            . ($rh->{'required'} ? " NOT NULL":"")
            . ($rh->{'unique'} ? " UNIQUE":"")
            . ($rh->{'primary key'} ? " PRIMARY KEY":"")
            . ($rh->{'default'} ? " DEFAULT ".$rh->{'default'} : "");
    } grep { exists $a{$_}->{'db'} } @a);

    return "CREATE TABLE ".$self->sql_table." (\n".$a."\n);";
}

sub sql_drop_table {
    my $self = shift;
    return "DROP TABLE ".$self->sql_table.";";
}

sub sql_query_by {
    my $self = shift;
    return "SELECT * FROM ".$self->sql_table." WHERE ". join " AND ", map { "$_ = ?" } @_;
}

sub sql_update_t {
    my ($self,$attr) = @_;
    return "UPDATE ".$self->sql_table." SET $attr = now() WHERE ".join " AND ", map { "$_ = ?" } $self->key;
}

sub sql_update {
    my ($self,$attr) = @_;
    return "UPDATE ".$self->sql_table." SET $attr = ? WHERE ".join " AND ", map { "$_ = ?" } $self->key;
}

sub sql_insert {
    my $self = shift;
    my %attributes = $self->attributes;
    return "INSERT";
}

1;
