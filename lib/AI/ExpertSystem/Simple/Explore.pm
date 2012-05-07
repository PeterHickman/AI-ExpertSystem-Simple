package AI::ExpertSystem::Simple::Explore;

use strict;
use warnings;

use AI::ExpertSystem::Simple;

our $VERSION = '1.2';

sub new {
    my ( $class, $filename ) = @_;

    die "Explore->new() takes 1 argument" if scalar(@_) != 2;
    die "Explore->new() argument 1 (FILENAME) is undefined" if !defined($filename);

    my $self = {};

    $self->{_filename} = $filename;

    # Create the expert system and load the file in

    eval { $self->{_es} = AI::ExpertSystem::Simple->new(); };
    die "Explore->new() unable to create new expert system" if $@;

    eval { $self->{_es}->load($filename); };
    die "Explore->new() unable to load $filename into expert system" if $@;

    # Variables to store data from the script runs

    $self->{_answers}    = ();
    $self->{_unique}     = ();
    $self->{_good}       = 0;
    $self->{_bad}        = 0;
    $self->{_count}      = 0;
    $self->{_usage_good} = ();
    $self->{_usage_bad}  = ();
	$self->{_run}        = 0;
	$self->{_tree}		 = ();

    return bless $self, $class;
}

sub run_scripts {
    my ($self) = @_;

    my @questions;

	$self->{_run} = 1;

    die "Explore->run_scripts() takes no arguments" if scalar(@_) != 1;

    $self->{_es}->reset();

    my $r = $self->{_es}->process();

    if ( $r eq 'question' ) {
        my ( $text, @responses ) = $self->{_es}->get_question();
        foreach my $response (@responses) {
            push ( @questions, [ $text, $response ] );
        }
    }
    else {
        die "Explore->run_scripts() setup question did not occur";
    }

    # Start the process

    foreach my $script (@questions) {
        $self->{_es}->reset();

        $self->{_count}++;

        my $r;

        # Process the script so far

        my @list = @$script;
        while (@list) {
            my $q = shift @list;
            my $a = shift @list;

            $r = $self->{_es}->process();
            if ( $r eq 'question' ) {
                my ( $text, @responses ) = $self->{_es}->get_question();
                die "Explore->run_scripts() got the wrong question" if ( $text ne $q );
                $self->{_es}->answer($a);
            }
            elsif ( $r eq 'continue' ) {
                die "Explore->run_scripts() that should have been a continue" if ( $q ne $r );
            }
            else {
                die "Explore->run_scripts() that should have been a question";
            }
        }

        # Now process the next bit

        eval { $r = $self->{_es}->process(); };
        $r = 'failed' if $@;

        if ( $r eq 'question' ) {
            my ( $text, @responses ) = $self->{_es}->get_question();
            foreach my $response (@responses) {
                push ( @questions, [ @$script, $text, $response ] );
            }
        }
        elsif ( $r eq 'finished' ) {
            $self->{_good}++;
            my %x = $self->{_es}->diagnostic_usage();
            foreach my $rules ( keys %x ) {
                $self->{_usage_good}->{$rules}->{ $x{$rules} }++;
            }
			my @this_script = ( @$script, $self->{_es}->get_answer() );
			$self->_build_tree( \%{$self->{_tree}}, 0, grep { $_ ne 'continue' } @this_script );
            my $text = '[' . join ( '][', @this_script ) . ']';
            $self->{_answers}->{$text} = 1;
            $self->{_unique}->{$self->{_es}->get_answer()}++;
        }
        elsif ( $r eq 'failed' ) {
            $self->{_bad}++;
            my %x = $self->{_es}->diagnostic_usage();
            foreach my $rules ( keys %x ) {
                $self->{_usage_bad}->{$rules}->{ $x{$rules} }++;
            }
			my @this_script = ( @$script, 'failed' );
			$self->_build_tree( \%{$self->{_tree}}, 0, grep { $_ ne 'continue' } @this_script );
            my $text = '[' . join ( '][', @this_script ) . ']';
            $self->{_answers}->{$text} = 1;
        }
        elsif ( $r eq 'continue' ) {
            push ( @questions, [ @$script, 'continue', 'continue' ] );
        }
    }

	$self->{_run} = 2;
}

