module Main.Chat
  ( main
  ) where

import Html
import Task

import Lib.Mqtt as Mqtt
import Lib.App as App
import Model.Chat as M
import Update.Chat as U
import View.Chat as V

main : Signal Html.Html
main = app.main

app : App.App U.Action
app =
  let
    exec : U.Task -> Task.Task () ()
    exec task = case task of
      U.Request task ->
        task `Task.andThen` Signal.send app.address `Task.onError` Signal.send app.address
      U.MqttConnect info ->
        Signal.send mqtt.connect info
      U.MqttSend s ->
        Signal.send mqtt.send s
  in
    App.create
      { model = M.init
      , update = U.update
      , view = V.view
      , exec = exec
      }

mqtt : Mqtt.Mqtt
mqtt = Mqtt.create
  { address = app.address
  , connected = Signal.map (always U.Connected) mqttConnected
  , messageArrived = Signal.map U.MessageArrived mqttMessageArrived
  }

port mqttMessageArrived : Signal String
port mqttConnected : Signal ()

port mqttConnect : Signal (Maybe Mqtt.MqttInfo)
port mqttConnect = mqtt.ports.connect

port mqttSend : Signal (Maybe String)
port mqttSend = mqtt.ports.send

port handleAppTask : Signal (Task.Task () ())
port handleAppTask = app.ports.task

port handleMqttTask : Signal (Task.Task () ())
port handleMqttTask = mqtt.ports.task
