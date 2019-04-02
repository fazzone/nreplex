defmodule SessionManager do
  # Keep track of all of the unique sessions.
  # Handle clone, interrupt, close, ls-sessions
  
  use GenServer

  defstruct transport: nil, sessions_map: %{}

  def wrap_transport(transport) do
    GenServer.start_link(__MODULE__, transport)
  end

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
    with %{"op" => op, "id" => id} <- msg do
      case op do
	"clone" ->
	  new_id = new_session_id(sessions)
	  {:ok, new_session} = Session.new(new_id, transport)
	  Session.reply(new_session, msg, [{:status, [:done]}, {"new-session", new_id}])
	  {:reply, :ok, %SessionManager{transport: transport, sessions_map:  Map.put(sessions, new_id, new_session)}}
	other ->
	  %{"session" => ses_id} = msg
	  :ok = GenServer.call(Map.get(sessions, ses_id), msg)
	  {:reply, :ok, state}
      end
    end
  end
end
