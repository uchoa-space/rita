# frozen_string_literal: true

require "test_helper"

module Rita
  class DispatchTest < ActionDispatch::IntegrationTest
    setup { Journal::Note.reset! }

    test "a query on GET renders its result as JSON" do
      Journal::Note.write("one")
      get "/journal/recent", params: { limit: 5 }
      assert_response :ok
      assert_equal [ { "id" => 1, "text" => "one", "status" => "written" } ], response.parsed_body["notes"]
    end

    test "a command on POST runs and renders ok" do
      post "/journal/write", params: { text: "hi" }
      assert_response :ok
      assert_equal true, response.parsed_body["ok"]
      assert_equal "hi", response.parsed_body.dig("note", "text")
    end

    test "a domain failure is 422 with the code" do
      post "/journal/write", params: { text: " " }
      assert_response :unprocessable_entity
      assert_equal({ "ok" => false, "code" => "blank", "message" => "a note needs text" }, response.parsed_body)
    end

    test "an entity is coerced from the path and guarded" do
      note = Journal::Note.write("one")
      get "/journal/notes/#{note.id}"
      assert_equal "one", response.parsed_body.dig("note", "text")

      post "/journal/notes/#{note.id}/archive"
      assert_response :ok
      post "/journal/notes/#{note.id}/archive"
      assert_response :unprocessable_entity
      assert_equal "guard_failed", response.parsed_body["code"]

      get "/journal/notes/99"
      assert_response :unprocessable_entity
      assert_equal "invalid_argument", response.parsed_body["code"]
    end
  end
end
