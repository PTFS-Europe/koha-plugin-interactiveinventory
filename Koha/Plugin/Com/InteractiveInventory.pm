package Koha::Plugin::Com::InteractiveInventory;
use Modern::Perl;
use utf8;
## Required for all plugins
use base qw(Koha::Plugins::Base);
## We will also need to include any Koha libraries we want to access
use C4::Context;
use C4::Auth;
use DBI;
use CGI;
use JSON;
use Data::Dumper;
use URI::Escape;

#use Mojo::JSON qw(decode_json);
use C4::Auth   qw( get_template_and_user );
use C4::Output qw( output_html_with_http_headers );
use C4::Items  qw( GetItemsForInventory );
use Koha::Items;
use Koha::ItemTypes;

our $VERSION = 0.0;

our $metadata = {
    name            => 'Interactive Inventory',
    author          => 'Jacob O\'Mara',
    date_authored   => '2024-06-12',
    date_updated    => "2024-06-12",
    minimum_version => '21.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'Interactive Inventory plugin for Koha.',
};

# our $logger = Koha::Logger->get( { interface => 'intranet', category => 'InteractiveInventory'} );

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);

    return $self;
}

sub tool {
    my ( $self, $args ) = @_;
    my $cgi = $self->{cgi};

    my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
        {
            template_name => $self->bundle_path . '/InteractiveInventory.tt',
            query         => $cgi,
            type          => "intranet",
            flagsrequired => { tools => 'inventory' },
        }
    );
    my @class_sources = Koha::ClassSources->search( { used => 1 } )->as_list;
    my $pref_class    = C4::Context->preference("DefaultClassificationSource");

    # Pass @class_sources to the template
    $template->param(
        class_sources => \@class_sources,
        pref_class    => $pref_class,
    );

    output_html_with_http_headers $cgi, $cookie, $template->output;
}

# sub tool {
#   my ( $self, $args ) = @_;

#   my $cgi = $self->{'cgi'};

#   unless ( $cgi->param('session') ) {
#     $self->tool_start();
#   } else {
#     $self->tool_session();
#   }

# }

sub tool_start {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template( { file => 'InteractiveInventory.tt' } );

    $self->output_html( $template->output() );
}

sub get_item_data {
    my ( $self, $args ) = @_;

    # Create a new CGI object
    my $cgi = CGI->new;

    # Get the 'barcode' parameter from the query string
    my $barcode = $cgi->param('barcode');

    # Check if barcode is defined
    unless ( defined $barcode ) {
        print $cgi->header( 'application/json', '500 Internal Server Error' );
        print encode_json( { error => 'Barcode parameter is missing' } );
        return;
    }

    # Process the barcode (e.g., look up item data in the database)
    # For demonstration, let's assume we have a function `lookup_item_by_barcode`
    my $item_data = lookup_item_by_barcode($barcode);

    # Return the item data as a JSON response
    print $cgi->header('application/json');
    print encode_json($item_data);
}

sub lookup_item_by_barcode {
    my ($barcode) = @_;
    warn "Looking up item data for barcode: $barcode";

    my $item = Koha::Items->find( { barcode => $barcode } );

    my $item_data = $item->{_result}->{_column_data};
    warn Dumper($item_data);

    # # Ensure $item_data is a hash reference
    # unless ( ref $item_data eq 'HASH' ) {
    #     die "Expected a hash reference but got: " . ref($item_data);
    # }

    return $item_data;
}

sub start_session {
    my ( $self, $args ) = @_;

    my $session_data_encoded = $self->{cgi}->param('session_data');
    my $session_data_json    = uri_unescape($session_data_encoded);
    my $session_data         = decode_json($session_data_json);
    my @itemtypes            = Koha::ItemTypes->search->as_list;
    my @itemtype_codes       = map { $_->itemtype } @itemtypes;

    # Quote each item type manually
    my @quoted_itemtypes = map { "'$_'" } @itemtype_codes;
    warn Dumper(@itemtype_codes);

    my $minlocation  = $session_data->{'minlocation'};
    my $maxlocation  = $session_data->{'maxlocation'};
    my $location     = $session_data->{'location'};
    my $branchcode   = $session_data->{'branchcode'};
    my $datelastseen = $session_data->{'datelastseen'};
    my $ccode        = $session_data->{'ccode'};
    my @itemsarray   = ('BK');

    warn Dumper($minlocation);
    warn Dumper($maxlocation);
    warn Dumper($location);
    warn Dumper($branchcode);
    warn Dumper($datelastseen);
    warn Dumper($ccode);

    my ( $location_data, $iTotalRecords ) = GetItemsForInventory(
        {
            minlocation  => $minlocation,
            maxlocation  => $maxlocation,
            location     => $location,
            ignoreissued => 0,
            datelastseen => $datelastseen,
            branchcode   => $branchcode,
            branch       => 'CPL',
            offset       => 0,
            size         => 1,
            statushash   => 0,
            itemtypes    => \@quoted_itemtypes,
        }
    );

    # Combine location_data and iTotalRecords into an array
    my @combined_data = ( $location_data, $iTotalRecords );

    # Encode the array as JSON
    my $json_output = encode_json( \@combined_data );

    # Print the JSON-encoded array
    print $json_output;
}

=head3

=cut

sub install {
    my ( $self, $args ) = @_;

    return 1;
}

=head3 static_routes

=cut

sub static_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('api/staticapi.json');
    my $spec     = decode_json($spec_str);
    warn Dumper($spec);

    return $spec;
}

=head3 api_namespace

=cut

sub api_namespace {
    my ($self) = @_;

    return 'interactiveinventory';
}

sub api_routes {
    my ($self) = @_;

    my $spec_str = $self->mbf_read('api/openapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

1;
