defmodule Server do
  def listen(port) do
    {:ok, sock} = :gen_tcp.listen(port, [:binary,
					 packet: :line,
					 active: false,
					 reuseaddr: true])
    accept(sock)
  end

  def accept(sock) do
    {:ok, client} = :gen_tcp.accept(sock)
    Task.start_link(fn -> handle(client) end)
    accept(sock)
  end

  def handle(sock) do
    {:ok, in_data} = :gen_tcp.recv(sock, 0)
    :gen_tcp.send(sock, in_data)
    handle(sock)
  end

end
