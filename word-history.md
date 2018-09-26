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
available to perl mapper code using `pR`:

```sh
$ ni pRdiff.pl \
     1p'r je $_ for diff
        q{ These divisions are excarbated by a very polemical debate around the names of various types of anarchism and related ideas.  For example, &quot;anarchism&quot; is variously understood as being either socialist or capitalist.  In the United States, &quot;libertarianism&quot; typically does not refer to either anarchism or socialism, while in e.g. Latin America it refers to both.  Finally, the term &quot;anarchy&quot; is frequently used as a perjorative in reference to [[anomy]]. },
        q{ These divisions are excarbated by a very polemical debate around the names of various types of anarchism and related ideas.  For example, &quot;anarchism&quot; is variously understood as being either socialist or capitalist.  In the United States, &quot;libertarianism&quot; typically does not refer to either anarchism or socialism, while in e.g. Latin America it refers to both.  Finally, the term &quot;anarchy&quot; is frequently used improperly as a perjorative in reference to [[anomie]]. }
       '
{"add":"improperly ","at":440,"remove":""}
{"add":"anomie","at":475,"remove":"anomy"}
```

One last check before we run the full dataset: are revisions stored in semantic
order? We can figure this out by looking at the series of timestamps within each
page.

```sh
$ ni /mnt/v1/data/wikipedia-history-2018.0923 p'"7z://$_"' \<\< \
     p'return () unless /<page/;
       r "out of order" if
         grep $_ < 0,
         deltas map tpe(/\d+/g), map /<timestamp>([^<]+)/, ru {/<\/page>/}; ()'
```

Nothing yet; I think we're in good shape. A command to iterate on the diff
locally:

```sh
$ ni pRdiff.pl \
     sr3[/mnt/v1/data/wikipedia-history-2018.0923 p'"7z://$_"' \<r1\< \
         p'^{$title = $contributor = $time = $text = undef}
            $title       = $1, $text = "", return () if /<title>([^<]+)/;
            $contributor = $1, return () if /<(?:ip|username)>([^<]+)/;
            $time        = $1, return () if /<timestamp>([^<]+)/;
            if (s/^\s*<text[^>]*>//)
            {
              (my $newtext = join"", ru {/<\/text>/}) =~ s/<\/text>.*//;
              r $title, $contributor, tpe($time =~ /\d+/g),
                je [diff $text, $newtext];
              $text = $newtext;
            }
            ()']

```

The final command:

```sh
$ ni /mnt/v1/data/wikipedia-history-2018.0923 \
     pRdiff.pl \
     SX24 [\$'"7z://{}"' \<] \
          z\>\$'"diffs/" . basename("{}") =~ s/\.7z$//r' \
          p'^{$title = $contributor = $time = $text = undef}
            $title       = $1, $text = "", return () if /<title>([^<]+)/;
            $contributor = $1, return () if /<(?:ip|username)>([^<]+)/;
            $time        = $1, return () if /<timestamp>([^<]+)/;
            if (s/^\s*<text[^>]*>//)
            {
              (my $newtext = join"", ru {/<\/text>/}) =~ s/<\/text>.*//;
              r $title, $contributor, tpe($time =~ /\d+/g),
                je [diff $text, $newtext];
              $text = $newtext;
            }
            ()'
```
