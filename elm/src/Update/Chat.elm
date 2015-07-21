module Update.Chat
  ( Action(..)
  , update
  ) where

import Json.Decode as JD
import Task
import Time exposing (Time)
import Http

import Model.Chat as M

type Action
  = ConnectionFormInput (M.ConnectionForm -> M.ConnectionForm)
  | Connect
  | ConnectError
  | Connected
  | PostFormInput (M.PostForm -> M.PostForm)
  | Post Time

update : Action -> M.Model -> (M.Model, Maybe (Task.Task Action Action))
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
            task = Just
              << Task.mapError (\_ -> ConnectError)
              << Task.map (\_ -> Connected)
              <| Http.get JD.value "/api/mqtt"
          in
            (next, task)
    (M.Connecting state, ConnectError) ->
      let
        next = M.Connected
          { name = state.name
          , form = { content = "" }
          , posts = []
          }
        task = Nothing
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
              , posts <- post :: state.posts
              }
            task = Nothing
          in
            (next, task)
    _ ->
      (model, Nothing)
