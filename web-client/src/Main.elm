port module Main exposing (main)

import Browser
import Flags exposing (Flags)
import Init exposing (init)
import Model exposing (Model)
import Msg exposing (Msg(..))
import Subscriptions exposing (subscriptions)
import Update exposing (update)
import View exposing (view)


{-| The entry point to the elm application. The navigation module allows us to use the `urlUpdate` field so we can
essentially subscribe to url changes.
-}
main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , onUrlRequest = OnUrlRequest
        , onUrlChange = OnUrlChange
        }