sub report_scripts {
    my ($self) = @_;

    die "Explore->report_scripts() takes no arguments" if scalar(@_) != 1;
	die "Explore->report_scripts() run_scripts has not been run" if($self->{_run} == 0);
	die "Explore->report_scripts() run_scripts failed at some point" if($self->{_run} == 1);

    my $text = '';

    $text .= '<h1>The Knowledgebase contains</h1>';
    $text .= '<table border="1">';
    $text .= '<tr><td>Rules</td><td>' . $self->{_es}->diagnostic_rules() . '</td></tr>';
    $text .= '<tr><td>Attributes</td><td>' . $self->{_es}->diagnostic_attributes() . '</td></tr>';
    $text .= '<tr><td>Questions</td><td>' . $self->{_es}->diagnostic_questions() . '</td></tr>';
    $text .= '<tr><td>Rules setting goal</td><td>' . $self->{_es}->diagnostic_outcomes() . '</td></tr>';
    $text .= '<tr><td>Distinct goal values</td><td>' . $self->{_es}->diagnostic_outcomes_distinct() . '</td></tr>';
    $text .= '</table>';

    $text .= '<h1>The test scripts</h1>';
    $text .= '<table border="1">';
    $text .= '<tr><td>Scripts run</td><td>' . $self->{_count} . '</td></tr>';
    $text .= '<tr><td>Results found</td><td>' . ($self->{_good} + $self->{_bad}) . '</td></tr>';
    $text .= '<tr><td>Good results</td><td>' . $self->{_good} . '</td></tr>';
    $text .= '<tr><td>Bad results</td><td>' . $self->{_bad} . '</td></tr>';
    $text .= '<tr><td>Unique answers</td><td>' . scalar(keys %{$self->{_unique}}) . '</td></tr>';
    $text .= '</table>';

    return $text;
}

sub report_usage_good {
    my ($self) = @_;

    die "Explore->report_usage_good() takes no arguments" if scalar(@_) != 1;

    return $self->_report_usage( 'Usage pattern for successful outcomes', %{ $self->{_usage_good} } );
}

sub report_usage_bad {
    my ($self) = @_;

    die "Explore->report_usage_bad() takes no arguments" if scalar(@_) != 1;

    return $self->_report_usage( 'Usage pattern for failed outcomes', %{ $self->{_usage_bad} } );
}

sub report_usage_total {
    my ($self) = @_;

    die "Explore->report_usage_total() takes no arguments" if scalar(@_) != 1;

    return $self->_report_usage( 'Usage pattern for all outcomes', $self->_merge_hashes( $self->{_usage_good}, %{ $self->{_usage_bad} } ));
}

sub report_answers {
	my ($self) = @_;

    die "Explore->report_answers() takes no arguments" if scalar(@_) != 1;

	my $text = '';

	$text .= '<h1>Occurences of unique answers</h1>';
	$text .= '<table border="1">';
	$text .= '<tr><th>Answer</th><th>Occurs</th></tr>';
	foreach my $answer (sort keys %{$self->{_unique}}) {
		$text .= '<tr>';
		$text .= "<td>$answer</td>";
		$text .= '<td>' . $self->{_unique}->{$answer} . '</td>';
		$text .= '</tr>';
	}
	$text .= '</table>';

	return $text;
}

sub report_tree {
	my ($self) = @_;

    die "Explore->report_tree() takes no arguments" if scalar(@_) != 1;

	my $text = '<h1>The script tree</h1>';
	$text .= $self->_walk_tree(\%{$self->{_tree}});

	return $text;
}

