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
import Array
import Debug

port loggedIn : (UserInfo -> msg) -> Sub msg
port signedOut : (() -> msg) -> Sub msg
port signOut : () -> Cmd msg

type RequestStatus
  = NotAsked
  | Loading
  | Error
  | Success

type alias Email =
  { id: Maybe Int
  , email: Maybe String
  , createdAt: Maybe String
  , updatedAt: Maybe String
  , currencyId: Maybe Int
  , currencieId: Maybe Int
  }

emailDecoder : Decoder Email
emailDecoder =
  Decode.succeed Email
    |> Pipeline.required "id" (Decode.maybe Decode.int)
    |> Pipeline.required "email" (Decode.maybe Decode.string)
    |> Pipeline.required "created_at" (Decode.maybe Decode.string)
    |> Pipeline.required "updated_at" (Decode.maybe Decode.string)
    |> Pipeline.required "currency_id" (Decode.maybe Decode.int)
    |> Pipeline.required "currencie_id" (Decode.maybe Decode.int)

emailEncoder : Email -> Encode.Value
emailEncoder email =
  Encode.object
    [ ( "id", (Encode.int) (Maybe.withDefault 0 email.id) )
    , ( "email", (Encode.string) (Maybe.withDefault "" email.email) )
    , ( "created_at", (Encode.string) (Maybe.withDefault "" email.createdAt) )
    , ( "updated_at", (Encode.string) (Maybe.withDefault "" email.updatedAt) )
    , ( "currency_id", (Encode.int) (Maybe.withDefault 0 email.currencyId) )
    , ( "currencie_id", (Encode.int) (Maybe.withDefault 0 email.currencieId) )
    ]

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
  , cost: Maybe Float
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
    |> Pipeline.required "cost" (Decode.maybe Decode.float)
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
    , idToken : String
    }
     
initialUserInfo : UserInfo
initialUserInfo =
  { fullName = ""
  , imageUrl = ""
  , email = ""
  , idToken = ""
  }

userInfoDecoder : Decoder UserInfo
userInfoDecoder =
  Decode.succeed UserInfo
    |> Pipeline.required "fullName" Decode.string
    |> Pipeline.required "imagUrl" Decode.string
    |> Pipeline.required "email" Decode.string
    |> Pipeline.required "idToken" Decode.string

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
  , requestStatus: RequestStatus
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
      , requestStatus = NotAsked
      }
  in
  ( initialModel
  , Cmd.none
  )


-- UPDATE

type Msg 
  = NoOp 
  | LoggedIn UserInfo
  | SignOut
  | SignedOut ()
  | GotCurrencies (Result Http.Error (List Currencie))
  | GotIntervals (Result Http.Error (List Interval))
  | SelectCurrency String
  | InsertSubscription
  | GotEmail (Result Http.Error Email)
  | GotSubscriptions (Result Http.Error (List Subscription))
  | InputSubscriptionName Int String
  | InputSubscriptionPrice Int String
  | InputSubscriptionIntervalAmount Int String
  | InputSubscriptionIntervalId Int String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of 
    NoOp -> 
      ( model, Cmd.none )

    LoggedIn userInfo ->
      let
        newModel = { model | user = Just userInfo }
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

        newModel = { model | requestStatus = Loading, email = newEmail }
      in
      (Debug.log <| Debug.toString <| newEmail)
      saveEmail newModel

    InsertSubscription ->
      let
        newSubscriptions = model.subscriptions ++ [ initialSubscription ]  
      in
      ( { model | subscriptions = newSubscriptions }, Cmd.none )

    GotEmail res ->
      case res of
        Ok email -> 
          (Debug.log <| Debug.toString res)
          fetchEmailSubscriptions { model | email = Just email }

        _ ->
          (Debug.log <| Debug.toString res)
          ( model, Cmd.none  )

    GotSubscriptions res ->
      case res of
        Ok subs ->
          ( { model | subscriptions = subs, requestStatus = Success }, Cmd.none  )
        
        _ ->
          ( { model | requestStatus = Error }, Cmd.none )

    InputSubscriptionName i name ->
      let
        newSubscriptions = 
          List.indexedMap 
            (\ix subscription -> 
              if ix == i then
                { subscription | name = Just name }
              else
                subscription
            )
          model.subscriptions
      in
      ( { model | subscriptions = newSubscriptions }, Cmd.none )
      
    InputSubscriptionPrice i priceString ->
      let
        newSubscriptions =
          List.indexedMap
            (\ix subscription ->
              if ix == i then
                { subscription | cost = Just <| Maybe.withDefault 0.0 (String.toFloat priceString) }
              else
                subscription
            )
          model.subscriptions
      in
      ( { model | subscriptions = newSubscriptions }, Cmd.none )
      
    InputSubscriptionIntervalAmount i amountString ->
      let
        newSubscriptions =
          List.indexedMap
            (\ix subscription ->
              if ix == i then
                { subscription | intervalAmount = Just <| Maybe.withDefault 0 (String.toInt amountString) }
              else
                subscription
            )
            model.subscriptions
      in
      ( { model | subscriptions = newSubscriptions }, Cmd.none )
      
    InputSubscriptionIntervalId i intervalIdString ->
      let
        newSubscriptions =
          List.indexedMap
            (\ix subscription ->
              if ix == i then
                { subscription | intervalId = (String.toInt intervalIdString) }
              else
                subscription
            )
            model.subscriptions
      in
      -- (Debug.log <| Debug.toString intervalIdString)
      ( { model | subscriptions = newSubscriptions }, Cmd.none )

