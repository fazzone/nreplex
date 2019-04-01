defmodule Nrepl do
  use Application
  def start(type, args) do
    Nrepl.Supervisor.start_link(name: Nrepl.Supervisor)
  end
end
