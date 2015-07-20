module Update.Chat
  ( Action(..)
  , update
  ) where

import Time exposing (Time)
import Model.Chat as M

type Action
  = ConnectionFormInput (M.ConnectionForm -> M.ConnectionForm)
  | Connect
  | PostFormInput (M.PostForm -> M.PostForm)
  | Post Time

update : Action -> M.Model -> M.Model
update action model =
  case (model, action) of
    (M.NotConnected m, ConnectionFormInput f) ->
      M.NotConnected
        { m |
          form <- f m.form
        }
    (M.NotConnected m, Connect) ->
      if m.form.name == ""
        then
          model
        else
          M.Connected
            { name = m.form.name
            , form = { content = "" }
            , posts = []
            }
    (M.Connected m, PostFormInput f) ->
      M.Connected
        { m |
          form <- f m.form
        }
    (M.Connected m, Post t) ->
      if m.form.content == ""
        then
          model
        else
          let
            post =
              { user = m.name
              , time = t
              , content = m.form.content
              }
          in
            M.Connected
              { m |
                form <- { content = "" }
              , posts <- post :: m.posts
              }
    _     ->
      model