fetchEmailSubscriptions : Model -> ( Model, Cmd Msg )
fetchEmailSubscriptions newModel =
  ( newModel
  , Http.request
    { method = "GET"
    , headers = 
        [ Http.header 
            "authorization" 
            (case newModel.user of
              Just user ->
                user.idToken 
              
              _ ->
                ""
            )
        ]
    , url 
        = newModel.url 
        ++ "/emails/byname/" 
        ++  (case newModel.email of
              Just email ->
                Maybe.withDefault "" email.email

              _ ->
                ""
            )
        ++ "/subscriptions"
    , body = Http.emptyBody
    , expect = Http.expectJson GotSubscriptions (Decode.list subscriptionDecoder)
    , timeout = Nothing
    , tracker = Nothing
    }
  )

-- VIEW

view : Model -> Html Msg
view model =
  let
    currencyId =
        case model.email of
          Just email ->
            Maybe.withDefault 0 email.currencieId
          
          _ ->
            0

    foundCurrency =
      List.find 
        (\currency -> Maybe.withDefault 0 currency.id == currencyId) 
        model.currencies

    actualCurrencyName =
      case foundCurrency of
        Just currency ->
          Maybe.withDefault "" currency.name

        _ ->
          ""

    monthlyPrice =
      List.foldl
        (\subs acc -> acc + Maybe.withDefault 0.0 subs.cost)
        0.0
        model.subscriptions
  in
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
        , case model.user of
            Just user ->
              button [ onClick SignOut, class "btn btn-danger" ] [ text "Logout" ]
            _ ->
              span [] []
        ]
    
    -- , div [] [ text (String.fromInt model.currentTime) ]
    , case model.user of
        Just user ->
          div [ class "d-flex flex-column align-items-center justify-content-center" ]
            [ h5 [ class "text-center" ] [text <| "Hello, " ++ user.fullName ++ "! (" ++ user.email ++ ")"]
            , div []
                [ img [ class "rounded-pill", src user.imageUrl ] [] ]
            -- , div []
            --     [ text <| Debug.toString model.currencies ]
            -- , div []
            --     [ text <| Debug.toString model.intervals ]
            -- , div []
            --     [ text <| Debug.toString model.email ]
            -- , div []
            --     [ text <| Debug.toString model.subscriptions ]
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
                        (\currency -> 
                          option 
                            [ value <| String.fromInt (Maybe.withDefault 0 currency.id) ] 
                            [ text <| Maybe.withDefault "" currency.name ] 
                        ) 
                        model.currencies
                      ))
                ]
            , if model.requestStatus == Loading then
                div [ class "spinner-border", attribute "role" "status" ] 
                  [ span [ class "sr-only" ] [] ]
              else
                div [] []
            , div [ class "my-2" ]
                [ button [ onClick InsertSubscription, class "btn btn-sm btn-primary" ]
                    [ text "Insert" ]
                ]
            , div [ class "my-2" ]
                (List.indexedMap
                  (subscriptionCard model)
                  (model.subscriptions)
                )
            , div [ class "text-center" ]
                [ h4 [] [ text "You pay about:" ]
                , h3 
                    [ class "text-success" ] 
                    [ text <| format spanishLocale monthlyPrice ++ " " ++ actualCurrencyName ++ " monthly" ]
                , div 
                    [ class "fw-bold" ]
                    [ text "or" ]
                , h3 
                    [ class "text-success" ] 
                    [ text <| format spanishLocale (monthlyPrice * 12) ++ " " ++ actualCurrencyName ++ " annualy" ]
                ]
            ]
        _ ->
          div [] []
    -- , div [ class "d-flex justify-content-center text-center bg-primary rounded fw-bold p-2 rounded-lg text-white" ] [ text <| Debug.toString model.user ]
    ]


