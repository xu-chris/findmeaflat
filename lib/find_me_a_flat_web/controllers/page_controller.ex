defmodule FindMeAFlatWeb.PageController do
  use FindMeAFlatWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
