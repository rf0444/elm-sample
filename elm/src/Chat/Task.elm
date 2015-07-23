module Chat.Task
  ( Context
  , exec
  , execJs
  ) where

import Http
import Json.Decode as JD
import Json.Decode exposing ((:=))
import Json.Encode as JE
import Result
import Task as T

import Chat.Action as A
import Chat.Model as M

type alias Context =
  { address : Signal.Address A.Action
  , js : Signal.Address String
  }

exec : Context -> A.Task -> T.Task () ()
exec context task = case task of
  A.RequestMqtt ->
    let
      task = Http.get mqttInfoDecoder "/api/mqtt"
        |> T.map A.MqttInfoResponse
        |> T.mapError A.ResponseError
    in
      task `T.andThen` Signal.send context.address `T.onError` Signal.send context.address
  A.MqttConnect info ->
    Signal.send context.js
      << toJsonString
      << withType "connect"
      << wrap ("destination", JE.string "/chat") "info"
      <| mqttInfoToJValue info
  A.MqttSend post ->
    Signal.send context.js
      << toJsonString
      << withType "send"
      << wrap ("destination", JE.string "/chat") "message"
      << JE.string
      <| postToString post

execJs : Context -> JE.Value -> T.Task () ()
execJs context value =
  case JD.decodeValue jsDecoder value of
    Result.Ok (Just action) ->
      Signal.send context.address action
    Result.Ok Nothing ->
      T.succeed ()
    Result.Err _ ->
      T.fail ()

mqttInfoDecoder : JD.Decoder A.MqttInfo
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

jsDecoder : JD.Decoder (Maybe A.Action)
jsDecoder =
  JD.at ["type"] JD.string `JD.andThen`
    (\t -> case t of
      "connected" ->
        JD.succeed <| Just A.Connected
      "messageArrived" ->
        JD.at ["message"] JD.string `JD.andThen`
          (\m -> case jsonStringToPost(m) of
            Just post -> JD.succeed << Just <| A.PostArrived post
            Nothing -> JD.succeed Nothing
          )
      _ ->
        JD.fail "invalid type"
    )

jsonStringToPost : String -> Maybe M.Post
jsonStringToPost =
  let
    toPost user time content =
      { user = user
      , time = time
      , content = content
      }
    dec = JD.object3 toPost
      ("user" := JD.string)
      ("time" := JD.float)
      ("content" := JD.string)
  in
    Result.toMaybe << JD.decodeString dec

toJsonString : JE.Value -> String
toJsonString = JE.encode 0

mqttInfoToJValue : A.MqttInfo -> JE.Value
mqttInfoToJValue info = JE.object
  [ ("host", JE.string info.host)
  , ("port", JE.int info.port_)
  , ("clientId", JE.string info.clientId)
  , ("username", JE.string info.username)
  , ("password", JE.string info.password)
  ]

postToString : M.Post -> String
postToString post = JE.encode 0 <| JE.object
  [ ("user", JE.string post.user)
  , ("time", JE.float post.time)
  , ("content", JE.string post.content)
  ]

wrap : (String, JE.Value) -> String -> JE.Value -> JE.Value
wrap w key value = JE.object [ w, (key, value) ]

withType : String -> JE.Value -> JE.Value
withType type_ = wrap ("type", JE.string type_) "data"
