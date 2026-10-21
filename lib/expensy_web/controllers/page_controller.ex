defmodule ExpensyWeb.PageController do
  use ExpensyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
