# Name: QW.pm

package QW;

use strict;
use Getopt::Long;

%QW::defaults = (
    'mode' => 'cli',
    'app'  => 'QW',
);

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    $self = bless {
        config => {},
        options => {},
        app => undef,
        section => undef,
        command => undef,
        argv => undef,
        mode => undef,
    }, $class;

    return $self;
}

sub mode    { $_[0]->{'mode'}; }

sub options { $_[0]->{'options'}; }
sub option  { $_[0]->{'options'}->{$_[1]}; }

sub argv    { $_[0]->{'argv'} }

sub app     { $_[0]->{'app'}; }
sub section { $_[0]->{'section'}; }
sub command { $_[0]->{'command'}; }

sub command_parse { $_[0]->{'command'}."_parse_".$_[0]->{'mode'}; }

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

sub init {
    my $self = shift;
    my %init = @_;
    map { $self->{$_} = exists($init{$_}) ? $init{$_} : $QW::defaults{$_} } keys %QW::defaults;
    return $self;
}

sub dump {
    my $self = $_[0];
    require Data::Dumper;
    print &Data::Dumper::Dumper([ @_ ]);
    return $self;
}

sub execute {
    my $self = shift;
    my $status = 1;

    # Check section and load it
    eval { require $self->app."/Section/".$self->section.".pm"; };    
    warn $@ if($@ && $self->option('debug'));
    if($@ =~ m/^Can\'t locate /) {
        die "Section ".$self->section." not found!";
    }
    
    # Check command existence
    my $package = $self->app."::Section::".$self->section;
    if(! $package->can($self->command)) {
        die "Command ".$self->command." in section ".$self->section." not found!";            
    }

    my @parse = ();
    if($package->can($self->command_parse)) {
        eval { $self->parse_options( $package->can($self->command_parse)->($self) ); };
        warn $@ if($@ && $self->option('debug'));
        if($@) {
            die "Command ".$self->command." in section ".$self->section." failed to parse!";
        }
    }

    $self->dump($self) if $self->option('debug');

    eval { $status = $package->can($self->command)->($self,@{ $self->argv }); };
    warn $@ if($@ && $self->option('debug'));
    if($@) {
        die "Command ".$self->command." in section ".$self->section." failed to execute!";
    }
    return $status;
}

1;
