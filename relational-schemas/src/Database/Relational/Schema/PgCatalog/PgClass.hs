{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE FlexibleInstances #-}

-- |
-- Module      : Database.Relational.Schema.PgCatalog.PgClass
-- Copyright   : 2013 Kei Hibino
-- License     : BSD3
--
-- Maintainer  : ex8k.hibino@gmail.com
-- Stability   : experimental
-- Portability : unknown
module Database.Relational.Schema.PgCatalog.PgClass where

import Data.Int (Int32)

import Database.Relational.Query.TH (defineTableTypesAndRecord)

import Database.Relational.Schema.PgCatalog.Config (config)


$(defineTableTypesAndRecord config
  "PG_CATALOG" "pg_class"
  [("oid"         , [t| Int32 |]),
 -- relname        | name      | not null
   ("relname"     , [t| String |]),
 -- relnamespace   | oid       | not null
   ("relnamespace", [t| Int32 |])
 -- reltype        | oid       | not null
 -- reloftype      | oid       | not null
 -- relowner       | oid       | not null
 -- relam          | oid       | not null
 -- relfilenode    | oid       | not null
 -- reltablespace  | oid       | not null
 -- relpages       | integer   | not null
 -- reltuples      | real      | not null
 -- reltoastrelid  | oid       | not null
 -- reltoastidxid  | oid       | not null
 -- relhasindex    | boolean   | not null
 -- relisshared    | boolean   | not null
 -- relpersistence | "char"    | not null
 -- relkind        | "char"    | not null
 -- relnatts       | smallint  | not null
 -- relchecks      | smallint  | not null
 -- relhasoids     | boolean   | not null
 -- relhaspkey     | boolean   | not null
 -- relhasrules    | boolean   | not null
 -- relhastriggers | boolean   | not null
 -- relhassubclass | boolean   | not null
 -- relfrozenxid   | xid       | not null
 -- relacl         | aclitem[] |
 -- reloptions     | text[]    |
  ]
  [''Show])
