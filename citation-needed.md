# Which concepts require citations?
Put differently, what do people tend to add to Wikipedia without citing it
properly? Let's collect all sentences that are followed by the `{{cn}}` or
`{{Citation needed...}}` markers to find out.

First let's take a quick look at the context of CN tags:

```sh
$ ni sr3[/mnt/v1/data/wikipedia-history-2018.0923 p'"7z://$_"' \<\< \
         rp's/\{\{cn\}\}.*// || s/\{\{Citation needed.*//' \
         p'no warnings "substr"; substr $_, length() - 78' ur20]

begin to bunch together. As the saying goes, &quot;strength in numbers&quot;. 
 by groups like the [[WOMBLES]] through their participation in [[Euromayday]].
cosystem]] of a plant have control over all its outputs, including pollutants.
, he, following Warren, advocated the use of money denominated in labor hours.
Tarsus]] reintroduced [[Pharisee]]ic [[Judaism]] via [[dialectical]] legalism,
, he, following Warren, advocated the use of money denominated in labor hours.
Tarsus]] reintroduced [[Pharisee]]ic [[Judaism]] via [[dialectical]] legalism,
, he, following Warren, advocated the use of money denominated in labor hours.
Tarsus]] reintroduced [[Pharisee]]ic [[Judaism]] via [[dialectical]] legalism,
, he, following Warren, advocated the use of money denominated in labor hours.
 Sharp Press (2001) p.6&lt;/ref&gt; This includes rejection of [[wage labour]]
Tarsus]] reintroduced [[Pharisee]]ic [[Judaism]] via [[dialectical]] legalism,
, he, following Warren, advocated the use of money denominated in labor hours.
 Sharp Press (2001) p.6&lt;/ref&gt; This includes rejection of [[wage labour]]
Tarsus]] reintroduced [[Pharisee]]ic [[Judaism]] via [[dialectical]] legalism,
, he, following Warren, advocated the use of money denominated in labor hours.
 Sharp Press (2001) p.6&lt;/ref&gt; This includes rejection of [[wage labour]]
Tarsus]] reintroduced [[Pharisee]]ic [[Judaism]] via [[dialectical]] legalism,
be.&quot;&lt;/ref&gt;. Anarcho-capitalists, like all individualist anarchists,
deas, after his participation in a failed [[Richard Owen|Owenite]] experiment.
```

More repetitive than I was hoping for, but also informative: CN tags follow all
sorts of constructs and phrases, and the sentences in which they appear can be
preceded by varying forms of punctuation.

## CN tag diffs: newly flagged content
Let's do this in the simplest way possible. Sentence boundaries should be one of
two things: a capitalized letter at the beginning of a line, or a capitalized
letter after `.` followed by some whitespace. Here's how well that theory holds
up:

