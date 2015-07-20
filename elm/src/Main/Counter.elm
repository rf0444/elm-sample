module Main.Counter where

import Signal exposing (Signal)
import Html exposing (Html)
import StartApp

import Model.Counter as M
import Update.Counter as U
import View.Counter as V

main : Signal Html
main = StartApp.start { model = M.model, view = V.view, update = U.update }
