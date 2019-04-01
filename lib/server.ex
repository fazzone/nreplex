defmodule Server do
  def listen(port) do
    {:ok, sock} = :gen_tcp.listen(port, [:binary, active: false, packet: :raw])
    IO.puts("listening on port " <> Integer.to_string(port))
    accept(sock)
  end

  def accept(sock) do
    {:ok, client} = :gen_tcp.accept(sock)
    IO.inspect(client, label: "connected")
    Task.start_link(fn -> handle(client) end)
    accept(sock)
  end

  def send_response(resp, sock) do
    with {:ok, encoded} <- Bento.encode(resp)
      do :gen_tcp.send(sock, encoded)
    end
  end

  def handle(sock) do
    with {:ok, transport} <- GenServer.start_link(Transport, sock),
	 {:ok, manager} <- GenServer.start_link(SessionManager, transport) do
      loop(transport, manager)
    end
  end

  def loop(transport, session_manager) do
    data = GenServer.call(transport, :read, :infinity)
    IO.inspect(session_manager, label: "manager")
    IO.inspect(data, label: "received") 
    # case data do
    #   %{"op" => op, "id" => id} -> IO.puts("ok")
    #   other_data ->
    # 	IO.inspect(other_data, label: "did not understand")
    # end
    #GenServer.cast(transport, GenServer.call(session_manager, data))
    :ok = GenServer.call(session_manager, data)
    loop(transport, session_manager)
  end

  defp response_for(%{}) do
    nil
  end

  def read1(sock, rest \\ []) do
    IO.inspect(rest, label: "read1 rest")
    with {:ok, data} <- :gen_tcp.recv(sock, 0) do
      if ?e == last_byte!(data) do
	{:ok, Bento.decode!(rest ++ [data])}
      else
	read1(sock, rest ++ [data])
      end
    end
  end

  defp last_byte!(data) do
    init_size = 8*(byte_size(data) - 1)
    case data do
      <<_ :: size(init_size), last>> -> last
    end
  end
end