-- SUBSCRIPTIONS

subscriptionCard : Model -> Int -> Subscription -> Html Msg
subscriptionCard model i subscription =
  let
    currencyId =
      case model.email of
        Just email ->
          Maybe.withDefault 0 email.currencieId
        
        _ ->
          0

    foundCurrency =
      List.find 
        (\currency -> Maybe.withDefault 0 currency.id == currencyId) 
        model.currencies

    actualCurrencyName =
      case foundCurrency of
        Just currency ->
          Maybe.withDefault "" currency.name

        _ ->
          ""
  in
  div
    [ class "card shadow p-3 d-flex align-items-center justify-content-center my-2" ]
    [ 
      -- div [] [ text <| String.fromInt i ]
    input 
        [ class "form-control my-1" 
        , placeholder "Subscription name..."
        , value <| Maybe.withDefault "" subscription.name
        , onInput (InputSubscriptionName i) 
        ]
        []
    , div
        [ class "d-flex align-items-center my-1" ]
        [ div 
            [ class "fw-bold mx-1" ]
            [ text "For" ]
        , div []
            [ input 
                [ class "mx-1 form-control form-control-sm"
                , placeholder "Price..." 
                , onInput (InputSubscriptionPrice i)
                , value <| String.fromFloat (Maybe.withDefault 0  subscription.cost)
                ] []
            ]
        , div [ class "mx-1" ]
            [ text actualCurrencyName ]
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
                , value <| String.fromInt <| Maybe.withDefault 0 subscription.intervalAmount
                , onInput (InputSubscriptionIntervalAmount i)
                ] 
                [] 
            ]
        , div
            [ class "ml-1 flex-grow-1" ]
            [(select
              [ onInput (InputSubscriptionIntervalId i)
              , class "form-select form-select-sm" 
              ]
              
              ( [ option [ value "" ] [ text "" ] ] ++
              (List.map
                (\interval -> 
                  option 
                    [ value <| String.fromInt <| Maybe.withDefault 0 interval.id ]
                    [ text <| Maybe.withDefault "" interval.name ] 
                )
                model.intervals
              ))
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
  Http.request
    { method = "GET"
    , headers = 
        [ Http.header 
            "authorization" 
            (case model.user of
              Just user ->
                user.idToken 
              
              _ ->
                ""
            )
        ]
    , url =  model.url ++ "/intervals"
    , body = Http.emptyBody
    , expect = Http.expectJson GotIntervals (Decode.list intervalDecoder)
    , timeout = Nothing
    , tracker = Nothing
    }
    
fetchCurrencies : Model -> Cmd Msg
fetchCurrencies model  =
  Http.request
    { method = "GET"
    , headers = 
        [ Http.header 
            "authorization" 
            (case model.user of
              Just user ->
                user.idToken 
              
              _ ->
                ""
            )
        ]
    , url = model.url ++ "/currencies"
    , body = Http.emptyBody
    , expect = Http.expectJson GotCurrencies (Decode.list currencieDecoder)
    , timeout = Nothing
    , tracker = Nothing
    }

fetchEmail : Model -> ( Model, Cmd Msg)
fetchEmail model =
  ( { model | requestStatus = Loading }
  , Cmd.batch
      [ fetchIntervals model 
      , fetchCurrencies model
      , Http.request
          { method = "POST"
          , headers = 
              [ Http.header 
                  "authorization" 
                  (case model.user of
                    Just user ->
                      user.idToken 
                    
                    _ ->
                      ""
                  )
              ]
          , url = model.url ++ "/emails/save"
          , body = Http.jsonBody 
              (emailSaveBodyEncoder
                (case model.user of
                  Just user ->
                    user.email
                  
                  _ ->
                    ""
                )
              )
          , expect = Http.expectJson GotEmail emailDecoder
          , timeout = Nothing
          , tracker = Nothing
          }
      ] 
    
  )

saveEmail : Model -> ( Model,  Cmd Msg )
saveEmail model =
  ( model
  , Http.request
    { method = "POST"
    , headers = 
        [ Http.header 
            "authorization" 
            (case model.user of
              Just user ->
                user.idToken 
              
              _ ->
                ""
            )
        ]
    , url = model.url ++ "/emails"
    , body = case model.email of 
        Just email ->
          Http.jsonBody (emailEncoder email)

        _ ->
          Http.emptyBody    
    , expect = Http.expectJson GotEmail emailDecoder
    , timeout = Nothing
    , tracker = Nothing
    }
  )
  