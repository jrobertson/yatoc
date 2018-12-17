#!/usr/bin/env ruby

# file: yatoc.rb

# description: Yet Another Table Of Contents HTML generator


require 'c32'
require 'line-tree'


class Yatoc
  using ColouredText

  attr_reader :to_html, :to_toc
  
  def initialize(html, min_sections: 3, debug: false)
    
    @debug = debug

    @to_html = html.scan(/<h\d+/).length > 3 ? gen_toc(html) : html

  end

  def gen_toc(html)

    a = scan_headings html
    puts a.inspect.debug if @debug
    
    a2 = make_tree(a)
    puts a2.inspect.debug if @debug
    
    a3 = LineTree.new(a2).to_a
    puts a3.inspect.debug if @debug
    
    toc = "<ul>%s</ul>" % make_headings(a3)
    @to_toc = toc
    
    pos = html =~ /<h2/
    html.insert(pos, "<div id='toc' class='toc'>\n%s\n</div>\n\n" % toc)

  end

  private

  def make_headings(a, indent=-1, count=nil)

    items = a.map.with_index do |x, i|    
      
      if x.is_a? Array then

        id, head, tail = if count then 
         
          [
            count.to_s + '.' + i.to_s, 
            i == 1 ? "<ul>\n" : '', 
            i == a.length - 1 ? "</li>\n</ul></li>" : \
                i == a.length - 1 ? '</ul></li>' : ''
          ]

        else
          [i+1, '', '']
        end

        head + make_headings(x, indent+1, id) + tail
        
      else

        #"%s%s %s" % ['  ' * indent, count, x]
        r = "%s<li><a href='#%s'><span>%s</span> %s</a>" % \
          ['  ' * indent, x.downcase.gsub(' ','-'), count, x]
        i == 1 ? "<ul>" + r : r

      end

    end

    items.join("\n")

  end


  def make_tree(a, indent=0)
    
    if @debug then
      puts 'inside make_tree'.debug 
      puts ('a: ' + a.inspect).debug
    end
    
    a.map.with_index do |x, i|

      
      puts ('x: ' + x.inspect).debug if @debug
      
      if x.is_a? Array then

        puts 'before make_true()'.info if @debug
        
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
