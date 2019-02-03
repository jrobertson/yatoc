#!/usr/bin/env ruby

# file: yatoc.rb

# description: Yet Another Table Of Contents HTML generator

require 'pxindex'
require 'line-tree'
require 'kramdown'


class Yatoc
  using ColouredText

  attr_reader :to_html, :to_toc, :to_index
  
  def initialize(content, min_sections: 3, numbered: nil, debug: false)
    
    @numbered, @debug, @content = numbered, debug, content

    
    @to_html = if content =~ /<index[^>]+>/ then

      @numbered ||= false
      puts '1. ready to gen_index'.info if @debug
      html2 = gen_index(content)
      puts 'html2: ' + html2.inspect
      "%s\n\n<div class='main'>%s</div>" % \
          [html2, content.sub(/<index[^>]+>/, '')]
      
    elsif content =~ /<ix[^>]+>/ then

      @numbered ||= false
      puts '2. ready to gen_index'.info if @debug
      html2 = gen_index(content, threshold: nil)
      puts 'html2: ' + html2.inspect
      "%s\n\n<div class='main'>%s</div>" % \
          [html2, content.sub(/<ix[^>]+>/, '')]      
      
    elsif content.scan(/<h\d+/).length > min_sections
      
      @numbered ||= true
      puts 'ready to gen_toc()'.info if @debug
      gen_toc(content)                 
      
    else
      
      content
      
    end      

    
    # note: @to_html is important because this gem is used by the 
    #       Martile gem which expect to pass HTML through to render any TOCs.
    
  end
  
  # use in conjunction with the <ix/> tag to render a sidebar
  #  
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
    gen_index(@content, threshold: threshold)
  end

  def to_aztoc()
    
    a = @content.split(/(?=^# )/).map {|x| x.scan(/^#+ +[^\n]+/)}

    a2 = a.group_by {|x| x.first[/# +(.)/,1]}.sort

    s = a2.map do |heading, body|
      lists = body.map do |x|
        x.map do |line| 
          line.sub(/^(#+)/) {|y| '  ' * (y.length - 1) + '*'}
        end.join("\n")
      end.join("\n") + "\n"
      ['# ' + heading, lists]
    end.join("\n")
    
    puts 'to_aztoc | s: ' + s if @debug
    
    doc = Rexle.new("<div>%s</div>" % Kramdown::Document.new(s).to_html)
    
    doc.root.xpath('//li').each do |li|

      pnode = li.parent.parent

      pg = ''

      pg = if pnode.name == 'li' then
        pnode.element('a/attribute::href').to_s.strip[/^[^#]+/] + '#' \
            + li.text.to_s.strip.gsub(/ /,'_').downcase
      else

        li.text.to_s.strip.gsub(/ /,'_')
      end
      
      puts 'pg: ' + pg.inspect if @debug

      e = Rexle::Element.new('a', attributes: {href: pg}, \
                             value: li.text.to_s.strip)
      li.children[0] = e
    end    
    
    doc.xml
    
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
  
  def gen_aztoc(html)
    
      a = scan_headings html, 1
      puts ('_a: ' + a.inspect).debug if @debug
      
      s = make_tree(a,0, 1)
      puts ('s: ' + s.inspect).debug if @debug
      
      px = PxIndex.new
      px.import(s)

      @to_index = "<div id='azindex' class='sidenav'>\n%s\n</div>\n\n" \
          % px.build_html    
  end
  
  def gen_index(html, threshold: 5)

    a = html.split(/(?=<h2)/)
    puts ('gen_index a: ' + a.inspect).debug if @debug
    
    if threshold.nil? or a.length < threshold then
      
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


  def make_tree(a, indent=0, hn=2)
    
    if @debug then
      puts 'inside make_tree'.debug 
      puts ('a: ' + a.inspect).debug
    end
    
    a.map.with_index do |x, i|
      
      puts ('x: ' + x.inspect).debug if @debug
      
      if x.is_a? Array then

        puts 'before make_tree()'.info if @debug
        
        make_tree(x, indent+1, hn)

      else

        next unless x =~ /<h[#{hn}-4]/
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
