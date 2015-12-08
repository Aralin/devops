package QW::DB;

=head1 NAME

QW::DB

=head1 DESCRIPTION

Abstraction Database Layer

=head1 AUTHOR

Jiri Klouda E<lt>jk@zg.czE<gt>

=head1 COPYRIGHT

Copyright 2015 by Jiri Klouda

=cut

use parent QW;

use strict;
use warnings;

use DBI;
use DBD::Pg;
use 5.010;

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    $self = $self->SUPER::new;

    $self->{'db'} = undef;
    $self->{'dbh'} = undef;
    push @{ $self->{'packages'} }, __PACKAGE__;

    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->disconnect;
    $self->SUPER::DESTROY;
}

sub db  { $_[0]->{'db'}; }
sub dbh { $_[0]->{'dbh'}; }

sub dbinfo {
    my $self = shift;
    my $db = 'qw:question@localhost:5432/qw';    # Hardcode default
    $db = $ENV{'QW_DB'} if exists $ENV{'QW_DB'}; # Environment default
    $db = $self->db || $db;
    return split(/[\@:\/]/,$db);
}

sub is_connected { return defined $_[0]->dbh; }

sub connect {
    my $self = shift;
    return $self->dbh if $self->is_connected;

    my ($username,$password,$host,$port,$dbname) = $self->dbinfo;

    $self->debug("QW::DB::connect");

    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port", #";options=$options",
        $username, $password,
        {AutoCommit => 0, RaiseError => 1, PrintError => $self->option('debug')}
    );

    $self->{'dbh'} = $dbh;
    return $dbh;
}

sub disconnect {
    my $self = shift; 
    return unless $self->is_connected;
    $self->debug("QW::DB::disconnect");
    eval { $self->dbh->disconnect; };
    $self->{'dbh'} = undef;
}

sub commit {
    my $self = shift;
    return unless $self->is_connected;
    $self->debug("QW::DB::commit");
    state $updated = $self->check_version;
    $self->dbh->commit;
}

sub transaction {
    my $self = shift; 
    return unless $self->is_connected;
    $self->dbh->begin_work;
}

sub rollback {
    my $self = shift; 
    return unless $self->is_connected;
    $self->debug("QW::DB::rollback");
    $self->dbh->rollback;
}

sub _compare_versions {
    my @c = split(/\./, $_[0]);
    my @r = split(/\./, $_[1]);
    while(@c || @r) {
        my $c = shift(@c) || "0";
        my $r = shift(@r) || "0";
        return $c <=> $r if $c <=> $r;
    }
    return 0;
}
    
sub check_version {
    my $self = shift;
    $self->debug("QW::DB::check_version ".$self->version." <=> ".$self->cached_cli_version);
    my $c = &_compare_versions($self->version,$self->cached_cli_version);
    die "Application ".$self->app." version ".$self->version." does not match required client version ".$self->cached_cli_version if $c < 0;
}

sub cli_version {
    my $self = shift;
    my $query = q{ SELECT cli_version FROM qw$app WHERE name = ? ORDER BY update_t DESC FETCH FIRST 1 ROW ONLY };
    return $self->select_row($query,$self->app);
}

sub execute { &select; }
sub select {
    my ($self,$statement,@values) = @_;

    $self->debug("QW::DB::select Statement: $statement Values:".join(",",map { defined($_)?$_:"<undef>" } @values));
    $self->connect;
    my $sth = $self->dbh->prepare($statement) or die $self->dbh->errstr;
    my $rc = $sth->execute(@values) or die $self->dbh->errstr;
    $sth->finish;

    return $rc;
}

sub select_hash {
    my ($self,$statement,@values) = @_;

    $self->debug("QW::DB::select_hash Statement: $statement Values:".join(",",map { defined($_)?$_:"<undef>" } @values));
    $self->connect;
    my $sth = $self->dbh->prepare($statement) or die $self->dbh->errstr;
    $sth->execute(@values) or die $self->dbh->errstr;

    return $sth->fetchrow_hashref;
}

sub select_row {
    my ($self,$statement,@values) = @_;

    $self->debug("QW::DB::select_row Statement: $statement Values:".join(",",map { defined($_)?$_:"<undef>" } @values));
    $self->connect;
    my $sth = $self->dbh->prepare($statement) or die $self->dbh->errstr;
    $sth->execute(@values) or die $self->dbh->errstr;

    return $sth->fetchrow_array;
}

sub select_col {
    my ($self,$statement,@values) = @_;

    $self->debug("QW::DB::select_col Statement: $statement Values:".join(",",map { defined($_)?$_:"<undef>" } @values));
    $self->connect;
    my $sth = $self->dbh->prepare($statement) or die $self->dbh->errstr;
    $sth->execute(@values) or die $self->dbh->errstr;

    return map { @{ $_ } } @{ $sth->fetchall_arrayref };
    return @{ $sth->fetchall_arrayref };
}


# Returns a list of all records
# Each record is an array
sub selectall_array {
    my ($self,$statement,@values) = @_;

    $self->debug("QW::DB::selectall_array Statement: $statement Values:".join(",",map { defined($_)?$_:"<undef>" } @values));
    $self->connect;
    my $sth = $self->dbh->prepare($statement) or die $self->dbh->errstr;
    $sth->execute(@values) or die $self->dbh->errstr;

    return @{$sth->fetchall_arrayref()};
}

# Returns a list of all records
# Each record is a hash of column names and values
sub selectall_hash {
    my ($self,$statement,@values) = @_;

    $self->debug("QW::DB::selectall_hash Statement: $statement Values:".join(",",map { defined($_)?$_:"<undef>" } @values));
    $self->connect;
    my $sth = $self->dbh->prepare($statement) or die $self->dbh->errstr;
    $sth->execute(@values) or die $self->dbh->errstr;

    return @{$sth->fetchall_arrayref({})};
}

sub selectall {
    my ($self,$statement,@values) = @_;

    $self->debug("QW::DB::selectall Statement: $statement Values:".join(",",map { defined($_)?$_:"<undef>" } @values) );
    $self->connect;
    my $sth = $self->dbh->prepare($statement) or die $self->dbh->errstr;
    $sth->execute(@values) or die $self->dbh->errstr;

    return $sth->fetchall_arrayref;
}

sub now { $_[0]->selectall('select now()')->[0][0] }

1;

