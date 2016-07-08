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
  say $shortname;
  say $file;

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
    my %config;
    m/\$config\{'(?<config>.+?)'\}/ && $config{$+{config}}++;
    # Collect %in variables referenced
    my %in;
    m/\$in\{'(?<in>.+?)'\}/ && $in{$+{in}}++;
    #
  }
  close $fh;
  say Dumper(keys %globals);

  #foreach my $global (keys %globalsall) {
  #  # Split out parenthesized list of vars
  #my @is_list;
  #  if ($global =~ m/^\((?<is_list>.+)\)/) {
  #    say "In is_list";
  #    push (@is_list, (split /, /, $+{is_list}));
  #    delete $globalsall($_);
  #  }
  #  print Dumper(@is_list);
  #}
}
# Create mocks for globals vars

# Get the list of functions in this module, and generate a stub test file for
# each one, if one doesn't already exist.
