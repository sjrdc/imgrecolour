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

  def from_hsv(hue, saturation, value, alpha = 255)
      raise ArgumentError, "Hue must be between 0 and 360" unless (0..360).include?(hue)
      raise ArgumentError, "Saturation must be between 0 and 1" unless (0..1).include?(saturation)
      raise ArgumentError, "Value/brightness must be between 0 and 1" unless (0..1).include?(value)
      chroma = value * saturation
      rgb    = cylindrical_to_cubic(hue, saturation, value, chroma)
      rgb.map! { |component| ((component + value - chroma) * 255).to_i }
      rgb << alpha
      self.rgba(*rgb)
    end
    alias_method :from_hsb, :from_hsv

    def cylindrical_to_cubic(hue, saturation, y_component, chroma)
      hue_prime = hue.fdiv(60)
      x = chroma * (1 - (hue_prime % 2 - 1).abs)

      case hue_prime
      when (0...1); [chroma, x, 0]
      when (1...2); [x, chroma, 0]
      when (2...3); [0, chroma, x]
      when (3...4); [0, x, chroma]
      when (4...5); [x, 0, chroma]
      when (5..6);  [chroma, 0, x]
      end
    end
    private :cylindrical_to_cubic
end

module SelectiveColor
  # Really simple, just change the pixels to grayscale if their distance to a
  # reference hue is larger than a delta value.
  def to_selective_color!(hue, delta)
    reference = ChunkyPNG::Color.from_hsv(hue, 1, 1)
    pixels.map!{|pixel| ChunkyPNG::Color.distance(pixel, reference) > delta ? ChunkyPNG::Color.to_grayscale(pixel) : pixel}
    self
  end
end


if ARGV.size < 1
  puts "usage: #{$PROGRAM_NAME} infile.png [hue] [tolerance] [outfile.png]"
  exit
end

@infile = Pathname(File.expand_path(ARGV[0]))
@hue = ARGV.size >= 2 ? ARGV[1].to_i : 0
@tolerance = ARGV.size >= 3 ? ARGV[2].to_i : 10
@outfile = ARGV.size >= 4 ? Pathname(File.expand_path(ARGV[3])) : "out.png"

def recolour(file, hue, tolerance, outfile)

  image = ChunkyPNG::Image.from_file(file)
  image.extend(SelectiveColor)

  image.to_selective_color!(hue, tolerance)
  image.save(outfile)

end

recolour(@infile, @hue, @tolerance, @outfile)
