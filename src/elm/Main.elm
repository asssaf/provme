port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, field, int, string)
import Json.Encode as Encode
import Process
import Random
import Svg
import Svg.Attributes as SvgAttr
import Task
import Time



-- TYPES & MODELS

type alias SSHConfig =
    { user : String
    , port_ : Int
    , hostKey : String
    }

type alias Client =
    { clientId : String
    , ip : String
    , ssh : SSHConfig
    , createdAt : String
    }

type ToastType
    = Success
    | Error
    | Info

type alias Toast =
    { id : Int
    , message : String
    , type_ : ToastType
    }

type alias Model =
    { registrations : List Client
    , searchQuery : String
    , autoRefresh : Bool
    , keyModal : Maybe String
    , toasts : List Toast
    , nextToastId : Int
    , lastActivity : String
    , isRefreshing : Bool
    }


-- PORTS

port copyToClipboard : String -> Cmd msg
port copiedFeedback : (Bool -> msg) -> Sub msg


-- INITIALIZATION

init : () -> ( Model, Cmd Msg )
init _ =
    ( { registrations = []
      , searchQuery = ""
      , autoRefresh = True
      , keyModal = Nothing
      , toasts = []
      , nextToastId = 1
      , lastActivity = "Never"
      , isRefreshing = False
      }
    , fetchDataCmd
    )


-- MESSAGES

type Msg
    = FetchData
    | FetchedData (Result Http.Error (List Client))
    | SearchChanged String
    | AutoRefreshToggled
    | Tick Time.Posix
    | TriggerSimulation
    | SimulatePayload MockPayload
    | Registered (Result Http.Error Client)
    | DeleteClient String
    | Deleted String (Result Http.Error String)
    | OpenKeyModal String
    | CloseModal
    | DismissToast Int
    | CopyText String
    | CopiedFeedback Bool
    | NoOp


-- HTTP COMMANDS

fetchDataCmd : Cmd Msg
fetchDataCmd =
    Http.get
        { url = "/v1/registrations"
        , expect = Http.expectJson FetchedData (Decode.list clientDecoder)
        }

deleteClientCmd : String -> Cmd Msg
deleteClientCmd clientId =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = "/v1/registrations/" ++ clientId
        , body = Http.emptyBody
        , expect = Http.expectJson (Deleted clientId) (Decode.field "message" string)
        , timeout = Nothing
        , tracker = Nothing
        }

registerMockCmd : MockPayload -> Cmd Msg
registerMockCmd payload =
    Http.post
        { url = "/v1/register"
        , body = Http.jsonBody (encodeMockPayload payload)
        , expect = Http.expectJson Registered clientDecoder
        }


