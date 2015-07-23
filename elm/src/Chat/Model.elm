module Chat.Model
  ( Model(..)
  , NotConnectedState
  , ConnectingState
  , ConnectedState
  , Post
  , ConnectionForm
  , PostForm
  , init
  ) where

import Time exposing (Time)

type Model
  = NotConnected NotConnectedState
  | Connecting ConnectingState
  | Connected ConnectedState

type alias NotConnectedState =
  { form : ConnectionForm
  }

type alias ConnectionForm =
  { name : String
  }

type alias ConnectingState =
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
