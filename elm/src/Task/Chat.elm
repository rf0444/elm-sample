module Task.Chat
  ( Task(..)
  , exec
  ) where

import Http
import Json.Decode as JD
import Json.Decode exposing ((:=))
import Json.Encode as JE
import Result
import Task as T

import Action.Chat as A
import Lib.Mqtt as Mqtt
import Model.Chat as M

type Task
  = RequestMqtt
  | MqttConnect Mqtt.MqttInfo
  | MqttSend M.Post

type alias Context =
  { address : Signal.Address A.Action
  , mqtt :
    { connect : Signal.Address Mqtt.MqttInfo
    , send : Signal.Address String
    }
  }

exec : Context -> Task -> T.Task () ()
exec context task = case task of
  RequestMqtt ->
    let
      task = Http.get mqttInfoDecoder "/api/mqtt"
        |> T.map A.MqttInfoResponse
        |> T.mapError A.ResponseError
    in
      task `T.andThen` Signal.send context.address `T.onError` Signal.send context.address
  MqttConnect info ->
    Signal.send context.mqtt.connect info
  MqttSend post ->
    Signal.send context.mqtt.send <| postToJsonString post

mqttInfoDecoder : JD.Decoder Mqtt.MqttInfo
mqttInfoDecoder =
  let
    toMqttInfo host port_ clientId username password =
      { host = host
      , port_ = port_
      , clientId = clientId
      , username = username
      , password = password
      }
  in
    JD.object5 toMqttInfo
      ("host" := JD.string)
      ("port" := JD.int)
      ("clientId" := JD.string)
      ("username" := JD.string)
      ("password" := JD.string)

postToJsonString : M.Post -> String
postToJsonString post = JE.encode 0 <| JE.object
  [ ("user", JE.string post.user)
  , ("time", JE.float post.time)
  , ("content", JE.string post.content)
  ]
