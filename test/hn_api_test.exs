defmodule HNApiTest do
  use ExUnit.Case
  alias HN.Api

  test "get item returns an item" do
    item = Api.get_item(1)

    assert item == %{
             "by" => "pg",
             "descendants" => 15,
             "id" => 1,
             "kids" => [15, 234_509, 487_171, 454_426, 454_424, 454_410, 82729],
             "score" => 57,
             "time" => 1_160_418_111,
             "title" => "Y Combinator",
             "type" => "story",
             "url" => "http://ycombinator.com"
           }
  end
end
