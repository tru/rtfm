# BEGIN LICENSE BLOCK
# 
#  Copyright (c) 2002 Jesse Vincent <jesse@bestpractical.com>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of version 2 of the GNU General Public License 
#  as published by the Free Software Foundation.
# 
#  A copy of that license should have arrived with this
#  software, but in any event can be snarfed from www.gnu.org.
# 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
# END LICENSE BLOCK

no warnings qw/redefine/;

use RT::FM::CustomFieldValueCollection;
use RT::FM::ArticleCFValueCollection;
use RT::FM::ClassCustomFieldCollection;

=head2 ValidateName new_name

The name of a custom field can neither be blank nor a duplicate

=cut

sub ValidateName {
    my $self = shift;
    my $val = shift;
    return undef if ($val eq undef || $val eq '');
    my $obj = RT::FM::CustomField->new($RT::SystemUser);
    $obj->LoadByCols(Name => $val);
    return undef if ($obj->Id);
    return(1);

}


use vars qw( @TYPES);

@TYPES = qw(SelectSingle SelectMultiple FreeformSingle FreeformMultiple MIMESingle MIMEMultiple );


# {{{ Create

=head2 Create



=begin testing

use_ok('RT::CurrentUser');
my $user = RT::CurrentUser->new('root');
ok ($user->Id, "Loaded the user");

use_ok('RT::FM::CustomField');
ok(my $cf= RT::FM::CustomField->new($user));
my ($id, $msg) = $cf->Create(Name => '');
ok(!$id, $msg);



 ($id, $msg) = $cf->Create(Name => '');
ok(!$id, $msg);
 ($id, $msg) = $cf->Create(Name =>undef);
ok(!$id, $msg);
 ($id, $msg) = $cf->Create(Name => 'foo', Type => 'SelectMultiple');
ok($id, $msg);
 ($id, $msg) = $cf->Create(Name => 'foo');
ok(!$id, $msg);

=end testing



=cut


# }}}
# {{{ Dealing with "possible" values for selectfoo customfields

# {{{ Value

=item Value NAME

Returns a RT::FM::CustomFieldValue object of this Field\'s value with the name NAME

=cut

sub Value {
    my $self = shift;
    my $name = shift;

    my $values = $self->ValuesObj();
    $values->Limit(FIELD => 'Name',
		   OPERATOR => '=',
		   VALUE => $name);

    return ($values->First);

}

# }}}

# {{{ ValuesObj

=item ValuesObj

Returns a RT::FM::CustomFieldValueCollection object of this Field's values.

=cut

sub ValuesObj {
	my $self = shift;
	my $values = RT::FM::CustomFieldValueCollection->new($self->CurrentUser);
	$values->Limit( FIELD => 'CustomField', OPERATOR => '=', VALUE => $self->Id );
	return ($values);
}

# }}}

# {{{ AddValue

=item AddValue HASH

Create a new value for this CustomField.  Takes a paramhash containing the elements Name, Description and SortOrder

=begin testing

my $cf = RT::FM::CustomField->new($RT::SystemUser);
$cf->Load('foo');
ok ($cf->Id, "Loaded the 'foo' customfield");
my  ($id, $msg) =  $cf->AddValue(Name => 'Val1', Description => "Testing");
ok ($id, $msg);
  ($id, $msg) =  $cf->AddValue(Name => 'Val2', Description => "Testing");
ok ($id, $msg);

my $values = $cf->ValuesObj;
ok ($values, "Got a values object of type ".ref($values));
ok ($cf->ValuesObj->Count == 2, "The CF has two values");
($id, $msg) =  $cf->DeleteValue('Val1');
ok ($id,$msg);
ok ($cf->ValuesObj->Count == 1, "The CF has one value");
is($cf->ValuesObj->First->Name, 'Val2');

=end testing


=cut

sub AddValue {
	my $self = shift;
	my %args = ( Name => undef,
		     Description => '',
		     SortOrder => '0',
		     @_ );
             
	my $newval = RT::FM::CustomFieldValue->new($self->CurrentUser);
	return($newval->Create(  CustomField => $self->Id,
             Name =>$args{'Name'},
             Description => $args{'Description'},
             SortOrder => $args{'SortOrder'} 
        ));    



}

# }}}

# {{{ DeleteValue

=item DeleteValue  <id_or_name>

Deletes a value from this custom field by id or name.  

Does not remove this value for any article which has had it selected    

=cut

sub DeleteValue {
        my $self = shift;
    my $id = shift;

        my $val_to_del = RT::FM::CustomFieldValue->new($self->CurrentUser);
        $val_to_del->Load($id);
        unless ($val_to_del->Id) {
                return (0, $self->loc("Couldn't find that value"));
        }
        unless ($val_to_del->CustomField == $self->Id) {
                return (0, $self->loc("That is not a value for this custom field"));
        }

        my $retval = $val_to_del->Delete();
    if ($retval) {
        return ($retval, $self->loc("Custom field value deleted"));
    } else {
        return(0, $self->loc("Custom field value could not be deleted"));
    }
}

