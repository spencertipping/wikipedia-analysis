# Edit timing analysis
In the [link history writeup](link-history.md) I noted that the edit rate
appears to have a yearly cycle. Let's see what else we can find.

## Edit metadata table
Anything involving the article body is going to be large, so let's bulk-generate
a separate table storing just a few fields: `title contributor timestamp`. We
can use the `link-history` dataset as a starting point; this will be faster than
reprocessing the original XML.

```sh
$ ni link-history \<S24fABC z4\>edit-metadata
```

## Month of year + hour of day

