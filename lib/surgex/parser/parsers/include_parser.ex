defmodule Surgex.Parser.IncludeParser do
  @moduledoc """
  Parses the JSON API's include parameter according to the
  [JSON API spec](http://jsonapi.org/format/#fetching-includes).

  Produces a list of includes constrained to the provided relationship paths.
  """

  @doc false
  def call(nil, _spec), do: {:ok, []}
  def call("", _spec), do: {:ok, []}

  def call(input, allowed_paths) when is_binary(input) do
    paths = String.split(input, ",")
    allowed_paths = Enum.map(allowed_paths, &convert_to_string/1)

    validate_relationship_path(paths, allowed_paths)
  end

  defp convert_to_string(path) when is_binary(path), do: path
  defp convert_to_string(path) when is_atom(path), do: Atom.to_string(path)

  defp validate_relationship_path(paths, allowed_paths) do
    case Enum.all?(paths, &Enum.member?(allowed_paths, &1)) do
      true -> {:ok, Enum.map(paths, &String.to_atom/1)}
      false -> {:error, :invalid_relationship_path}
    end
  end

  @doc """
  Flattens the result of the parser (inclusion list) into multiple keys.

  ## Examples

      iex> IncludeParser.flatten({:ok, include: [:user]}, :include)
      {:ok, include_user: true}

  """
  def flatten({:ok, opts}, key) do
    case Keyword.pop(opts, key) do
      {nil, _} ->
        {:ok, opts}

      {value_list, rem_opts} when is_list(value_list) ->
        new_opts =
          value_list
          |> Enum.map(fn value -> {String.to_atom("#{key}_#{value}"), true} end)
          |> Keyword.merge(rem_opts)

        {:ok, new_opts}
    end
  end

  def flatten(input, _key), do: input
end
