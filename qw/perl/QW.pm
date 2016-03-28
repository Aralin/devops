package QW;

=head1 NAME

QW - Question Why - Framework for CLI/REST app building

=head1 SYNOPSIS

    use QW;

    my $qw = QW->new;
    eval { $qw->init('app' => 'QW', 'mode' => 'cli')->parse(@ARGV); };
    if($@) { warn $@; exit 1; }

    eval { exit $qw->run; };
    warn $@ if $@;
    # Print Usage
    exit 1;

=head1 DESCRIPTION

QW provides a simple to create a CLI/REST Application

=cut

use 5.010;
use strict;
use Getopt::Long;

%QW::defaults = (
    'mode' => 'cli',
    'app'  => 'QW',
    'version' => '1.0.0',
);

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    $self = bless {
        cache => {},
        options => {},
        packages => [],
        app => undef,
        version => undef,
        section => undef,
        command => undef,
        argv => undef,
        mode => undef,
        model => {},
        view => {},
        controller => {},
        objects => [],
    }, $class;

    push @{ $self->{'packages'} }, __PACKAGE__;

    return $self;
}

sub DESTROY {
    my $self = shift;
}

sub init {
    my $self = shift;
    require U;
    my %init = &U::hash(@_);
    map { $self->{$_} = exists($init{$_}) ? $init{$_} : $QW::defaults{$_} } keys %QW::defaults;
    return $self;
}

sub options { $_[0]->{'options'}; }
sub option  { $_[0]->{'options'}->{$_[1]}; }

sub cache   { $_[0]->{'cache'}; }
sub has_c   { exists $_[0]->{'cache'}->{$_[1]}; }
sub set_c   { $_[0]->{'cache'}->{$_[1]} = $_[2]; return $_[2]; }
sub get_c   { $_[0]->{'cache'}->{$_[1]}; }

sub version { $_[0]->{'version'}; }

sub mode    { $_[0]->{'mode'}; }

sub argv    { $_[0]->{'argv'} }

sub app     { $_[0]->{'app'}; }
sub section { $_[0]->{'section'}; }
sub command { $_[0]->{'command'}; }

sub command_parse { $_[0]->{'command'}."_parse_".$_[0]->{'mode'}; }

sub objects { return keys %{ $_[0]->{'model'} }; }
sub handles { return keys %{ $_[0]->{'controller'} }; }

# Messaging
sub say {
    my $self = shift;
    say @_ if $self->mode eq "cli";
}

sub debug {
    my $self = shift;
    return unless $self->option('debug');
    say @_ if $self->mode eq "cli";
}

sub warn {
    my $self = shift;
    return unless $self->option('debug');
    warn @_ if $self->mode eq "cli";
}

sub error {
    my $self = shift;
    say STDERR "ERROR:",@_ if $self->mode eq "cli";
}

sub dump {
    my $self = shift;
    require Data::Dumper;
    say &Data::Dumper::Dumper( @_ ) if $self->mode eq "cli";
    return $self;
}

# MVC - Model View Controller section

# Model registration
sub model {
    my ($self,$name,$package) = @_;
    if(exists $self->{'model'}->{$name}) {
        return $self->{'model'}->{$name} unless $package;
        die "Already registered model $name with package ".$self->{'model'}->{$name} unless $self->{'model'}->{$name} eq $package;
    } else {
        return undef unless $package;
        $self->{'model'}->{$name} = $package;
    } 
    return $package;
}

sub model_config ($$$) {
    my ($self,$name,$key) = @_;
    return undef unless exists $self->{'model'}->{$name};
    my %config = &{$self->{'model'}->{$name}."::config"}->(); 
    return undef unless exists $config{$key};
    return $config{$key};
}

# Nodel management
sub create {
    my $self = shift;
    my $class = shift; # Class name

    my $package = $self->model($class)            
               || $self->app."::Object::".$class; 
    
    # Check default application controllers
    eval "require $package;";    
    $self->warn($@) if $@;
    if($@ =~ m/^Can\'t locate /) {
        die "Model for $class in package $package not found!";
    }   

    if(! $package->can("new")) {
        die "Model $class in package $package missing constructor";
    }

    my $object = $package->new(@_);
    push @{ $self->{'objects'} }, $object;
    $object->set('_app'=>$self);
    $object->set('_class'=>$class);
    return $object;
}

