port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline

port loggedIn : (String -> msg) -> Sub msg
port signedOut : (() -> msg) -> Sub msg
port signOut : () -> Cmd msg

type alias UserInfo =
    { fullName : String
    , imageUrl : String
    , email : String
    }

initialUserInfo : UserInfo
initialUserInfo =
   { fullName = ""
    , imageUrl = ""
    , email = ""
   }

userInfoDecoder : Decoder UserInfo
userInfoDecoder =
  Decode.succeed UserInfo
    |> Pipeline.required "Ad" Decode.string
    |> Pipeline.required "iK" Decode.string
    |> Pipeline.required "du" Decode.string 

type alias GoogleUser =
    { user : UserInfo
    }


googleUserDecoder : Decoder GoogleUser
googleUserDecoder  =
  Decode.succeed GoogleUser
    |> Pipeline.required "xt" userInfoDecoder

-- MAIN

main : Program Int Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL

type alias Model = 
  { currentTime : Int
  , user  : Maybe UserInfo 
  }

init : Int -> ( Model, Cmd Msg )
init currentTime =
  ( { currentTime = currentTime 
    , user = Nothing
    }
  , Cmd.none
  )


-- UPDATE

type Msg 
  = NoOp 
  | LoggedIn String
  | SignOut
  | SignedOut ()

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of 
    NoOp -> 
      ( model, Cmd.none )

    LoggedIn loginInfo ->
      let
        decodedUser = Decode.decodeString userInfoDecoder loginInfo

        userInfo =
          case decodedUser of
            Ok user ->
              Just user
            _ ->
              Nothing
      in
      (Debug.log (Debug.toString decodedUser))

      -- (Debug.log loginInfo)
      ( { model | user = userInfo  }, Cmd.none )

    SignOut -> 
      ( model, signOut () )

    SignedOut _ ->
      ( { model | user = Nothing }, Cmd.none )


-- VIEW

view : Model -> Html Msg
view model =
  div
    [ class "container bg-light shadow p-2 d-flex align-items-center flex-column justify-items-center"
    ]
    [ div []
        [ h2 [] [ text "Monty" ]
        ]
    , div [ class "fst-italic" ]
        [ text "Monthly subscription price calculator" ]
      
    , div [ class "d-flex my-2" ]
        [ div [ class "g-signin2", attribute "data-onsuccess" "onSignIn" ] []
        , button [ onClick SignOut, class "btn btn-danger" ] [ text "Logout" ]
        ]
    
    -- , div [] [ text (String.fromInt model.currentTime) ]
    , case model.user of
        Just user ->
          div [ class "d-flex flex-column align-items-center justify-content-center" ]
            [ h5 [ ] [text <| "Hello, " ++ user.fullName ++ "! (" ++ user.email ++ ")"]
            , div []
                [ img [ class "rounded-pill", src user.imageUrl ] [] ]
            , div [ class "my-2" ]
                [ table [ class "table rounded rounded-lg table-sm table-bordered border-info shadow" ]
                    [ thead [] 
                      [ tr [ class "table-primary" ]
                          [ th [] [text "Name"]
                          , th [] [text "Price ()"]
                          , th [] [text "Interval"]
                          ]
                      ]
                    , tbody []
                        [ tr []
                            [ td [] [ text "Name" ]
                            , td [] [ text "Price" ]
                            , td [] [ text "Interval" ] 
                            ]
                        ]
                    ]
                ]
            , div [ class "text-center" ]
                [ h4 [] [ text "You pay about:" ]
                , h3 [ class "text-success" ] [ text "5.00 USD monthly" ]
                , h3 [ class "text-success" ] [ text "60.00 USD annualy" ]
                ]
            ]
        _ ->
          div [] []
    , div [ class "d-flex justify-content-center text-center bg-primary rounded fw-bold p-2 rounded-lg text-white" ] [ text <| Debug.toString model.user ]
    
    ]


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.batch [
    loggedIn LoggedIn,
    signedOut SignedOut
  ]