module Slate.TestEntities.Address.Entity
    exposing
        ( Fragment
        , FragmentDict
        , Entity
        , defaultFragment
        , default
        , fragmentEncode
        , fragmentDecode
        , mutate
        )

{-|

    Entity Entity.

@docs Fragment , FragmentDict , Entity , defaultFragment , default , fragmentEncode , fragmentDecode , mutate

-}

import Json.Encode as JE exposing (..)
import Json.Decode as JD exposing (..)
import StringUtils exposing (..)
import Utils.Json as JsonU exposing ((///), (<||))
import Slate.Common.Entity exposing (..)
import Slate.Common.Mutation exposing (..)
import Slate.Common.Event exposing (..)
import Utils.Ops exposing (..)


{-| Entity Fragment
-}
type alias Fragment =
    { street : Maybe String
    , city : Maybe String
    , state : Maybe String
    , zip : Maybe String
    }


{-| Entity Fragment Dictionary
-}
type alias FragmentDict =
    EntityDict Fragment


{-| Starting point for all Entity Fragments
since events are applied one at a time to build the final subSet entity
-}
defaultFragment : Fragment
defaultFragment =
    { street = Nothing
    , city = Nothing
    , state = Nothing
    , zip = Nothing
    }


{-| Entity Type
-}
type alias Entity =
    { street : String
    , city : String
    , state : String
    , zip : String
    }


{-| Default Entity
-}
default : Entity
default =
    { street = ""
    , city = ""
    , state = ""
    , zip = ""
    }



-- encoding/decoding


{-|

    Encode fragment.
-}
fragmentEncode : Fragment -> String
fragmentEncode address =
    JE.encode 0 <|
        JE.object <|
            (List.filter (\( _, value ) -> value /= JE.null))
                [ ( "street", JsonU.encMaybe JE.string address.street )
                , ( "city", JsonU.encMaybe JE.string address.city )
                , ( "state", JsonU.encMaybe JE.string address.state )
                , ( "zip", JsonU.encMaybe JE.string address.zip )
                ]


{-|

    Decode fragment.
-}
fragmentDecode : String -> Result String Fragment
fragmentDecode json =
    JD.decodeString
        ((JD.succeed Fragment)
            <|| (field "street" <| JD.maybe JD.string)
            <|| (field "city" <| JD.maybe JD.string)
            <|| (field "state" <| JD.maybe JD.string)
            <|| (field "zip" <| JD.maybe JD.string)
        )
        json


{-|

    Mutate the Fragment based on an event.
-}
mutate : MutateFunction Fragment
mutate eventRecord entity =
    let
        event =
            eventRecord.event

        setStreet value entity =
            { entity | street = value }

        setCity value entity =
            { entity | city = value }

        setState value entity =
            { entity | state = value }

        setZip value entity =
            { entity | zip = value }
    in
        case getEventType event of
            ( "entity", operation, _ ) ->
                case operation of
                    "created" ->
                        entity |> Just |> Ok

                    "destroyed" ->
                        Ok Nothing

                    _ ->
                        Debug.crash ("Program bug: Unsupported entity operation:" +-+ operation)

            ( target, operation, maybePropertyName ) ->
                let
                    crash _ =
                        Debug.crash ("Program bug: Unsupported property operation:" +-+ operation +-+ "for" +-+ target ++ ":" +-+ maybePropertyName)
                in
                    case target of
                        "property" ->
                            case ( operation, maybePropertyName ) of
                                ( "added", Just "street" ) ->
                                    updatePropertyValue getStringValue setStreet event entity |??> Just

                                ( "removed", Just "street" ) ->
                                    setStreet Nothing entity |> Just |> Ok

                                ( "added", Just "city" ) ->
                                    updatePropertyValue getStringValue setCity event entity |??> Just

                                ( "removed", Just "city" ) ->
                                    setCity Nothing entity |> Just |> Ok

                                ( "added", Just "state" ) ->
                                    updatePropertyValue getStringValue setState event entity |??> Just

                                ( "removed", Just "state" ) ->
                                    setState Nothing entity |> Just |> Ok

                                ( "added", Just "zip" ) ->
                                    updatePropertyValue getStringValue setZip event entity |??> Just

                                ( "removed", Just "zip" ) ->
                                    setZip Nothing entity |> Just |> Ok

                                _ ->
                                    crash ()

                        "relationship" ->
                            case ( operation, maybePropertyName ) of
                                _ ->
                                    crash ()

                        "propertyList" ->
                            case ( operation, maybePropertyName ) of
                                _ ->
                                    crash ()

                        "relationshipList" ->
                            case ( operation, maybePropertyName ) of
                                _ ->
                                    crash ()

                        unhandled ->
                            Debug.crash <| "Unsupported target:" +-+ unhandled
