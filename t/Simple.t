#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 272;

use_ok('AI::ExpertSystem::Simple');

################################################################################
# Create a new expert system
################################################################################

my $x;

eval { $x = AI::ExpertSystem::Simple->new(1); };
like($@, qr/^Simple->new\(\) takes no arguments /, 'Too many arguments');

$x = AI::ExpertSystem::Simple->new();

isa_ok($x, 'AI::ExpertSystem::Simple');

################################################################################
# Load a file
################################################################################

eval { $x->load(); };
like($@, qr/^Simple->load\(\) takes 1 argument /, 'Too few arguments');

eval { $x->load(1,2); };
like($@, qr/^Simple->load\(\) takes 1 argument /, 'Too many arguments');

eval { $x->load(undef); };
like($@, qr/^Simple->load\(\) argument 1 \(FILENAME\) is undefined /, 'Filename is undefined');

eval { $x->load('no_test.xml'); };
like($@, qr/^Simple->load\(\) unable to use file /, 'Cant use this file');

eval { $x->load('t/empty.xml'); };
like($@, qr/^Simple->load\(\) XML parse failed: /, 'Cant use this file');

is($x->load('t/test.xml'), '1', 'File is loaded');

eval { $x->process(1); };
like($@, qr/^Simple->process\(\) takes no arguments /, 'Too many arguments');

is($x->process(), 'question', 'We have a question to answer');

eval { $x->get_question(1); };
like($@, qr/^Simple->get_question\(\) takes no arguments /, 'Too many arguments');

my ($t, $r) = $x->get_question();

eval { $x->answer(); };
like($@, qr/^Simple->answer\(\) takes 1 argument /, 'Too few arguments');

eval { $x->answer(1,2); };
like($@, qr/^Simple->answer\(\) takes 1 argument /, 'Too many arguments');

eval { $x->answer(undef); };
like($@, qr/^Simple->answer\(\) argument 1 \(VALUE\) is undefined /, 'Value is undefined');

$x->answer('yes');

is($x->process(), 'continue', 'Carry on');
is($x->process(), 'finished', 'Thats all folks');

eval { $x->get_answer(1); };
like($@, qr/^Simple->get_answer\(\) takes no arguments /, 'Too many arguments');

is($x->get_answer(), 'You have set the goal to pretzel', 'Got the answer');

$x->explain();
my @log = $x->log();

isnt(scalar @log, 0, 'The log has data');

################################################################################
# Reset and do it all again
################################################################################

eval { $x->reset(1); };
like($@, qr/^Simple->reset\(\) takes no arguments /, 'Too many arguments');

$x->reset();

is($x->process(), 'question', 'We have a question to answer');

($t, $r) = $x->get_question();

$x->answer('yes');

is($x->process(), 'continue', 'Carry on');
is($x->process(), 'finished', 'Thats all folks');

is($x->get_answer(), 'You have set the goal to pretzel', 'Got the answer');

eval { $x->log(1); };
like($@, qr/^Simple->log\(\) takes no arguments /, 'Too many arguments');

@log = $x->log();

isnt(scalar @log, 0, 'The log has data');

@log = $x->log();

is(scalar @log, 0, 'The log is empty');

eval { $x->explain(1); };
like($@, qr/^Simple->explain\(\) takes no arguments /, 'Too many arguments');

$x->explain();
@log = $x->log();

isnt(scalar @log, 0, 'The log has data');

################################################################################
# Lets test the diagnostic methods
################################################################################

is($x->load('t/bigger_test.xml'), '1', 'File is loaded');

eval { $x->diagnostic_outcomes(1); };
like($@, qr/^Simple->diagnostic_outcomes\(\) takes no arguments /, 'Too many arguments');

is( $x->diagnostic_outcomes(), 43, 'Correct number of outcomes' );

eval { $x->diagnostic_outcomes_distinct(1); };
like($@, qr/^Simple->diagnostic_outcomes_distinct\(\) takes no arguments /, 'Too many arguments');

is( $x->diagnostic_outcomes_distinct(), 41, 'Correct number of distinct values' );

eval { $x->diagnostic_rules(1); };
like($@, qr/^Simple->diagnostic_rules\(\) takes no arguments /, 'Too many arguments');

is( $x->diagnostic_rules(), 84, 'Correct number of rules' );

eval { $x->diagnostic_attributes(1); };
like($@, qr/^Simple->diagnostic_attributes\(\) takes no arguments /, 'Too many arguments');

is( $x->diagnostic_attributes(), 55, 'Correct number of attributes' );

eval { $x->diagnostic_questions(1); };
like($@, qr/^Simple->diagnostic_questions\(\) takes no arguments /, 'Too many arguments');

is( $x->diagnostic_questions(), 43, 'Correct number of questions' );

eval { $x->diagnostic_usage(1); };
like($@, qr/^Simple->diagnostic_usage\(\) takes no arguments /, 'Too many arguments');

my %y = $x->diagnostic_usage();
isa_ok(\%y, 'HASH');

is( $y{1}, 'completed', 'Rule is completed' );
is( $y{2}, 'completed', 'Rule is completed' );
foreach my $z ((3..84)) {
	is( $y{$z}, 'unused', 'Rule is unused' );
}

################################################################################
# Testing the expose methods
################################################################################

eval { $x->expose_rules(1); };
like($@, qr/^Simple->expose_rules\(\) takes no arguments /, 'Too many arguments');

%y = $x->expose_rules();
isa_ok(\%y, 'HASH');

foreach my $z (keys %y) { isa_ok($y{$z}, 'AI::ExpertSystem::Simple::Rule'); }

eval { $x->expose_knowledge(1); };
like($@, qr/^Simple->expose_knowledge\(\) takes no arguments /, 'Too many arguments');

%y = $x->expose_knowledge();
isa_ok(\%y, 'HASH');

foreach my $z (keys %y) { isa_ok($y{$z}, 'AI::ExpertSystem::Simple::Knowledge'); }

eval { $x->expose_goal(1); };
like($@, qr/^Simple->expose_goal\(\) takes no arguments /, 'Too many arguments');

my $z = $x->expose_goal();
isa_ok($z, 'AI::ExpertSystem::Simple::Goal');

# vim: syntax=perl:
