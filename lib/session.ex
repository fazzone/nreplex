defmodule Session do
  # Keep track of an individual nREPL session
  # Session knows its own ID and is responsible for attaching it to all messages

  use GenServer

  defstruct id: nil, transport: nil, bindings: [], aliases: [], requires: [], functions: [], macros: []

  def new(id, transport) do
    GenServer.start_link(__MODULE__, {id, transport})
  end

  def init({id, transport}) do
    {:ok, %Session{id: id, transport: transport}}
  end

  def response(%Session{id: ses_id}, %{"id" => msg_id}, keys \\ []) do
    #Enum.into(keys, %{"id" => msg_id, "session" => ses_id})
    Enum.into(keys, %{id: msg_id, session: ses_id})
  end

  def reply(session, msg, keys \\ []) do
    GenServer.cast(session, {msg, keys})
  end

  def forward_output(state, msg) do
    receive do
      chars ->
	send_message(state, {msg, [out: chars]})
    end
    forward_output(state, msg)
  end

  def eval_capture(state = %Session{bindings: bindings}, %{"code" => code} = msg) do
    {:ok, fwd} = Task.start_link(fn -> forward_output(state, msg) end)
    {:ok, capture_pid} = GenServer.start_link(IOCapture, {fwd, nil})
    me = self()
    Task.start_link(fn ->
      Process.group_leader(self(), capture_pid)
      result = try do
    		 {result, new_bindings} = Code.eval_string(code, bindings)
    		 {:ok, result, new_bindings}
    	       catch
    		 kind, error -> {:err, Exception.format(kind, error, __STACKTRACE__)}
    	       end
      send(me, result)
    end)
    receive do
      v -> v
    end
  end

  def send_message(state = %Session{transport: transport}, {msg, keys}) do
    GenServer.cast(transport, response(state, msg, keys))
  end

  def handle_cast(msgspec, state) do
    send_message(state, msgspec)
    {:noreply, state}
  end

  def handle_call(msg, from, state = %Session{id: ses_id, transport: transport, bindings: bindings}) do
    case msg do
      %{"op" => "eval"} ->
	try do
	  case eval_capture(state, msg) do
	    {:ok, result, new_bindings} ->
	      :ok = GenServer.cast(transport, response(state, msg, value: inspect(result)))
	      {:reply, :ok, %Session{state | bindings: bindings ++ new_bindings}}
	    {:err, error} ->
	      :ok = GenServer.cast(transport, response(state, msg, err: error))
	      {:reply, :ok, state}
	  end
	after
	  :ok = GenServer.cast(transport, response(state, msg, status: [:done]))
	end
      other ->
	{:error, "unhandled operation!"} 
    end
  end
end
