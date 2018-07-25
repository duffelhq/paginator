defmodule Paginator.Factory do
  use ExMachina.Ecto, repo: Paginator.Repo

  alias Paginator.{Customer, Address, Payment}

  def customer_factory do
    %Customer{
      name: "Bob",
      active: true
    }
  end

  def address_factory do
    %Address{
      city: "City name",
      customer: build(:customer)
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
