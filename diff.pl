# perl mappers run in this namespace
package ni::pl;

use strict;
use warnings;

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

sub sync_offset($$$$)
{
  # Find the nearest point where we have a substantial amount of text that
  # aligns between the two strings, then return a pair of ($li, $ri) indicating
  # the location at which we can resume skipping equal text. The implication is
  # that a change has occurred between the input and output $li and $ri.
  use bytes;
  use constant sync_size => 16;

  my $li = shift;
  my $ri = shift;

  # Search in both directions at once, exiting when either is successful.
  my ($li_out1, $ri_out1) = ($li - sync_size, -1);
  my ($li_out2, $ri_out2) = (-1, $ri - sync_size);
  while ($li_out1 + sync_size      < length $_[0] && $ri_out1 == -1
           && $ri_out2 + sync_size < length $_[1] && $li_out2 == -1)
  {
    $ri_out1 = index $_[1], substr($_[0], $li_out1 += sync_size, sync_size), $ri;
    $li_out2 = index $_[0], substr($_[1], $ri_out2 += sync_size, sync_size), $li;
  }

  # If no part of the strings align, then everything from here is a diff;
  # consume the entirety of both arguments.
  ($li_out1, $ri_out1) = (length $_[0], length $_[1]) if $ri_out1 == -1;
  ($li_out2, $ri_out2) = (length $_[0], length $_[1]) if $li_out2 == -1;

  # See which direction yielded smaller deltas. We measure this as the total
  # amount of skipped stuff.
  my $skip1 = ($li_out1 - $li) + ($ri_out1 - $ri);
  my $skip2 = ($li_out2 - $li) + ($ri_out2 - $ri);
  my $li_out = $skip1 < $skip2 ? $li_out1 : $li_out2;
  my $ri_out = $skip1 < $skip2 ? $ri_out1 : $ri_out2;

  # Now $li_out and $ri_out are aligned; rewind any common text we've skipped.
  my $l = common_suffix_length
    substr($_[0], max($li, $li_out - sync_size), sync_size),
    substr($_[1], max($ri, $ri_out - sync_size), sync_size);
  ($li_out - $l, $ri_out - $l);
}

sub diff($$)
{
  my @diff;
  my ($li, $ri) = (0, 0);
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
      my ($next_li, $next_ri) = sync_offset $li, $ri, $_[0], $_[1];
      my ($left_word)  = (substr($_[0], $li - 15,     16) =~ /\w(\w*)$/, "");
      my ($right_word) = (substr($_[0], $next_li - 1, 16) =~ /^(\w*)\w/, "");

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
  push @diff, { at => $li, add => substr $_[1], $ri, remove => '' } if $ri < length $_[1];
  @diff;
}
