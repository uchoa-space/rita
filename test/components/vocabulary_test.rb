# frozen_string_literal: true

require "test_helper"

# The static checks of ADR 004 and 008: the vocabulary is closed and the theme is classless.
module Rita
  class VocabularyTest < ActiveSupport::TestCase
    RAW_TAG = /<[a-z][\w-]*[\s>\/]/i

    # Comments and the ladder's prompt delimiters (`<sources>`) are not markup; code lines are.
    def code_lines(file)
      File.read(file).lines.reject { |line| line.strip.start_with?("#") }.join
    end

    test "no file under app/ outside app/components emits a raw HTML tag" do
      files = Dir[Rails.root.join("app/**/*.{rb,erb}")].reject do |f|
        f.include?("/app/components/") || f.include?("/layouts/mailer") || f.include?("/app/ladder/")
      end
      assert_operator files.size, :>, 10
      offenders = files.select { |f| code_lines(f).match?(RAW_TAG) }
      assert_empty offenders.map { |f| f.delete_prefix(Rails.root.to_s) }
    end

    test "no leaf or archetype source uses a class: attribute" do
      offenders = Dir[Rails.root.join("app/components/**/*.rb")].select { |f| File.read(f).match?(/\bclass:\s/) }
      assert_empty offenders
    end

    test "the theme has zero class selectors, by the ADR 008 rule" do
      count = `tr '}' '\\n' < #{Rita::Theme.path} | grep -c '^\\.'`.strip.to_i
      assert_equal 0, count
      assert_empty Rita::Theme.new(Rita::Theme.path.read).class_selectors
    end

    test "the theme's tokens meet 4.5:1 in both schemes and every background has its on- pair" do
      theme = Rita::Theme.new(Rita::Theme.path.read)
      assert_equal %i[light dark], theme.tokens.keys
      theme.tokens.each_value { |values| assert_operator values.size, :>=, 12 }
      pairs = theme.pairs
      assert_operator pairs.size, :>=, 12
      pairs.each { |pair| assert_operator pair.ratio, :>=, 4.5, "#{pair.scheme} #{pair.name}" }
      assert theme.verify!
      assert_empty theme.defects
    end

    test "the contrast check fails boot on a low pair or a class selector" do
      bad = ":root { --rita-bg: #ffffff; --rita-on-bg: #cccccc; }\n.card { color: red }\n"
      theme = Rita::Theme.new(bad)
      assert_equal 2, theme.defects.size
      assert_raises(Rita::DefinitionError) { theme.verify! }
      assert_in_delta 21.0, Rita::Theme.contrast("#000", "#fff"), 0.01
    end

    test "the theme's rules are keyed to data attributes or elements and reduced motion is last" do
      css = Rita::Theme.path.read.gsub(%r{/\*.*?\*/}m, "")
      assert_match(/@media \(prefers-color-scheme: dark\)/, css)
      assert_match(/@media \(prefers-reduced-motion: reduce\)[^}]*\{[^}]*\}\s*\}\s*\z/m, css)
      assert_match(/turbo-frame\[busy\] \[data-component="typing"\]/, css)
      assert_match(/@media \(min-width: 1024px\)/, css)
      assert_match(/min-height: var\(--rita-target\)/, css)
    end
  end
end