sub report_attributes {
	my ($self) = @_;

    die "Explore->report_attributes() takes no arguments" if scalar(@_) != 1;

	my %summary;
	my %detailed;

	my %rules = $self->{_es}->expose_rules();

	foreach my $rule (keys %rules) {
		my %conditions = $rules{$rule}->conditions();

		foreach my $condition (keys %conditions) {
			$summary{$condition}->{c}++;
			$summary{$condition}->{r}->{$conditions{$condition}}++;

			$detailed{$condition}->{$conditions{$condition}}->{c}->{$rule}++;
		}

		my %actions = $rules{$rule}->actions();

		foreach my $action (keys %actions) {
			$summary{$action}->{a}++;
			$summary{$action}->{r}->{$actions{$action}}++;

			$detailed{$action}->{$actions{$action}}->{a}->{$rule}++;
		}
	}

	my $goal = $self->{_es}->expose_goal();

	$summary{$goal->name()}->{g}++;

	my %knowledge = $self->{_es}->expose_knowledge();

	foreach my $item (keys %knowledge) {
		if($knowledge{$item}->diagnostic_has_question()) {
			$summary{$item}->{q}++;
			my ($question, @responses) = $knowledge{$item}->get_question();
			foreach my $x (@responses) {
				$summary{$item}->{r}->{$x}++;

				$detailed{$item}->{$x}->{q}++;
			}
		}
	}

	my $text = '<h1>Summary of Attribute usage</h1><table border="1">';
	$text .= '<tr><th>attribute</th><th>goal</th><th>condition</th><th>action</th><th>question</th><th>responses</th><th>status</th></tr>';

	foreach my $key (sort keys %summary) {
		$text .= "<tr><td valign=\"top\">$key</td>";
		my @list;
		foreach my $x (qw/g c a q/) {
			$text .= '<td align="right" valign="top">' . ($summary{$key}->{$x} || '-') . '</td>';
			push(@list, $summary{$key}->{$x});
		}
		$text .= '<td valign="top">' . join('<br />', (sort keys %{$summary{$key}->{r}})) . '</td>';
		$text .= '<td valign="top">' . $self->_validate( @list ) . '</td>';
		$text .= '</tr>';
	}

	$text .= '</table>';

	$text .= '<h1>Detail of Attribute usage</h1><table border="1">';
	$text .= '<tr><th>attribute</th><th>value</th><th>usage</th><th>data</th></tr>';

	foreach my $attribute (sort keys %detailed) {
		foreach my $value (sort keys %{$detailed{$attribute}}) {
			$text .= "<tr><td valign=\"top\" rowspan=\"3\">$attribute</td>";
			$text .= "<td valign=\"top\" rowspan=\"3\">$value</td>";
			$text .= "<td valign=\"top\">rule condition</td>";
			$text .= "<td valign=\"top\">" . join('<br />', sort keys %{$detailed{$attribute}->{$value}->{c}}) . "</td>";
			$text .= '</tr>';

			$text .= "<tr><td valign=\"top\">rule action</td>";
			$text .= "<td valign=\"top\">" . join('<br />', sort keys %{$detailed{$attribute}->{$value}->{a}}) . "</td>";
			$text .= '</tr>';

			$text .= "<tr><td valign=\"top\">question</td>";
			$text .= "<td valign=\"top\">" . ($detailed{$attribute}->{$value}->{a} ? 'Yes' : 'No') . "</td>";
			$text .= '</tr>';
		}
	}

	$text .= '</table>';

	return $text;
}

sub _validate {
	my ($self, $g, $c, $a, $q) = @_;

	my @errors;

	if($g and $c) {
		push(@errors, 'The goal attribute should not be used in a condition');
	}

	if($g and not $a) {
		push(@errors, 'The goal needs to be set by some actions');
	}

	if($g and $q) {
		push(@errors, 'The goal should not be set from a question' );
	}

	if($c and not ($a or $q)) {
		push(@errors, 'Conditions need to be set from actions or questions');
	}

	if(@errors) {
		return '<font color="red">' . join('<br />', @errors) . '</font>';
	} else {
		return '<font color="green">OK</font>';
	}
}

