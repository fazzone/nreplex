defmodule IOCapture do
  use GenServer
  #constructors?

  def init({out, infn}) do
    {:ok, {out, infn}}
  end

  def handle_info({msg, from, reply_as, req}, state) do
    IO.inspect(from, label: "handle info from")
    case msg do
      :io_request -> io_request(from, reply_as, req, state)
      _ -> nil
    end
    {:noreply, state}
  end
  
  def io_request(from, reply_as, req, {out, infn}) do
    case req do
      {:put_chars, chars} -> send(out, chars)
      {:put_chars, mod, fun, args} -> send(out, apply(mod, fun, args))
      {:put_chars, encoding, chars} -> send(out, :unicode.characters_to_binary(chars, encoding))
      {:put_chars, encoding, mod, fun, args} -> send(out, apply(mod, fun, args) |> :unicode.characters_to_binary(encoding))
    end
    send(from, {:io_reply, reply_as, nil})
  end
end

