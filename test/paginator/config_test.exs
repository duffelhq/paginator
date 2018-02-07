defmodule Paginator.ConfigTest do
  use ExUnit.Case, async: true

  alias Paginator.Config

  describe "Config.new/2" do
    test "creates a new config" do
      config =
        Config.new(
          after: 15,
          before: 20,
          limit: 10
        )

      assert config.after == 15
      assert config.before == 20
      assert config.limit == 10
    end
  end
end
