# Page/page links over time
I want to see if it's possible to visualize this somehow. The first step is to
start with the history and build a series of link-list snapshots. We should get
a format like `page contributor timestamp link1 link2 ...`.

The first order of business is to download all of the history files. I'm going
to use 7zip here because those files are _much_ smaller -- like 1/10th of the
bzip2's. This makes sense given 7z's long lookback window.

```sh
$ ni https://dumps.wikimedia.org/enwiki/latest/ \
     p'/href="([^"]+\.7z)"/g' \
     p'"https://dumps.wikimedia.org/enwiki/latest/$_"' \
  | xargs wget -c
```

Now we can use 7z accessors to read the stream; for example:

```sh
$ ni 7z://enwiki-latest-pages-meta-history1.xml-p10p2101.7z \<r10
<mediawiki xmlns="http://www.mediawiki.org/xml/export-0.10/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.mediawiki.org/xml/export-0.10/ http://www.mediawiki.org/xml/export-0.10.xsd" version="0.10" xml:lang="en">
  <siteinfo>
    <sitename>Wikipedia</sitename>
    <dbname>enwiki</dbname>
    <base>https://en.wikipedia.org/wiki/Main_Page</base>
    <generator>MediaWiki 1.32.0-wmf.19</generator>
    <case>first-letter</case>
    <namespaces>
      <namespace key="-2" case="first-letter">Media</namespace>
      <namespace key="-1" case="first-letter">Special</namespace>
```

We end up with a series of `<page>` elements, each with revisions:

```sh
$ ni . p'"7z://$_"' \<\<rp'/<page/../<\/page>/'
  <page>
    <title>AccessibleComputing</title>
    <ns>0</ns>
    <id>10</id>
    <redirect title="Computer accessibility" />
    <revision>
      <id>233192</id>
      <timestamp>2001-01-21T02:12:21Z</timestamp>
      <contributor>
        <username>RoseParks</username>
        <id>99</id>
      </contributor>
      <comment>*</comment>
      <model>wikitext</model>
      <format>text/x-wiki</format>
      <text xml:space="preserve">This subject covers

* AssistiveTechnology

* AccessibleSoftware

* AccessibleWeb

* LegalIssuesInAccessibleComputing

</text>
      <sha1>8kul9tlwjm9oxgvqzbwuegt9b2830vw</sha1>
    </revision>
    <revision>
      <id>862220</id>
      <parentid>233192</parentid>
      <timestamp>2002-02-25T15:43:11Z</timestamp>
      <contributor>
        <username>Conversion script</username>
        <id>0</id>
      </contributor>
      <minor />
      <comment>Automated conversion</comment>
      <model>wikitext</model>
      <format>text/x-wiki</format>
      <text xml:space="preserve">#REDIRECT [[Accessible Computing]]
</text>
      <sha1>i8pwco22fwt12yp12x29wc065ded2bh</sha1>
    </revision>
...
```

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
