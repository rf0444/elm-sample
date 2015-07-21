module Update.Chat
  ( Action(..)
  , Task(..)
  , MqttInfo
  , update
  ) where

import Json.Encode as JE
import Json.Decode as JD
import Json.Decode exposing ((:=))
import Result
import Task as T
import Time exposing (Time)
import Http

import Model.Chat as M

type Action
  = ConnectionFormInput (M.ConnectionForm -> M.ConnectionForm)
  | Connect
  | MqttInfoResponse MqttInfo
  | ResponseError Http.Error
  | Connected
  | MessageArrived String
  | PostFormInput (M.PostForm -> M.PostForm)
  | Post Time

type Task
  = Request (T.Task Action Action)
  | MqttConnect MqttInfo
  | MqttSend String

type alias MqttInfo =
  { host : String
  , port_ : Int
  , clientId : String
  , username : String
  , password : String
  }

update : Action -> M.Model -> (M.Model, Maybe Task)
update action model =
  case (model, action) of
    (M.NotConnected state, ConnectionFormInput f) ->
      let
        next = M.NotConnected
          { state |
            form <- f state.form
          }
        task = Nothing
      in
        (next, task)
    (M.NotConnected state, Connect) ->
      if state.form.name == ""
        then
          (model, Nothing)
        else
          let
            next = M.Connecting
              { name = state.form.name
              }
            task = Just << Request
              << T.mapError ResponseError
              << T.map MqttInfoResponse
              <| Http.get mqttInfoDecoder "/api/mqtt"
          in
            (next, task)
    (M.Connecting state, ResponseError _) ->
      let
        next = M.NotConnected
          { form =
            { name = ""
            }
          }
        task = Nothing
      in
        (next, task)
    (M.Connecting state, MqttInfoResponse info) ->
      let
        next = M.Connecting state
        task = Just (MqttConnect info)
      in
        (next, task)
    (M.Connecting state, Connected) ->
      let
        next = M.Connected
          { name = state.name
          , form = { content = "" }
          , posts = []
          }
        task = Nothing
      in
        (next, task)
    (M.Connected state, PostFormInput f) ->
      let
        next = M.Connected
          { state |
            form <- f state.form
          }
        task = Nothing
      in
        (next, task)
    (M.Connected state, Post t) ->
      if state.form.content == ""
        then
          (model, Nothing)
        else
          let
            post =
              { user = state.name
              , time = t
              , content = state.form.content
              }
            next = M.Connected
              { state |
                form <- { content = "" }
              }
            task = Just (MqttSend (postToJsonString post))
          in
            (next, task)
    (M.Connected state, MessageArrived s) ->
      let
        mpost = jsonStringToPost s
        next = Maybe.withDefault model <| Maybe.map
          (\post ->
            M.Connected
              { state |
                posts <- post :: state.posts
              }
          ) mpost
        task = Nothing
      in
        (next, task)
    _ ->
      (model, Nothing)

mqttInfoDecoder : JD.Decoder MqttInfo
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
