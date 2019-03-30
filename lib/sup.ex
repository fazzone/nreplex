defmodule Nrepl.Supervisor do
  use Supervisor
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      Supervisor.child_spec({Task, fn -> Server.listen(7888) end}, restart: :permanent)
    ]
    IO.puts("i am init")
    Supervisor.init(children , strategy: :one_for_one)
  end
end
