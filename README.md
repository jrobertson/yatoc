# Introducing the Yatoc gem


    require 'yatoc'
    require 'kramdown'

    s2=<<EOF
    # Story 1345

    The story of this is not important. Learn more from the text below.

    ## Foo

    This is 1st paragraph

    ### Train

    Work at something

    ### Travel By Bike

    Travel by bike.

    ## Bar

    This is 2nd paragraph

    ### Mary

    Mary had a little lamb

    #### Time

    Take time to rest

    ### Weakness

    Your weakness is my weakness

    --------------
    EOF


    y = Yatoc.new(Kramdown::Document.new(s2).to_html)
    #File.write '/tmp/foo.html', y.to_html
    #puts Rexle.new(y.to_toc).xml pretty: true
    puts y.to_html

## Output

<h1 id="story-1345">Story 1345</h1>

<p>The story of this is not important. Learn more from the text below.</p>

<div id='toc' class='toc'>
<ul><li><a href='#foo'><span>1</span> Foo</a>
<ul>
  <li><a href='#train'><span>1.1</span> Train</a>
  <li><a href='#travel-by-bike'><span>1.2</span> Travel By Bike</a></li>
</ul></li>
<li><a href='#bar'><span>2</span> Bar</a>
<ul>
  <li><a href='#mary'><span>2.1</span> Mary</a>
<ul>
    <li><a href='#time'><span>2.1.1</span> Time</a></li>
</ul></li>
  <li><a href='#weakness'><span>2.2</span> Weakness</a></li>
</ul></li></ul>
</div>

<h2 id="foo">Foo</h2>

<p>This is 1st paragraph</p>

<h3 id="train">Train</h3>

<p>Work at something</p>

<h3 id="travel-by-bike">Travel By Bike</h3>

<p>Travel by bike.</p>

<h2 id="bar">Bar</h2>

<p>This is 2nd paragraph</p>

<h3 id="mary">Mary</h3>

<p>Mary had a little lamb</p>

<h4 id="time">Time</h4>

<p>Take time to rest</p>

<h3 id="weakness">Weakness</h3>

<p>Your weakness is my weakness</p>

<hr />


## Resources

* yatoc https://rubygems.org/gems/yatoc

html toc yatoc gem
