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

modelWithTask : Signal (M.Model, Maybe U.Task)
modelWithTask = Signal.foldp
  (\(Just action) (model, _) -> U.update action model)
  (M.init, Nothing)
  actions.signal

port handleTasks : Signal (Task.Task () ())
port handleTasks =
  let
    exec : U.Task -> Task.Task () ()
    exec task = case task of
      U.Request task ->
        task `Task.andThen` Signal.send address `Task.onError` Signal.send address
      U.MqttConnect info ->
        Signal.send connectToMqtt.address (Just info)
      U.MqttSend s ->
        Signal.send sendToMqtt.address s
  in
    Signal.filterMap (Maybe.map exec << snd) (Task.succeed ()) modelWithTask

connectToMqtt : Signal.Mailbox (Maybe U.MqttInfo)
connectToMqtt = Signal.mailbox Nothing

sendToMqtt : Signal.Mailbox String
sendToMqtt = Signal.mailbox ""

port mqttConnect : Signal (Maybe U.MqttInfo)
port mqttConnect = connectToMqtt.signal

port mqttSend : Signal String
port mqttSend = sendToMqtt.signal

port mqttMessageArrived : Signal String
port mqttConnected : Signal ()

port handleMqttMessageArrived : Signal (Task.Task () ())
port handleMqttMessageArrived =
  Signal.map (Signal.send address << U.MessageArrived) mqttMessageArrived

port handleMqttConnected : Signal (Task.Task () ())
port handleMqttConnected =
  Signal.map (\_ -> Signal.send address U.Connected) mqttConnected