# View registration
sub view {
    my ($self,$name,$package) = @_;
    if(exists $self->{'view'}->{$name}) {
        return $self->{'view'}->{$name} unless $package;
        die "Already registered view $name with package ".$self->{'view'}->{$name} unless $self->{'view'}->{$name} eq $package;
    } else {
        return undef unless $package;
        $self->{'view'}->{$name} = $package;
    } 
    return $package;
}

# Controller registration
sub controller {
    my ($self,$name,$package) = @_;
    if(exists $self->{'controller'}->{$name}) {
        return $self->{'controller'}->{$name} unless $package;
        die "Already registered controller $name with package ".$self->{'controller'}->{$name} unless $self->{'controller'}->{$name} eq $package;
    } else {
        return undef unless $package;
        $self->{'controller'}->{$name} = $package;
    } 
    return $package;
}

# Command parsing
sub parse_options_cli {
    my $self = shift;
    
    &Getopt::Long::Configure("pass_through","bundling","no_auto_abbrev");
    &Getopt::Long::GetOptionsFromArray($self->argv,$self->options,
        @_
    );
    &Getopt::Long::Configure("auto_abbrev");
    return 0;    
}

sub parse_cli {
    my $self = shift;

    $self->{'argv'} = [ @_ ];

    $self->parse_options_cli(
        'database|db=s',
        'debug',
    );

    $self->{'section'} = lc shift(@{$self->argv}) || return 1;
    $self->{'command'} = lc shift(@{$self->argv}) || return 1;

    return 0;
}

sub parse_options {
    my $self = shift;
    
    if($self->can("parse_options_".$self->mode)) {
        eval { $self->can("parse_options_".$self->mode)->($self,@_); };
        warn $@ if($@ && $self->option('debug'));
        if($@) {
            die "Failed to parse options: @_";
        }
    } else {
        die "Unknown parsing method";
    }
}

sub parse {
    my $self = shift;
    if($self->can("parse_".$self->mode)) {
        eval { $self->can("parse_".$self->mode)->($self,@_); };
        warn $@ if($@ && $self->option('debug'));
        if($@) {
            die "Failed to parse arguments: @_";
        }
    } else {
        die "Unknown parsing method";
    }
    return $self;
}

# Controller entry point
sub run {
    my $self = shift;
    my $status = 1;

    my $package = $self->controller($self->section)           # Defined value
               || $self->app."::Controller::".$self->section; # Default value
    
    # Check default application controllers
    eval "require $package;";    
    $self->warn($@) if $@;
    if($@ =~ m/^Can\'t locate /) {
        die "Controller for ".$self->section." in package $package not found!";
    }   

    if(! $package->can($self->command)) {
        die "Command ".$self->command." in controller ".$self->section." not found!";            
    }

    my @parse = ();
    if($package->can($self->command_parse)) {
        eval { $self->parse_options( $package->can($self->command_parse)->($self) ); };
        $self->warn($@) if $@;
        if($@) {
            die "Command ".$self->command." in controller ".$self->section." failed to parse!";
        }
    }

    #$self->dump($self) if $self->option('debug'); 

    eval { $status = $package->can($self->command)->($self,@{ $self->argv }); };
    $self->warn($@) if $@;
    if($@) {
        die "Command ".$self->command." in controller ".$self->section." failed to execute!";
    }
    return $status;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $called = $AUTOLOAD =~ s/.*:://r;
    
    for($called) {
        /^cached_(.*)$/ && do { # Autoload config method
            my $method = $1;
            return $self->get_c($method) if $self->has_c($method);
            return $self->set_c($method,$self->can($method)->($self,@_));
        };
        /^hash_(.*)$/ && do {
            my $method = $1;
            require U;
            my $rh_arg = &U::hash(@_);
            return map { $self->can($method)->($self,$_,$rh_arg->{$_}); } keys %$rh_arg;
        };
        /^create_(.*)$/ && do { # Autoload config method
            return $self->create($1,@_);
        };
    }
    die "Undefined subroutine $AUTOLOAD called";
}


1;

=head1 TODO

Add REST/Web part of the app

=head1 AUTHOR

Jiri Klouda E<lt>jk@zg.czE<gt>

=head1 COPYRIGHT

Copyright 2015 by Jiri Klouda

=cut
