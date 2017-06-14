module Slate.TestEntities.Address.Schema
    exposing
        ( entityName
        , schema
        , properties
        )

{-|
    Address Schema.

@docs entityName, schema , properties
-}

import Slate.Common.Schema exposing (..)


{-| Entity name
-}
entityName : String
entityName =
    "Address"


{-|
    Address Schema.
-}
schema : EntitySchema
schema =
    { entityName = entityName
    , properties = properties
    }


{-|
    Address Properties.
-}
properties : List PropertySchema
properties =
    List.map SinglePropertySchema [ "street", "city", "state", "zip" ]
