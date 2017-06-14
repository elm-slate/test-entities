module Slate.TestEntities.Person.Schema
    exposing
        ( entityName
        , schema
        , properties
        )

{-|
    Person Schema.

@docs entityName, schema , properties
-}

import Slate.Common.Schema exposing (..)
import Slate.TestEntities.Address.Schema as Address


{-| Entity name
-}
entityName : String
entityName =
    "Person"


{-|
    Person Schema.
-}
schema : EntitySchema
schema =
    { entityName = entityName
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
