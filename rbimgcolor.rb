#!/usr/bin/ruby

require 'RMagick'
require 'pathname'

if ARGV.size < 1
  puts "usage: #{$PROGRAM_NAME} img.ext"
  exit
end


def colors_from_photo(file, num)
  image = Magick::ImageList.new(file)
  q = image.quantize(num, Magick::RGBColorspace)
  palette = q.color_histogram.sort {|a, b| b[1] <=> a[1]}
  total_depth = image.columns * image.rows
  results = []

  palette.count.times do |i|
    p = palette[i]

    r1 = p[0].red / 256
    g1 = p[0].green / 256
    b1 = p[0].blue / 256

    r2 = r1.to_s(16)
    g2 = g1.to_s(16)
    b2 = b1.to_s(16)

    r2 += r2 unless r2.length == 2 
    g2 += g2 unless g2.length == 2
    b2 += b2 unless b2.length == 2

    rgb = "#{r1},#{g1},#{b1}"
    hex = "#{r2}#{g2}#{b2}"
    depth = p[1]

    results << {
      rgb: rgb,
      hex: hex,
      percent: ((depth.to_f / total_depth.to_f) * 100).round(2)
    }
  end

  results
end

@file = Pathname(File.expand_path(ARGV[0]))
@width = 800

colors = colors_from_photo(@file, 10)

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
