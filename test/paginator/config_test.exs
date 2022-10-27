defmodule Paginator.ConfigTest do
  use ExUnit.Case, async: true

  alias Paginator.{Config, Cursor}

  describe "Config.new/2" do
    test "creates a new config" do
      config = Config.new(cursor_fields: [:id], limit: 10)

      assert config.after_values == nil
      assert config.before_values == nil
      assert config.limit == 10
      assert config.cursor_fields == [id: :asc]
    end
  end

  describe "Config.new/2 applies sort_fields" do
    test "applies column fields with default direction" do
      config = Config.new(cursor_fields: [:id])

      assert config.cursor_fields == [id: :asc]
    end

    test "applies column fields with alternate direction" do
      config = Config.new(cursor_fields: [:id], sort_direction: :desc)

      assert config.cursor_fields == [id: :desc]
    end

    test "applies column with direction tuples" do
      config = Config.new(cursor_fields: [id: :desc], sort_direction: :asc)

      assert config.cursor_fields == [id: :desc]
    end

    test "applies column with direction tuples mixed with column fields" do
      config = Config.new(cursor_fields: [{:id, :desc}, :name], sort_direction: :asc)

      assert config.cursor_fields == [id: :desc, name: :asc]
    end

    test "applies {binding, column} tuples with direction" do
      config = Config.new(cursor_fields: [{{:payments, :id}, :desc}], sort_direction: :asc)

      assert config.cursor_fields == [{{:payments, :id}, :desc}]
    end

    test "applies {binding, column} tuples without direction" do
      config = Config.new(cursor_fields: [{:payments, :id}], sort_direction: :asc)

      assert config.cursor_fields == [{{:payments, :id}, :asc}]
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
      assert config.before_values == %{id: "pay_789"}
      assert config.limit == 10
      assert config.cursor_fields == [id: :asc]
    end

    test "simple after" do
      config = Config.new(limit: 10, cursor_fields: [:id], after: simple_after())

      assert config.after_values == %{id: "pay_123"}
      assert config.before_values == nil
      assert config.limit == 10
      assert config.cursor_fields == [id: :asc]
    end

    test "complex before" do
      config = Config.new(limit: 10, cursor_fields: [:created_at, :id], before: complex_before())

      assert config.after_values == nil
      assert config.before_values == %{date: "2036-02-09T20:00:00.000Z", id: "pay_789"}
      assert config.limit == 10
      assert config.cursor_fields == [created_at: :asc, id: :asc]
    end

    test "complex after" do
      config = Config.new(limit: 10, cursor_fields: [:created_at, :id], after: complex_after())

      assert config.after_values == %{date: "2036-02-09T20:00:00.000Z", id: "pay_123"}
      assert config.before_values == nil
      assert config.limit == 10
      assert config.cursor_fields == [created_at: :asc, id: :asc]
    end
  end

  describe "Config.validate!/1" do
    test "raises ArgumentError when cursor_fields are not set" do
      config = Config.new([])

      assert_raise ArgumentError, "expected `:cursor_fields` to be set", fn ->
        Config.validate!(config)
      end
    end

    test "raises ArgumentError when after cursor does not match the cursor_fields" do
      config = Config.new(cursor_fields: [:date], after: complex_after())

      assert_raise ArgumentError,
                   "expected `:after` cursor to match `:cursor_fields`",
                   fn ->
                     Config.validate!(config)
                   end
    end

    test "raises ArgumentError when after cursor does not match cursor_fields with schema" do
      config =
        Config.new(
          cursor_fields: [{:person, :first_name}, {{:person, :last_name}, :asc}],
          after:
            Cursor.encode(%{
              {:person, :first_name} => "Test 121",
              {:person, :birth_date} => "1990-10-10"
            })
        )

      assert_raise ArgumentError,
                   "expected `:after` cursor to match `:cursor_fields`",
                   fn ->
                     Config.validate!(config)
                   end
    end

    test "ok when after cursor matches cursor_fields with schema" do
      config =
        Config.new(
          cursor_fields: [{:person, :first_name}, {{:person, :last_name}, :asc}],
          after:
            Cursor.encode(%{
              {:person, :first_name} => "Test 121",
              {:person, :last_name} => "Test"
            })
        )

      Config.validate!(config)
    end

    test "raises ArgumentError when before cursor does not match the cursor_fields" do
      config = Config.new(cursor_fields: [:id], before: complex_before())

      assert_raise ArgumentError,
                   "expected `:before` cursor to match `:cursor_fields`",
                   fn ->
                     Config.validate!(config)
                   end
    end
  end

  def simple_after, do: Cursor.encode(%{id: "pay_123"})
  def simple_before, do: Cursor.encode(%{id: "pay_789"})
  def complex_after, do: Cursor.encode(%{date: "2036-02-09T20:00:00.000Z", id: "pay_123"})
  def complex_before, do: Cursor.encode(%{date: "2036-02-09T20:00:00.000Z", id: "pay_789"})
end
