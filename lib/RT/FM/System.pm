
=head1 NAME 

RT::FM::System

=head1 DESCRIPTION

RT::FM::System is a simple global object used as a focal point for things
that are system-wide.

It works sort of like an RT::Record, except it's really a single object that has
an id of "1" when instantiated.

This gets used by the ACL system so that you can have rights for the scope "RT::FM::System"

In the future, there will probably be other API goodness encapsulated here.

=cut


package RT::FM::System;
use base qw /RT::Base/;
use strict;
use vars qw/ $RIGHTS/;



# System rights are rights granted to the whole system
# XXX TODO Can't localize these outside of having an object around.
$RIGHTS = {
};


foreach my $right ( keys %{$RIGHTS} ) {
    $RT::ACE::LOWERCASERIGHTNAMES{ lc $right } = $right;
}


=head2 AvailableRights

Returns a hash of available rights for this object. The keys are the right names and the values are a description of what the rights do

=cut

sub AvailableRights {
    my $self = shift;
    my $class = RT::FM::Class->new($RT::SystemUser);
    my $rights = class->AvailableRights();
    return($rights);
}


=head2 new

Create a new RT::FM::System object. Really, you should be using $RT::FM::System

=cut

                         
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless( $self, $class );


    return ($self);
}

=head2 id

Returns RT::FM::System's id. It's 1. 


=begin testing

use RT::FM::System;
my $sys = RT::FM::System->new();
is( $sys->Id, 1);
is ($sys->id, 1);

=end testing


=cut

*Id = \&id;

sub id {
    return (1);
}

1;