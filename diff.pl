package ni::pl;

use strict;
use warnings;
no warnings 'substr';

use constant sync_size => 12;

sub common_prefix_length($$)
{
  use bytes;
  my ($x) = ($_[0] ^ $_[1]) =~ /^(\0*)/;
  length $x;
}

sub common_suffix_length($$)
{
  use bytes;
  my $min = min length $_[0], length $_[1];
  my ($x) = (substr($_[0], -$min + length $_[0])
           ^ substr($_[1], -$min + length $_[1])) =~ /(\0*)$/;
  length $x;
}

sub sync_offset
{
  # Find the nearest point where we have a substantial amount of text that
  # aligns between the two strings, then return a pair of ($li, $ri) indicating
  # the location at which we can resume skipping equal text. The implication is
  # that a change has occurred between the input and output $li and $ri.
  use bytes;
  use constant none => [];

  my $li   = shift;
  my $ri   = shift;
  my $lidx = shift;
  my $ridx = shift;

  my $min_l1 = length $_[0];
  my $min_l2 = length $_[0];
  my $min_r1 = length $_[1];
  my $min_r2 = length $_[1];
  for my $k (grep exists $$ridx{$_}, keys %$lidx)
  {
    ($min_l1) = (grep($_ >  $li && $_ < $min_l1, @{$$lidx{$k}}), $min_l1);
    ($min_l2) = (grep($_ >= $li && $_ < $min_l2, @{$$lidx{$k}}), $min_l2);
    ($min_r1) = (grep($_ >= $ri && $_ < $min_r1, @{$$ridx{$k}}), $min_r1);
    ($min_r2) = (grep($_ >  $ri && $_ < $min_r2, @{$$ridx{$k}}), $min_r2);
  }

  # Now remove up to sync_size from the right ends of the sync point.
  my ($lo, $ro) = $min_l1 + $min_r1 < $min_l2 + $min_r2
                ? ($min_l1, $min_r1)
                : ($min_l2, $min_r2);
  my $l = common_suffix_length substr($_[0], $lo - sync_size, sync_size),
                               substr($_[1], $ro - sync_size, sync_size);
  ($lo - $l, $ro - $l);
}

sub diff_index($)
{
  # Create a substring index we can use to rapidly locate text within a string.
  my %index;
  push @{$index{substr $_[0], $_, sync_size} //= []}, $_
    for 1 .. length($_[0]) - sync_size;
  \%index;
}

sub diff($$)
{
  my @diff;
  my ($li, $ri) = (0, 0);
  my $lidx = diff_index $_[0];
  my $ridx = diff_index $_[1];

  while ($li < length $_[0] && $ri < length $_[1])
  {
    my $l = common_prefix_length substr($_[0], $li, 256),
                                 substr($_[1], $ri, 256);
    if ($l)
    {
      $li += $l;
      $ri += $l;
    }
    else
    {
      # At this point we have a change between $li and $next_li. Because the
      # text outside this region is shared between the two strings, we can just
      # look at the left string to expand to word boundaries.
      my ($next_li, $next_ri) = sync_offset $li, $ri, $lidx, $ridx, $_[0], $_[1];
      my ($left_word)  = (substr($_[0], $li - 15,     16) =~ /(\w*)\w$/, "");
      my ($right_word) = (substr($_[0], $next_li - 1, 16) =~ /^\w(\w*)/, "");

      $li      -= length $left_word;
      $ri      -= length $left_word;
      $next_li += length $right_word;
      $next_ri += length $right_word;

      push @diff, { at     => $li,
                    remove => substr($_[0], $li, $next_li - $li),
                    add    => substr($_[1], $ri, $next_ri - $ri) };
      $li = $next_li;
      $ri = $next_ri;
    }
  }

  push @diff, { at => $li, add => '', remove => substr $_[0], $li } if $li < length $_[0];
  push @diff, { at => $li, remove => '', add => substr $_[1], $ri } if $ri < length $_[1];
  @diff;
}