```sh
$ ni sr3[/mnt/v1/data/wikipedia-history-2018.0923 p'"7z://$_"' \<\< \
         p'^{$title = $contributor = $time = undef; %uncited = ()}
           $title       = $1, %uncited = (), return () if /<title>([^<]+)/;
           $contributor = $1, return () if /<(?:ip|username)>([^<]+)/;
           $time        = $1, return () if /<timestamp>([^<]+)/;
           if (s/^\s*<text[^>]*>//)
           {
             my @cn = map /(?:^|\.\s+)
                           ([[:upper:]][^\.]+
                            (?:\{\{cn\}\}|\{\{Citation needed))/xg,
                          grep /\{\{cn\}\}/ || /Citation needed/,
                          ru {/<\/text>/};
             my @new = grep !$uncited{$_}, @cn if @cn;
             %uncited = map +($_ => 1), @cn;
             r $title, $contributor, tpe($time =~ /\d+/g), @new if @new;
           }
           ()' ur20]

Anarchism       Jacob Haller    1185362188      Some of them feel that the teachings of the [[Nazarene]]s and other early groups of followers were corrupted  by contemporary religious views - most notably when [[Paul of Tarsus]] reintroduced [[Pharisee]]ic [[Judaism]] via [[dialectical]] legalism,{{cn}}
Anarchism       VoluntarySlave  1185667243      Anarcho-capitalists, like all individualist anarchists,{{cn}}
Anarchism       Operation Spooner       1186075397      Several market-oriented anarchist philosophies, including agorism{{cn}} (derived from anarcho-capitalism), mutualism{{cn}}
Anarchism       Jacob Haller    1187831732      To these anarchists the economic preferences are considered to be of &quot;secondary importance&quot; to abolishing all authority,{{cn}}
Anarchism       Jacob Haller    1187900900      The [[Confédération Générale du Travail]] (General Confederation of Labour, CGT), formed in France in 1895, was the first major anarcho-syndicalist movement,{{cn}}
Anarchism       Jacob Haller    1187924518      By the early 1880s, most of the European anarchist movement had adopted an [[anarcho-communist]] position,{{cn}}
Anarchism       Skomorokh       1191515462      Today there is disagreement between primitivists and followers of more traditional forms of anarchism, such as the [[social ecology]] of [[Murray Bookchin]] and [[class struggle]] anarchism,{{cn}}
Anarchism       Fifelfoo        1304384992      Friedman |publisher=Journal of Legal Studies |month=March | year=1979 |accessdate=2008-07-02}}&lt;/ref&gt; the [[Province of Pennsylvania]],{{cn}}
Anarchism       Fifelfoo        1304385184      Friedman |publisher=Journal of Legal Studies |month=March | year=1979 |accessdate=2008-07-02 |page=unknown page referenced}}&lt;/ref&gt; the [[Province of Pennsylvania]],{{cn}}
Autism          Twiceuponatime  1282206261      The number of people diagnosed with autism has increased dramatically since the 1980s (from &lt;1 to &gt;5 per 1,000){{cn}}
Albedo          GianniG46       1286493877      The shape of these crowns trap radiant energy more effectively{{cn}}
Abraham         Lincoln JimWae  1304629307      That March,{{cn}}
Abraham Lincoln Lhb1239         1309572900      Nancy Hanks was the illegitimate daughter of Lucy Hanks{{cn}}
Academy Award for Best Production Design        Lugnuts 1346396741      The category's orignal name was '''Best Art Direction''' and was changed to its current name for the 85th Academy Awards,{{cn}}
Ayn Rand        CABlankenship   1233037891      She recognized an intellectual kinship with [[John Locke]] in political philosophy{{cn}}, agreeing with Locke's ideas that individuals have a right to the products of their own labor and have [[natural rights]] to life, liberty, and property{{cn}} Unlike Locke, she found the basis for individual rights in man's nature as a being whose survival depends upon his independent exercise of reason{{cn}}
Ayn Rand        Skomorokh       1237795468      The most famous{{cn}}
Ayn Rand        Medeis  1351793461      Since Rand's death, interest in her work has gradually{{cn}}
Ayn Rand        NazariyKaminski 1382720222      Rand was born Alisa Zinov'yevna Rosenbaum ({{lang-ru|Алиса Зиновьевна Розенбаум}}) on February 2, 1905, to a [[Russian Jew]]ish [[Bourgeoisie|bourgeois]]{{cn}}
Algeria Doug Weller     1262976917      Between 1830 and 1847 50,000 French people emigrated to Algeria,&lt;ref&gt;'France - Republic, Monarchy, and Empire' By Keith Randell&lt;/ref&gt; but the conquest was slow because of intense resistance from such people as [[Emir Abdelkader]], [[Cheikh Mokrani]]{{cn}}, [[Cheikh Bouamama]], the tribe of [[Ouled Sid Cheikh]], whose relationships with the French vacillated from cooperation to resistence,{{cn}}
Topics of note in Atlas Shrugged        SummerWithMorons        1350118268      Because of the holistic nature of anthropological research,{{cn}}
```

That looks pretty good. I'm not sure how much of the text itself we'll be able
to use, but this is a decent starting point.

I should point out that the contributor is the person _flagging_ the content,
but probably not the one originating it. If we want to find out which users
submit CN content, we'll have to make a separate pass and resolve the text to
specific edits.

## Full run
```sh
$ ni /mnt/v1/data/wikipedia-history-2018.0923 \
     SX24 [\$'"7z://{}"' \<] \
          z\>\$'"citation-needed/" . basename"{}" =~ s/\.7z$//r' \
          p'^{$title = $contributor = $time = undef; %uncited = ()}
            $title       = $1, %uncited = (), return () if /<title>([^<]+)/;
            $contributor = $1, return () if /<(?:ip|username)>([^<]+)/;
            $time        = $1, return () if /<timestamp>([^<]+)/;
            if (s/^\s*<text[^>]*>//)
            {
              my @cn = map /(?:^|\.\s+)
                            ([[:upper:]][^\.]+
                             (?:\{\{cn\}\}|\{\{Citation needed))/xg,
                           grep /\{\{cn\}\}/ || /Citation needed/,
                           ru {/<\/text>/};
              my @new = grep !$uncited{$_}, @cn if @cn;
              %uncited = map +($_ => 1), @cn;
              r $title, $contributor, tpe($time =~ /\d+/g), @new if @new;
            }
            ()'
```
