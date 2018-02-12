defmodule Paginator.Factory do
  use ExMachina.Ecto, repo: Paginator.Repo

  alias Paginator.{Customer, Payment}

  def customer_factory do
    %Customer{
      name: "Bob",
      active: true
    }
  end

  def payment_factory do
    %Payment{
      description: "Skittles",
      charged_at: DateTime.utc_now(),
      amount: :rand.uniform(100),
      status: "success",
      customer: build(:customer)
    }
  end
end
