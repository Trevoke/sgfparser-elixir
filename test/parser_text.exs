defmodule ExSgf.ParserTest do
  use ExUnit.Case, async: true
  alias SGF.{ParserNode, Sequence, GameTree, Collection}

  describe "node" do
    test "has properties" do
      {:ok, [node], "", %{}, _, _} = SgfParser.node(";GM[1]FF[4]")
      expected = %ParserNode{
        properties: %{"GM" => ["1"], "FF" => ["4"]}
      }
      assert node == expected
    end
  end

  describe "sequence" do
    test "two nodes in a row" do
      {:ok, [sequence], "", %{}, _, _} = SgfParser.sequence(";C[1];C[2]")
      expected = %Sequence{
        nodes: [
          %ParserNode{properties: %{"C" => ["1"] }},
          %ParserNode{properties: %{"C" => ["2"]}}
        ]
      }

      assert sequence == expected
    end
  end

  describe "gametrees" do
    test "empty gametree" do
      {:ok, [gt], "", %{}, _, _} = SgfParser.game_tree("(;)")
      expected = %GameTree{sequence: %Sequence{nodes: [%ParserNode{}]}}
      assert gt == expected
    end

    test "a sequence can be followed by a gametree" do
      {:ok, [gametree], "", %{}, _, _} = SgfParser.game_tree("(;C[1](;C[2])(;C[3]))")
      gt2 = %GameTree{
        sequence: %Sequence{nodes: [%ParserNode{properties: %{"C" => ["2"]}}]},
        sub_trees: []
      }
      gt3 = %GameTree{
        sequence: %Sequence{nodes: [%ParserNode{properties: %{"C" => ["3"]}}]},
        sub_trees: []
      }
      expected = %GameTree{
        sequence: %Sequence{nodes: [%ParserNode{properties: %{"C" => ["1"]}}]},
        sub_trees: [gt2, gt3]
      }

      assert gametree == expected
    end
  end

  describe "collections" do
    test "can have many gametrees" do
      {:ok, [collection], "", %{}, _, _} = SgfParser.sgf_string("(;)(;)")
      gt1 = %GameTree{
        sequence: %Sequence{nodes: [%ParserNode{}]},
      }
      gt2 = %GameTree{
        sequence: %Sequence{nodes: [%ParserNode{}]},
      }
      expected = %Collection{
        game_trees: [gt1, gt2]
      }
      assert collection == expected
    end
  end
end