defmodule Nrepl do
  use Application
  def start(type, args) do
    IO.inspect(type, label: "type=");
    IO.inspect(args, label: "args=");
    Nrepl.Supervisor.start_link(name: Nrepl.Supervisor)
  end
end
