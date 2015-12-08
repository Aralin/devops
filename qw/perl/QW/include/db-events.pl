#
# File : QW/include/db-events.pl
# Role : Database Events
# 

# Include this file to add a database object the ability to have events
# Depends on role defining $self->id

our $db_event_table = 'qw$event';

sub e_list { returrn (); }
sub e_set {}

sub e_my {
    my $self = shift;
    $self->e_log($self->app->user(),@_);
}

# [when(timestamp)], where(id), who(user), what(event), how(text), with(data)
sub e_log {
    my ($self,$user,$event,$text,@data) = @_;
    unshift @data, map { $_ => $self->get($_) } grep { defined $self->get($_) } $self->e_sign if $self->can("e_sign");
    $self->e_db($user,$event,$text,$self->e_data(@data));
}

sub e_data {
    my $self = shift;
    my %date = @_;
    return sprintf "<event>%s</event>", join "", map { "<$_>".$data{$_}."</$_>"; } grep { defined $data{$_} } keys %data;
}

sub e_db {
    my $self = shift;
    my $rc = $self->app->execute( $self->sql_insert_event, $self->id, @_);
    return undef unless defined $rc;
    $self->e_set(@_);
}

# DB Specific - PostgreSQL

sub sql_insert_event {
    return qq{
        INSERT INTO TABLE $db_event_table (id,username,event,description,data) VALUES (?,?,?,?,XMLPARSE(CONTENT ?))
    }
}
