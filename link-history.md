# Page/page links over time
I want to see if it's possible to visualize this somehow. The first step is to
start with the history and build a series of link-list snapshots. We should get
a format like `page contributor timestamp link1 link2 ...`.

If we want a series of revisions from the article, we can sequentially parse
pairs of `<timestamp>` and `<text>` nodes, tracking state in a series of
variables. I just added [the SX
operator](https://github.com/spencertipping/ni/commit/f573d9bb6d33d9a190c5a5d93677086a4e1bb678)
to simplify this a bit.

```sh
$ ni /mnt/v1/data/wikipedia-history-2018.0923 \
     SX24 [\$'"7z://{}"' \<] \
          z\>\$'"link-history/" . basename("{}") =~ s/\.7z$//r' \
          p'^{$title = $contributor = $time = undef}
            $title       = $1, return () if /<title>([^<]+)/;
            $contributor = $1, return () if /<(?:ip|username)>([^<]+)/;
            $time        = $1, return () if /<timestamp>([^<]+)/;
            r $title, $contributor, tpe($time =~ /\d+/g),
              map /\[\[([^]\|]+)/g, ru {/<\/text>/} if /<text/; ()'
```

## Let's visualize this
I'm not completely sure where to start, so let's kick this off by taking a look
at articles ordered by the maximum number of outbound links in their history.
Maybe we'll find something interesting in the trends.

```sh
$ ni link-history \<S24[p'r a, FM' p'r a, max b_ rea'] gp'r a, max b_ rea' \
     z\>article-max-links
```
