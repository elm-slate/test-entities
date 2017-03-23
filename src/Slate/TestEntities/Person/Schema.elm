module Slate.TestEntities.Person.Schema
    exposing
        ( schema
        , properties
        )

{-|
    Person Schema.

@docs schema , properties
-}

import Slate.Common.Schema exposing (..)
import Slate.TestEntities.Address.Schema as Address exposing (..)


{-|
    Person Schema.
-}
schema : EntitySchema
schema =
    { entityName = "Person"
    , properties = properties
    }


{-|
    Person Properties.
-}
properties : List PropertySchema
properties =
    List.concat
        [ List.map SinglePropertySchema [ "name", "age" ]
        , List.map MultiplePropertySchema [ "aliases" ]
        , [ SingleRelationshipSchema "address" Address.schema True ]
        , [ MultipleRelationshipSchema "oldAddresses" Address.schema True ]
        ]
