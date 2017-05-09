defmodule Surgex.Mixfile do
  use Mix.Project

  def project do
    [app: :surgex,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     name: "Surgex",
     description: "All Things Elixir @ Surge Ventures",
     source_url: "https://github.com/surgeventures/surgex",
     homepage_url: "https://github.com/surgeventures/surgex",
     docs: [main: "README",
            logo: "logo.png",
            extras: ["README.md"]]]
  end

  defp package do
    [maintainers: ["Karol Słuszniak"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/surgeventures/surgex"},
     files: ~w(lib LICENSE.md mix.exs README.md)]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:ex_doc, "~> 0.14", only: :dev, runtime: false}]
  end
end
