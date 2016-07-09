#!/usr/bin/env perl
use strict;
use warnings;
use v5.10.1;
use Data::Dumper;

# Find all perl files
my @files = glob("*.pl *.pm *.cgi");

unless (@files) { die "There are no .pl, .pm, or .cgi files in this dircetory."}

# Insure we have a t/ test directory
unless (-d "./t") {
  # Create it
  say "Creating t/ test directory.";
  mkdir "./t" or die "Failed to create test directory: $1";
}

foreach my $file (@files) {
  my $shortname = $file;
  $shortname =~ s{\.[^.]+$}{};

  # Create a strict/warnings syntax test for each file
  unless (-e "./t/$shortname-syntax.t") {
    open(my $test, ">", "./t/$shortname-syntax.t") or
      die "Couldn't create ./t/$shortname-syntax.t";
      print $test <<"EOF";
use Test::Strict tests => 3;                      # last test to print

syntax_ok( '$file' );
strict_ok( '$file' );
warnings_ok( '$file' );
EOF
    close($test);
  }

  # Get the list of %config variables used by this module
  # Get a list of global variables used ("our" vars at top of files)
  # or defined (our definitions).
  say "Working on $file";
  my %globals;
  my %config;
  my %in;
  open my $fh, "<", $file;
  while (<$fh>) {
    if (m/^our (?<global>.+);/) {
      my @is_list;
      if ($+{global} =~ m/^\((?<is_list>.+)\)/){
        foreach my $key (split /, /, $+{is_list}) {
          $globals{$key}++;
        }
        next; # We found a (list, of, vars), split, added, and now next iteration.
      }
      $globals{$+{global}}++;
    }
    # Collect all config variables referenced
    m/\$config\{'(?<config>.+?)'\}/ && $config{$+{config}}++;
    # Collect %in variables referenced
    m/\$in\{'(?<in>.+?)'\}/ && $in{$+{in}}++;
  }

  unless (-e "t/$shortname.t") {
    # Spit them into comments in a new test file
    open my $test, ">", "t/$shortname.t";
    print $test <<"EOF";
use strict;
use warnings;
use v5.10.1;

EOF
    if (scalar keys %globals) {
      print $test "# Global variables pulled from web-lib and module lib\n";
      foreach my $key (keys %globals) {
        print $test "my $key;\n";
      }
    }
    if (scalar keys %config) {
      print $test "# Config variables\n";
      print $test "my %config;\n";
      foreach my $key (keys %config) {
        # Dummy values, need to change during test construction
        print $test "\$config{'$key'} = 0;\n"
      }
    }
    if (scalar keys %in) {
      print $test "# Input values (query string or posted values)\n";
      print $test 'my %in\n';
      foreach my $key (keys %in) {
        # Dummy values, change'em when writing tests
        print $test "\$in{'$key'} = 0;\n"
      }
    }
  }
  close $fh;
}
