module Chat.Action
  ( MqttInfo
  , Action(..)
  , Task(..)
  ) where

import Http
import Time exposing (Time)

import Chat.Model as M

type alias MqttInfo =
  { host : String
  , port_ : Int
  , clientId : String
  , username : String
  , password : String
  }

type Action
  = ConnectionFormInput (M.ConnectionForm -> M.ConnectionForm)
  | Connect
  | MqttInfoResponse MqttInfo
  | ResponseError Http.Error
  | Connected
  | PostArrived M.Post
  | PostFormInput (M.PostForm -> M.PostForm)
  | Post Time

type Task
  = RequestMqtt
  | MqttConnect MqttInfo
  | MqttSend M.Post
