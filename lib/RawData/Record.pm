=pod

=head1 DESCRIPTION

The L<RawData::Parser> class reads individual records from a file into memory.
This is the in-memory representation of a record. You should use 
L<RawData::Parser> to create the instances of this class.

This class knows almost nothing about the format or content of the records. 
It provides a generic API. The API keeps L<RawData::Converter> from having
different code covering every possible file format.

=cut

package RawData::Record;
use Moose;


=head1 METHODS & ATTRIBUTES

=head3 came_from

This text goes into error messages so that the user can find and fix any
problems with the original data. The L<RawData::Parser/read_one_record> class 
normally sets this value.

=cut

has 'came_from' => (
	is  => 'rw',
	isa => 'Str',
);


=head3 data

This hash holds the actual data. It is keyed by the file field name. The
name depends on the file format. For example, a spreadsheet would use the
column. A text file might use the field number.

=cut

has 'data' => (
	default => sub { {} },
	is      => 'ro',
	isa     => 'HashRef',
);


=head3 from_array

This class method returns a new L<RawData::Record> object with data from a
Perl list - or a reference to a list. L</data>'s hash key is the position 
number in the list.

=cut

sub from_array($@) {
	my ($class, @fields) = @_;

	# The main loop always uses a list reference. That way I can use the
	# same loop, and still accept multiple types if input. If the only
	# parameter is a list reference, then we assume you want the referenced
	# list - not the pointer. Otherwise we copy the list you sent.
	my $list = \@fields;
	   $list = $fields[0] if (
			(@fields == 1) 
			and (ref( $fields[0] ) eq 'ARRAY')
		);

	# Yes - "foreach" is nicer. I need the index to create the key for the
	# hash. "foreach" doesn't offer any advantage in this case. Besides, I
	# want the hash to count from field one - not zero.
	my %data;
	for (my $index = 0; $index < @$list; $index++) {
		$data{$index + 1} = $list->[$index];
	}

	# Create an object that stores this data.
	return $class->new( data => \%data );
}


=head3 is_blank

This boolean flag indicates if the record is blank. I<Blank> may mean 
different things to different file formats. using a flag gives me a standard
means of checking.

The L<RawData::Parser/read_one_record> normally sets this attribute.

=cut

has 'is_blank' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
);


=head1 SEE ALSO

L<RawData::File>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy,
Vanderbilt University Medical Center

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

