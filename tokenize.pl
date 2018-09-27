package ni::pl;
use strict;
use warnings;

sub tokenize($)
{
  local $_ = shift;
  my @r;
  pos($_) = 0;
  /\Ghttps?:\/\/([^\/]+)\/\S*/gc || /\G(\w+)/gc
  ? push @r, $1
  : /\G\s+/gc || /\G&lt;.*?&gt;/gc
              || /\G&[^;]+;/gc
              || /\G<.*?>/gc
              || /\G\[\[[^]]*\]\]/gc
              || /\G\{\{[^}]*\}\}/gc
              || /\G\[[^[]/gc
              || /\G\]/gc
              || /\G#REDIRECT.*/gc
              || /\G\W+/gc
  ? 1
  : /\G(.)/gc && r "unparsed:$1"
  while pos() < length;
  @r;
}
