module Main.Chat
  ( main
  ) where

import Html
import Task

import Action.Chat as A
import Lib.App as App
import Lib.Mqtt as Mqtt
import Model.Chat as M
import Task.Chat as T
import Update.Chat as U
import View.Chat as V

actions : Signal.Mailbox (Maybe A.Action)
actions = Signal.mailbox Nothing

address : Signal.Address A.Action
address = Signal.forwardTo actions.address Just

mqtt : Mqtt.Mqtt
mqtt = Mqtt.create
  { address = address
  , connected = Signal.map (always A.Connected) mqttConnected
  , messageArrived = Signal.map A.MessageArrived mqttMessageArrived
  }

app : App.App A.Action
app = App.create
  { signal = actions.signal
  , address = address
  , model = M.init
  , update = U.update
  , view = V.view
  , task = T.exec
    { address = address
    , mqtt =
      { connect = mqtt.connect
      , send = mqtt.send
      }
    }
  }

main : Signal Html.Html
main = app.main

port mqttMessageArrived : Signal String
port mqttConnected : Signal ()

port mqttConnect : Signal (Maybe Mqtt.MqttInfo)
port mqttConnect = mqtt.ports.connect

port mqttSend : Signal (Maybe String)
port mqttSend = mqtt.ports.send

port execAppTask : Signal (Task.Task () ())
port execAppTask = app.ports.task

port execMqttTask : Signal (Task.Task () ())
port execMqttTask = mqtt.ports.task
