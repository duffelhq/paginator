defmodule Paginator.ConfigTest do
  use ExUnit.Case, async: true

  alias Paginator.{Config, Cursor}

  describe "Config.new/2" do
    test "creates a new config" do
      config = Config.new(cursor_fields: [:id], limit: 10)

      assert config.after_values == nil
      assert config.before_values == nil
      assert config.limit == 10
      assert config.cursor_fields == [:id]
    end
  end

  describe "Config.new/2 applies min/max limit" do
    test "applies default limit" do
      config = Config.new()
      assert config.limit == 50
      assert config.total_count_primary_key_field == :id
    end

    test "applies minimum limit" do
      config = Config.new(limit: 0)
      assert config.limit == 1
    end

    test "applies maximum limit" do
      config = Config.new(limit: 1000)
      assert config.limit == 500
    end

    test "respects configured maximum limit" do
      config = Config.new(limit: 1000, maximum_limit: 2000)
      assert config.limit == 1000

      config = Config.new(limit: 3000, maximum_limit: 2000)
      assert config.limit == 2000
    end
  end

  describe "Config.new/2 decodes cusors" do
    test "simple before" do
      config = Config.new(limit: 10, cursor_fields: [:id], before: simple_before())

      assert config.after_values == nil
      assert config.before_values == ["pay_789"]
      assert config.limit == 10
      assert config.cursor_fields == [:id]
    end

    test "simple after" do
      config = Config.new(limit: 10, cursor_fields: [:id], after: simple_after())

      assert config.after_values == ["pay_123"]
      assert config.before_values == nil
      assert config.limit == 10
      assert config.cursor_fields == [:id]
    end

    test "complex before" do
      config = Config.new(limit: 10, cursor_fields: [:created_at, :id], before: complex_before())

      assert config.after_values == nil
      assert config.before_values == ["2036-02-09T20:00:00.000Z", "pay_789"]
      assert config.limit == 10
      assert config.cursor_fields == [:created_at, :id]
    end

    test "complex after" do
      config = Config.new(limit: 10, cursor_fields: [:created_at, :id], after: complex_after())

      assert config.after_values == ["2036-02-09T20:00:00.000Z", "pay_123"]
      assert config.before_values == nil
      assert config.limit == 10
      assert config.cursor_fields == [:created_at, :id]
    end
  end

  def simple_after, do: Cursor.encode("pay_123")
  def simple_before, do: Cursor.encode("pay_789")
  def complex_after, do: Cursor.encode(["2036-02-09T20:00:00.000Z", "pay_123"])
  def complex_before, do: Cursor.encode(["2036-02-09T20:00:00.000Z", "pay_789"])
end
