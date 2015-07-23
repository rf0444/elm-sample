module Update.Chat
  ( update
  ) where

import Json.Decode as JD
import Json.Decode exposing ((:=))

import Action.Chat as A
import Model.Chat as M
import Task.Chat as T

update : A.Action -> M.Model -> (M.Model, Maybe T.Task)
update action model =
  case (model, action) of
    (M.NotConnected state, A.ConnectionFormInput f) ->
      let
        next = M.NotConnected
          { state |
            form <- f state.form
          }
        task = Nothing
      in
        (next, task)
    (M.NotConnected state, A.Connect) ->
      if state.form.name == ""
        then
          (model, Nothing)
        else
          let
            next = M.Connecting
              { name = state.form.name
              }
            task = Just T.RequestMqtt
          in
            (next, task)
    (M.Connecting state, A.ResponseError _) ->
      let
        next = M.NotConnected
          { form =
            { name = ""
            }
          }
        task = Nothing
      in
        (next, task)
    (M.Connecting state, A.MqttInfoResponse info) ->
      let
        next = M.Connecting state
        task = Just (T.MqttConnect info)
      in
        (next, task)
    (M.Connecting state, A.Connected) ->
      let
        next = M.Connected
          { name = state.name
          , form = { content = "" }
          , posts = []
          }
        task = Nothing
      in
        (next, task)
    (M.Connected state, A.PostFormInput f) ->
      let
        next = M.Connected
          { state |
            form <- f state.form
          }
        task = Nothing
      in
        (next, task)
    (M.Connected state, A.Post t) ->
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
            task = Just (T.MqttSend post)
          in
            (next, task)
    (M.Connected state, A.MessageArrived s) ->
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
