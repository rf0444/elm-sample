module View.Counter
  ( view
  ) where

import Signal exposing (Address)

import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)

import Model.Counter as M
import Update.Counter as U

view : Address U.Action -> M.Model -> Html
view address model =
  div
    [ style [ ("text-align", "center") ] ]
    [ button
      [ class "btn btn-default"
      , onClick address U.Decrement 
      ]
      [ text "-" ]
    , span
      [ style
        [ ("display", "inline-block")
        , ("width", "40px")
        ]
      ]
      [ text (toString model) ]
    , button
      [ class "btn btn-default"
      , onClick address U.Increment ] [ text "+" ]
    ]
