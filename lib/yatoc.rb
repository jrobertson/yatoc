#!/usr/bin/env ruby

# file: yatoc.rb

# description: Yet Another Table Of Contents HTML generator

require 'pxindex'
require 'line-tree'


class Yatoc
  using ColouredText

  attr_reader :to_html, :to_toc, :to_index
  
  def initialize(html, min_sections: 3, numbered: nil, debug: false)
    
    @numbered, @debug, @html = numbered, debug, html

    @to_html = if html =~ /<index[^>]+>/ then

      @numbered ||= false
      html2 = gen_index(html)
      puts 'html2: ' + html2.inspect
      "%s\n\n<div class='main'>%s</div>" % [html2, html.sub(/<index[^>]+>/, '')]
      
    elsif html.scan(/<h\d+/).length > min_sections
      
      @unmbered ||= true
      gen_toc(html)                 
      
    else
      html
    end      

  end
  
  def to_css()
    
<<CSS
.sidenav {
  border-top: 1px solid #9ef;
  border-bottom: 1px solid #9ef;
  width: 130px;
  position: fixed;
  z-index: 1;
  top: 80px;
  left: 10px;
  background: transparent;
  overflow-x: hidden;
  padding: 8px 0;
}
  .sidenav ul {
    background-color: transparent; margin: 0.3em 0.3em 0.3em 0.9em; 
    padding: 0.3em 0.5em;   color: #5af;
  }
    
    .sidenav ul li {
      background-color: transparent; margin: 0.3em 0.1em; 
      padding: 0.2em
    }

.sidenav a {
  color: #5af;
  padding: 6px 8px 6px 8px;
  text-decoration: none;
  font-size: 0.9em;

}


.sidenav a:focus { color: #1e2; }
.sidenav a:hover { color: #1e2; }
.sidenav a:active { color: #1e2; }


a:link:active, a:visited:active {
  color: (internal value);
}

.main {
  margin-left: 140px; /* Same width as the sidebar + left position in px */
  font-size: 1.0em; /* Increased text to enable scrolling */
  padding: 0px 10px;
}

}
CSS

  end
  
  def to_index(threshold: 5)
    gen_index(@html, threshold: threshold)
  end

  private

  def build_html(a)
    
    puts ('a: ' + a.inspect).debug if @debug    
    
    a2 = make_tree(a)
    puts a2.inspect.debug if @debug
    
    raw_html = LineTree.new(a2).to_html(numbered: @numbered)               
    puts ('raw_html: ' + raw_html.inspect).debug if @debug
    
    make_linkable(raw_html)    
    
  end
  
  def gen_index(html, threshold: 5)

    a = html.split(/(?=<h2)/)
    puts ('gen_index a: ' + a.inspect).debug if @debug
    
    if a.length < threshold then
      
      index = build_html(a)

      @to_index = "<div id='index' class='sidenav'>\n%s\n</div>\n\n" % index
      
    else
      
      a = scan_headings html
      puts ('_a: ' + a.inspect).debug if @debug
      
      s = make_tree(a)
      puts ('s: ' + s.inspect).debug if @debug
      
      px = PxIndex.new
      px.import(s)

      @to_index = "<div id='azindex' class='sidenav'>\n%s\n</div>\n\n" \
          % px.build_html
    end

  end    

  def gen_toc(html)

    a = scan_headings html
    
    toc = build_html(a)
    @to_toc = toc
    
    pos = html =~ /<h2/
    html.insert(pos, "<div id='toc' class='toc'>\n%s\n</div>\n\n" % toc)

  end  

  def make_linkable(html)

    doc = Rexle.new(html)
    doc.root.each_recursive do |node|

      if node.name == 'li' then
        
        link = node.text ? '#' + node.text.strip.downcase.gsub(' ', '-') : ''
        anchor = Rexle::Element.new('a', attributes: {href: link})
        
        if @numbered then
          anchor.add Rexle::Element.new('span', value: node\
                                        .attributes[:id][1..-1].gsub('-','.'))
          node.attributes.delete :id
          anchor.children << ' ' + node.text if node.text
        else
          anchor.text = node.text if node.text
        end
        
        node.add anchor
        node.text = ''

      end
    end
    
    doc.xml declaration: false
  end


  def make_tree(a, indent=0)
    
    if @debug then
      puts 'inside make_tree'.debug 
      puts ('a: ' + a.inspect).debug
    end
    
    a.map.with_index do |x, i|
      
      puts ('x: ' + x.inspect).debug if @debug
      
      if x.is_a? Array then

        puts 'before make_tree()'.info if @debug
        
        make_tree(x, indent+1)

      else

        next unless x =~ /<h[2-4]/
        space = i == 0 ? indent-1 : indent
        heading = ('  ' * space) + x[/(?<=\>)[^<]+/]
        puts ('heading: ' + heading.inspect).debug if @debug
        heading

      end

    end.compact.join("\n")

  end

  def scan_headings(s, n=2)
    
    s.split(/(?=<h#{n})/).map do |x| 
      x.include?('<h' + (n+1).to_s) ? scan_headings(x, n+1) : x
    end

  end

end