-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchData ->
            ( { model | isRefreshing = True }, fetchDataCmd )

        FetchedData result ->
            case result of
                Ok data ->
                    let
                        sorted =
                            List.sortWith (\a b -> compare b.createdAt a.createdAt) data

                        lastAct =
                            case List.head sorted of
                                Just c ->
                                    c.createdAt

                                Nothing ->
                                    model.lastActivity
                    in
                    ( { model | registrations = sorted, isRefreshing = False, lastActivity = lastAct }, Cmd.none )

                Err _ ->
                    let
                        ( newModel, cmd ) =
                            addToast "Connection to server failed" Error model
                    in
                    ( { newModel | isRefreshing = False }, cmd )

        SearchChanged query ->
            ( { model | searchQuery = query }, Cmd.none )

        AutoRefreshToggled ->
            ( { model | autoRefresh = not model.autoRefresh }, Cmd.none )

        Tick _ ->
            if model.autoRefresh then
                ( model, fetchDataCmd )
            else
                ( model, Cmd.none )

        TriggerSimulation ->
            ( model, Random.generate SimulatePayload mockPayloadGenerator )

        SimulatePayload payload ->
            ( model, registerMockCmd payload )

        Registered result ->
            case result of
                Ok _ ->
                    let
                        ( newModel, cmd ) =
                            addToast "Simulation: Registered new client" Success model
                    in
                    ( newModel, Cmd.batch [ cmd, fetchDataCmd ] )

                Err _ ->
                    let
                        ( newModel, cmd ) =
                            addToast "Failed to simulate registration" Error model
                    in
                    ( newModel, cmd )

        DeleteClient clientId ->
            ( model, deleteClientCmd clientId )

        Deleted clientId result ->
            case result of
                Ok _ ->
                    let
                        ( newModel, cmd ) =
                            addToast "Client deregistered successfully" Success model
                    in
                    ( newModel, Cmd.batch [ cmd, fetchDataCmd ] )

                Err _ ->
                    let
                        ( newModel, cmd ) =
                            addToast "Failed to delete client" Error model
                    in
                    ( newModel, cmd )

        OpenKeyModal key ->
            ( { model | keyModal = Just key }, Cmd.none )

        CloseModal ->
            ( { model | keyModal = Nothing }, Cmd.none )

        DismissToast toastId ->
            ( { model | toasts = List.filter (\t -> t.id /= toastId) model.toasts }, Cmd.none )

        CopyText text ->
            ( model, copyToClipboard text )

        CopiedFeedback _ ->
            let
                ( newModel, cmd ) =
                    addToast "Copied to clipboard!" Success model
            in
            ( newModel, cmd )

        NoOp ->
            ( model, Cmd.none )


-- TOAST HELPER

addToast : String -> ToastType -> Model -> ( Model, Cmd Msg )
addToast message type_ model =
    let
        toastId =
            model.nextToastId

        newToast =
            { id = toastId, message = message, type_ = type_ }

        dismissCmd =
            Process.sleep 3000
                |> Task.perform (\_ -> DismissToast toastId)
    in
    ( { model
        | toasts = model.toasts ++ [ newToast ]
        , nextToastId = toastId + 1
      }
    , dismissCmd
    )


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every 5000 Tick
        , copiedFeedback CopiedFeedback
        ]


-- VIEW

view : Model -> Html Msg
view model =
    let
        filteredClients =
            List.filter (filterClient model.searchQuery) model.registrations

        uniqueIps =
            List.map .ip model.registrations
                |> uniqueList
                |> List.length

        lastActText =
            if model.lastActivity == "Never" then
                "Never"

            else
                formatTimeStr model.lastActivity
    in
    div [ class "container" ]
        [ -- Header
          header []
            [ div [ class "logo-section" ]
                [ div [ class "logo-icon" ]
                    [ svgLogo ]
                , div [ class "title-group" ]
                    [ h1 [] [ text "PROVME Admin" ]
                    , p [] [ text "Client Registration Management Portal (Elm Version)" ]
                    ]
                ]
            , div [ class "status-badge" ]
                [ span [ class "status-dot" ] []
                , span [] [ text "System Operational" ]
                ]
            ]
        , -- Stats Grid
          div [ class "stats-grid" ]
            [ statCard "Total Clients" (String.fromInt (List.length model.registrations)) "Registered in-memory" "var(--primary)" totalClientsIcon
            , statCard "Unique IPs" (String.fromInt uniqueIps) "Distinct client locations" "var(--cyan)" uniqueIpsIcon
            , statCard "Last Activity" lastActText "Latest registration event" "var(--emerald)" lastActivityIcon
            ]
        , -- Controls Toolbar
          div [ class "controls-row" ]
            [ div [ class "search-wrapper" ]
                [ span [ class "search-icon" ] [ searchIcon ]
                , input
                    [ type_ "text"
                    , class "search-input"
                    , placeholder "Search by Client ID, IP, SSH user..."
                    , value model.searchQuery
                    , onInput SearchChanged
                    ]
                    []
                ]
            , div [ class "actions-group" ]
                [ div [ class "refresh-toggle-container" ]
                    [ span [] [ text "Auto-refresh" ]
                    , label [ class "switch" ]
                        [ input
                            [ type_ "checkbox"
                            , checked model.autoRefresh
                            , onCheck (\_ -> AutoRefreshToggled)
                            ]
                            []
                        , span [ class "slider" ] []
                        ]
                    ]
                , button
                    [ classList [ ( "btn", True ), ( "btn-secondary", True ), ( "btn-icon-only", True ), ( "rotating", model.isRefreshing ) ]
                    , title "Refresh Now"
                    , onClick FetchData
                    ]
                    [ refreshIcon ]
                , button
                    [ class "btn btn-primary"
                    , onClick TriggerSimulation
                    ]
                    [ simulateIcon
                    , text "Simulate Registration"
                    ]
                ]
            ]
        , -- Table
          div [ class "table-container" ]
            [ table [ id "clients-table" ]
                [ thead []
                    [ tr []
                        [ th [] [ text "Client ID" ]
                        , th [] [ text "IP Address" ]
                        , th [] [ text "SSH Access" ]
                        , th [] [ text "Host Key Preview" ]
                        , th [] [ text "Registered At" ]
                        , th [ style "text-align" "right" ] [ text "Actions" ]
                        ]
                    ]
                , tbody [] (List.map viewClientRow filteredClients)
                ]
            , if List.isEmpty filteredClients then
                viewEmptyState

              else
                text ""
            ]
        , -- Modal
          case model.keyModal of
            Just key ->
                viewKeyModal key

            Nothing ->
                text ""
        , -- Toasts
          div [ class "toast-container" ] (List.map viewToast model.toasts)
        ]