sub _report_usage {
    my ( $self, $title, %usage ) = @_;

    my $text = '';

    $text .= "<h1>$title</h1>";
    $text .= '<table border="1">';

    $text .= '<tr><th>' . join('</th><th>', ( 'rule', 'unused', 'active', 'completed', 'invalid' ) ) . '</th></tr>';

	my $counter = 0;

    foreach my $rule ( sort keys %usage ) {
        $text .= "<tr><td>$rule</td>";

		$counter++;

        foreach my $key ( 'unused', 'active', 'completed', 'invalid' ) {
			$text .= '<td>';
            $text .= $usage{$rule}->{$key} || 0;
			$text .= '</td>';
        }
        $text .= '</tr>';
    }

	unless($counter) {
		$text .= '<tr><td colspan="5"><b>*There are no results for this report*</td><tr>';
	}

    $text .= '</table>';

    return $text;
}

sub _merge_hashes {
    my ( $self, $hash1, %hash2 ) = @_;

    my %result = %$hash1;

    foreach my $key ( keys %hash2 ) {
        foreach my $subkey ( keys %{ $hash2{$key} } ) {
            if ( $result{$key}->{$subkey} ) {
                $result{$key}->{$subkey} += $hash2{$key}->{$subkey};
            }
            else {
                $result{$key}->{$subkey} = $hash2{$key}->{$subkey};
            }
        }
    }

    return %result;
}

sub _build_tree {
	my ($self, $hashref, $type, @list) = @_;

	my $item = shift @list;

	if(scalar(@list) == 0) {
		$hashref->{"T:$item"} = 1;
	} else {
		my $flag = ($type == 0 ? 'Q' : 'A');
		$self->_build_tree(\%{$hashref->{"$flag:$item"}}, ($type == 0 ? 1 : 0), @list);
	}
}

sub _walk_tree {
	my ($self, $tree ) = @_;

	my $result = '';

	foreach my $child (sort keys %$tree) {
		my ($flag, $text) = split(':', $child, 2);

		   if($flag eq 'Q') { $result .= "<b>$text</b><ol>"; }
		elsif($flag eq 'A') { $result .= "<li><i>$text</i><br />"; }
		else {
			if($text eq 'failed') {
				$result .= '<font color="red">FAILED</font>';
			} else {
				$result .= '<font color="green">' . $text . '</font>';
			}
		}

		if(ref($tree->{$child}) eq 'HASH') {
			$result .= $self->_walk_tree( \%{$tree->{$child}} );
		}

		   if($flag eq 'Q') { $result .= '</ol>'; }
		elsif($flag eq 'A') { $result .= '</li>'; }
	}

	return $result;
}

1;

=head1 NAME

AI::ExpertSystem::Simple::Explore - A simple expert system shell

=head1 VERSION

This document refers to verion 1.2 of AI::ExpertSystem::Simple::Explore, released June 10, 2003

=head1 SYNOPSIS

This class is used to exercise a knowledge base by simulating all possible user responses and 
building up statistics for a variety of reports.

=head1 DESCRIPTION

=head2 Overview

Given a knowledgebase this class will allow you to test all possible responses and creates
a set of HTML based reports of the information that it finds. It uses a brute force approach
and can take some time on badly designed knowledgebases.

=head2 Constructors and initialisation

=over 4

=item new( FILENAME )

The constructor takes the name of the file containing the knowledgebase to test and initialises some variables

=back

=head2 Public methods

=over 4

=item run_scripts( )

Runs all possible scripts against the knowledgebase to build up the various statistics that are reported below

=item report_scripts( )

Reports the basic information about the scripts that were run including the number of rules, attributes and questions that 
were defined in the knowledge base, how many rules set the goal and how many distinct goal values are set.

It also reports the number of scripts that were run, how many results were found and how many were good (elicited an answer
from the knowledgebase) or bad (the knowledgebase was unable to provide an answer) along with the number of unique answers
that were produced.

=item report_usage_good( )

Reports all the rules and their states that produced 'good' outcomes (as defined above). The four column count the total 
number of times a rule fell into a category.

=over 4

=item unused

The number of times a rule took no part in the consultation

=item active

The number of times a rule completed some, but not all of its conditions. This rule did not run it's action part

=item completed

The number of times a rule completed all of it's conditions and then ran it's action part

