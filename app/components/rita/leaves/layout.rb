# frozen_string_literal: true

module Rita
  module Leaves
    # The document every screen renders into: head, the one `h1`, and `main`. The only
    # heading level a screen adds below it is `h2` (Section), so the order is verified by
    # construction and by test.
    class Layout < Base
      include Phlex::Rails::Helpers::CSRFMetaTags
      include Phlex::Rails::Helpers::CSPMetaTag
      include Phlex::Rails::Helpers::StylesheetLinkTag
      include Phlex::Rails::Helpers::JavascriptImportmapTags

      def initialize(title:, heading: title)
        @title = title
        @heading = heading
      end

      def view_template(&block)
        doctype
        html(lang: I18n.locale.to_s) do
          head do
            title { @title }
            meta(name: "viewport", content: "width=device-width,initial-scale=1")
            meta(name: "color-scheme", content: "light dark")
            csrf_meta_tags
            csp_meta_tag
            stylesheet_link_tag("rita", data: { turbo_track: "reload" })
            javascript_importmap_tags
          end
          body(data: { component: "layout" }) do
            header(data: { component: "masthead" }) do
              a(href: "/", data: { component: "brand" }) { h1 { @heading } }
            end
            main(data: { component: "screen" }, &block)
          end
        end
      end
    end
  end
end
