defmodule ExSgf.Parser do
  import NimbleParsec
  alias ExSgf.{Collection, GameTree, Sequence, ParserNode}

  # Define whitespace handling
  whitespace = ignore(ascii_char([?\s, ?\t, ?\n, ?\r, ?\v])) |> repeat()

  # Define UcLetter (uppercase letter)
  uc_letter = ascii_char([?A..?Z])

  # PropIdent is one or more uppercase letters
  prop_ident =
    times(uc_letter, min: 1)
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:propident)

  # Helper to capture escaped characters (e.g., \] becomes ])
  escaped_char = string("\\]")

  # Helper to capture non-escaped characters excluding "]"
  regular_char = utf8_char([{:not, ?]}])

  # Combine escaped and regular characters into a value parser
  c_value_type =
    repeat(choice([escaped_char, regular_char]))
    |> reduce({List, :to_string, []})

  # PropValue is a value enclosed in brackets, allowing nested values
  prop_value =
    ignore(string("["))
    |> concat(c_value_type)
    |> ignore(string("]"))

  prop_values =
    prop_value
    |> times(min: 1)
    |> tag(:propvalues)

  # Property is a PropIdent followed by one or more PropValues
  defparsec(
    :property,
    prop_ident
    |> concat(prop_values)
    |> reduce({__MODULE__, :build_property, []})
    |> ignore(whitespace)
  )

  node_def =
    ignore(string(";"))
    |> concat(repeat(parsec(:property)))
    |> tag(:properties)
    |> ignore(whitespace)

  # Node is a semicolon followed by zero or more Properties
  defparsec(
    :node,
    node_def
    |> times(1)
    |> map({__MODULE__, :build_node, []})
  )

  # Sequence is one or more Nodes
  defparsec(
    :sequence,
    times(parsec(:node), min: 1)
    # |> reduce({Function, :identity, []})
    |> tag(:sequence)
    |> map({__MODULE__, :build_sequence, []})
  )

  # GameTree is a recursive structure: open parenthesis, a Sequence,
  # followed by zero or more GameTrees, and a close parenthesis
  defparsec(
    :game_tree,
    ignore(string("("))
    |> concat(parsec(:sequence) |> tag(:sequence))
    |> concat(repeat(parsec(:game_tree)) |> tag(:sub_trees))
    |> reduce({Function, :identity, []})
    |> map({__MODULE__, :build_game_tree, []})
    |> ignore(string(")"))
    |> ignore(whitespace)
  )

  # Collection is one or more GameTrees
  collection =
    times(parsec(:game_tree), min: 1)
    |> reduce({Function, :identity, []})
    |> map({__MODULE__, :build_collection, []})

  # Main parser for the SGF format
  defparsec(:sgf_string, collection)

  def build_property(propident: k, propvalues: v) do
    %{k => v}
  end

  def build_node({:properties, properties}) do
    props =
      properties
      |> Enum.reduce(%{}, fn map, acc -> Map.merge(map, acc) end)

    %ParserNode{properties: props}
  end

  def build_sequence({:sequence, nodes}) do
    %Sequence{nodes: nodes}
  end

  def build_game_tree(sequence: [sequence], sub_trees: sub_trees) do
    %GameTree{sequence: sequence, sub_trees: sub_trees}
  end

  # Helper function to build a Collection struct
  def build_collection(game_trees), do: %Collection{game_trees: game_trees}
end