=item invalid

The number of times a rule dropped out of a consultation because it's conditions were incorrect

=back

=item report_usage_bad( )

The same report as above except for the 'bad' outcomes

=item report_usage_total( )

The same report again for both the good and bad outcomes

=item report_answers( )

Lists all the answers generated by the scripts and the number of times each occured

=item report_tree( )

Displays all the scripts in tree form as question response pairs all the way down to the success for failure nodes

=item report_attributes( )

Report the usage of the various attributes

=back

=head2 Private methods

=over 4

=item _report_usage( TITLE, HASH )

A generic method used by the public report_usage_* methods to format the data

=item _merge_hashes( HASHREF, HASH )

Merges two multilevel hashes togenther

=item _build_tree( ARRAY )

Takes a script and creates a tree from it, each script adds more branches to the tree

=item _walk_tree( )

Walks the tree built by _build_tree and formats the output to be reported by report_tree

=item _validate( SCALAR, SCALAR, SCALAR, SCALAR )

Validates the use of an attribute according to how it is used

=back

=head1 ENVIRONMENT

None

=head1 DIAGNOSTICS

=over 4

=item Explore->new() takes 1 argument

When the method is called it requires one argument.  This message is given if more or less arguments were supplied.
					   
=item Explore->new() argument 1 (FILENAME) is undefined

The corrct number of arguments were supplied with the method call, however the first argument, FILENAME, was undefined.
								
=item Explore->new() unable to create new expert system

Unable to initialise the AI::ExpertSystem::Simple object

=item Explore->new() unable to load ... into expert system

After creating the AI::ExpertSystem::Simple object it was then unable to load the knowledgebase given by the 
filename into it

=item Explore->run_scripts() takes no arguments

When the constructor is initialised it requires no arguments. This message is given if some arguments were supplied.

=item Explore->run_scripts() setup question did not occur

A question was expected, but did not occur. This is a CAN NOT HAPPEN type of error

=item Explore->run_scripts() got the wrong question

A question was expected, but the a dirrerent one was presented. This is a CAN NOT HAPPEN type of error

=item Explore->run_scripts() that should have been a continue

A continue was expected but something else happened. This is a CAN NOT HAPPEN type of error

=item Explore->run_scripts() that should have been a question

A question was expected but something else happened. This is a CAN NOT HAPPEN type of error

=item Explore->report_scripts() takes no arguments

When the constructor is initialised it requires no arguments. This message is given if some arguments were supplied.

=item Explore->report_scripts() run_scripts has not been run

You cannot report what you have not run

=item Explore->report_scripts() run_scripts failed at some point

Somehow the scripts did not complete, you cannot run the reports

=item Explore->report_usage_good() takes no arguments

When the constructor is initialised it requires no arguments. This message is given if some arguments were supplied.

=item Explore->report_usage_bad() takes no arguments

When the constructor is initialised it requires no arguments. This message is given if some arguments were supplied.

=item Explore->report_usage_total() takes no arguments

When the constructor is initialised it requires no arguments. This message is given if some arguments were supplied.

=item Explore->report_answers() takes no arguments

When the constructor is initialised it requires no arguments. This message is given if some arguments were supplied.

=item Explore->report_tree() takes no arguments

When the constructor is initialised it requires no arguments. This message is given if some arguments were supplied.

=back

=head1 BUGS

None

=head1 FILES

See the Explore.t file in the test directory and checkkb in the bin directory.

=head1 SEE ALSO

AI::ExpertSystem::Simple - An expert system class

AI::ExpertSystem::Simple::Goal - A utility class

AI::ExpertSystem::Simple::Knowledge - A utility class

AI::ExpertSystem::Simple::Rule - A utility class

=head1 TO DO

Speeding up the script engine

Report attribute value settings

Static reporting of the knowledge base

Report the state of the attibutes at the point of success or failure

Smarten up the reports

=head1 AUTHORS

Peter Hickman (peterhi@ntlworld.com)

=head1 COPYRIGHT

Copyright (c) 2003, Peter Hickman. All rights reserved.

This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.
