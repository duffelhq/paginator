defmodule Paginator.ConfigTest do
  use ExUnit.Case, async: true

  alias Paginator.{Config, Cursor}

  describe "Config.new/2" do
    test "creates a new config" do
      config = Config.new(limit: 10)

      assert config.after_values == nil
      assert config.before_values == nil
      assert config.limit == 10
      assert config.sort_columns == [:id]
    end
  end

  describe "Config.new/2 decodes cusors" do
    test "simple before" do
      config = Config.new(limit: 10, before: simple_before())

      assert config.after_values == nil
      assert config.before_values == ["pay_789"]
      assert config.limit == 10
      assert config.sort_columns == [:id]
    end

    test "simple after" do
      config = Config.new(limit: 10, after: simple_after())

      assert config.after_values == ["pay_123"]
      assert config.before_values == nil
      assert config.limit == 10
      assert config.sort_columns == [:id]
    end

    test "complex before" do
      config = Config.new(limit: 10, sort_columns: [:created_at, :id], before: complex_before())

      assert config.after_values == nil
      assert config.before_values == ["2036-02-09T20:00:00.000Z", "pay_789"]
      assert config.limit == 10
      assert config.sort_columns == [:created_at, :id]
    end

    test "complex after" do
      config = Config.new(limit: 10, sort_columns: [:created_at, :id], after: complex_after())

      assert config.after_values == ["2036-02-09T20:00:00.000Z", "pay_123"]
      assert config.before_values == nil
      assert config.limit == 10
      assert config.sort_columns == [:created_at, :id]
    end
  end

  def simple_after, do: Cursor.encode("pay_123")
  def simple_before, do: Cursor.encode("pay_789")
  def complex_after, do: Cursor.encode(["2036-02-09T20:00:00.000Z", "pay_123"])
  def complex_before, do: Cursor.encode(["2036-02-09T20:00:00.000Z", "pay_789"])
end
