defmodule Surgex.DataPipe.ForeignDataWrapper do
  @moduledoc """
  Configures a PostgreSQL Foreign Data Wrapper linkage between two repos.

  Specifically, it executes the following steps:

  - adds postgres_fdw extension to local repo
  - (re)creates server and user mapping based on current remote repo's config
  - copies remote repo's schema to local repo (named with underscored repo module name)

  Everything is executed in one transaction, so it's safe to use while existing transactions that
  depend on connection to foreign repo and its schema are running in the system (based on
  https://robots.thoughtbot.com/postgres-foreign-data-wrapper).
  """

  require Logger
  alias Ecto.Adapters.SQL

  @doc """
  Links source repo to a given foreign repo.
  """
  def init(source_repo, foreign_repo) do
    local_name = source_repo |> Module.split |> List.last
    server = schema = build_foreign_alias(foreign_repo)
    config = foreign_repo.config

    Logger.info(fn -> "Preparing foreign data wrapper at #{local_name}.#{server}..." end)

    server_opts = build_server_opts(config)
    user_opts = build_user_opts(config)

    apply(source_repo, :transaction, [fn ->
      source_repo
      |> execute("CREATE EXTENSION IF NOT EXISTS postgres_fdw")
      |> execute("DROP SERVER IF EXISTS #{server} CASCADE")
      |> execute("CREATE SERVER #{server} FOREIGN DATA WRAPPER postgres_fdw" <> server_opts)
      |> execute("CREATE USER MAPPING FOR CURRENT_USER SERVER #{server}" <> user_opts)
      |> execute("DROP SCHEMA IF EXISTS #{schema}")
      |> execute("CREATE SCHEMA #{schema}")
      |> execute("IMPORT FOREIGN SCHEMA public FROM SERVER #{server} INTO #{schema}")
    end])
  end

  @doc """
  Puts a foreign repo prefix (aka. schema) in a given Repo query.

  After calling this function, a given query will target tables from the previously linked repo
  instead of Repo.
  """
  def prefix(query, foreign_repo) do
    Map.put(query, :prefix, build_foreign_alias(foreign_repo))
  end

  defp build_server_opts(config) do
    build_opts([
      {"host", Keyword.get(config, :hostname)},
      {"dbname", Keyword.get(config, :database)},
      {"port", Keyword.get(config, :port)}
    ])
  end

  defp build_user_opts(config) do
    build_opts([
      {"user", Keyword.get(config, :username)},
      {"password", Keyword.get(config, :password)}
    ])
  end

  defp build_opts(mapping) do
    opts_string =
      mapping
      |> Enum.filter(fn {_, value} -> value end)
      |> Enum.map(fn {option, value} -> "#{option} '#{value}'" end)
      |> Enum.join(", ")

    case opts_string do
      "" -> ""
      _  -> " OPTIONS (#{opts_string})"
    end
  end

  defp build_foreign_alias(repo) do
    repo
    |> Module.split
    |> List.last
    |> Macro.underscore
  end

  defp execute(repo, sql) do
    SQL.query!(repo, sql)
    repo
  end
end