-- VIEW HELPERS

statCard : String -> String -> String -> String -> Html Msg -> Html Msg
statCard titleText val desc color icon =
    div [ class "stat-card", style "--card-accent" color ]
        [ div [ class "stat-info" ]
            [ h3 [] [ text titleText ]
            , div [ class "stat-value" ] [ text val ]
            , div [ class "stat-desc" ] [ text desc ]
            ]
        , div [ class "stat-icon-wrapper" ] [ icon ]
        ]

viewClientRow : Client -> Html Msg
viewClientRow client =
    let
        shortId =
            if String.length client.clientId > 8 then
                String.left 8 client.clientId ++ "..."

            else
                client.clientId
    in
    tr [ id ("row-" ++ client.clientId) ]
        [ td []
            [ div [ class "td-client-id" ]
                [ span [ class "client-id-text", title client.clientId ] [ text shortId ]
                , button [ class "copy-btn", title "Copy Client ID", onClick (CopyText client.clientId) ] [ copyIcon ]
                ]
            ]
        , td []
            [ span [ class "td-ip" ] [ text client.ip ]
            ]
        , td []
            [ span [ class "ssh-badge-user" ] [ text client.ssh.user ]
            , span [ class "ssh-badge-port" ] [ text (":" ++ String.fromInt client.ssh.port_) ]
            ]
        , td []
            [ span [ class "key-preview", title client.ssh.hostKey ] [ text client.ssh.hostKey ]
            , button [ class "key-action-btn", onClick (OpenKeyModal client.ssh.hostKey) ] [ text "View Key" ]
            ]
        , td []
            [ span [ class "time-text", title client.createdAt ] [ text (formatTimeStr client.createdAt) ]
            ]
        , td [ style "text-align" "right" ]
            [ button [ class "btn-danger-link", title "Deregister Client", onClick (DeleteClient client.clientId) ] [ deleteIcon ]
            ]
        ]

