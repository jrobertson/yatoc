#!/usr/bin/env ruby

# file: yatoc.rb

# description: Yet Another Table Of Contents HTML generator

require 'line-tree'


class Yatoc
  using ColouredText

  attr_reader :to_html, :to_toc
  
  def initialize(html, min_sections: 3, debug: false)
    
    @debug = debug

    @to_html = html.scan(/<h\d+/).length > min_sections ? gen_toc(html) : html

  end

  private  

  def gen_toc(html)

    a = scan_headings html
    puts ('a: ' + a.inspect).debug if @debug
    
    a2 = make_tree(a)
    puts a2.inspect.debug if @debug
    raw_html = LineTree.new(a2).to_html(numbered: true)            
    
    puts ('raw_html: ' + raw_html.inspect).debug if @debug
    toc = make_linkable(raw_html)
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
        anchor.add Rexle::Element.new('span', value: node\
                                      .attributes[:id][1..-1].gsub('-','.'))
        
        anchor.children << ' ' + node.text if node.text

        node.add anchor
        node.text = ''
        node.attributes.delete :id

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
