module Elm.MainTests exposing (..)

import Expect exposing (Expectation)
import Main exposing (..)
import Test exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode


suite : Test
suite =
    describe "Provme Admin Elm Frontend"
        [ describe "Helper Functions"
            [ test "filterClient matches clientId" <|
                \_ ->
                    let
                        client =
                            { clientId = "8f3b2024", ip = "192.168.1.1", ssh = { user = "ubuntu", port_ = 22, hostKey = "key" }, createdAt = "2024-01-01T00:00:00Z" }
                    in
                    filterClient "8f3b" client
                        |> Expect.equal True

            , test "filterClient matches ip" <|
                \_ ->
                    let
                        client =
                            { clientId = "8f3b2024", ip = "192.168.1.1", ssh = { user = "ubuntu", port_ = 22, hostKey = "key" }, createdAt = "2024-01-01T00:00:00Z" }
                    in
                    filterClient "192.168" client
                        |> Expect.equal True

            , test "filterClient matches ssh user" <|
                \_ ->
                    let
                        client =
                            { clientId = "8f3b2024", ip = "192.168.1.1", ssh = { user = "ubuntu", port_ = 22, hostKey = "key" }, createdAt = "2024-01-01T00:00:00Z" }
                    in
                    filterClient "ubun" client
                        |> Expect.equal True

            , test "filterClient is case insensitive" <|
                \_ ->
                    let
                        client =
                            { clientId = "8f3b2024", ip = "192.168.1.1", ssh = { user = "UBUNTU", port_ = 22, hostKey = "key" }, createdAt = "2024-01-01T00:00:00Z" }
                    in
                    filterClient "ubun" client
                        |> Expect.equal True

            , test "formatTimeStr formats ISO date string" <|
                \_ ->
                    formatTimeStr "2026-06-25T23:12:42.123Z"
                        |> Expect.equal "2026-06-25 23:12:42"

            , test "uniqueList removes duplicates" <|
                \_ ->
                    uniqueList [ "a", "b", "a", "c", "b" ]
                        |> Expect.equal [ "a", "b", "c" ]
            ]
        , describe "JSON Decoders & Encoders"
            [ test "clientDecoder decodes valid JSON" <|
                \_ ->
                    let
                        json =
                            """
                            {
                                "client_id": "8f3b2024-9b2f-4f76-8041-b0e7d56653df",
                                "ip": "192.168.1.100",
                                "ssh": {
                                    "user": "ubuntu",
                                    "port": 22,
                                    "host-key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL..."
                                },
                                "created_at": "2026-06-25T23:12:42Z"
                            }
                            """
                    in
                    case Decode.decodeString clientDecoder json of
                        Ok client ->
                            Expect.all
                                [ \c -> Expect.equal "8f3b2024-9b2f-4f76-8041-b0e7d56653df" c.clientId
                                , \c -> Expect.equal "192.168.1.100" c.ip
                                , \c -> Expect.equal "ubuntu" c.ssh.user
                                , \c -> Expect.equal 22 c.ssh.port_
                                , \c -> Expect.equal "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL..." c.ssh.hostKey
                                ]
                                client

                        Err err ->
                            Expect.fail (Decode.errorToString err)

            , test "clientDecoder handles host_key (snake_case)" <|
                \_ ->
                    let
                        json =
                            """
                            {
                                "client_id": "8f3b2024",
                                "ip": "192.168.1.100",
                                "ssh": {
                                    "user": "ubuntu",
                                    "port": 22,
                                    "host_key": "some-key"
                                },
                                "created_at": "2026-06-25T23:12:42Z"
                            }
                            """
                    in
                    case Decode.decodeString clientDecoder json of
                        Ok client ->
                            Expect.equal "some-key" client.ssh.hostKey

                        Err err ->
                            Expect.fail (Decode.errorToString err)

            , test "encodeSSHConfig encodes to correct JSON structure" <|
                \_ ->
                    let
                        ssh = { user = "ubuntu", port_ = 22, hostKey = "some-key" }
                        encoded = encodeSSHConfig ssh
                    in
                    encoded
                        |> Encode.encode 0
                        |> Expect.equal """{"user":"ubuntu","port":22,"host-key":"some-key"}"""
            ]
        , describe "Update Function"
            [ test "SearchChanged updates searchQuery" <|
                \_ ->
                    let
                        ( initialModel, _ ) = init ()
                        ( updatedModel, _ ) = update (SearchChanged "test-query") initialModel
                    in
                    Expect.equal "test-query" updatedModel.searchQuery

            , test "AutoRefreshToggled toggles autoRefresh" <|
                \_ ->
                    let
                        ( initialModel, _ ) = init ()
                        ( model1, _ ) = update AutoRefreshToggled initialModel
                        ( model2, _ ) = update AutoRefreshToggled model1
                    in
                    Expect.all
                        [ \m -> Expect.equal (not initialModel.autoRefresh) m.autoRefresh
                        , \_ -> Expect.equal initialModel.autoRefresh model2.autoRefresh
                        ]
                        model1

            , test "OpenKeyModal and CloseModal" <|
                \_ ->
                    let
                        ( initialModel, _ ) = init ()
                        ( modelWithKey, _ ) = update (OpenKeyModal "my-key") initialModel
                        ( modelClosed, _ ) = update CloseModal modelWithKey
                    in
                    Expect.all
                        [ \m -> Expect.equal (Just "my-key") m.keyModal
                        , \_ -> Expect.equal Nothing modelClosed.keyModal
                        ]
                        modelWithKey

            , test "DismissToast removes specific toast" <|
                \_ ->
                    let
                        initialModel =
                            { registrations = []
                            , searchQuery = ""
                            , autoRefresh = True
                            , keyModal = Nothing
                            , toasts = [ { id = 1, message = "Toast 1", type_ = Success }, { id = 2, message = "Toast 2", type_ = Error } ]
                            , nextToastId = 3
                            , lastActivity = "Never"
                            , isRefreshing = False
                            }
                        ( updatedModel, _ ) = update (DismissToast 1) initialModel
                    in
                    Expect.equal [ { id = 2, message = "Toast 2", type_ = Error } ] updatedModel.toasts
            ]
        ]
