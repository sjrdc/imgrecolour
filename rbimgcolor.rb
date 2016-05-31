#!/usr/bin/ruby

require 'RMagick'
require 'pathname'

if ARGV.size < 1
  puts "usage: #{$PROGRAM_NAME} img.ext [#colors]"
  exit
end

def colors_from_photo(file, num)
  image = Magick::ImageList.new(file)
  q = image.quantize(num, Magick::RGBColorspace)
  palette = q.color_histogram.sort {|a, b| b[1] <=> a[1]}
  total_depth = image.columns * image.rows
  results = []

  palette.each do |p|

    r1 = p[0].red / 256
    g1 = p[0].green / 256
    b1 = p[0].blue / 256

    r2 = r1.to_s(16)
    g2 = g1.to_s(16)
    b2 = b1.to_s(16)

    r2 = "0" + r2 unless r2.length == 2 
    g2 = "0" + g2 unless g2.length == 2
    b2 = "0" + b2 unless b2.length == 2

    hex = "#{r2}#{g2}#{b2}"

    results << {
      hex: hex,
      percent: ((p[1].to_f / total_depth.to_f) * 100).round(2)
    }
  end

  results
end

@file = Pathname(File.expand_path(ARGV[0]))
@ncolors = ARGV.size == 2 ? ARGV[1].to_i : 10
@width = 800

colors = colors_from_photo(@file, @ncolors)

puts "<!DOCTYPE html>"
puts "<html><head><title>#{@file}</title></head><body>"
puts "<img src=\"#{@file}\" width=\"#{@width}px\">"
puts "<table width=\"#{@width}px\" style=\"table-layout: fixed;\"><tr>"
colors.each do |c|
  puts "<td height=\"50px\" bgcolor=\"##{c[:hex]}\"></td>"
end
puts "</tr><tr>"
colors.each do |c| 
  puts "<td align=\"center\">#{c[:percent]}\%</td>"
end
puts "</tr></table></body></html>"
