module Lib.App
  ( App
  , AppOption
  , Actions
  , createActions
  , create
  , execTask
  ) where

import Html
import Task

type alias App action task =
  { main : Signal Html.Html
  , address : Signal.Address action
  , task : Signal (Maybe task)
  }

type alias AppOption model action task =
  { model : model
  , update : action -> model -> (model, Maybe task)
  , view : Signal.Address action -> model -> Html.Html
  }

type alias Actions a =
  { address : Signal.Address a
  , signal : Signal (Maybe a)
  }

createActions : Maybe a -> Actions a
createActions default =
  let
    --actions : Signal.Mailbox (Maybe a)
    actions = Signal.mailbox default
  in
   { address = Signal.forwardTo actions.address Just
   , signal = actions.signal
   }

create : AppOption model action task -> App action task
create option =
  let
    --actions : Actions action
    actions = createActions Nothing
    
    --modelWithTask : Signal (model, Maybe task)
    modelWithTask = Signal.foldp
      (\(Just action) (model, _) -> option.update action model)
      (option.model, Nothing)
      actions.signal
    
    --model : Signal model
    model = Signal.map fst modelWithTask
    
    --task : Signal (Maybe task)
    task = Signal.map snd modelWithTask
    
    main : Signal Html.Html
    main = Signal.map (option.view actions.address) model
  in
    { main = main
    , address = actions.address
    , task = task
    }

execTask : (task -> Task.Task () ()) -> Signal (Maybe task) -> Signal (Task.Task () ())
execTask f =
  Signal.map (Maybe.withDefault (Task.succeed ()) << Maybe.map f)
