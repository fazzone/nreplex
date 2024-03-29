defmodule Nrepl.MixProject do
  use Mix.Project

  def project do
    [
      app: :nrepl,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Nrepl, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:bento, "~> 0.9"},
      # {:bencode, "~> 0.3.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:uuid, "~> 1.1.8"},
      {:bento, git: "https://github.com/fazzone/bento.git", branch: "master"}
    ]
  end
end


