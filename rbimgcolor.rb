#!/usr/bin/ruby

require 'color'
require 'RMagick'
require 'pathname'

if ARGV.size < 1
  puts "usage: #{$PROGRAM_NAME} img.ext [#colors]"
  exit
end

def recolour(file, hue, num)

  image = Magick::ImageList.new(file)
  image.colorspace = Magick::HSLColorspace
  bin = (hue.to_f/(Magick::QuantumRange.to_f)*num).to_i
  image.each_pixel do |p, r, c|
    h = p.red.to_f
    if (h./(Magick::QuantumRange.to_f)*num).to_i != bin then
      p.green = 0
      image.pixel_color(r, c, p)
    end
  end
  image.write(file.to_s + "_recolored.jpg") do
    self.quality = 100
  end
  # free up RAM
  image.destroy!
  
end

def colours_from_photo(file, num)
  image = Magick::ImageList.new(file)
  q = image.quantize(num, Magick::HSLColorspace)
  palette = q.color_histogram.sort {|a, b| b[1] <=> a[1]}
  npixels = (image.columns * image.rows).to_f
  results = []

  palette.each do |p|

    h = p[0].red
    s = p[0].green
    l = p[0].blue
    
    rgb = Magick::Pixel.from_hsla(h.to_f/Magick::QuantumRange*360.to_i,
                                  s.to_f/Magick::QuantumRange*256.to_i,
                                  l.to_f/Magick::QuantumRange*256.to_i,
                                  1);

    r1 = rgb.red.to_i
    g1 = rgb.green.to_i
    b1 = rgb.blue.to_i

    # puts "#{r1}#{g1}#{b1}"

    r2 = r1.to_s(16)
    g2 = g1.to_s(16)
    b2 = b1.to_s(16)

    r2 = "0" + r2 unless r2.length == 2 
    g2 = "0" + g2 unless g2.length == 2
    b2 = "0" + b2 unless b2.length == 2

    hex = "#{r2}#{g2}#{b2}"

    results << {
      hsl: {hue: h, saturation: s, luminosity: l},
      hex: hex,
      fraction: ((p[1].to_f / npixels) * 100).round(2)
    }
  end

  results
end

@file = Pathname(File.expand_path(ARGV[0]))
@ncolors = ARGV.size == 2 ? ARGV[1].to_i : 10
@width = 800

# puts "#{@file.basename}" + "_resized.jpg"

colours = colours_from_photo(@file, @ncolors)
recolour(@file, colours.first[:hsl][:hue], @ncolors)

puts "<!DOCTYPE html>"
puts "<html><head><title>#{@file}</title></head><body>"
puts "<img src=\"#{@file}\" width=\"#{@width}px\">"
puts "<table width=\"#{@width}px\" style=\"table-layout: fixed;\"><tr>"
colours.each do |c|
  puts "<td height=\"50px\" bgcolor=\"##{c[:hex]}\"></td>"
end
puts "</tr><tr>"
colours.each do |c| 
  puts "<td align=\"center\">#{c[:fraction]}\%</td>"
end
puts "</tr></table>"
puts "<img src=\"#{@file.to_s + "_recolored.jpg"}\" width=\"#{@width}px\">"
puts "</body></html>"

