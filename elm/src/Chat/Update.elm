module Chat.Update
  ( update
  ) where

import Json.Decode as JD
import Json.Decode exposing ((:=))

import Chat.Action as A
import Chat.Model as M

update : A.Action -> M.Model -> (M.Model, Maybe A.Task)
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
            task = Just A.RequestMqtt
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
        task = Just (A.MqttConnect info)
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
            task = Just (A.MqttSend post)
          in
            (next, task)
    (M.Connected state, A.PostArrived post) ->
      let
        next = M.Connected
          { state |
            posts <- post :: state.posts
          }
        task = Nothing
      in
        (next, task)
    _ ->
      (model, Nothing)
