defmodule ExpensyWeb.PageController do
  use ExpensyWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: "/wallet")
  end
end
