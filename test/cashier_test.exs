defmodule CashierTest do
  @moduledoc false

  use ExUnit.Case, async: true

  describe "acceptance tests — spec baskets" do
    test "GR1, SR1, GR1, GR1, CF1 → £22.45" do
      {:ok, session} = Cashier.new_checkout()
      Enum.each(~w(GR1 SR1 GR1 GR1 CF1), fn code -> :ok = Cashier.scan(session, code) end)
      assert Cashier.formatted_total(session) == "£22.45"
    end

    test "GR1, GR1 → £3.11" do
      {:ok, session} = Cashier.new_checkout()
      Enum.each(~w(GR1 GR1), fn code -> :ok = Cashier.scan(session, code) end)
      assert Cashier.formatted_total(session) == "£3.11"
    end

    test "SR1, SR1, GR1, SR1 → £16.61" do
      {:ok, session} = Cashier.new_checkout()
      Enum.each(~w(SR1 SR1 GR1 SR1), fn code -> :ok = Cashier.scan(session, code) end)
      assert Cashier.formatted_total(session) == "£16.61"
    end

    test "GR1, CF1, SR1, CF1, CF1 → £30.57" do
      {:ok, session} = Cashier.new_checkout()
      Enum.each(~w(GR1 CF1 SR1 CF1 CF1), fn code -> :ok = Cashier.scan(session, code) end)
      assert Cashier.formatted_total(session) == "£30.57"
    end
  end

  describe "scan order independence" do
    test "same basket in different order produces same total" do
      {:ok, s1} = Cashier.new_checkout()
      Enum.each(~w(GR1 SR1 GR1 GR1 CF1), fn code -> :ok = Cashier.scan(s1, code) end)

      {:ok, s2} = Cashier.new_checkout()
      Enum.each(~w(CF1 GR1 GR1 SR1 GR1), fn code -> :ok = Cashier.scan(s2, code) end)

      assert Cashier.total(s1) == Cashier.total(s2)
    end
  end

  describe "error handling" do
    test "unknown product code returns error and does not change cart" do
      {:ok, session} = Cashier.new_checkout()
      assert {:error, {:product_not_found, "INVALID"}} = Cashier.scan(session, "INVALID")
      assert Cashier.total(session) == Decimal.new("0.00")
    end

    test "oversized product code raises FunctionClauseError" do
      {:ok, session} = Cashier.new_checkout()
      long_code = String.duplicate("A", 33)

      assert_raise FunctionClauseError, fn ->
        Cashier.scan(session, long_code)
      end
    end

    test "empty product code raises FunctionClauseError" do
      {:ok, session} = Cashier.new_checkout()

      assert_raise FunctionClauseError, fn ->
        Cashier.scan(session, "")
      end
    end
  end

  describe "empty cart" do
    test "total of empty cart equals Decimal 0.00" do
      {:ok, session} = Cashier.new_checkout()
      assert Cashier.total(session) == Decimal.new("0.00")
    end
  end

  describe "clear" do
    test "clear resets the total to 0.00" do
      {:ok, session} = Cashier.new_checkout()
      Enum.each(~w(GR1 SR1), fn code -> :ok = Cashier.scan(session, code) end)
      Cashier.clear(session)
      assert Cashier.total(session) == Decimal.new("0.00")
    end
  end

  describe "stop" do
    test "stop terminates the session" do
      {:ok, session} = Cashier.new_checkout()
      assert Cashier.alive?(session)
      Cashier.stop(session)
      refute Cashier.alive?(session)
    end
  end

  describe "session lifecycle" do
    test "session is supervised under DynamicSupervisor" do
      {:ok, session} = Cashier.new_checkout()
      children = DynamicSupervisor.which_children(Cashier.SessionSupervisor)
      pids = Enum.map(children, fn {_, pid, _, _} -> pid end)

      [{session_pid, _}] = Registry.lookup(Cashier.Registry, session.id)
      assert session_pid in pids
    end

    test "session is registered in Registry" do
      {:ok, session} = Cashier.new_checkout()
      assert [{_pid, _}] = Registry.lookup(Cashier.Registry, session.id)
    end

    test "crashed session is detected by alive?" do
      {:ok, session} = Cashier.new_checkout()
      [{pid, _}] = Registry.lookup(Cashier.Registry, session.id)

      ref = Process.monitor(pid)
      Process.exit(pid, :kill)
      assert_receive {:DOWN, ^ref, :process, ^pid, :killed}

      refute Cashier.alive?(session)
    end

    test "session auto-terminates after idle timeout" do
      {:ok, session} = Cashier.new_checkout(idle_timeout: 50)
      [{pid, _}] = Registry.lookup(Cashier.Registry, session.id)

      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 500

      refute Cashier.alive?(session)
    end

    test "each session gets a unique ID" do
      {:ok, s1} = Cashier.new_checkout()
      {:ok, s2} = Cashier.new_checkout()
      assert s1.id != s2.id
    end
  end

  describe "concurrent access" do
    test "concurrent scans on same session are serialized correctly" do
      {:ok, session} = Cashier.new_checkout()

      1..10
      |> Enum.map(fn _ -> Task.async(fn -> Cashier.scan(session, "GR1") end) end)
      |> Task.await_many()

      # 10 GR1s with BOGO: charged = div(11, 2) = 5, 5 × 3.11 = 15.55
      assert Cashier.formatted_total(session) == "£15.55"
    end
  end
end
