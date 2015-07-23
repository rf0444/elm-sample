module Chat.Action
  ( Action(..)
  , Task(..)
  ) where

import Http
import Time exposing (Time)

import Chat.Model as M
import Lib.Mqtt as Mqtt

type Action
  = ConnectionFormInput (M.ConnectionForm -> M.ConnectionForm)
  | Connect
  | MqttInfoResponse Mqtt.MqttInfo
  | ResponseError Http.Error
  | Connected
  | MessageArrived String
  | PostFormInput (M.PostForm -> M.PostForm)
  | Post Time

type Task
  = RequestMqtt
  | MqttConnect Mqtt.MqttInfo
  | MqttSend M.Post
