defmodule SessionManager do
  use GenServer

  defstruct transport: nil, sessions_map: %{}

  def init(transport) do
    {:ok, %SessionManager{transport: transport}}
  end

  def new_session_id(sessions_map) do
    new_id = UUID.uuid4()
    case sessions_map do
      %{^new_id => _} -> new_session_id(sessions_map)
      _ -> new_id
    end
  end

  def handle_call(msg, from, state = %SessionManager{transport: transport, sessions_map: sessions}) do
    IO.inspect(msg, label: "sess mgr called")
    with %{"op" => op, "id" => id} <- msg do
      case op do
	"clone" ->
	  #new_id = 1 + map_size(sessions)
	  new_id = new_session_id(sessions)
	  #new_session = spawn_link(fn -> Session.loop(new_id) end)
	  {:ok, new_session} = GenServer.start_link(Session, {new_id, transport})
	  GenServer.cast(transport, %{"id" => id, "new-session" => new_id, "status" => [:done]})
	  {:reply, :ok, %SessionManager{transport: transport, sessions_map:  Map.put(sessions, new_id, new_session)}}
	other ->
	  %{"session" => ses_id} = msg
	  session = Map.get(sessions, ses_id)
	  IO.inspect(session, label: "got session")
	  :ok = GenServer.call(session, msg)
	  {:reply, :ok, state}
      end
    end
  end
end
