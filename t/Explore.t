#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;

use_ok('AI::ExpertSystem::Simple::Explore');

################################################################################
# Create a new expert system
################################################################################

my $x;

eval { $x = AI::ExpertSystem::Simple::Explore->new(); };
like( $@, qr/^Explore->new\(\) takes 1 argument /, 'Too few arguments' );

eval { $x = AI::ExpertSystem::Simple::Explore->new( 1, 2 ); };
like( $@, qr/^Explore->new\(\) takes 1 argument /, 'Too many arguments' );

eval { $x = AI::ExpertSystem::Simple::Explore->new(undef); };
like( $@, qr/^Explore->new\(\) argument 1 \(FILENAME\) is undefined /, 'Filename is undefined' );

eval { $x = AI::ExpertSystem::Simple::Explore->new('t/empty.xml'); };
like( $@, qr/^Explore->new\(\) unable to load /, 'Invalid knowledgebase' );

$x = AI::ExpertSystem::Simple::Explore->new('t/test.xml');

isa_ok( $x, 'AI::ExpertSystem::Simple::Explore' );

################################################################################
# Run the scripts
################################################################################

eval { $x->report_scripts(); };
like( $@, qr/^Explore->report_scripts\(\) run_scripts has not been run /, 'Reports cannot be run yet' );

eval { $x->run_scripts(1); };
like( $@, qr/^Explore->run_scripts\(\) takes no arguments /, 'Too many arguments' );

$x->run_scripts();

eval { $x->report_scripts(1); };
like( $@, qr/^Explore->report_scripts\(\) takes no arguments /, 'Too many arguments' );
isnt( $x->report_scripts(), '', 'There was some output' );

eval { $x->report_usage_good(1); };
like( $@, qr/^Explore->report_usage_good\(\) takes no arguments /, 'Too many arguments' );
isnt( $x->report_usage_good(), '', 'There was some output' );

eval { $x->report_usage_bad(1); };
like( $@, qr/^Explore->report_usage_bad\(\) takes no arguments /, 'Too many arguments' );
isnt( $x->report_usage_bad(), '', 'There was some output' );

eval { $x->report_usage_total(1); };
like( $@, qr/^Explore->report_usage_total\(\) takes no arguments /, 'Too many arguments' );
isnt( $x->report_usage_total(), '', 'There was some output' );

eval { $x->report_answers(1); };
like( $@, qr/^Explore->report_answers\(\) takes no arguments /, 'Too many arguments' );
isnt( $x->report_answers(), '', 'There was some output' );

eval { $x->report_tree(1); };
like( $@, qr/^Explore->report_tree\(\) takes no arguments /, 'Too many arguments' );
isnt( $x->report_tree(), '', 'There was some output' );

eval { $x->report_attributes(1); };
like( $@, qr/^Explore->report_attributes\(\) takes no arguments /, 'Too many arguments' );
isnt( $x->report_attributes(), '', 'There was some output' );

################################################################################
# Unable to create test for these errors
################################################################################

# Explore->new() unable to create new expert system
#
# Explore->run_scripts() setup question did not occur
# Explore->run_scripts() got the wrong question
# Explore->run_scripts() that should have been a continue
# Explore->run_scripts() that should have been a question
#
# Explore->report_scripts() run_scripts has not been run
# Explore->report_scripts() run_scripts failed at some point

# vim: syntax=perl:
