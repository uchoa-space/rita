# frozen_string_literal: true

module Rita
  # The plain theme's boot-time audit (ADR 008): every `--rita-<x>` background with an
  # `--rita-on-<x>` pair must meet WCAG 4.5:1 in both colour schemes, and the stylesheet
  # must carry no class selector. Computed here in Ruby; a defect is a DefinitionError in
  # development and test, a logged error elsewhere.
  class Theme
    MINIMUM_CONTRAST = 4.5
    Pair = Struct.new(:scheme, :name, :background, :foreground, :ratio)

    def self.path = Rails.root.join("app/assets/stylesheets/rita.css")
    def self.verify!(css = path.read) = new(css).verify!

    def initialize(css)
      @css = css
    end

    # scheme => { token => value }, one block per `:root { ... }` — the first is light,
    # the one inside `prefers-color-scheme: dark` is dark.
    def tokens
      @tokens ||= @css.scan(/(@media[^{]*\{)?\s*:root\s*\{([^}]*)\}/m).each_with_object({}) do |(media, body), schemes|
        scheme = media.to_s.include?("dark") ? :dark : :light
        schemes[scheme] = body.scan(/(--rita-[\w-]+)\s*:\s*([^;]+);/).to_h { |k, v| [ k, v.strip ] }
      end
    end

    def pairs
      tokens.flat_map do |scheme, values|
        values.keys.filter_map do |token|
          next if token.start_with?("--rita-on-")

          on = token.sub("--rita-", "--rita-on-")
          next unless values.key?(on)

          Pair.new(scheme, token, values[token], values[on], self.class.contrast(values[token], values[on]))
        end
      end
    end

    def class_selectors
      @css.gsub(%r{/\*.*?\*/}m, "").split("}").map(&:strip).select { |rule| rule.start_with?(".") }
    end

    def defects
      low = pairs.select { |pair| pair.ratio < MINIMUM_CONTRAST }.map do |pair|
        "#{pair.scheme} #{pair.name} #{pair.background} on #{pair.foreground} is #{pair.ratio.round(2)}:1, below #{MINIMUM_CONTRAST}:1"
      end
      low + class_selectors.map { |rule| "class selector in theme: #{rule.lines.first.strip}" }
    end

    def verify!
      found = defects
      return true if found.empty?

      message = "rita.css: #{found.join('; ')}"
      raise DefinitionError, message if Rails.env.local?

      Rails.logger.error("rita.theme #{message}")
      false
    end

    # WCAG 2.x relative luminance contrast, from two hex colours.
    def self.contrast(hex_a, hex_b)
      la, lb = [ hex_a, hex_b ].map { |hex| luminance(hex) }.sort.reverse
      ((la + 0.05) / (lb + 0.05)).round(4)
    end

    def self.luminance(hex)
      digits = hex.strip.delete_prefix("#")
      digits = digits.chars.map { |c| c * 2 }.join if digits.size == 3
      r, g, b = digits.scan(/../).map { |pair| channel(pair.hex / 255.0) }
      0.2126 * r + 0.7152 * g + 0.0722 * b
    end

    def self.channel(value)
      value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
    end
  end
end
