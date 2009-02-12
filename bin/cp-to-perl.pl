#!/usr/bin/perl

=pod

Script to copy those files that live also in the core into a perl
source tree.

I use it such that I first make a branch of bleedperl:

    git checkout -b orange93

Then I use cp-to-perl to clobber the branch:

    sudo -u sand perl bin/cp-to-perl.pl /home/src/perl/repoperls/perl5.git.perl.org/perl

Test and then do in git over there

    # edit manifest if necessary
    git add ...
    git commit -m 'Update CPAN.pm to xxx'
    git format-patch origin

=cut

use strict;
use warnings;
use File::Basename qw(dirname);
use File::Copy qw(cp);
use Term::Prompt;

die "missing support for 'Porting/Maintainers.pl' and gabor refactoring";

my $target = shift or die "Usage: $0 targetdirectory";
die "Could not find directory '$target'" unless -d $target;
$target =~ s|/+$||;
# warn "Copying to '$target'\n";

my $MAP;
{
  no warnings 'qw';
  $MAP = {
          "" => ["lib/CPAN/" => [qw(
                                     PAUSE*.pub
                                   )]],
          "lib/" => ["lib/"  => [qw(
                                    lib/CPAN.pm
                                    lib/CPAN/API/HOWTO.pod
                                    lib/CPAN/Debug.pm
                                    lib/CPAN/DeferredCode.pm
                                    lib/CPAN/Distroprefs.pm
                                    lib/CPAN/FirstTime.pm
                                    lib/CPAN/HandleConfig.pm
                                    lib/CPAN/Kwalify.pm
                                    lib/CPAN/Kwalify/distroprefs.dd
                                    lib/CPAN/Kwalify/distroprefs.yml
                                    lib/CPAN/Nox.pm
                                    lib/CPAN/Queue.pm
                                    lib/CPAN/Tarzip.pm
                                    lib/CPAN/Version.pm
                                   )]],
          "scripts/" => ["lib/CPAN/bin/" => [qw(
                                                scripts/cpan
                                               )]],
          "t/" => ["lib/CPAN/t/" => [qw(
                                        t/{01,02,03,10,11}*.t
                                       )]], # loadme, mirroredby, nox, vcmp, version
         };
}

my @command;
while (my($here,$v) = each %$MAP) {
  my($theredir,$files) = @$v;
  for my $file (@$files) {
    my $prefix_length = length($here);
    die "bad file[$file]" unless substr($file,0,$prefix_length) eq $here;
    my @expand_file = glob($file);
    for my $efile (@expand_file) {
      my @c = $efile;
      my $target_file = sprintf "%s/%s%s", $target, $theredir, substr($efile,$prefix_length);
      unless (-d dirname $target_file) {
          push @command, sprintf "mkdir %s", dirname $target_file;
      }
      push @c, $target_file;
      printf "cp %-21s %s\n", @c;
      push @command, \@c;
    }
  }
}

exit unless prompt("y","Proceed?","","y");
for my $c (@command) {
  unlink $c->[1] or warn "Warning: Could not unlink the target $c->[1]: $!";
  cp @$c or die "Alert: Could not cp $c->[0] to $c->[1]: $!";
}

