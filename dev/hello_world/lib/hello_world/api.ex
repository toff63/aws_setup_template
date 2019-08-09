defmodule HelloWorld.Api do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/v1/" do
    send_resp(conn, 200, "ok")
  end

  get "/hello" do
    case HelloWorld.Greeting.greet() do
      {:ok, greet} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, greet)
      _ -> send_resp(conn, 500, "Internal server error")
    end
  end

  match _ do
    send_resp(conn, 404, "Wrong Address")
  end
end