viewEmptyState : Html Msg
viewEmptyState =
    div [ id "empty-state-view", class "empty-state" ]
        [ div [ class "empty-icon" ]
            [ Svg.svg
                [ SvgAttr.viewBox "0 0 24 24"
                , SvgAttr.fill "none"
                , SvgAttr.stroke "currentColor"
                , SvgAttr.strokeWidth "2"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                [ Svg.path [ SvgAttr.d "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" ] []
                , Svg.circle [ SvgAttr.cx "9", SvgAttr.cy "7", SvgAttr.r "4" ] []
                , Svg.path [ SvgAttr.d "M23 21v-2a4 4 0 0 0-3-3.87" ] []
                , Svg.path [ SvgAttr.d "M16 3.13a4 4 0 0 1 0 7.75" ] []
                ]
            ]
        , h3 [] [ text "No registered clients" ]
        , p [] [ text "Use the simulator button above or send a POST request to /v1/register to register new devices." ]
        ]


viewKeyModal : String -> Html Msg
viewKeyModal key =
    div [ id "key-modal", class "modal-overlay open", onClick CloseModal ]
        [ div [ class "modal", stopPropagationOnClick ]
            [ div [ class "modal-header" ]
                [ h3 [] [ text "SSH Host Key Details" ]
                , button [ class "modal-close", id "modal-close-btn", onClick CloseModal ]
                    [ Svg.svg
                        [ SvgAttr.viewBox "0 0 24 24"
                        , SvgAttr.fill "none"
                        , SvgAttr.stroke "currentColor"
                        , SvgAttr.strokeWidth "2"
                        , SvgAttr.strokeLinecap "round"
                        , SvgAttr.strokeLinejoin "round"
                        ]
                        [ Svg.line [ SvgAttr.x1 "18", SvgAttr.y1 "6", SvgAttr.x2 "6", SvgAttr.y2 "18" ] []
                        , Svg.line [ SvgAttr.x1 "6", SvgAttr.y1 "6", SvgAttr.x2 "18", SvgAttr.y2 "18" ] []
                        ]
                    ]
                ]
            , div [ class "modal-body" ]
                [ p [ style "font-size" "0.85rem", style "color" "var(--text-secondary)", style "margin-bottom" "0.75rem" ]
                    [ text "Full host key for this registration:" ]
                , div [ class "key-textarea-wrapper" ]
                    [ div [ id "modal-key-content", class "key-text-box" ] [ text key ]
                    ]
                ]
            , div [ class "modal-footer" ]
                [ button [ class "btn btn-secondary", id "modal-cancel-btn", onClick CloseModal ] [ text "Close" ]
                , button [ class "btn btn-primary", id "modal-copy-btn", onClick (CopyText key) ]
                    [ Svg.svg
                        [ SvgAttr.viewBox "0 0 24 24"
                        , SvgAttr.fill "none"
                        , SvgAttr.stroke "currentColor"
                        , SvgAttr.strokeWidth "2"
                        , SvgAttr.strokeLinecap "round"
                        , SvgAttr.strokeLinejoin "round"
                        , style "width" "16px"
                        , style "height" "16px"
                        ]
                        [ Svg.rect [ SvgAttr.x "9", SvgAttr.y "9", SvgAttr.width "13", SvgAttr.height "13", SvgAttr.rx "2", SvgAttr.ry "2" ] []
                        , Svg.path [ SvgAttr.d "M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" ] []
                        ]
                    , text " Copy Key"
                    ]
                ]
            ]
        ]


viewToast : Toast -> Html Msg
viewToast toast =
    let
        toastClass =
            case toast.type_ of
                Success ->
                    "toast toast-success show"

                Error ->
                    "toast toast-error show"

                Info ->
                    "toast toast-info show"

        iconSvg =
            case toast.type_ of
                Success ->
                    Svg.svg
                        [ SvgAttr.viewBox "0 0 24 24"
                        , SvgAttr.fill "none"
                        , SvgAttr.stroke "currentColor"
                        , SvgAttr.strokeWidth "2.5"
                        , style "width" "14px"
                        , style "height" "14px"
                        ]
                        [ Svg.polyline [ SvgAttr.points "20 6 9 17 4 12" ] [] ]

                _ ->
                    Svg.svg
                        [ SvgAttr.viewBox "0 0 24 24"
                        , SvgAttr.fill "none"
                        , SvgAttr.stroke "currentColor"
                        , SvgAttr.strokeWidth "2.5"
                        , style "width" "14px"
                        , style "height" "14px"
                        ]
                        [ Svg.line [ SvgAttr.x1 "18", SvgAttr.y1 "6", SvgAttr.x2 "6", SvgAttr.y2 "18" ] []
                        , Svg.line [ SvgAttr.x1 "6", SvgAttr.y1 "6", SvgAttr.x2 "18", SvgAttr.y2 "18" ] []
                        ]
    in
    div [ class toastClass ]
        [ div [ class "toast-icon" ] [ iconSvg ]
        , div [ class "toast-message" ] [ text toast.message ]
        ]


-- SVG ICON HELPERS

svgLogo : Html Msg
svgLogo =
    Svg.svg
        [ SvgAttr.viewBox "0 0 24 24" ]
        [ Svg.path [ SvgAttr.d "M12 2L2 22h20L12 2zm0 3.99L19.53 19H4.47L12 5.99zM13 16h-2v2h2v-2zm0-6h-2v4h2v-4z" ] [] ]


totalClientsIcon : Html Msg
totalClientsIcon =
    Svg.svg
        [ SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "2"
        , SvgAttr.strokeLinecap "round"
        , SvgAttr.strokeLinejoin "round"
        ]
        [ Svg.path [ SvgAttr.d "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" ] []
        , Svg.circle [ SvgAttr.cx "9", SvgAttr.cy "7", SvgAttr.r "4" ] []
        , Svg.path [ SvgAttr.d "M23 21v-2a4 4 0 0 0-3-3.87" ] []
        , Svg.path [ SvgAttr.d "M16 3.13a4 4 0 0 1 0 7.75" ] []
        ]


uniqueIpsIcon : Html Msg
uniqueIpsIcon =
    Svg.svg
        [ SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "2"
        , SvgAttr.strokeLinecap "round"
        , SvgAttr.strokeLinejoin "round"
        ]
        [ Svg.rect [ SvgAttr.x "2", SvgAttr.y "2", SvgAttr.width "20", SvgAttr.height "8", SvgAttr.rx "2", SvgAttr.ry "2" ] []
        , Svg.rect [ SvgAttr.x "2", SvgAttr.y "14", SvgAttr.width "20", SvgAttr.height "8", SvgAttr.rx "2", SvgAttr.ry "2" ] []
        , Svg.line [ SvgAttr.x1 "6", SvgAttr.y1 "6", SvgAttr.x2 "6.01", SvgAttr.y2 "6" ] []
        , Svg.line [ SvgAttr.x1 "6", SvgAttr.y1 "18", SvgAttr.x2 "6.01", SvgAttr.y2 "18" ] []
        ]


lastActivityIcon : Html Msg
lastActivityIcon =
    Svg.svg
        [ SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "2"
        , SvgAttr.strokeLinecap "round"
        , SvgAttr.strokeLinejoin "round"
        ]
        [ Svg.circle [ SvgAttr.cx "12", SvgAttr.cy "12", SvgAttr.r "10" ] []
        , Svg.polyline [ SvgAttr.points "12 6 12 12 16 14" ] []
        ]


searchIcon : Html Msg
searchIcon =
    Svg.svg
        [ SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "2"
        , SvgAttr.strokeLinecap "round"
        , SvgAttr.strokeLinejoin "round"
        ]
        [ Svg.circle [ SvgAttr.cx "11", SvgAttr.cy "11", SvgAttr.r "8" ] []
        , Svg.line [ SvgAttr.x1 "21", SvgAttr.y1 "21", SvgAttr.x2 "16.65", SvgAttr.y2 "16.65" ] []
        ]


refreshIcon : Html Msg
refreshIcon =
    Svg.svg
        [ SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "2"
        , SvgAttr.strokeLinecap "round"
        , SvgAttr.strokeLinejoin "round"
        , style "width" "18px"
        , style "height" "18px"
        ]
        [ Svg.polyline [ SvgAttr.points "23 4 23 10 17 10" ] []
        , Svg.polyline [ SvgAttr.points "1 20 1 14 7 14" ] []
        , Svg.path [ SvgAttr.d "M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" ] []
        ]


simulateIcon : Html Msg
simulateIcon =
    Svg.svg
        [ SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "2"
        , SvgAttr.strokeLinecap "round"
        , SvgAttr.strokeLinejoin "round"
        , style "width" "18px"
        , style "height" "18px"
        ]
        [ Svg.path [ SvgAttr.d "M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" ] []
        , Svg.polyline [ SvgAttr.points "14 2 14 8 20 8" ] []
        , Svg.line [ SvgAttr.x1 "12", SvgAttr.y1 "18", SvgAttr.x2 "12", SvgAttr.y2 "12" ] []
        , Svg.line [ SvgAttr.x1 "9", SvgAttr.y1 "15", SvgAttr.x2 "15", SvgAttr.y2 "15" ] []
        ]


copyIcon : Html Msg
copyIcon =
    Svg.svg
        [ SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "2"
        , SvgAttr.strokeLinecap "round"
        , SvgAttr.strokeLinejoin "round"
        , style "width" "14px"
        , style "height" "14px"
        ]
        [ Svg.rect [ SvgAttr.x "9", SvgAttr.y "9", SvgAttr.width "13", SvgAttr.height "13", SvgAttr.rx "2", SvgAttr.ry "2" ] []
        , Svg.path [ SvgAttr.d "M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" ] []
        ]


deleteIcon : Html Msg
deleteIcon =
    Svg.svg
        [ SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.strokeWidth "2"
        , SvgAttr.strokeLinecap "round"
        , SvgAttr.strokeLinejoin "round"
        , style "width" "16px"
        , style "height" "16px"
        ]
        [ Svg.polyline [ SvgAttr.points "3 6 5 6 21 6" ] []
        , Svg.path [ SvgAttr.d "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" ] []
        , Svg.line [ SvgAttr.x1 "10", SvgAttr.y1 "11", SvgAttr.x2 "10", SvgAttr.y2 "17" ] []
        , Svg.line [ SvgAttr.x1 "14", SvgAttr.y1 "11", SvgAttr.x2 "14", SvgAttr.y2 "17" ] []
        ]


-- MISC HELPERS

filterClient : String -> Client -> Bool
filterClient query client =
    if String.isEmpty query then
        True

    else
        let
            q =
                String.toLower query
        in
        String.contains q (String.toLower client.clientId)
            || String.contains q client.ip
            || String.contains q (String.toLower client.ssh.user)
            || String.contains q (String.toLower client.ssh.hostKey)

uniqueList : List a -> List a
uniqueList list =
    let
        helper x acc =
            if List.member x acc then
                acc

            else
                acc ++ [ x ]
    in
    List.foldl helper [] list

formatTimeStr : String -> String
formatTimeStr iso =
    let
        parts =
            String.split "T" iso

        date =
            Maybe.withDefault "" (List.head parts)

        timeFull =
            Maybe.withDefault "" (List.head (List.drop 1 parts))

        time =
            Maybe.withDefault "" (List.head (String.split "." timeFull))

        cleanTime =
            String.replace "Z" "" time
    in
    if String.isEmpty date then
        iso

    else
        date ++ " " ++ cleanTime

stopPropagationOnClick : Attribute Msg
stopPropagationOnClick =
    Html.Events.custom "click"
        (Decode.succeed
            { message = NoOp
            , stopPropagation = True
            , preventDefault = False
            }
        )


-- SIMULATION GENERATORS

type alias MockPayload =
    { clientId : String
    , ip : String
    , ssh : SSHConfig
    }

mockPayloadGenerator : Random.Generator MockPayload
mockPayloadGenerator =
    Random.map5 (\uuid ip user port_ hostKey -> MockPayload uuid ip (SSHConfig user port_ hostKey))
        uuidGenerator
        ipGenerator
        userGenerator
        portGenerator
        hostKeyGenerator

uuidGenerator : Random.Generator String
uuidGenerator =
    let
        hexDigit =
            Random.map (\n -> String.fromChar (hexChar n)) (Random.int 0 15)

        hexString len =
            Random.list len hexDigit |> Random.map String.concat
    in
    Random.map5 (\a b c d e -> String.concat [ a, "-", b, "-", c, "-", d, "-", e ])
        (hexString 8)
        (hexString 4)
        (hexString 4)
        (hexString 4)
        (hexString 12)

hexChar : Int -> Char
hexChar n =
    if n < 10 then
        Char.fromCode (48 + n)

    else
        Char.fromCode (97 + n - 10)

ipGenerator : Random.Generator String
ipGenerator =
    Random.map4 (\a b c d -> String.concat [ String.fromInt a, ".", String.fromInt b, ".", String.fromInt c, ".", String.fromInt d ])
        (Random.int 10 220)
        (Random.int 0 255)
        (Random.int 0 255)
        (Random.int 1 254)

userGenerator : Random.Generator String
userGenerator =
    let
        users =
            [ "ubuntu", "admin", "root", "ec2-user", "debian", "alpine" ]

        userFromIndex idx =
            Maybe.withDefault "ubuntu" (List.head (List.drop idx users))
    in
    Random.map userFromIndex (Random.int 0 (List.length users - 1))

portGenerator : Random.Generator Int
portGenerator =
    let
        ports =
            [ 22, 22, 22, 2222, 8022 ]

        portFromIndex idx =
            Maybe.withDefault 22 (List.head (List.drop idx ports))
    in
    Random.map portFromIndex (Random.int 0 (List.length ports - 1))

hostKeyGenerator : Random.Generator String
hostKeyGenerator =
    let
        keyTypes =
            [ "ssh-ed25519", "ssh-rsa", "ecdsa-sha2-nistp256" ]

        keyTypeFromIndex idx =
            Maybe.withDefault "ssh-ed25519" (List.head (List.drop idx keyTypes))

        chars =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

        charFromIndex idx =
            Maybe.withDefault 'A' (List.head (List.drop idx (String.toList chars)))

        randomChar =
            Random.map charFromIndex (Random.int 0 (String.length chars - 1))

        randomKeyBody =
            Random.list 60 randomChar |> Random.map String.fromList
    in
    Random.map2 (\keyType body -> keyType ++ " AAAAC3NzaC1lZDI1NTE5" ++ body ++ "...")
        (Random.map keyTypeFromIndex (Random.int 0 (List.length keyTypes - 1)))
        randomKeyBody


-- JSON CODECS

sshConfigDecoder : Decoder SSHConfig
sshConfigDecoder =
    Decode.map3 SSHConfig
        (field "user" string)
        (field "port" int)
        (Decode.oneOf [ field "host-key" string, field "host_key" string ])

clientDecoder : Decoder Client
clientDecoder =
    Decode.map4 Client
        (field "client_id" string)
        (field "ip" string)
        (field "ssh" sshConfigDecoder)
        (field "created_at" string)

encodeSSHConfig : SSHConfig -> Encode.Value
encodeSSHConfig ssh =
    Encode.object
        [ ( "user", Encode.string ssh.user )
        , ( "port", Encode.int ssh.port_ )
        , ( "host-key", Encode.string ssh.hostKey )
        ]

encodeMockPayload : MockPayload -> Encode.Value
encodeMockPayload payload =
    Encode.object
        [ ( "client_id", Encode.string payload.clientId )
        , ( "ip", Encode.string payload.ip )
        , ( "ssh", encodeSSHConfig payload.ssh )
        ]


-- PROGRAM ENTRY

main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
