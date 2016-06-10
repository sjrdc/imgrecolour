#!/usr/bin/ruby

require "chunky_png"
require 'pathname'

module ChunkyPNG::Color
  # See http://en.wikipedia.org/wiki/Hue#Computing_hue_from_RGB
  def self.hue(pixel)
    r, g, b = r(pixel), g(pixel), b(pixel)
    return 0 if r == b and b == g 
    ((180 / Math::PI * Math.atan2((2 * r) - g - b, Math.sqrt(3) * (g - b))) - 90) % 360
  end

  # The modular distance, as the hue is circular
  def self.distance(pixel, poxel)
    hue_pixel, hue_poxel = hue(pixel), hue(poxel)
    [(hue_pixel - hue_poxel) % 360, (hue_poxel - hue_pixel) % 360].min
  end
end

module SelectiveColor
  # Really simple, just change the pixels to grayscale if their distance to a
  # reference hue is larger than a delta value.
  def to_selective_color!(reference, delta)
    pixels.map!{|pixel| ChunkyPNG::Color.distance(pixel, reference) > delta ? ChunkyPNG::Color.to_grayscale(pixel) : pixel}
    self
  end
end


if ARGV.size < 1
  puts "usage: #{$PROGRAM_NAME} img.ext [#colors]"
  exit
end

@file = Pathname(File.expand_path(ARGV[0]))
# @color = ARGV.size >= 2 ? ARGV[1].to_i : 10
@tolerance = ARGV.size >= 2 ? ARGV[1].to_i : 10

def recolour(file, tolerance)
  image = ChunkyPNG::Image.from_file(file)
  image.extend(SelectiveColor)

  # Try the other colors if you like!
  keep = ChunkyPNG::Color.rgb(0, 230, 0)
  image.to_selective_color!(keep, tolerance)
  image.save("output.png")

end

recolour(@file, @tolerance)
