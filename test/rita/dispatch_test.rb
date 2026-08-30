# frozen_string_literal: true

require "test_helper"

module Rita
  class DispatchTest < ActionDispatch::IntegrationTest
    include Rendering

    setup { Journal::Note.reset! }

    TURBO = { "Accept" => "text/vnd.turbo-stream.html, text/html" }.freeze

    test "the root draws the chat screen empty" do
      get "/"
      assert_response :ok
      assert_match(/data-archetype="chat"/, response.body)
      assert_match(/data-component="empty"/, response.body)
      assert_heading_order(response.body)
      assert_no_class_attribute(response.body)
    end

    test "a query failure is 422 with the Failure leaf where the reader is" do
      get "/chat/threads/0"
      assert_response :unprocessable_entity
      assert_match(/data-component="failure" data-code="invalid_argument"/, response.body)
    end

    test "Open redirects to the thread it opened" do
      post "/chat/open"
      assert_response :see_other
      thread = ChatThread.last
      assert_redirected_to "/chat/threads/#{thread.id}"
      follow_redirect!
      assert_match(%r{action="/chat/threads/#{thread.id}/say"}, response.body)
    end

    test "Say answers Turbo Streams appending both turns into the log" do
      thread = ChatThread.create!
      post "/chat/threads/#{thread.id}/say", params: { text: "hello" }, headers: TURBO
      assert_response :ok
      assert_equal Mime[:turbo_stream], response.media_type
      assert_equal 2, response.body.scan(/<turbo-stream action="append" target="messages">/).size
      assert_match(/data-role="user"/, response.body)
      assert_match(/data-role="assistant".*data-code="handoff"/m, response.body)
    end

    test "a Say failure is a 422 Turbo Stream with a system message in the log" do
      thread = ChatThread.create!
      post "/chat/threads/#{thread.id}/say", params: { text: " " }, headers: TURBO
      assert_response :unprocessable_entity
      assert_match(/<turbo-stream action="append" target="messages">/, response.body)
      assert_match(/data-role="system".*data-code="blank"/m, response.body)
    end

    test "a Say failure without Turbo is a 422 screen with the Failure leaf" do
      thread = ChatThread.create!
      post "/chat/threads/#{thread.id}/say", params: { text: " " }
      assert_response :unprocessable_entity
      assert_match(/<h1>Rita<\/h1>/, response.body)
      assert_match(/data-component="failure" data-code="blank"/, response.body)
    end

    test "forgery protection is on" do
      assert_not Rita::DispatchController.new.send(:protect_against_forgery?) && ActionController::Base.allow_forgery_protection
      assert_not_includes Rita::DispatchController.instance_methods(false), :skip_forgery_protection
      assert Rita::DispatchController.forgery_protection_strategy
    end

    test "a query whose archetype is not drawn yet answers JSON, provisionally" do
      Journal::Note.write("one")
      get "/journal/recent", params: { limit: 5 }
      assert_response :ok
      assert_equal [ { "id" => 1, "text" => "one", "status" => "written" } ], response.parsed_body["notes"]
    end

    test "a command without Turbo redirects to the query it invalidates" do
      post "/journal/write", params: { text: "hi" }
      assert_redirected_to "/journal/recent"
      note = Journal::Note.store.values.first
      post "/journal/notes/#{note.id}/archive"
      assert_redirected_to "/journal/recent"
      post "/journal/notes/#{note.id}/archive"
      assert_response :unprocessable_entity
      assert_match(/data-code="guard_failed"/, response.body)
      get "/journal/notes/99"
      assert_response :unprocessable_entity
      assert_equal "invalid_argument", response.parsed_body["code"]
    end

    test "an unknown key is 404" do
      Rails.application.routes.draw { match "/nowhere", to: "rita/dispatch#call", via: :get, defaults: { rita_key: "no/such" } }
      get "/nowhere"
      assert_response :not_found
    ensure
      Rails.application.reload_routes!
    end
  end
end
