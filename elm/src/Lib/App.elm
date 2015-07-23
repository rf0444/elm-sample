module Lib.App
  ( App
  , AppOption
  , create
  ) where

import Html
import Task

type alias App action =
  { main : Signal Html.Html
  , ports :
    { task: Signal (Task.Task () ())
    }
  }

type alias Model model = model

type alias AppOption model action task =
  { signal : Signal (Maybe action)
  , address : Signal.Address action
  , model : model
  , update : action -> model -> (model, Maybe task)
  , view : Signal.Address action -> model -> Html.Html
  , task : task -> Task.Task () ()
  }

create : AppOption model action task -> App action
create option =
  let
    --modelWithTask : Signal (model, Maybe task)
    modelWithTask = Signal.foldp
      (\(Just action) (model, _) -> option.update action model)
      (option.model, Nothing)
      option.signal
    
    --model : Signal model
    model = Signal.map fst modelWithTask
    
    execTask : Signal (Task.Task () ())
    execTask = Signal.filterMap (Maybe.map option.task << snd) (Task.succeed ()) modelWithTask
    
    main : Signal Html.Html
    main = Signal.map (option.view option.address) model
  in
    { main = main
    , ports =
      { task = execTask
      }
    }
