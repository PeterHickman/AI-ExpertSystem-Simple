package AI::ExpertSystem::Simple::CheckEmail;

use strict;
use warnings;

use AI::ExpertSystem::Simple;

our $VERSION = '1.2';

sub new {
    my ( $class, $filename ) = @_;

    die "CheckEmail->new() takes one arguments"                if scalar(@_) != 2;
    die "CheckEmail->new() argument 1 (FILENAME) is undefined" if !defined($filename);

    my $self = {};

    $self->{_filename} = $filename;
    $self->{_expert}   = AI::ExpertSystem::Simple->new();
    $self->{_expert}->load($filename);

    return bless $self, $class;
}

sub process {
    my ( $self, $filename ) = @_;

    die "CheckEmail->process() takes one arguments"                if scalar(@_) != 2;
    die "CheckEmail->process() argument 1 (FILENAME) is undefined" if !defined($filename);

    ( $self->{_body}, $self->{_list_of_headers} ) = $self->_split_from_file($filename);

    my $response;

    if ( $self->_is_broken() ) {
        $response = "Headers are broken";
    }
    else {
        $response = $self->_classify_mail();
    }

    return $response;
}

sub check_header {
    my ( $self, $header_tag, $min, @data ) = @_;

    foreach my $header ( @{ $self->{_list_of_headers} } ) {
        if ( $header =~ m/^$header_tag:\s*(.*)/i ) {
            my $x = $1;

            my $counter = 0;
            foreach my $match (@data) {
                if ( $x =~ m/$match/i ) {
                    $counter++;
                }
            }

            return ( $counter >= $min ) ? 'yes' : 'no';
        }
    }

    return 'no';
}

sub check_body {
    my ( $self, $min, @data ) = @_;

    my $counter = 0;
    foreach my $match (@data) {
        if ( $self->{_body} =~ m/$match/im ) {
            $counter++;
        }
    }

    return ( $counter >= $min ) ? 'yes' : 'no';
}

sub _classify_mail {
    my ($self) = @_;

    $self->{_expert}->reset();

    while (1) {
        my $r = $self->{_expert}->process();

        if ( $r eq 'question' ) {
            $self->{_expert}->answer( $self->_ask_question( $self->{_expert}->get_question() ) );
        }
        elsif ( $r eq 'finished' ) {
            return $self->{_expert}->get_answer();
        }
        elsif ( $r eq 'failed' ) {
            return "Unknown";
        }
    }
}

sub _ask_question {
    my ( $self, $text, @responses ) = @_;

    my ( $tag, @data ) = split( ' ', $text );

    if ( $self->can("check_$tag") ) {
        no strict 'refs';
        &{"check_$tag"}( $self, @data );
        use strict 'refs';
    }
    else {
        die "CheckEmail->_ask_question() No such method check_$tag $text";
    }
}

sub _is_broken {
    my ($self) = @_;

    foreach my $header ( @{ $self->{_list_of_headers} } ) {
        chomp($header);

        return 1 unless $header =~ m/:/;

        my ( $tag, $data ) = split /:/, $header, 2;
        return 1 if $tag =~ m/[ \t]/;
        return 1 if $tag !~ m/^[a-zA-Z]+/;
    }

    return undef;
}

sub _split_from_file {
    my ( $self, $filename ) = @_;

    my $header = '';
    my $body   = '';

    open( FILE, $filename ) or die "CheckEmail->_split_from_file() Unable to read $filename: $!";
    {
        local $/ = "";
        $header = <FILE>;
        undef $/;
        $body = <FILE>;
    }
    close(FILE);

    my @header_list = split /\n(?!\s)/, $header;

    return ( $body, \@header_list );
}

1;

=head1 NAME

AI::ExpertSystem::Simple::CheckEmail - A wrapper to apply a knowledgebase to an email

=head1 VERSION

This document refers to verion 1.2 of AI::ExpertSystem::Simple::CheckEmail, released February 14th, 2004

