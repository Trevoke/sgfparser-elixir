defmodule ExSgf.ParserNode do
    defstruct properties: %{}
  end

defmodule ExSgf.Sequence do
    defstruct nodes: []
end

defmodule ExSgf.GameTree do
    defstruct sequence: %ExSgf.Sequence{}, sub_trees: []
end

defmodule ExSgf.Collection do
    defstruct game_trees: []
end