port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode 
import Json.Decode.Pipeline as Pipeline
import Http
import List.Extra as List
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (spanishLocale, usLocale)

port loggedIn : (String -> msg) -> Sub msg
port signedOut : (() -> msg) -> Sub msg
port signOut : () -> Cmd msg


type alias Email =
  { id: Maybe Int
  , email: Maybe String
  , createdAt: Maybe String
  , currencyId: Maybe Int
  , currencieId: Maybe Int
  }

emailDecoder : Decoder Email
emailDecoder =
  Decode.succeed Email
    |> Pipeline.required "id" (Decode.maybe Decode.int)
    |> Pipeline.required "email" (Decode.maybe Decode.string)
    |> Pipeline.required "created_at" (Decode.maybe Decode.string)
    |> Pipeline.required "currency_id" (Decode.maybe Decode.int)
    |> Pipeline.required "currencie_id" (Decode.maybe Decode.int)

type alias EmailSaveBody =
  { name : String
  }

emailSaveBodyEncoder : String -> Encode.Value
emailSaveBodyEncoder emailName =
  Encode.object
    [ ( "name", Encode.string emailName ) ]
  

type alias Subscription =
  { id: Maybe Int
  , email_id: Maybe String
  , name: Maybe String
  , cost: Maybe Int
  , intervalId: Maybe Int
  , intervalAmount: Maybe Int
  }

initialSubscription : Subscription
initialSubscription =
  { id = Nothing
  , email_id = Nothing
  , name = Just ""
  , cost = Just 0
  , intervalId = Nothing
  , intervalAmount = Just 0
  }

subscriptionDecoder : Decoder Subscription
subscriptionDecoder =
  Decode.succeed Subscription
    |> Pipeline.required "id" (Decode.maybe Decode.int)
    |> Pipeline.required "email" (Decode.maybe Decode.string)
    |> Pipeline.required "name" (Decode.maybe Decode.string)
    |> Pipeline.required "cost" (Decode.maybe Decode.int)
    |> Pipeline.required "interval_id" (Decode.maybe Decode.int)
    |> Pipeline.required "interval_amount" (Decode.maybe Decode.int)
    

type alias Interval =
  { id: Maybe Int
  , name: Maybe String
  }

intervalDecoder : Decoder Interval
intervalDecoder =
  Decode.succeed Interval 
    |> Pipeline.required "id" (Decode.maybe Decode.int)
    |> Pipeline.required "name" (Decode.maybe Decode.string)
    
type alias Currencie =
  { id: Maybe Int
  , name: Maybe String
  }

currencieDecoder : Decoder Currencie
currencieDecoder =
  Decode.succeed Currencie 
    |> Pipeline.required "id" (Decode.maybe Decode.int)
    |> Pipeline.required "name" (Decode.maybe Decode.string)  

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

type alias Flag =
  { dateInt : Int
  , url : String
  }


main : Program Flag Model Msg
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
  , url : String
  , user  : Maybe UserInfo 
  , currencies : List Currencie
  , intervals : List Interval
  , subscriptions : List Subscription
  , email : Maybe Email
  }


init : Flag -> ( Model, Cmd Msg )
init flags =
  let
    initialModel : Model
    initialModel =
      { currentTime = flags.dateInt
      , url = flags.url
      , user = Nothing
      , intervals = []
      , currencies = []
      , subscriptions = []
      , email = Nothing
      }
  in
  ( initialModel
  , Cmd.batch
      [ fetchIntervals initialModel 
      , fetchCurrencies initialModel
      ]
  )


-- UPDATE

type Msg 
  = NoOp 
  | LoggedIn String
  | SignOut
  | SignedOut ()
  | GotCurrencies (Result Http.Error (List Currencie))
  | GotIntervals (Result Http.Error (List Interval))
  | SelectCurrency String
  | InsertSubscription
  | GotEmail (Result Http.Error Email)

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

        newModel = { model | user = userInfo }
      in
      fetchEmail newModel

    SignOut -> 
      ( model, signOut () )

    SignedOut _ ->
      ( { model | user = Nothing }, Cmd.none )

    GotCurrencies res ->
      case res of
        Ok currencies -> 
          ({ model | currencies = currencies }, Cmd.none) 
        _ ->
          (model, Cmd.none)

    GotIntervals res ->
      case res of
        Ok intervals -> 
          ({ model | intervals = intervals }, Cmd.none) 
        _ ->
          (model, Cmd.none)

    SelectCurrency currencyId ->
      let
        email = model.email
        newEmail = 
          case email of
            Just emailRes ->
              Just { emailRes | currencieId = Just <| Maybe.withDefault 0 (String.toInt currencyId) }

            _ ->
              Nothing
      in
      ( { model | email = newEmail }, Cmd.none )

    InsertSubscription ->
      let
        newSubscriptions = model.subscriptions ++ [ initialSubscription ]  
      in
      ( { model | subscriptions = newSubscriptions }, Cmd.none )

    GotEmail res ->
      case res of
        Ok email ->
          (Debug.log <| Debug.toString res)
          ( model, Cmd.none )

        _ ->
          (Debug.log <| Debug.toString res)
          ( model, Cmd.none  )


