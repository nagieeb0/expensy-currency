defmodule ExpensyWeb.PageControllerTest do
  use ExpensyWeb.ConnCase

  test "GET / redirects to /wallet", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn, 302) == ~p"/wallet"
  end
end
