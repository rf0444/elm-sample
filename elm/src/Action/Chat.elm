module Action.Chat
  ( Action(..)
  ) where

import Http
import Time exposing (Time)

import Lib.Mqtt as Mqtt
import Model.Chat as M

type Action
  = ConnectionFormInput (M.ConnectionForm -> M.ConnectionForm)
  | Connect
  | MqttInfoResponse Mqtt.MqttInfo
  | ResponseError Http.Error
  | Connected
  | MessageArrived String
  | PostFormInput (M.PostForm -> M.PostForm)
  | Post Time
