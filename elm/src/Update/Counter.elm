module Update.Counter
  ( Action(..)
  , update
  ) where

import Model.Counter as M

type Action = Increment | Decrement

update : Action -> M.Model -> M.Model
update action model =
  case action of
    Increment -> model + 1
    Decrement -> model - 1
