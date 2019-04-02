defmodule Transport do
  use GenServer

  defstruct sock: nil, rest: []

  def wrap_socket(sock) do
    GenServer.start_link(__MODULE__, sock)
  end

  #callbacks

  def init(sock) do
    {:ok, %Transport{sock: sock}}
  end

  def handle_call(:read, from, %Transport{sock: sock, rest: rest}) do
    case read1(sock, rest) do
      {:ok, v, new_rest} -> {:reply, v, %Transport{sock: sock, rest: new_rest}}
    end
  end

  def handle_cast(resp, state = %Transport{sock: sock}) do
    with {:ok, encoded} <- Bento.encode(resp),
	 :ok <- :gen_tcp.send(sock, encoded) do
      {:noreply, state}
    end
  end

  def read1(sock, rest \\ []) do
    with {:ok, data} <- :gen_tcp.recv(sock, 0) do
      if ?e == last_byte!(data) do
	with {:ok, v, more} <- Bento.decode_partial(rest ++ data) do
	  {:ok, v, if more = "" do [] else [more] end}
	end
      else
	read1(sock, rest ++ data)
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
