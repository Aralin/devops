# Name: QW.pm

package QW;

use strict;
use Getopt::Long;

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    $self = bless {
        config => {},
        options => {},
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

sub section { $_[0]->{'section'}; }
sub command { $_[0]->{'command'}; }

sub command_parse { $_[0]->{'command'}."_parse_".$_[0]->{'mode'}; }

sub init {}

sub parse_cli {
    my $self = shift;

    $self->{'mode'} = "cli";
    $self->{'argv'} = [ @_ ];

    $self->parse(
        'database|db=s',
        'debug',
    );

    $self->{'section'} = shift(@{$self->argv}) || return 1;
    $self->{'command'} = shift(@{$self->argv}) || return 1;

    return 0;
}

sub parse_getopt {
    my $self = shift;
    
    &Getopt::Long::Configure("pass_through","bundling","no_auto_abbrev");
    &Getopt::Long::GetOptionsFromArray($self->argv,$self->options,
        @_
    );
    &Getopt::Long::Configure("auto_abbrev");
    return 0;    
}

sub parse {
    my $self = shift;
    return $self->parse_getopt(@_) if $self->mode eq "cli";
    die "Unknown parsing method";
}

sub dump {
    require Data::Dumper;
    print &Data::Dumper::Dumper([ @_ ]);
}

sub execute {
    my $self = shift;
    my $status = 1;

    # Check section and load it
    eval { require "QW/Section/".$self->section.".pm"; };    
    warn $@ if($@ && $self->option('debug'));
    if($@ =~ m/^Can\'t locate /) {
        die "Section ".$self->section." not found!";
    }
    
    # Check command existence
    my $package = "QW::Section::".$self->section;
    if(! $package->can($self->command)) {
        die "Command ".$self->command." in section ".$self->section." not found!";            
    }

    my @parse = ();
    if($package->can($self->command_parse)) {
        eval { $self->parse( $package->can($self->command_parse)->($self) ); };
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
