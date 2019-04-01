defmodule Session do
  use GenServer

  defstruct id: nil, transport: nil, aliases: [], requires: [], functions: [], macros: []

  def init({id, transport}) do
    {:ok, %Session{id: id, transport: transport}}
  end

  def response(%{"id" => msg_id}, %Session{id: ses_id, transport: transport}, keys \\ []) do
    Enum.into(keys, %{"id" => msg_id, "session" => ses_id})
  end

  def do_capture() do
    receive do
      msg -> IO.inspect(msg, label: "received io?")
    end
    do_capture()
  end

  def eval_capture(str) do
    {:ok, capture_pid} = Task.start_link(&do_capture/0)
    me = self()
    Task.start_link(fn ->
      Process.group_leader(self(), capture_pid)
      send(me, Code.eval_string(str))
    end)
    IO.puts("Waiting for result...")
    receive do
      result ->
	IO.inspect(result, label: "returned result")
	result
    end
  end

  def handle_call(msg, from, state = %Session{id: ses_id, transport: transport}) do
    IO.inspect(msg, label: "session received")
    case msg do
      %{"op" => "eval", "id" => id, "code" => code} ->
	IO.puts("eval #{code}")
	{result, new_bindings} = IO.inspect(Code.eval_string(code), label: "eval result")
	:ok = GenServer.cast(transport, response(msg, state, value: inspect(result)))
	:ok = GenServer.cast(transport, response(msg, state, status: [:done]))
	{:reply, :ok, state}
      other  ->
	{:error, "unhandled operation!"} 
    end
  end
end