# }}}



=head2 ValidateValue Value

Returns true if Value is a valid value for this custom field.

Returns undef otherwise.

In the case of a non-select custom field, always returns true.

=cut

sub ValidateValue {
    my $self  = shift;
    my $value = shift;

    unless ($value) {
        $RT::Logger->debug("$self asked to validate an undefined value");
        undef;
    }

    #non select-foo custom fields can have whatever values they want
    if ( $self->Type !~ /^Select/ ) {
        return (1);
    }
    else {

        my $values = $self->ValuesObj;
        $values->Limit( FIELD => 'Name', OPERATOR => '=', VALUE => $value );
        if ( $values->First ) {
            return (1);
        }
        else {
            return (undef);
        }
    }
}


# }}}

# {{{ Types

=item Types 

Retuns an array of the types of CustomField that are supported

=cut

sub Types {
	return (@TYPES);
}

# }}}

# {{{ ValidateType

=head2 ValidateType type

Returns true if type is a valid custom field type. returns undef otherwise

=begin testing 

my $o = RT::FM::CustomField->new($RT::SystemUser);

ok ($o->ValidateType('SelectSingle'), "SelectSingle");
ok ($o->ValidateType('SelectMultiple'), "SelectMultiple");
ok ($o->ValidateType('FreeformSingle'), "FreeformSingle");
ok ($o->ValidateType('FreeformMultiple'), "FreeformMultiple");
ok ($o->ValidateType('MIMESingle'), "MIMESingle");
ok ($o->ValidateType('MIMEMultiple'), "MIMEMultiple");
ok (!$o->ValidateType('BlahgSingle'), "BlahgSingle");
ok (!$o->ValidateType('BlahgMultiple'), "BlahgMultiple");


=end testing


=cut

sub ValidateType {
    my $self = shift;
    my $type = shift;

    return grep {/^$type$/}  @TYPES; 
}


# }}}

# {{{ SingleValue


=head2 SingleValue 

Returns true if this custom field is a single-valued custom field. 
Returns undef otherwise.

=cut

sub SingleValue {

    my $self = shift;
    if ( $self->Type =~ /Single/ ) { 
        return 1;
     } else {
        return(undef);
     }

}

# }}}

# {{{ Deal with values for a given article

# {{{ ValuesForArticle

=item ValuesForArticle TICKET

Returns a RT::ArticleCustomFieldValues object of this Field's values for TICKET.
Article is a ticket id.


=cut

sub ValuesForArticle {
        my $self = shift;
    my $article_id = shift;

        my $values = new RT::FM::ArticleCFValueCollection($self->CurrentUser);
        $values->LimitToCustomField($self->Id);
        $values->LimitToArticle($article_id);
        return ($values);
}

# }}}


# {{{ AddValueForArticle

=item AddValueForArticle HASH

Adds a custom field value for a Article. Takes a param hash of Article and Content

=cut

sub AddValueForArticle {
        my $self = shift;
        my %args = ( Article => undef,
                 Content => undef,
                     @_ );


        my $newval = RT::FM::ArticleCFValue->new($self->CurrentUser);
        my ($val,$msg) = $newval->Create(Article => $args{'Article'},
                            Content => $args{'Content'},
                            CustomField => $self->Id);

    return($val,$msg);

}

# }}}

# {{{ DeleteValueForArticle

=item DeleteValueForArticle HASH

Adds a custom field value for a Article. Takes a param hash of Article and Content

=cut

