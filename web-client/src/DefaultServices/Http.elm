module DefaultServices.Http exposing (get, handleHttpResult, post)

{- This module is designed to be used with a backend which serves errors back, refer to Models.ApiError to see the
   format of expected errors.
-}

import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Models.ApiError as ApiError


{-| In case of an http error, extracts the ApiError, otherwise extracts the body.
-}
handleHttpResult : (ApiError.ApiError -> b) -> (a -> b) -> Result Http.Error a -> b
handleHttpResult onApiError onApiSuccess httpResult =
    let
        convertToApiError httpError =
            case httpError of
                Http.BadUrl _ ->
                    ApiError.InternalError

                Http.NetworkError ->
                    ApiError.RawNetworkError

                Http.Timeout ->
                    ApiError.RawTimeout

                Http.BadStatus { body } ->
                    case Decode.decodeString ApiError.decoder body of
                        Ok apiError ->
                            apiError

                        Err errorMessage ->
                            ApiError.InternalError

                Http.BadPayload _ _ ->
                    ApiError.UnexpectedPayload
    in
    case httpResult of
        Ok expectedResult ->
            onApiSuccess expectedResult

        Err httpError ->
            onApiError (convertToApiError httpError)


{-| A HTTP get request.

  - Set's `withCredentials` = `True`.

-}
get : String -> Decode.Decoder a -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
get url decoder onApiError onApiSuccess =
    let
        -- Get with credentials.
        get_ : String -> Decode.Decoder a -> Http.Request a
        get_ url_ decoder_ =
            Http.request
                { method = "GET"
                , headers = []
                , url = url_
                , body = Http.emptyBody
                , expect = Http.expectJson decoder_
                , timeout = Nothing
                , withCredentials = True
                }

        httpRequest =
            get_ url decoder
    in
    Http.send (handleHttpResult onApiError onApiSuccess) httpRequest


{-| A HTTP post request.

  - adds a JSON header
  - Set's `withCredentials` = `True`

-}
post : String -> Decode.Decoder a -> Encode.Value -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
post url decoder body onApiError onApiSuccess =
    let
        -- Post with credentials.
        post_ : String -> Http.Body -> Decode.Decoder a -> Http.Request a
        post_ url_ body_ decoder_ =
            Http.request
                { method = "POST"
                , headers = []
                , url = url_
                , body = body_
                , expect = Http.expectJson decoder_
                , timeout = Nothing
                , withCredentials = True
                }

        httpRequest =
            post_ url (Http.jsonBody body) decoder
    in
    Http.send (handleHttpResult onApiError onApiSuccess) httpRequest