-- VIEW

view : Model -> Html Msg
view model =
  div
    [ class "container bg-light shadow p-2 d-flex align-items-center flex-column justify-content-center"
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
            [ h5 [ class "text-center" ] [text <| "Hello, " ++ user.fullName ++ "! (" ++ user.email ++ ")"]
            , div []
                [ img [ class "rounded-pill", src user.imageUrl ] [] ]
            , div []
                [ text <| Debug.toString model.currencies ]
            , div []
                [ text <| Debug.toString model.intervals ]
            , div []
                [ text <| Debug.toString model.email ]
            , div [ class "d-flex align-items-center" ]
                [ div [ class "fw-bold" ] [ text "Currency:" ]
                , select
                    [ class "ml-1 form-select shadow"
                    , onInput SelectCurrency
                    , value 
                        (case model.email of
                          Just email ->
                            String.fromInt <| Maybe.withDefault 0 email.currencieId

                          _ ->
                            "0"
                        )
                    ]
                    ( [ option [] [ text "" ] ]
                      ++
                      (List.map 
                        (\currency -> option [ value <| String.fromInt (Maybe.withDefault 0 currency.id) ] [ text <| Maybe.withDefault "" currency.name ] ) 
                        model.currencies
                      ))
                ]
            , div [ class "my-2" ]
                [ button [ onClick InsertSubscription, class "btn btn-sm btn-primary" ]
                    [ text "Insert" ]
                ]
            , div [ class "my-2" ]
                (List.map
                  (subscriptionCard model)
                  model.subscriptions
                )
            , div [ class "text-center" ]
                [ h4 [] [ text "You pay about:" ]
                , h3 [ class "text-success" ] [ text "5.00 USD monthly" ]
                , h3 [ class "text-success" ] [ text "60.00 USD annualy" ]
                ]
            ]
        _ ->
          div [] []
    -- , div [ class "d-flex justify-content-center text-center bg-primary rounded fw-bold p-2 rounded-lg text-white" ] [ text <| Debug.toString model.user ]
    ]


-- SUBSCRIPTIONS

subscriptionCard : Model -> Subscription -> Html Msg
subscriptionCard model subscription =
  div
    [ class "card shadow p-3 d-flex align-items-center justify-content-center my-2" ]
    [ input 
        [ class "form-control my-1" 
        , placeholder "Subscription name..."
        , value <| Maybe.withDefault "" subscription.name
        ]
        []
    , div
        [ class "d-flex align-items-center my-1" ]
        [ div 
            [ class "fw-bold mx-1" ]
            [ text "For" ]
        , div []
            [ input [ class "mx-1 form-control form-control-sm", placeholder "Price..." ] []
            ]
        , div [ class "mx-1" ]
            [ let
                currencyId =
                  case model.email of
                    Just email ->
                      Maybe.withDefault 0 email.currencieId
                    
                    _ ->
                      0

                foundCurrency =
                  List.find (\currency -> Maybe.withDefault 0 currency.id == currencyId) model.currencies

                actualCurrencyName =
                  case foundCurrency of
                    Just currency ->
                      Maybe.withDefault "" currency.name

                    _ ->
                      ""
              in
              text actualCurrencyName
            ]
        ]
    , div
        [ class "d-flex flex-wrap justify-content-center align-items-center my-1" ]
        [ div
            [ class "fw-bold flex-grow-1" ]
            [ text "Every" ]
        , div
            [ class "mx-1" ]
            [ input 
                [ class "form-control form-control-sm"
                , placeholder "Every..."
                , type_ "number"
                , value <| String.fromInt <| Maybe.withDefault 0 subscription.cost 
                ] 
                [] 
            ]
        , div
            [ class "ml-1 flex-grow-1" ]
            [(select
              [ class "form-select form-select-sm" ]
              (List.map
                (\interval -> option [] [ text <| Maybe.withDefault "" interval.name ] )
                model.intervals
              )
            )]
        ]
    ]

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.batch [
    loggedIn LoggedIn,
    signedOut SignedOut
  ]

fetchIntervals : Model -> Cmd Msg
fetchIntervals model =
  Http.get 
    { url = model.url ++ "/intervals"
    , expect = Http.expectJson GotIntervals (Decode.list intervalDecoder)
    }
    
fetchCurrencies : Model -> Cmd Msg

fetchCurrencies model  =
  Http.get
    { url = model.url ++ "/currencies"
    , expect = Http.expectJson GotCurrencies (Decode.list currencieDecoder )
    }

fetchEmail : Model -> ( Model, Cmd Msg)
fetchEmail model =
  ( { model 
    | email = Just 
        { id = Just 0
        , email =
            (case model.user of
              Just user ->
                Just user.email 
              
              _ ->
                Nothing
            )
        , createdAt = Nothing
        , currencieId = Nothing
        , currencyId = Nothing
        }
    }
  , Http.post
      { url = model.url ++ "/emails/save"
      , body = 
          Http.jsonBody 
            (emailSaveBodyEncoder
              (case model.user of
                Just user ->
                  user.email
                
                _ ->
                  ""
              )
            )
      , expect = Http.expectJson GotEmail emailDecoder
      }
  )