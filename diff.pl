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

sub sync_offset($$$$)
{
  # Find the nearest point where we have a substantial amount of text that
  # aligns between the two strings, then return a pair of ($li, $ri) indicating
  # the location at which we can resume skipping equal text. The implication is
  # that a change has occurred between the input and output $li and $ri.
  use bytes;
  use constant sync_size => 32;

  my $li = shift;
  my $ri = shift;

  my $li_out = $li;
  my $ri_out = -1;
  for (; $li_out < length $_[0] && $ri_out == -1;
         $li_out += sync_size)
  {
    $ri_out = index $_[1], substr($_[0], $li_out, sync_size), $ri;
  }

  # If no part of the left string aligns, then everything from here is a diff;
  # consume the entirety of both arguments.
  return (length $_[0], length $_[1]) if $ri_out == -1;

  # Now $li_out and $ri_out are aligned; rewind any common prefix we've skipped.
  my $l = common_prefix_length substr($_[0], $li_out - sync_size, sync_size),
                               substr($_[1], $ri_out - sync_size, sync_size);
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
      next;
    }

    # If we get here, it means we no longer have a common prefix -- and that
    # means we're looking at a change.
    my ($next_li, $next_ri) = sync_offset $li, $ri, $_[0], $_[1];
    push @diff, { at     => $li,
                  remove => substr($_[0], $li, $next_li - $li),
                  add    => substr($_[1], $ri, $next_ri - $ri) };
    $li = $next_li;
    $ri = $next_ri;
  }

  push @diff, { at => $li, remove => substr $_[0], $li } if $li < length $_[0];
  push @diff, { at => $li, add    => substr $_[1], $ri } if $ri < length $_[1];
  @diff;
}
