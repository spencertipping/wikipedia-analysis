# Word distribution over time
I'm interested to see whether Wikipedia edits focus on different words at
different points in time. We can use the history source data from
[link-history.md](link-history.md), calculate word counts, and then calculate
differences.

I don't have a strong opinion about which words we include or exclude; I think
the goal is to tokenize word-level entities that correspond to topics a person
might discuss. Then we can make a histogram of those results.

## Wikipedia tokenization strategies
Let's take a look at an article to see what we're up against. I want something
long enough to have the full range of pathologies, which in this case happens
early in a revision of `Anarchism`:

```sh
$ ni sr3[/mnt/v1/data/wikipedia-history-2018.0923 p'"7z://$_"' \<\< \
         p'r ru {s/<\/text>//} if s/<text[^>]*>//; ()' \
         rp'length() > 10000' r1pF_] \
     \>text/anarchism
```

Here are the first few paragraphs, line-wrapped for readability:

```
''Anarchism'' is the political theory that advocates the abolition of all forms
of government. The word anarchism derives from Greek roots &lt;i&gt;an&lt;/i&gt;
(no) and &lt;i&gt;archos&lt;/i&gt; (ruler).

Different groups have radically different understandings of what the abolition
of governments would entail: &quot;[[libertarian socialism|Libertarian
socialists]]&quot; are convinced it means a collectivist economy;
&quot;[[anarcho-capitalism|anarcho-capitalists]]&quot; are convinced it means
capitalism; &quot;[[individualist anarchism|individualist anarchists]]&quot;
don't know or don't care as much about such issues, but insist above all on
individual freedom from state.

These divisions are excarbated by a very polemical debate around the names of
various types of anarchism and related ideas.  For example,
&quot;anarchism&quot; is variously understood as being either socialist or
capitalist.  In the United States, &quot;libertarianism&quot; typically does not
refer to either anarchism or socialism, while in e.g. Latin America it refers to
both.  Finally, the term &quot;anarchy&quot; is frequently used as a perjorative
in reference to [[anomy]].

=== [[Libertarian socialism]] ===

This theory of anarchism calls for a system of socialism, notably with
collective ownership of means of production, without the need for any government
authority or [[coercion]].
```

...and here are the last few lines:

```
* [http://recollectionbooks.com/bleed/gallery/galleryindex.htm Anarchist Encyclopedia] list several hundred anarchists, with relevant resource links
* [http://recollectionbooks.com/bleed/indexTimeline.htm Anarchist Timeline] lists about 1500 dates with events &amp; resource links
Web sites with a clear [[anarcho-capitalism|anarcho-capitalist]] bent:
* Bryan Caplan's [http://www.gmu.edu/departments/economics/bcaplan/anarfaq.htm Anarchism Theory FAQ]
* David Hart's [http://www.arts.adelaide.edu.au/personal/DHart/ClassicalLiberalism/Molinari/ToC.html Gustave De Molinari And The Anti-Statist Liberal Tradition]
See also: [[nihilism]], [[syndicalism]], [[libertarianism]]
----
[[talk:Anarchism|/Talk]] &lt;br&gt;
[[Anarchism/Todo|/Todo]] &lt;br&gt;
[[talk:Anarchy]] [http://www.wikipedia.com/wiki.cgi?action=history&amp;id=Anarchy Anarchy History] (The content of Anarchy and Anarchism have since been merged into this version)
```

There are a few different strategies we can use to tokenize:

1. Text as displayed: ignore all link destinations and other semantic
   information
2. Text and link destinations, each tagged differently
3. Text, link destinations, and external site domains

In other words, are we trying to extract _words_ or _entities?_ I think I want
to start with just words to keep it simple, but I want to revisit entity
extraction down the line.

...so let's start with displayed words and external domains. I've got
Wikipedia-focused links covered [in this writeup](link-history.md), so let's
drop those links entirely.

