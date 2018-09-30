# Downloading all page view analytics
Wikipedia provides
[pagecounts-ez](https://dumps.wikimedia.org/other/pagecounts-ez/), which
contains hourly page views per article compressed on a monthly basis. Let's grab
the non-`totals` files:

```sh
$ ni https://dumps.wikimedia.org/other/pagecounts-ez/merged/ \
     p'/href="(.*\.bz2)"/g' rp'!/totals\./' \
     p'"https://dumps.wikimedia.org/other/pagecounts-ez/merged/$_"' \
     e[xargs wget -c]
```

These are all bz2's, so let's recompress as something more sensible. A quick
comparison for 100MB worth of the first one:

```sh
$ ni pagecounts-2011-12-views-ge-5.bz2 e[head -c104857600] zb9e'wc -c'
25345768            # this is what we have now

$ ni pagecounts-2011-12-views-ge-5.bz2 e[head -c104857600] z9e'wc -c'
34497242

$ ni pagecounts-2011-12-views-ge-5.bz2 e[head -c104857600] zx9e'wc -c'
26787824
```

Huh, ok let's leave these as bzip2s.
