module Main.Chat where

import Signal exposing (Signal)
import Html exposing (Html)
import StartApp

import Model.Chat as M
import Update.Chat as U
import View.Chat as V

main : Signal Html
main = StartApp.start { model = M.init, view = V.view, update = U.update }