## Extracting visible words
[Here's the Wikipedia syntax
cheatsheet](https://en.wikipedia.org/wiki/Help:Cheatsheet), which I assume
covers everything we need to think about.

There are a few cases we need to parse through:

```
[[link]]                                # drop these
<!-- comment -->                        # drop these
<s>stuff</s>                            # drop HTML tags
<ref name='x' />                        # drop this entirely
{{template}}                            # drop templates
http://site.com/...                     # include the domain
[http://site.com/...]                   # include the domain
```

The text is XML-encoded, meaning that we'll have escaped entities. Here's a look
at the first million:

```sh
$ ni sr3[/mnt/v1/data/wikipedia-history-2018.0923 p'"7z://$_"' \<\< \
         p'r ru {s/<\/text>//} if s/<text[^>]*>//; ()' \
         p'/&([^;]+);/g' rE6gcO]

662206  quot
242716  amp
47539   lt
47539   gt
```

Awesome: we can ignore all of these except `&lt;` and `&gt;`, which are used to
encode HTML tags and comments.

## The monster regex approach
We can use Perl's `\G` anchor to parse text piecewise. I'm preserving case for
now because although beginning-of-sentence is a false capitalization, knowing
that a word was in lowercase is meaningful, e.g. the difference between `Bill`
(a name) and `bill` (a noun or verb).

```sh
$ ni sr3[/mnt/v1/data/wikipedia-history-2018.0923 p'"7z://$_"' \<\< \
         p'r ru {s/<\/text>.*//} if s/.*<text[^>]*>//; ()' \
         p'pos($_) = 0;
                    /\Ghttps?:\/\/([^\/]+)\/\S*/gc || /\G(\w+)/gc
           ? r $1 : /\G\s+/gc || /\G&lt;.*?&gt;/gc
                              || /\G&[^;]+;/gc
                              || /\G<.*?>/gc
                              || /\G\[\[[^]]*\]\]/gc
                              || /\G\{\{[^}]*\}\}/gc
                              || /\G\[[^[]/gc
                              || /\G\]/gc
                              || /\G#REDIRECT.*/gc
                              || /\G\W+/gc
           ? 1    : /\G(.)/gc && r "unparsed:$1"
           while pos($_) < length' rE5gcO]

4165    of
3341    the
3070    and
1881    in
1734    to
1539    as
1400    is
1373    a
1339    that
988     anarchism
953     by
895     on
807     anarchist
798     libertarian
790     socialists
...
24      n
24      ispp.org
24      fascist
24      fascism
24      factions
24      exists
24      es
24      dwardmac.pitzer.edu
24      del
24      controlled
24      cnt
24      civil
24      cities
24      Zapata
24      Trabajo
24      Spain
...
8       Russian
8       Revolution
8       PeterKropotkin
8       Mexico
8       Mexican
8       Makhnovists
8       Madero
8       Liberty
...
```

I'm going to put the regex code into its own function in `tokenize.pl` so we can
store the words in a frequency hash. A quick test run:

```sh
$ ni pRtokenize.pl \
     sr3[/mnt/v1/data/wikipedia-history-2018.0923 p'"7z://$_"' \<\<] \
     p'^{$title = $contributor = $time = undef; $last_freqs = {}}
       $title       = $1, $last_freqs = {}, return () if /<title>([^<]+)/;
       $contributor = $1, return () if /<(?:ip|username)>([^<]+)/;
       $time        = $1, return () if /<timestamp>([^<]+)/;
       if (s/^\s*<text[^>]*>//)
       {
         my $new_freqs = freqs tokenize join"", ru {/<\/text>/};
         my %diffs     = %$new_freqs;
         $diffs{$_} -= $$last_freqs{$_} for keys %$last_freqs;
         r $title, $contributor, tpe($time =~ /\d+/g),
           map +($_ => $diffs{$_}), grep $diffs{$_}, sort keys %diffs;
         $last_freqs = $new_freqs;
       }
       ()' r20

AccessibleComputing	RoseParks	980046742	AccessibleSoftware	1	AccessibleWeb	1	AssistiveTechnology	1	LegalIssuesInAccessibleComputing	1	This	1	covers	1	subject	1
AccessibleComputing	Conversion script	1014655392	AccessibleSoftware	-1	AccessibleWeb	-1	AssistiveTechnology	-1	LegalIssuesInAccessibleComputing	-1	This	-1	covers	-1	subject	-1
AccessibleComputing	Ams80	1051309119
AccessibleComputing	Ams80	1051309119
AccessibleComputing	Ams80	1051309119
AccessibleComputing	Ams80	1051309119
AccessibleComputing	Ams80	1051309119
AccessibleComputing	OlEnglish	1282862317
AccessibleComputing	Godsy	1487986229
AccessibleComputing	Ø§ÙÛØ± Ø§Ø¹ÙØ§ÙÛ	1522787883
AccessibleComputing	Godsy	1534229245
Anarchism	The Cunctator	1002831528	1814	1	1819	1	1840s	1	1854	1	1866	1	1873	1	1876	1	1910	1	1912	2	1939	1	1950s	1	1958	1	1992	1	19th	1	20th	1	Adherents	2	All	1	Anarchism	5	Anarchist	4	Anarchists	1	Anarcho	7	Anarchy	4	And	1	Anomy	1	Anti	1	ArchivesWeb	1	Bakunin	2	Benjamin	1	Beyond	1	Both	1	Brian	1	Britannica	1	Bryan	1	CNT	1	Caplan	1	Civil	1	ClassicalLiberalism	1	Cleyre	1	Confederaci	1	Crabtree	1	DHart	1	David	1	De	1	Different	1	During	1	Encyclopaedia	1	External	1	FAQ	1	Famous	1	Few	1	Fights	1	For	1	Greek	1	Gustave	3	Hart	1	Here	1	Historical	1	History	3	However	3	Individualist	2	Kropotkin	1	Liberal	1	Libertarian	6	Like	2	Links	1	Lysander	1	Many	1	Michael	1	Molinari	4	Most	2	Movements	1	National	1	On	2	One	1	Proponents	1	Proudhon	1	Rocker	1	Rudolph	1	See	2	Spain	1	Spanish	2	Spooner	1	Statist	1	Talk	1	The	8	Theory	1	There	1	They	1	This	2	ToC	1	Todo	1	Trabajo	1	Tradition	1	Tucker	1	USA	2	Voltairine	1	War	1	Web	1	Whigs	1	a	15	abolition	3	about	2	above	2	absence	2	absolute	1	accept	1	accepts	1	acknowledged	1	action	2	activities	1	actually	3	adelaide	1	adhere	1	advocate	1	advocates	1	against	3	age	1	all	6	also	2	although	2	american	1	among	1	an	7	anarchism	11	anarchist	5	anarchists	11	anarcho	12	anarchy	1	anarfaq	1	and	37	anomy	2	anti	2	any	5	anyone	1	approaches	1	archos	2	are	8	argue	2	arts	1	as	18	association	1	at	3	au	1	authority	1	back	2	based	3	bcaplan	1	be	5	because	1	been	4	believe	3	bent	2	best	1	between	2	beyond	1	bombing	1	both	2	brand	1	broke	1	businesses	1	but	4	by	7	call	3	called	2	calls	2	can	3	capable	1	capitalism	12	capitalists	12	care	2	categories	1	centuries	2	century	2	cgi	1	chaos	1	choose	2	cities	1	civil	1	claim	1	classical	3	clear	3	cnt	1	coercion	2	coherent	1	collective	1	collectivism	3	collectivist	2	com	1	common	1	communists	2	completely	1	comprised	1	connotations	1	consenting	1	consider	5	consisted	1	constitutes	1	content	1	contests	1	control	1	controlled	1	convinced	2	countercultural	1	criticizes	1	current	1	de	5	debate	1	defender	1	del	1	denote	1	departments	1	derives	1	different	1	differently	1	disagree	1	discussion	1	disorder	2	distinguish	1	do	1	doesn	1	don	3	done	1	due	1	during	1	dwardmac.pitzer.edu	1	e	2	each	5	early	2	economic	1	economics	1	economy	2	edu	2	eighteenth	1	elaborate	1	elements	1	embraced	1	emphasis	1	employee	2	employees	1	employer	3	enforcing	1	english	1	entail	1	es	1	essential	2	etc	1	even	2	exist	1	existed	1	existence	1	exists	1	experience	1	explicit	1	external	1	factions	1	facto	2	factories	1	famous	2	fascism	1	fascist	1	fighting	1	first	1	flourishing	1	for	7	forces	1	form	3	forms	1	freedom	2	from	6	future	1	g	2	general	2	give	1	gmu	1	government	11	governments	4	great	1	groups	4	hand	1	has	7	hate	1	have	4	he	1	him	1	historically	1	history	1	hostility	1	how	1	htm	1	html	1	id	1	ideology	1	if	1	ignorance	1	immediately	1	impose	2	in	15	including	1	indeed	1	individual	5	individualism	2	individualist	4	individuals	1	insist	2	into	1	is	16	ispp.org	1	issue	1	issues	2	it	8	its	2	just	1	justice	1	justifying	1	kind	1	know	1	known	2	late	1	law	2	least	1	left	4	legitimizes	1	length	1	let	1	liberals	3	libertarian	10	libertarianism	2	liberty	2	like	1	little	1	loathe	2	long	1	macho	1	made	1	majoritarily	1	many	1	market	1	matter	1	matters	1	meaning	1	means	3	members	1	mere	1	merged	1	modern	2	monarchists	1	more	4	most	2	mostly	1	movement	1	much	4	murder	1	must	1	mutually	1	n	1	natural	1	necessary	1	need	1	negative	1	nihilism	1	nineteenth	1	no	1	normal	1	not	5	notably	2	notion	1	now	1	of	48	older	2	on	7	only	1	opponents	1	opposes	1	opposition	2	oppressed	1	oppressive	1	or	9	order	2	orderly	1	organized	1	other	3	out	2	ownership	1	part	1	passively	1	past	1	people	1	personal	1	political	3	popular	1	popularly	1	position	2	possible	1	power	2	precisely	1	presence	1	prevail	1	prevented	1	preventing	1	principles	1	private	1	production	1	profitable	1	promote	1	promotes	1	put	1	question	1	quot	3	radical	1	radically	1	rather	1	refer	1	reference	1	regarding	1	regulation	1	reject	1	rejected	1	relationship	2	replace	1	reply	1	republicans	1	respected	1	revolution	2	revolutions	1	right	1	rights	1	roots	2	ruler	1	s	3	scholars	1	see	2	selection	1	seventeenth	1	several	2	share	1	sharing	1	should	2	shows	1	side	1	since	3	sites	2	slur	1	small	1	socialism	8	socialists	10	society	1	some	2	sometimes	1	source	1	state	2	states	1	statist	1	still	1	strong	1	such	4	suits	1	support	1	supported	1	syndicalism	1	system	3	t	4	tend	2	territory	1	than	2	that	14	the	39	their	5	theirs	1	them	3	themselves	6	theories	1	theorist	1	theory	4	these	2	they	8	think	1	thinkers	2	this	6	though	1	throughout	1	thus	1	time	2	to	17	together	1	trace	1	traces	1	tradition	3	traditions	2	true	1	trying	1	ttp	4	two	1	understandings	1	usage	1	use	1	used	1	various	2	vehemently	1	version	1	view	2	views	3	violence	2	violent	4	voluntary	1	vs	3	war	2	way	1	weakness	1	website	1	well	1	were	1	what	4	whereas	1	which	3	while	2	wiki	1	wikipedia	1	will	2	willing	1	with	6	without	4	word	4	works	1	would	2	wrong	1	www	4	www.spunk.org	1
Anarchism	Ffaker	1006957946	1828	1	19	1	1910	1	Chomsky	1	Christian	1	Leo	1	Noam	1	Novelist	1	Tolstoy	1	anarchist	1	and	1	present	1	thinker	1
Anarchism	216.39.146.xxx	1007309293	Anarchist	2	Archives	1	ArchivesWeb	-1	Encyclopedia	1	Timeline	1	Web	1	recollectionbooks.com	2
Anarchism	216.39.146.xxx	1007310304	1500	1	1842	1	1921	1	Anarchism	-1	Anarchy	-3	Bakunin	1	History	-1	Kroptkin	1	Peter	1	The	-1	Web	-1	about	1	action	-1	advance	1	an	1	anarchist	2	anarchists	1	anarcho	1	and	-1	as	1	been	-1	cgi	-1	collectivism	1	com	-1	communism	1	content	-1	credited	1	dates	1	events	1	figure	1	first	1	have	-1	history	-1	hundred	1	id	-1	important	1	in	1	into	-1	links	1	linksWeb	1	list	1	lists	1	merged	-1	movement	1	on	1	recollectionbooks.com	2	relevant	1	resource	2	s	1	several	1	since	-1	syndicalist	1	theorist	1	this	-1	ttp	-1	version	-1	wiki	-1	wikipedia	-1	with	2	www	-1
Anarchism	Conversion script	1014652823	Anarchism	2	Anarchy	3	History	1	The	1	Todo	-1	action	1	and	1	been	1	cgi	1	com	1	content	1	have	1	history	1	id	1	into	1	merged	1	of	1	since	1	talk	1	this	1	ttp	1	version	1	wiki	1	wikipedia	1	www	1
Anarchism	140.232.153.45	1014655392	20th	-1	America	1	Anarchist	1	Anarcho	1	European	1	Few	-1	Finally	1	For	1	In	3	International	1	Karl	1	Late	1	Latin	1	Major	1	Many	1	Marxists	1	Most	-1	Others	1	President	1	Similarly	1	Socialists	1	States	1	Their	1	These	1	This	2	Tolstoian	1	United	1	While	1	a	6	actually	-1	advocate	1	advocated	1	advocates	1	ages	1	although	-1	among	3	an	1	anarchism	4	anarchist	3	anarchy	1	and	4	any	-1	anyone	-1	are	1	around	2	as	5	assinated	1	back	-1	began	3	being	1	believe	1	between	1	bombing	-1	both	1	but	-1	by	4	can	-2	capitalism	1	capitalist	1	centuries	-1	century	1	clear	-1	climate	1	cohesive	1	communists	1	consensus	2	cooperative	1	cooperativism	1	critical	1	criticisms	1	debate	1	deed	1	divisions	1	does	1	e	1	early	-1	economy	1	education	1	eighteenth	-1	either	2	element	1	employ	1	era	2	escalated	1	especially	1	etc	-1	example	1	excarbated	1	exceptions	1	exist	-1	experiments	1	fact	1	famous	-1	few	1	focus	1	frequently	1	future	-1	g	1	give	-1	historians	1	how	-1	ideas	1	immediately	-1	impression	1	in	8	included	1	institutions	1	insurrections	1	into	1	is	5	its	-1	justice	-1	justified	1	justifying	-1	kind	-1	labor	3	lasting	2	late	-1	left	-1	legitimacy	1	legitimizes	-1	libertarian	3	libertarianism	1	living	1	long	1	many	1	met	1	middle	1	minority	1	movements	1	murder	-1	names	1	near	1	no	3	non	1	not	-2	of	14	often	1	on	3	oppression	1	or	1	organizing	1	other	1	others	2	out	1	perjorative	1	polemical	1	position	-1	prevalent	1	propaganda	1	public	1	quot	3	reaction	1	refer	1	referred	1	refers	1	regarding	-1	related	1	revolution	-1	revolved	1	roots	1	see	1	significant	1	similar	1	social	1	socialism	1	socialist	1	socialists	3	some	2	split	1	strikes	1	structures	1	struggles	1	such	1	syndicalists	1	tactic	1	term	1	that	4	the	12	there	3	they	2	this	1	those	1	though	-1	throughout	-1	thrown	1	to	8	trace	1	traces	-1	type	1	types	1	typically	1	understood	1	unions	3	until	1	use	1	used	1	utility	1	various	1	variously	1	very	1	violence	2	violent	-2	was	4	were	2	what	1	which	3	while	1	with	1	without	-1	writings	1
Anarchism	24.188.31.147	1014834850	An	1	Anarchism	1	Anarchist	1	FAQ	1	Provides	1	information	1	of	1	on	1	social	1	the	1	theory	1	useful	1	www.anarchistfaq.org	1
Anarchism	24.188.31.147	1014835002	Anarchist	1	Infoshop	1	an	1	and	1	information	1	is	1	links	1	linksWeb	-1	newswire	1	org	1	serviceWeb	1	www.infoshop.org	1
```

Looks great; let's run it at scale.

```sh
$ ni /mnt/v1/data/wikipedia-history-2018.0923 \
     pRtokenize.pl \
     SX24 [\$'"7z://{}"' \<] \
          z\>\$'"word-history/" . basename("{}") =~ s/\.7z$//r' \
          p'^{$title = $contributor = $time = undef; $last_freqs = {}}
            $title       = $1, $last_freqs = {}, return () if /<title>([^<]+)/;
            $contributor = $1, return () if /<(?:ip|username)>([^<]+)/;
            $time        = $1, return () if /<timestamp>([^<]+)/;
            if (s/^\s*<text[^>]*>//)
            {
              my $new_freqs = freqs tokenize join"", ru {/<\/text>/};
              my %diffs     = %$new_freqs;
              $diffs{$_} -= $$last_freqs{$_} for keys %$last_freqs;
              r $title, $contributor, tpe($time =~ /\d+/g),
                map +($_ => $diffs{$_}), grep $diffs{$_}, sort keys %diffs;
              $last_freqs = $new_freqs;
            }
            ()'
```
