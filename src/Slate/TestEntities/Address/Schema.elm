module Slate.TestEntities.Address.Schema
    exposing
        ( schema
        , properties
        )

{-|
    Address Schema.

@docs schema , properties
-}

import Slate.Common.Schema exposing (..)


{-|
    Address Schema.
-}
schema : EntitySchema
schema =
    { entityName = "Address"
    , properties = properties
    }


{-|
    Address Properties.
-}
properties : List PropertySchema
properties =
    List.map SinglePropertySchema [ "street", "city", "state", "zip" ]
