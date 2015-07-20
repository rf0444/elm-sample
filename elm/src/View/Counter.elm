module View.Counter
  ( view
  ) where

import Signal exposing (Address)
import Html exposing (Html, div, button, text)
import Html.Events exposing (onClick)
import Model.Counter as M
import Update.Counter as U

view : Address U.Action -> M.Model -> Html
view address model =
  div []
    [ button [ onClick address U.Decrement ] [ text "-" ]
    , div [] [ text (toString model) ]
    , button [ onClick address U.Increment ] [ text "+" ]
    ]
