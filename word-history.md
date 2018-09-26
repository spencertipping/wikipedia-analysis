# Word distribution over time
I'm interested to see whether Wikipedia edits focus on different words at
different points in time. We can use the history source data from
[link-history.md](link-history.md), calculate text diffs, and compute word
counts on those diffs.

## Simple diff algorithm
We need a few things from our diff algorithm:

1. It needs to be fast, particularly when most of the text hasn't changed
2. It needs to identify just the changed text, at a sub-line level
3. Its output should contain both versions of any changed text
4. It should look at whole words, since we're interested in word usage

Here are three revisions from the `Anarchism` article, with changes and
near-changes in bold:

> These divisions are excarbated by a very polemical debate around the names of
> various types of anarchism and related ideas.  For example,
> &quot;anarchism&quot; is variously understood as being either socialist or
> capitalist.  In the United States, &quot;libertarianism&quot; typically does
> not refer to either anarchism or socialism, while in e.g. Latin America it
> refers to both.  Finally, the term &quot;anarchy&quot; is frequently used as a
> perjorative in reference to [[anomy]].

> These divisions are excarbated by a very polemical debate around the names of
> various types of anarchism and related ideas.  For example,
> &quot;anarchism&quot; is variously understood as being either socialist or
> capitalist.  In the United States, &quot;libertarianism&quot; typically does
> not refer to either anarchism or socialism, while in e.g. Latin America it
> refers to both.  Finally, the term &quot;anarchy&quot; is frequently used
> **improperly** as a perjorative in reference to **[[anomie]]**.

> These **visions have created** a very polemical debate around the names of
> various types of anarchism and related ideas.  For example,
> &quot;anarchism&quot; is variously understood as being either socialist or
> capitalist.  In the United States, &quot;libertarianism&quot; typically does
> not refer to either anarchism or socialism, while in e.g. Latin America it
> refers to both. Finally, the term &quot;anarchy&quot; is frequently **used as
> a** perjorative in reference to [[anomie]].

Our diff algorithm should produce something like this:

```pl
# first two revisions
[ { at => index1,                    add => "improperly " },
  { at => index2, remove => "anomy", add => "anomie" } ]

# second and third revisions
[ { at => index1, remove => "divisions are excarbated",
                  add    => "visions have created" },
  { at => index2, remove => "improperly " } ]
```

[Here's the code](diff.pl) I came up with. We can ask `ni` to make this
available to perl mapper code using `pR`.

```sh
$ ni /mnt/v1/data/wikipedia-history-2018.0923 \
     pRdiff.pl \
     SX24 [\$'"7z://{}"' \<] \
          z\>\$'basename("{}") =~ s/\.7z$//r' \
          p'^{$title = $contributor = $time = $text = undef}
            $title       = $1, $text = "", return () if /<title>([^<]+)/;
            $contributor = $1, return () if /<(?:ip|username)>([^<]+)/;
            $time        = $1, return () if /<timestamp>([^<]+)/;
            if (s/^\s*<text[^>]*>//)
            {
              my $newtext = join"", ru {s/<\/text>$//};
              r $title, $contributor, tpe($time =~ /\d+/g),
                diff $text, $newtext;
              $text = $newtext;
            }
            ()'
```