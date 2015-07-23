module Chat.View
  ( view
  ) where

import Date
import Date.Format
import Html
import Html.Attributes as HA
import Html.Events as HE
import Html.Lazy
import Json.Decode as JD
import Time

import Chat.Action as A
import Chat.Model as M

view : Signal.Address A.Action -> M.Model -> Html.Html
view address model =
  let
    children = case model of
      M.NotConnected _ ->
        [ Html.div
          [ HA.class "row" ]
          [ userInput address ]
        ]
      M.Connecting _ ->
        [ Html.div
          [ HA.class "row" ]
          [ Html.text "connecting..." ]
        ]
      M.Connected c ->
        [ Html.div
          [ HA.class "row"
          , HA.style [ ("padding", "0 20px 10px 0") ]
          ]
          [ Html.Lazy.lazy showUser c.name ]
        , Html.div
          [ HA.class "row"
          , HA.style [ ("padding", "10px") ]
          ]
          [ Html.Lazy.lazy2 post address c ]
        , Html.div
          [ HA.class "row"
          , HA.style [ ("padding", "10px") ]
          ]
          [ Html.Lazy.lazy list c.posts ]
        ]
  in
    Html.div [ HA.class "container" ] children

userInput : Signal.Address A.Action -> Html.Html
userInput address =
  Html.div
    [ HA.style
      [ ("display", "flex")
      ]
    ]
    [ Html.div
      [ HA.style
        [ ("flex", "1")
        , ("padding", "0 5px")
        ]
      ]
      [ Html.input
        [ HA.class "form-control"
        , HA.placeholder "Name"
        , HE.on "input" HE.targetValue
          (\x ->
            Signal.message address
              (A.ConnectionFormInput
                (\form ->
                  { form | name <- x }
                )
              )
          )
        ]
        []
      ]
    , Html.div
      [ HA.style
        [ ("width", "100px")
        , ("padding", "0 10px")
        , ("text-align", "center")
        ]
      ]
      [ Html.button
        [ HA.class "btn btn-success"
        , HA.style
          [ ("display", "block")
          , ("width", "100%")
          ]
        , HE.onClick address A.Connect
        ]
        [ Html.text "Connect" ]
      ]
    ]

showUser : String -> Html.Html
showUser name =
  Html.div
    [ HA.style [ ("text-align", "right") ]]
    [ Html.text ("user: " ++ name) ]

post : Signal.Address A.Action -> M.ConnectedState -> Html.Html
post address model =
  Html.div
    [ HA.style
      [ ("display", "flex")
      ]
    ]
    [ Html.div
      [ HA.style
        [ ("flex", "1")
        , ("padding", "0 5px")
        ]
      ]
      [ Html.input
        [ HA.class "form-control"
        , HA.value model.form.content
        , HA.placeholder "Content"
        , HE.on "input" HE.targetValue
          (\x ->
            Signal.message address
              (A.PostFormInput
                (\form ->
                  { form | content <- x }
                )
              )
          )
        ]
        []
      ]
    , Html.div
      [ HA.style
        [ ("width", "100px")
        , ("padding", "0 10px")
        , ("text-align", "center")
        ]
      ]
      [ Html.button
        [ HA.class "btn btn-success"
        , HA.style
          [ ("display", "block")
          , ("width", "100%")
          ]
        , HE.on "click" (JD.at ["timeStamp"] JD.float) (Signal.message address << A.Post)
        ]
        [ Html.text "Post" ]
      ]
    ]

list : List M.Post -> Html.Html
list posts =
  let
    toTr post = Html.tr []
      [ Html.td [] [ Html.text (post.user) ]
      , Html.td [] [ Html.text (post.content) ]
      , Html.td [] [ Html.text (timeToString post.time) ]
      ]
  in
    Html.table
      [ HA.class "table" ]
      [ Html.thead []
        [ Html.th [ HA.style [ ("width", "200px") ] ] [ Html.text "user" ]
        , Html.th [ HA.style [ ("width", "auto" ) ] ] [ Html.text "content" ]
        , Html.th [ HA.style [ ("width", "200px") ] ] [ Html.text "timestamp" ]
        ]
      , Html.tbody [] <| List.map toTr posts
      ]

timeToString : Time.Time -> String
timeToString =
  Date.Format.format "%Y/%m/%d %H:%M:%S" << Date.fromTime
