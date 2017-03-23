module Slate.TestEntities.Person.Entity
    exposing
        ( Fragment
        , FragmentDict
        , Entity
        , Name
        , defaultFragment
        , default
        , fragmentEncode
        , fragmentDecode
        , mutate
        )

{-|
    Entity Entity.

@docs Fragment , FragmentDict , Entity , Name , defaultFragment , default , fragmentEncode , fragmentDecode , mutate
-}

import Dict exposing (..)
import Json.Encode as JE exposing (..)
import Json.Decode as JD exposing (..)
import StringUtils exposing (..)
import Utils.Json as JsonU exposing ((///), (<||))
import Slate.Common.Entity exposing (..)
import Slate.Common.Mutation exposing (..)
import Slate.Common.Event as Event exposing (..)
import Slate.Common.Relationship exposing (..)
import Slate.TestEntities.Address.Entity as Address exposing (..)
import Slate.TestEntities.Person.Schema exposing (..)
import Utils.Ops exposing (..)


-- API


{-| Entity Fragment
-}
type alias Fragment =
    { name : Maybe Name
    , age : Maybe Int
    , address : Maybe RelationshipId
    , aliases : PropertyList String
    , oldAddresses : PropertyList RelationshipId
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
    { name = Nothing
    , age = Nothing
    , address = Nothing
    , aliases = mtPropertyList
    , oldAddresses = mtPropertyList
    }


{-| Default Entity Type
-}
type alias Entity =
    { name : Name
    , age : Int
    , address : Address.Entity
    , aliases : List String
    , oldAddresses : List String
    }


{-| Default Entity
-}
default : Entity
default =
    { name = defaultName
    , age = -1
    , address = Address.default
    , aliases = []
    , oldAddresses = []
    }



-- Value Objects


{-|
    Person's name.
-}
type alias Name =
    { first : String
    , middle : String
    , last : String
    }


{-|
    Default Person's name.
-}
defaultName : Name
defaultName =
    { first = ""
    , middle = ""
    , last = ""
    }


{-|
    Name encode.
-}
nameEncode : Name -> JE.Value
nameEncode name =
    JE.object
        [ ( "first", JE.string name.first )
        , ( "middle", JE.string name.middle )
        , ( "last", JE.string name.last )
        ]


{-|
    Name decoder.
-}
nameDecoder : JD.Decoder Name
nameDecoder =
    JD.succeed Name
        <|| (field "first" JD.string)
        <|| (field "middle" JD.string)
        <|| (field "last" JD.string)



-- encoding/decoding


{-|
    Encode fragment.
-}
fragmentEncode : Fragment -> String
fragmentEncode person =
    JE.encode 0 <|
        JE.object <|
            (List.filter (\( _, value ) -> value /= JE.null))
                [ ( "name", JsonU.encMaybe nameEncode person.name )
                , ( "age", JsonU.encMaybe JE.int person.age )
                , ( "address", JsonU.encMaybe entityRelationshipEncode person.address )
                , ( "aliases", propertyListEncode JE.string person.aliases )
                , ( "oldAddresses", propertyListEncode JE.string person.oldAddresses )
                ]


{-|
    Decode fragment.
-}
fragmentDecode : String -> Result String Fragment
fragmentDecode json =
    JD.decodeString
        ((JD.succeed Fragment)
            <|| (field "name" <| JD.maybe nameDecoder)
            <|| (field "age" <| JD.maybe JD.int)
            <|| (field "address" <| JD.maybe entityRelationshipDecoder)
            <|| (field "aliases" <| propertyListDecoder JD.string)
            <|| (field "oldAddresses" <| propertyListDecoder JD.string)
        )
        json


{-|
    Mutate the Fragment based on an event.
-}
mutate : MutateCascadingDeleteFunction Fragment
mutate event entity =
    let
        decodeName event =
            getConvertedValue (JD.decodeString nameDecoder) event

        setName value entity =
            { entity | name = value }

        setAge value entity =
            { entity | age = value }

        setAddress value entity =
            { entity | address = value }

        setAliases value entity =
            { entity | aliases = value }

        setOldAddresses value entity =
            { entity | oldAddresses = value }

        cascadingDelete =
            buildCascadingDelete schema relationshipIdAccessDict entity
    in
        case getEventType event of
            ( "entity", operation, _ ) ->
                case operation of
                    "created" ->
                        ( entity |> Just |> Ok, Nothing )

                    "destroyed" ->
                        ( Ok Nothing, Just cascadingDelete )

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
                                ( "added", Just "name" ) ->
                                    ( updatePropertyValue decodeName setName event entity |??> Just, Nothing )

                                ( "removed", Just "name" ) ->
                                    ( setName Nothing entity |> Just |> Ok, Nothing )

                                ( "added", Just "age" ) ->
                                    ( updatePropertyValue getIntValue setAge event entity |??> Just, Nothing )

                                ( "removed", Just "age" ) ->
                                    ( setAge Nothing entity |> Just |> Ok, Nothing )

                                _ ->
                                    crash ()

                        "relationship" ->
                            case ( operation, maybePropertyName ) of
                                ( "added", Just "address" ) ->
                                    ( updatePropertyRelationship setAddress event entity |??> Just, Nothing )

                                ( "removed", Just "address" ) ->
                                    ( setAddress Nothing entity |> Just |> Ok, Nothing )

                                _ ->
                                    crash ()

                        "propertyList" ->
                            case ( operation, maybePropertyName ) of
                                ( "added", Just "aliases" ) ->
                                    ( addToPropertyList .aliases getStringValue setAliases event entity |??> Just, Nothing )

                                ( "removed", Just "aliases" ) ->
                                    ( removeFromPropertyList .aliases getStringValue setAliases event entity |??> Just, Nothing )

                                ( "positioned", Just "aliases" ) ->
                                    ( positionPropertyList .aliases setAliases event entity |??> Just, Nothing )

                                _ ->
                                    crash ()

                        "relationshipList" ->
                            case ( operation, maybePropertyName ) of
                                ( "added", Just "oldAddresses" ) ->
                                    ( addToRelationshipList .oldAddresses setOldAddresses event entity |??> Just, Nothing )

                                ( "removed", Just "oldAddresses" ) ->
                                    ( removeFromRelationshipList .oldAddresses setOldAddresses event entity |??> Just, Nothing )

                                ( "positioned", Just "oldAddresses" ) ->
                                    ( positionRelationshipList .oldAddresses setOldAddresses event entity |??> Just, Nothing )

                                _ ->
                                    crash ()

                        unhandled ->
                            Debug.crash <| "Unsupported target:" +-+ unhandled



-- PRIVATE API


relationshipIdAccessDict : RelationshipIdAccessDict Fragment
relationshipIdAccessDict =
    Dict.fromList
        [ ( "address", relationshipIdAccessor .address )
        , ( "oldAddresses", relationshipListIdsAccessor .oldAddresses )
        ]