sub DeleteValueForArticle {
    my $self = shift;
    my %args = ( Article  => undef,
                 Content => undef,
                 @_ );

    my $oldval = RT::ArticleCustomFieldValue->new( $self->CurrentUser );
    $oldval->LoadByArticleContentAndCustomField( Article      => $args{'Article'},
                                                Content     => $args{'Content'},
                                                CustomField => $self->Id );

    # check ot make sure we found it
    unless ( $oldval->Id ) {
        return (
            0,
            $self->loc(
                "Custom field value [_1] could not be found for custom field
 [_2]", $args{'Content'}, $self->Name ) );
    }

    # delete it

    my $ret = $oldval->Delete();
    unless ($ret) {
        return ( 0, $self->loc("Custom field value could not be found") );
    }
    return ( 1, $self->loc("Custom field value deleted") );
}


# }}}

# {{{ ValidForClass

=head2 ValidForClass ClassId

Returns true if this is a valid custom field for this Class.
Returns undef otherwise.
When called with no argument, looks only for global custom fields

=cut


sub ValidForClass {
    my $self  = shift;
    my $class = shift;

    my $class_cfs = RT::FM::ClassCustomFieldCollection->new($RT::SystemUser);

    if ($class) {
        my $class_obj = RT::FM::Class->new($RT::SystemUser);
        $class_obj->Load($class);
        unless ( $class_obj->Id ) {
            return (undef);
        }

        $class_cfs->Limit( FIELD           => 'Class',
                           OPERATOR        => '=',
                           VALUE           => $class_obj->Id,
                           ENTRYAGGREGATOR => 'OR' );

    }
    $class_cfs->Limit( FIELD    => 'CustomField',
                       OPERATOR => '=',
                       VALUE    => $self->Id );

    $class_cfs->Limit( FIELD           => 'Class',
                       OPERATOR        => '=',
                       VALUE           => '0',
                       ENTRYAGGREGATOR => 'OR' );

    if ( $class_cfs->Count ) {
        return (1);
    }
    else {
        return (undef);
    }
}

# }}}

# {{{ ValidateValueForArticle

=head2 ValidateValueForArticle { Value => undef, Article => undef }

Returns true if Value is a valid value for this custom field and the custom field
doesn't already have this value

Returns undef otherwise.


=cut

sub ValidateValueForArticle {
    my $self  = shift;
    my %args = ( Article => undef,
                 Value => undef,
                 @_);



    unless ($args{'Article'} && $args{'Value'}) {
        $RT::Logger->crit("ValidateValueForArticle called with an invalid parameter");
    }

    # If it's an invalid value for the custom field, don't keep going
    unless ($self->ValidateValue ($args{'Value'})) {
        return(undef);
    }

    
    my $article_values = $self->ValuesForArticle($args{'Article'});
  
    my @article_values = @{$article_values->ItemsArrayRef};

    # get the actual values for the custom field as an array and see if it has this entry
    my @values = grep { $_->ContentObj->Summary =~ /^$args{'Value'}$/i} @{$article_values->ItemsArrayRef};
    if (shift @values) {
        return undef;
    } else {
        return 1;
    }

}

# }}}


# }}}

=head2 AddToClass ID

Adds this custom field to the class specified by ID. 

Id can be a name or Id.

"0" is treated as "all classes"


=begin testing

my ($id, $msg);
my $cf = RT::FM::CustomField->new($RT::SystemUser);
($id, $msg) =$cf->Create(Name =>'ClassTest', Type => 'SelectMultiple');

ok($id,$msg);
($id,$msg) = $cf->AddToClass('1');
ok($id,$msg);
($id,$msg) = $cf->AddToClass('0');
ok($id,$msg);
($id,$msg) = $cf->AddToClass('99999999990');
ok(!$id,$msg);


=end testing

=cut

sub AddToClass {
    my $self  = shift;
    my $class = shift;

    
    unless ( $class eq '0' ) {
        my $class_obj = RT::FM::Class->new( $self->CurrentUser );
        $class_obj->Load($class);
        unless ( $class_obj->Id ) {
            return ( 0, $self->loc("Invalid value for class") );
        }
        $class = $class_obj->Id;
    }
    my $ClassCF = RT::FM::ClassCustomField->new( $self->CurrentUser );
    $ClassCF->LoadByCols( Class => $class, CustomField => $self->Id );
    if ( $ClassCF->Id ) {
        return ( 0, $self->loc("That is already the current value") );
    }
    my ( $id, $msg ) =
      $ClassCF->Create( Class => $class, CustomField => $self->Id );

    return ( $id, $msg );
}

=head2 RemoveFromClass ID

Removes this custom field from the class specified by ID. 

Id can be a name or Id.

"0" is treated as "all classes"


=begin testing

my ($id, $msg);
my $cf = RT::FM::CustomField->new($RT::SystemUser);
($id, $msg) =$cf->Load('ClassTest');

ok($id,$msg);
($id,$msg) = $cf->RemoveFromClass('1');
ok($id,$msg);
($id,$msg) = $cf->RemoveFromClass('0');
ok($id,$msg);
($id,$msg) = $cf->RemoveFromClass('99999999990');
ok(!$id,$msg);
($id,$msg) = $cf->RemoveFromClass('2');
ok(!$id,$msg);


=end testing

=cut

sub RemoveFromClass {
    my $self = shift;
    my $class = shift;

    
    unless ( $class eq '0' ) {
        my $class_obj = RT::FM::Class->new( $self->CurrentUser );
        $class_obj->Load($class);
        unless ( $class_obj->Id ) {
            return ( 0, $self->loc("Invalid value for class") );
        }
        $class = $class_obj->Id;
    }
    my $ClassCF = RT::FM::ClassCustomField->new( $self->CurrentUser );
    $ClassCF->LoadByCols( Class => $class, CustomField => $self->Id );
    unless ( $ClassCF->Id ) {
        return ( 0, $self->loc("This custom field does not apply to that class"));
    }
    my ( $id, $msg ) = $ClassCF->Delete;

    return ( $id, $msg );


}


1;