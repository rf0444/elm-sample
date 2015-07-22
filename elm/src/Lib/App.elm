module Lib.App
  ( App
  , AppOption
  , create
  ) where

import Html
import Task

type alias App action =
  { main : Signal Html.Html
  , address : Signal.Address action
  , ports :
    { task: Signal (Task.Task () ())
    }
  }

type alias Model model = model

type alias AppOption model action task =
  { model : model
  , update : action -> model -> (model, Maybe task)
  , exec : task -> Task.Task () ()
  , view : Signal.Address action -> model -> Html.Html
  }

create : AppOption model action task -> App action
create option =
  let
    --actions : Signal.Mailbox (Maybe action)
    actions = Signal.mailbox Nothing
    
    --address : Signal.Address action
    address = Signal.forwardTo actions.address Just
    
    --model : Signal model
    model = Signal.map fst modelWithTask
    
    --modelWithTask : Signal (model, Maybe task)
    modelWithTask = Signal.foldp
      (\(Just action) (model, _) -> option.update action model)
      (option.model, Nothing)
      actions.signal
    
    handleTask : Signal (Task.Task () ())
    handleTask = Signal.filterMap (Maybe.map option.exec << snd) (Task.succeed ()) modelWithTask
    
    main : Signal Html.Html
    main = Signal.map (option.view address) model
  in
    { main = main
    , address = address
    , ports =
      { task = handleTask
      }
    }