=head1 SYNOPSIS

  #!/usr/bin/perl -w

  use strict;
  use warnings;

  use AI::ExpertSystem::Simple::CheckEmail;
  use Getopt::Long;

  my $knowledgebase;
  my $directory;

  GetOptions( 'kb=s' => \$knowledgebase, 'dir=s' => \$directory );

  die "Knowledgebase not defined (--kb <file>)" unless $knowledgebase;
  die "Knowledgebase is not a file" unless -f $knowledgebase;
  die "Knowledgebase is not readable" unless -r $knowledgebase;

  die "Mail directory not defined (--dir <dir>)" unless $directory;
  die "Mail directory is not a directory" unless -d $directory;
  die "Mail directory is not readable" unless -r $directory;

  my $s = AI::ExpertSystem::Simple::CheckEmail->new($knowledgebase);

  opendir(DIR, $directory) or die "Unable to read $directory: $!";
  my @files = readdir(DIR);
  closedir(DIR);

  foreach my $filename (@files) {
    next if $filename =~ m/^\./;

    my $response = $s->process("$directory/$filename");

    print "$filename\t$response\n";
  }
						
=head1 DESCRIPTION

=head2 Overview

Given a knowledgebase this class will apply the rules against the email given to it by the process( ) method
returning the classification set by the knowledgebase or "Headers are broken" if the headers are malformed.

The basic class provides two methods to check an email. The first check_body( VALUE, @DATA ) scans the body of
the email and counts the number of strings in DATA that are found in the body. It will then return 'yes' if the
number of matches is greater than or equal to VALUE, otherwise it will return 'no'.

The other method is check_header( TAG, VALUE, @DATA ) scans all the TAG headers in the email for the number of 
strings in DATA that are found in the selected header. It will then return 'yes' if the number of matches is 
greater than or equal to VALUE, otherwise it will return 'no'.

=head2 Constructors and initialisation

=over 4

=item new( FILENAME )

The constructor takes the name of the file containing the knowledgebase to test and initialises some variables

=back

=head2 Public methods

=over 4

=item process( FILENAME )

Applied the knowledgebase against the email in FILENAME returning a classification or "Headers are broken" if the headers are 
malformed.

=item check_header( TAG, VALUE, @DATA )

A simple method that checks to see if the header TAG contains at least VALUE occurences of the strings in DATA

=item check_body( VALUE, @DATA )

A simple method that checks to see if the body contains at least VALUE occurences of the strings in DATA

=back

=head2 Private methods

=over 4

=item _classify_mail( )

The main classification loop

=item _ask_question( )

Handles the dialog between the expert system and the contents of the email

=item _is_broken( )

Checks to see if the headers are malformed

=item _split_from_file( )

Splits the email into a header and a body and then splits the header into a list.

=back

=head1 ENVIRONMENT

None

=head1 DIAGNOSTICS

=over 4

=item CheckEmail->new() takes one arguments

When the constructor is called it requires one argument. This message is given if more or less arguments were supplied.

=item CheckEmail->new() argument 1 (FILENAME) is undefined

The corrct number of arguments were supplied with the method call, however the first argument, FILENAME, was undefined.

=item CheckEmail->process() takes one arguments

When the method is called it requires one argument. This message is given if more or less arguments were supplied.

=item CheckEmail->process() argument 1 (FILENAME) is undefined

The corrct number of arguments were supplied with the method call, however the first argument, FILENAME, was undefined.

=item CheckEmail->_ask_question() No such method check_TYPE ...

The knowledgebase defined a test call TYPE but there is no method called check_TYPE defined in the class. You should 
subclass to add new methods.

=item CheckEmail->_split_from_file() Unable to read ...

The file containing the email to be read could bot be opened

=back

=head1 BUGS

None

=head1 FILES

See the CheckEmail.t file in the test directory, checkemail in the bin directory and email.xml in the examples directory.

=head1 SEE ALSO

AI::ExpertSystem::Simple - An expert system class

AI::ExpertSystem::Simple::Goal - A utility class

AI::ExpertSystem::Simple::Knowledge - A utility class

AI::ExpertSystem::Simple::Rule - A utility class

=head1 TO DO

Nothing

=head1 AUTHORS

Peter Hickman (peterhi@ntlworld.com)

=head1 COPYRIGHT

Copyright (c) 2004, Peter Hickman. All rights reserved.

This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.
