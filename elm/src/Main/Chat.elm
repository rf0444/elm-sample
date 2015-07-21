module Main.Chat
  ( main
  ) where

import Html exposing (Html)
import Task

import Model.Chat as M
import Update.Chat as U
import View.Chat as V

main : Signal Html
main = Signal.map (V.view address) model

actions : Signal.Mailbox (Maybe U.Action)
actions = Signal.mailbox Nothing

address : Signal.Address U.Action
address = Signal.forwardTo actions.address Just

model : Signal M.Model
model = Signal.map fst modelWithTask

modelWithTask : Signal (M.Model, Maybe (Task.Task U.Action U.Action))
modelWithTask = Signal.foldp
  (\(Just action) (model, _) -> U.update action model)
  (M.init, Nothing)
  actions.signal

port tasks : Signal (Task.Task () ())
port tasks =
  let
    send : Task.Task U.Action U.Action -> Task.Task () ()
    send task = task `Task.andThen` Signal.send address `Task.onError` Signal.send address
    withDefault = Maybe.withDefault (Task.succeed ())
  in
    Signal.map (withDefault << Maybe.map send << snd) modelWithTask
