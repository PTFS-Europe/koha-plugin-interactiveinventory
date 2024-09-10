package Koha::Plugin::Com::InteractiveInventory::Controllers::Items;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(decode_json);
use Try::Tiny;
use Data::Dumper;
use C4::Circulation qw( AddReturn );
use Koha::DateUtils qw( dt_from_string );


sub modifyItemFields {
    my $self = shift;

    # Parse JSON from request body
    my $data = $self->req->json;

    # Validate required fields
    unless ( $data->{barcode} && $data->{fields} && %{ $data->{fields} } ) {
        return $self->render(
            status => 400,
            json   => { error => 'Missing barcode or fields to update' }
        );
    }

    # Find the item by barcode
    my $item = Koha::Items->find( { barcode => $data->{barcode} } );
    unless ($item) {
        return $self->render(
            status => 404,
            json   => { error => 'Item not found' }
        );
    }

    # Attempt to update the item fields
    return try {
        foreach my $field ( keys %{ $data->{fields} } ) {
            warn "Updating field: $field";
            warn "Value: " . $data->{fields}->{$field};
            warn Dumper( $item->can($field) );
            warn $item->itemlost;
            if ( $item->can($field) ) {
                $item->$field( $data->{fields}->{$field} );
            } else {
                die "Invalid field: $field";
            }
        }
        $item->store;    # Assuming there's a method to save changes to the item

        $self->render(
            status => 200,
            json   => { success => 'Item updated successfully' }
        );
    } catch {
        my $error = $_;
        $self->render(
            status => 500,
            json   => { error => "Failed to update item: $error" }
        );
    };
}

sub checkInItem {
    my $self = shift;

    # Parse JSON from request body
    my $data = $self->req->json;

    # Validate required fields
    unless ( $data->{barcode} ) {
        return $self->render(
            status => 400,
            json   => { error => 'Missing barcode' }
        );
    }
    unless ( $data->{date} ) {
        return $self->render(
            status => 400,
            json   => { error => 'Missing date' }
        );
    }
    

    # Find the item by barcode
    my $item = Koha::Items->find( { barcode => $data->{barcode} } );
    unless ($item) {
        return $self->render(
            status => 404,
            json   => { error => 'Item not found' }
        );
    }

    my $item_unblessed = $item->unblessed;
    my ($doreturn, $messages, $iteminformation, $borrower) = AddReturn($data->{barcode}, $item->homebranch);
    if( $doreturn ) {
        $item_unblessed->{onloan} = undef;
        $item_unblessed->{datelastseen} = dt_from_string;
        $self->render(
            status => 200,
            json   => { success => 'Item checked-in successfully' }
        );
    } else {
        return $self->render(
            status => 500,
            json   => { error => "Failed to check in item" }
        );
    }
        
    
}
1
