module Lib.Mqtt
  ( Mqtt
  , MqttOption
  , MqttInfo
  , create
  ) where

import Task

type alias Mqtt =
  { connect : Signal.Address MqttInfo
  , send : Signal.Address String
  , ports :
    { connect : Signal (Maybe MqttInfo)
    , send : Signal (Maybe String)
    , task : Signal (Task.Task () ())
    }
  }

type alias MqttOption action =
  { address : Signal.Address action
  , connected : Signal action
  , messageArrived : Signal action
  }

type alias MqttInfo =
  { host : String
  , port_ : Int
  , clientId : String
  , username : String
  , password : String
  }

create : MqttOption action -> Mqtt
create option =
  let
    connectToMqtt : Signal.Mailbox (Maybe MqttInfo)
    connectToMqtt = Signal.mailbox Nothing
    
    sendToMqtt : Signal.Mailbox (Maybe String)
    sendToMqtt = Signal.mailbox Nothing
    
    handle : Signal (Task.Task () ())
    handle = Signal.map (Signal.send option.address)
      <| Signal.merge option.connected option.messageArrived
  in
    { connect = Signal.forwardTo connectToMqtt.address Just
    , send = Signal.forwardTo sendToMqtt.address Just
    , ports =
      { connect = connectToMqtt.signal
      , send = sendToMqtt.signal
      , task = handle
      }
    }
