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
import String
import Maybe
import Iso8601
import Time

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

initialEmail : Email
initialEmail =
  { id = Nothing
  , email = Just ""
  , createdAt = Nothing
  , updatedAt = Nothing
  , currencieId = Nothing
  , currencyId = Nothing
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
  
type alias EmailPostBody =
  { email : Email
  , subscriptions : List Subscription
  , subscriptionDeleteIds: List Int
  } 

emailPostBodyEncoder : Email -> List Subscription -> List Int -> Encode.Value
emailPostBodyEncoder  email subscriptions_list delete_ids =
  Encode.object
    [ ( "email", emailEncoder email )
    , ( "subscriptions", (Encode.list subscriptionEncoder) subscriptions_list )
    , ( "subscription_delete_ids", (Encode.list Encode.int) delete_ids )
    ]

type alias Subscription =
  { id: Maybe Int
  , emailId: Maybe Int
  , name: Maybe String
  , cost: Maybe Float
  , intervalId: Maybe Int
  , intervalAmount: Maybe Int
  , createdAt: Maybe String
  , updatedAt: Maybe String
  , currencieId: Maybe Int
  }

initialSubscription : Subscription
initialSubscription =
  { id = Nothing
  , emailId = Nothing
  , name = Just ""
  , cost = Just 1
  , intervalId = Nothing
  , intervalAmount = Just 1
  , createdAt = Nothing
  , updatedAt = Nothing
  , currencieId = Nothing
  }

subscriptionDecoder : Decoder Subscription
subscriptionDecoder =
  Decode.succeed Subscription
    |> Pipeline.required "id" (Decode.maybe Decode.int)
    |> Pipeline.required "email_id" (Decode.maybe Decode.int)
    |> Pipeline.required "name" (Decode.maybe Decode.string)
    |> Pipeline.required "cost" (Decode.maybe Decode.float)
    |> Pipeline.required "interval_id" (Decode.maybe Decode.int)
    |> Pipeline.required "interval_amount" (Decode.maybe Decode.int)
    |> Pipeline.required "created_at" (Decode.maybe Decode.string)
    |> Pipeline.required "updated_at" (Decode.maybe Decode.string)
    |> Pipeline.required "currencie_id" (Decode.maybe Decode.int)
  
subscriptionEncoder : Subscription -> Encode.Value
subscriptionEncoder subscription =
  Encode.object
    [ ( "id"
      , case subscription.id of
          Just subscriptionId ->
            Encode.int subscriptionId 
          
          _ ->
            Encode.null
      )
    , ( "email_id"
      , case subscription.emailId of
          Just emailId ->
            Encode.int emailId
          
          _ ->
            Encode.null
        )
    , ( "name", Encode.string  (Maybe.withDefault "" subscription.name) )
    , ( "cost", Encode.float  (Maybe.withDefault 0 subscription.cost) )
    , ( "interval_id", Encode.int  (Maybe.withDefault 0 subscription.intervalId) )
    , ( "interval_amount", Encode.int  (Maybe.withDefault 0 subscription.intervalAmount) )
    , ( "created_at"
      , case subscription.createdAt of
          Just createdAt ->
            Encode.string createdAt 
          
          _ ->
            Encode.null
      )
    , ( "updated_at"
      , case subscription.updatedAt of
          Just updatedAt ->
            Encode.string updatedAt
          
          _ ->
            Encode.null
      )
    , ( "currencie_id"
      , case subscription.currencieId of
          Just updatedAt ->
            Encode.int (Maybe.withDefault 0 subscription.currencieId) 
          
          _ ->
            Encode.null
      )
    ]

type alias Interval =
  { id: Maybe Int
  , name: Maybe String
  , createdAt : Maybe String
  , updatedAt : Maybe String
  , modifier : Maybe Float
  }

intervalDecoder : Decoder Interval
intervalDecoder =
  Decode.succeed Interval 
    |> Pipeline.required "id" (Decode.maybe Decode.int)
    |> Pipeline.required "name" (Decode.maybe Decode.string)
    |> Pipeline.required "created_at" (Decode.maybe Decode.string)
    |> Pipeline.required "updated_at" (Decode.maybe Decode.string)
    |> Pipeline.required "modifier" (Decode.maybe Decode.float)
    
type alias Currencie =
  { id: Maybe Int
  , name: Maybe String
  , createdAt: Maybe String
  , updatedAt: Maybe String
  , lastUpdateDay: Maybe String
  , rate: Maybe Float
  }

currencieDecoder : Decoder Currencie
currencieDecoder =
  Decode.succeed Currencie 
    |> Pipeline.required "id" (Decode.maybe Decode.int)
    |> Pipeline.required "name" (Decode.maybe Decode.string)
    |> Pipeline.required "created_at" (Decode.maybe Decode.string)
    |> Pipeline.required "updated_at" (Decode.maybe Decode.string)
    |> Pipeline.required "last_update_day" (Decode.maybe Decode.string)
    |> Pipeline.required "rate" (Decode.maybe Decode.float)

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
  , deleteIds : List Int
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
      , deleteIds = []
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
  | PostedSubscription (Result Http.Error ())
  | CreatedEmailBulk (Result Http.Error String)
  | SelectCurrency String
  | InsertSubscription
  | GotEmail (Result Http.Error Email)
  | GotSubscriptions (Result Http.Error (List Subscription))
  | InputSubscriptionName Int String
  | InputSubscriptionPrice Int String
  | InputSubscriptionIntervalAmount Int String
  | InputSubscriptionIntervalId Int String
  | SaveEmailWithSubscriptions
  | ChangeSubscriptionCurrencie Int String
  | DeleteSubscription Int Subscription

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
      saveEmail newModel

    InsertSubscription ->
      let
        foundInterval =
          List.find
          (\interval ->
            interval.name == Just "Month"
          )
          model.intervals

        newSubscriptions =
          model.subscriptions 
          ++  [ { initialSubscription 
                | currencieId =
                    case model.email of
                      Just email ->
                        email.currencieId

                      _ ->
                        Nothing
                , emailId =
                    case model.email of
                      Just email ->
                        email.id

                      _ ->
                        Nothing
                , intervalId =
                    case foundInterval of
                      Just interval ->
                        interval.id
                      
                      _ ->
                        Nothing
                } 
              ]  
      in
      ( { model | subscriptions = newSubscriptions }, Cmd.none )

    GotEmail res ->
      case res of
        Ok email -> 
          fetchEmailSubscriptions { model | email = Just email }

        _ ->
          ( model, Cmd.none  )

    GotSubscriptions res ->
      case res of
        Ok subs ->
          ( { model | subscriptions = subs, requestStatus = Success }, Cmd.none  )
        
        Err e ->
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
        priceFloat = Maybe.withDefault 1.0 (String.toFloat priceString)
        finalPrice = 
          if priceFloat <= 0 then
            1
          else
            priceFloat

        newSubscriptions =
          List.indexedMap
            (\ix subscription ->
              if ix == i then
                { subscription | cost = Just <| priceFloat }
              else
                subscription
            )
          model.subscriptions
      in
      ( { model | subscriptions = newSubscriptions }, Cmd.none )
      
    InputSubscriptionIntervalAmount i amountString ->
      let
        intervalAmountInt = Maybe.withDefault 1 (String.toInt amountString)
        finalIntervalAmount =
          if intervalAmountInt <= 0 then
            1
          else
            intervalAmountInt

        newSubscriptions =
          List.indexedMap
            (\ix subscription ->
              if ix == i then
                { subscription | intervalAmount = Just <| finalIntervalAmount }
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
      ( { model | subscriptions = newSubscriptions }, Cmd.none )

    PostedSubscription res ->
      case res of
        Ok(_) ->
          ( model, Cmd.none )
          
        _ ->
          ( model, Cmd.none )

    SaveEmailWithSubscriptions ->
      let 
        newModel = { model | requestStatus = Loading }
      in
      saveEmail newModel

    CreatedEmailBulk res ->
      case res of
        Ok _ ->
          ( model, Cmd.none )
        
        _ ->
          ( model, Cmd.none )
      
    ChangeSubscriptionCurrencie i currencieId ->
      let
        newSubscriptions =
          List.indexedMap
            (\ix subscription ->
              if i == ix then
                { subscription | currencieId = String.toInt currencieId }
              else
                subscription
            )
            model.subscriptions

      in
      ( { model | subscriptions = newSubscriptions }, Cmd.none )

    DeleteSubscription i subs ->
      let
        newSubscriptions =
          (Array.toIndexedList <| Array.fromList model.subscriptions)
            |> List.filter
                (\subscriptionTuple ->
                  let
                    (ix, subscription) = subscriptionTuple
                  in
                  ix /= i
                )
            |> List.map (\subscriptionTuple -> Tuple.second subscriptionTuple)
          
        deleteIds = model.deleteIds
        newDeleteIds = deleteIds ++ [ Maybe.withDefault 0 subs.id ]
      in
      ( { model | subscriptions = newSubscriptions, deleteIds = newDeleteIds }, Cmd.none )

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
        (\subs acc -> 
          acc + getSubscriptionMonthlyPrice model.email subs model.currencies model.intervals
        )
        0.0
        model.subscriptions

    lastCurrencyUpdated =
      (List.foldl
        (\currency acc ->
          Maybe.withDefault "" (currency.lastUpdateDay)
        )
        ""
        model.currencies)
      
      ++ "Z"

    lastCurrencyUpdatedPosix =
      Iso8601.toTime <| lastCurrencyUpdated
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
                    ( 
                      (List.map 
                        (\currency -> 
                          option 
                            [ value <| String.fromInt (Maybe.withDefault 0 currency.id) ] 
                            [ text <| Maybe.withDefault "" currency.name ] 
                        ) 
                        model.currencies
                      ))
                ]
            -- , div [] [ text <| "Last update: " ++ lastCurrencyUpdated ]
            -- , div [] 
            --     [ text 
            --         <| "Last update: " 
            --               ++ case (Iso8601.toTime lastCurrencyUpdated) of
            --                   Ok parsedDate ->
            --                     Iso8601.fromTime parsedDate

            --                   _ ->
            --                     "Failed parsing date"
            --     ]
            , case lastCurrencyUpdatedPosix of
                Ok timePosix -> 
                  div [ class "fw-bold fst-italic my-2 text-success" ]
                    [ text 
                        <|  "Last update: "
                              ++ String.fromInt (Time.toDay Time.utc timePosix)
                              ++ " "
                              ++ monthToString (Time.toMonth Time.utc timePosix)
                              ++ " "
                              ++ String.fromInt (Time.toYear Time.utc timePosix) 
                              
                    ]
            
                _ ->
                  div [] []
            , div [ class "fst-italic fw-bold" ] [ text "*1 month = 28 days" ]
            , if model.requestStatus == Loading then 
                div [ class "spinner-border", attribute "role" "status" ] 
                  [ span [ class "sr-only" ] [] ]
              else
                div [] []
            , div [ class "d-flex my-2" ]
                [ div [ class "mx-2" ]
                    [ button [ onClick InsertSubscription, class "btn btn-sm btn-outline-primary" ]
                      [ text "Insert" ]
                    ]
                , div [ class "mx-2" ]
                    [ button [ onClick SaveEmailWithSubscriptions, class "btn btn-sm btn-primary" ]
                      [ text "Save" ]
                    ] 
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
            , hr [ class "border border-secondary text-secondary shadow w-100" ] [ ]
            , div [ class "d-flex flex-column justify-content-center align-items-center" ]
                [ div
                    [ class "fst-italic fw-bold" ] 
                    [ text "Made with the "
                    , a [ href "https://github.com/vmasdani/argems-stack", target "_blank" ]
                        [ text "ARGEMS" ]
                    , text " stack"
                    ]
                ]
            , div [ class "fw-bold fst-italic" ]
                [ text "Buy me diesel "
                , img [ src "/diesel.png", style "width" "25" ] []
                , text " on "
                , a [ href "https://trakteer.id/vmasdani" ] [ text "Trakteer!" ]                
                ]
            ]
        _ ->
          div [] []
    ]


