=pod

=head1 NAME

ETL::Pipeline::Input::DelimitedText - Input source for CSV, tab, or pipe
delimited files

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['DelimitedText', iname => qr/\.csv$/i],
    mapping => {First => 'Header1', Second => 'Header2'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::DelimitedText> defines an input source for reading
CSV (comma seperated variable), tab delimited, or pipe delimited files. It
uses L<Text::CSV> for parsing.

B<ETL::Pipeline::Input::DelimitedText> expects a standard CSV file. A lot of
hand built exporters often forget quote marks, use invalid characters, or don't
escape the quotes. If you experience trouble with a file, experiment with the
options to L<Text::CSV>.

=cut

package ETL::Pipeline::Input::DelimitedText;
use Moose;

use 5.014000;
use warnings;

use Carp;
use Text::CSV;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

B<ETL::Pipeline::Input::DelimitedText> consumes the
L<ETL::Pipeline::Input::File> and L<ETL::Pipeline::Input::File::Table> roles.
It supports all of the attributes from these two.

In addition, B<ETL::Pipeline::Input::DelimitedText> uses the options from
L<Text::CSV>. See L<Text::CSV> for a list.

  # Pipe delimited, allowing embedded new lines.
  $etl->input( 'DelimitedText',
    iname => qr/\.dat$/i,
    sep_char => '|',
    binary => 1
  );

=cut

sub BUILD {
	my $self= shift;
	my $arguments = shift;

	my %options;
	while (my ($key, $value) = each %$arguments) {
		$options{$key} = $value unless $self->meta->has_attribute( $key );
	}
	$self->_csv_options( \%options );
}


=head3 skipping

Optional. If you use a code reference for B<skipping>, this input source sends a
line of plain text as the parameter. The text is B<not> parsed into fields. I
assume that you're skipping report headers, not formatted data.

=head2 Methods

=head3 run

This is the main loop. It opens the file, reads records, and closes it when
done. This is the place to look if there are problems.

L<ETL::Pipeline> automatically calls this method.

=cut

sub run {
	my ($self, $pipeline) = @_;

	my $csv = Text::CSV->new( $self->_csv_options );
	my $path = $self->file;

	# Open the file.
	my $handle = $path->openr();
	croak "Cannot read '$path'" unless defined $handle;

	# Skip over report headers. These are not data. They are extra rows put
	# there for report formats. The data starts after these rows.
	my $line;
	my $skip = $self->skipping;
	if (ref( $skip ) eq 'CODE') {
		while (!$handle->eof) {
			$line = $handle->getline;
			last if !$skip->( $line );
		}
	} elsif ($skip > 0) {
		$handle->getline foreach (1 .. $skip);
	}

	# Load field names.
	unless ($self->no_column_names) {
		my $fields;
		if (defined $line) {
			$fields = $csv->parse( $line );
			$line = undef;
		} else {
			$fields = $csv->getline( $handle );
		}

		if (defined $fields) {
			while (my ($index, $value) each @$fields) {
				$pipeline->add_alias( $value, $index )
			}
		}
	}

	# Read and process each line.
	while (!$csv->eof) {
		my $fields;
		if (defined $line) {
			$fields = $csv->parse( $line );
			$line = undef;
		} else {
			$fields = $csv->getline( $handle );
		}
		my $at = $csv->input_line_number();

		if (defined $fields) {
			my %record;
			while (my ($index, $value) each @$fields) {
				$record{$index} = $value;
			}
			$pipeline->record( \%record, "CSV file '$path', line $at" );
		} elsif (!$self->csv->eof) {
			my ($code, $message, $position) = $self->csv->error_diag;
			croak "CSV file '$path', error $code: $message at character $position (line $at)";
		}
	}

	# Close the file when done.
	close $handle;
}


=head2 Internal Methods & Attributes

=head3 _csv_options

L<Text::CSV> options passed into the object constructor. I either needed to
store the options or a L<Text::CSV> object. I chose to store the options. The
L</run> method uses them to create a L<Text::CSV> object.

=cut

has '_csv_options' => (
	is  => 'rw',
	isa => 'HashRef[Any]',
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File>,
L<ETL::Pipeline::Input::File::Table>, L<Text::CSV>

=cut

with 'ETL::Pipeline::Input';
with 'ETL::Pipeline::Input::File';
with 'ETL::Pipeline::Input::File::Table';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
