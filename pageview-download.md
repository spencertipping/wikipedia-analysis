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