-- SUBSCRIPTIONS

subscriptionCard : Model -> Int -> Subscription -> Html Msg
subscriptionCard model i subscription =
  let
    foundInterval =
      List.find 
        (\interval -> Maybe.withDefault 0 interval.id == Maybe.withDefault 0 subscription.intervalId) 
        model.intervals

    foundCurrency =
      List.find 
        (\currency -> Maybe.withDefault 0 currency.id == Maybe.withDefault 0 subscription.currencieId) 
        model.currencies

    actualCurrencyName =
      case foundCurrency of
        Just currency ->
          Maybe.withDefault "" currency.name

        _ ->
          ""

    foundEmailCurrency =
      List.find 
        (\currency -> 
          Maybe.withDefault 0 currency.id == 
          case model.email of
            Just email ->
              Maybe.withDefault 0 email.currencieId
            
            _ ->
              0
        )
        model.currencies

    actualEmailCurrencyName =
      case foundEmailCurrency of
        Just currency ->
          Maybe.withDefault "" currency.name

        _ ->
          ""
        
    actualIntervalName =
      case foundInterval of
        Just interval ->
          Maybe.withDefault "" interval.name

        _ ->
          ""
    
    currencyIdString = String.fromInt <| Maybe.withDefault 0 subscription.currencieId
  

    finalConversionModifier =
      getFinalConversionRate
        model.currencies
        model.email
        subscription

    finalSubscriptionPrice = 
      getSubscriptionMonthlyPrice 
        model.email
        subscription
        model.currencies
        model.intervals
        
        
  in
  div
    [ class "card shadow p-3 d-flex align-items-center justify-content-center my-2" ]
    [ 
      -- div [] [ text <| String.fromInt <| Maybe.withDefault 0 subscription.emailId ]
      input 
        [ class "form-control my-1 fw-bold" 
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
        , div 
            [ style "width" "75" ]
            [ input
                [ class "mx-1 form-control form-control-sm"
                , placeholder "Price..." 
                , onInput (InputSubscriptionPrice i)
                , value <| String.fromFloat (Maybe.withDefault 0 subscription.cost)
                ] []
            ]
        , div [ class "mx-2" ] [ text <| actualCurrencyName ]
        , div []
            [ select 
                [ class "form-select mx-1 form-select-sm" 
                , value currencyIdString 
                , onInput 
                    <| ChangeSubscriptionCurrencie i
                ]
                (
                  ( List.map
                    (\currency ->
                      option
                        [ value <| String.fromInt <| Maybe.withDefault 0 currency.id ]
                        [ text <| Maybe.withDefault "" currency.name ]
                    )
                    model.currencies
                  )
                )
            ]
        
        ]
    , div
        [ class "d-flex flex-wrap justify-content-center align-items-center my-1" ]
        [ div
            [ class "fw-bold flex-grow-1" ]
            [ text "Every" ]
        , div
            [ class "mx-1", style "width" "75" ]
            [ input 
                [ class "form-control form-control-sm"
                , placeholder "Every..."
                , type_ "number"
                , value <| String.fromInt <| Maybe.withDefault 1 subscription.intervalAmount
                , onInput (InputSubscriptionIntervalAmount i)
                ] 
                [] 
            ]
        , div [ class "mx-1" ] [ text actualIntervalName ]
        , div
            [ class "ml-1 flex-grow-1" ]
            [(select
              [ onInput (InputSubscriptionIntervalId i)
              , value <| String.fromInt <| Maybe.withDefault 0 subscription.intervalId
              , class "form-select form-select-sm" 
              ]
              
              ( 
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
    -- , div [] 
    --     [ text 
    --         <| "Rate diff: " ++ 
    --            String.fromFloat finalConversionModifier
    --     ]
    
        , div [ class "text-primary fw-bold" ]
            [ text <|
                "Final/mo: " ++ 
                format spanishLocale finalSubscriptionPrice ++
                " " ++
                actualEmailCurrencyName
            ]
        , div []
            [ button [ class "btn btn-danger btn-sm", onClick (DeleteSubscription i subscription) ] [ text "Delete" ] ]
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
          , url 
              = model.url 
                ++ "/emails/save-bulk"
          , body = Http.jsonBody (emailPostBodyEncoder (Maybe.withDefault initialEmail model.email) model.subscriptions model.deleteIds )
          , expect = Http.expectJson GotEmail emailDecoder
          , timeout = Nothing
          , tracker = Nothing
          }
  )

getSubscriptionMonthlyPrice : Maybe Email -> Subscription -> List Currencie -> List Interval -> Float
getSubscriptionMonthlyPrice email subs currencies intervals =
  let
    subCost = Maybe.withDefault 0.0 subs.cost
    intervalAmount = Maybe.withDefault 0 subs.intervalAmount
    
    foundInterval =
      List.find
      (\interval -> interval.id == subs.intervalId)
      intervals

    intervalModifier =
      case foundInterval of
        Just intervalRes ->
          Maybe.withDefault 1.0 intervalRes.modifier

        _ ->
          1.0

    -- Currency code
    finalConversionModifier = getFinalConversionRate currencies email subs
     
  in
  subCost / (toFloat intervalAmount) * intervalModifier * finalConversionModifier

getFinalConversionRate : List Currencie -> Maybe Email -> Subscription -> Float
getFinalConversionRate currencies email subs =
  let
    foundSubscriptionCurrency =
      List.find
      (\currency -> currency.id == subs.currencieId)
      currencies

    foundSubscriptionCurrencyRate =
      case foundSubscriptionCurrency of
        Just subscriptionCurrency ->
          Maybe.withDefault 0.0 subscriptionCurrency.rate

        _ ->
          0.0

    foundUserCurrency =
      List.find
      (\currency -> 
        Maybe.withDefault 0 currency.id == 
        case email of
          Just emailRes ->
            Maybe.withDefault 0 emailRes.currencieId

          _ ->
            0      
      )
      currencies

    foundUserCurrencyRate =
      case foundUserCurrency of
        Just userCurrency ->
          Maybe.withDefault 0.0 userCurrency.rate

        _ ->
          0.0

    finalConversionModifier = foundUserCurrencyRate / foundSubscriptionCurrencyRate
  in
  finalConversionModifier

monthToString month =
  case month of
    Time.Jan -> "Jan"
    Time.Feb -> "Feb"
    Time.Mar -> "Mar"
    Time.Apr -> "Apr"
    Time.May -> "May"
    Time.Jun -> "Jun"
    Time.Jul -> "Jul"
    Time.Aug -> "Aug"
    Time.Sep -> "Sep"
    Time.Oct -> "Oct"
    Time.Nov -> "Nov"
    Time.Dec -> "Dec"
    