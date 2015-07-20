module Model.Chat
  ( Model(..)
  , NotConnectedState
  , ConnectedState
  , Post
  , ConnectionForm
  , PostForm
  , init
  ) where

import Time exposing (Time)

type Model
  = NotConnected NotConnectedState
  | Connected ConnectedState

type alias NotConnectedState =
  { form : ConnectionForm
  }

type alias ConnectionForm =
  { name : String
  }

type alias ConnectedState =
  { name : String
  , form : PostForm
  , posts : List Post
  }

type alias PostForm =
  { content : String
  }

type alias Post =
  { user : String
  , time : Time
  , content : String
  }

init : Model
init = NotConnected
  { form =
    { name = ""
    }
  }
