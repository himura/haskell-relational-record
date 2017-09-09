{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}

-- |
-- Module      : Database.Relational.ProjectableExtended
-- Copyright   : 2013-2017 Kei Hibino
-- License     : BSD3
--
-- Maintainer  : ex8k.hibino@gmail.com
-- Stability   : experimental
-- Portability : unknown
--
-- This module defines operators on various projected records.
module Database.Relational.ProjectableExtended (
  -- * Projection for nested 'Maybe's
  ProjectableFlattenMaybe (flatten),

  flattenPiMaybe,

  -- * Get narrower records
  (!), (?!), (?!?), (!??),

  -- * Aggregate functions
  unsafeAggregateOp,
  count,
  sum', sumMaybe, avg, avgMaybe,
  max', maxMaybe, min', minMaybe,
  every, any', some',

  -- * Zipping projection type trick
  ProjectableIdZip (leftId, rightId),
  ProjectableRunIdsZip (runIds), flattenPh
  -- generalizedZip', (>?<)
  )  where

import Prelude hiding (pi)

import qualified Language.SQL.Keyword as SQL
import Database.Record (PersistableWidth)

import Database.Relational.Internal.ContextType (Flat, Aggregated, OverWindow)
import Database.Relational.SqlSyntax (Predicate, Record, )

import qualified Database.Relational.Record as Record
import Database.Relational.Projectable
  (PlaceHolders, unsafeUniOp,
   ProjectableMaybe (flattenMaybe), ProjectableIdZip (leftId, rightId),
   SqlProjectable)
import Database.Relational.Pi (Pi)


class AggregatedContext ac
instance AggregatedContext Aggregated
instance AggregatedContext OverWindow

-- | Unsafely make aggregation uni-operator from SQL keyword.
unsafeAggregateOp :: (AggregatedContext ac, SqlProjectable (p ac))
                  => SQL.Keyword -> Record Flat a -> p ac b
unsafeAggregateOp op = unsafeUniOp ((op SQL.<++>) . SQL.paren)

-- | Aggregation function COUNT.
count :: (Integral b, AggregatedContext ac, SqlProjectable (p ac))
      => Record Flat a -> p ac b
count =  unsafeAggregateOp SQL.COUNT

-- | Aggregation function SUM.
sumMaybe :: (Num a, AggregatedContext ac, SqlProjectable (p ac))
         => Record Flat (Maybe a) -> p ac (Maybe a)
sumMaybe  =  unsafeAggregateOp SQL.SUM

-- | Aggregation function SUM.
sum' :: (Num a, AggregatedContext ac, SqlProjectable (p ac))
     => Record Flat a -> p ac (Maybe a)
sum'  =  sumMaybe . Record.just

-- | Aggregation function AVG.
avgMaybe :: (Num a, Fractional b, AggregatedContext ac, SqlProjectable (p ac))
         => Record Flat (Maybe a) -> p ac (Maybe b)
avgMaybe   =  unsafeAggregateOp SQL.AVG

-- | Aggregation function AVG.
avg :: (Num a, Fractional b, AggregatedContext ac, SqlProjectable (p ac))
    => Record Flat a -> p ac (Maybe b)
avg =  avgMaybe . Record.just

-- | Aggregation function MAX.
maxMaybe :: (Ord a, AggregatedContext ac, SqlProjectable (p ac))
         => Record Flat (Maybe a) -> p ac (Maybe a)
maxMaybe  =  unsafeAggregateOp SQL.MAX

-- | Aggregation function MAX.
max' :: (Ord a, AggregatedContext ac, SqlProjectable (p ac))
     => Record Flat a -> p ac (Maybe a)
max' =  maxMaybe . Record.just

-- | Aggregation function MIN.
minMaybe :: (Ord a, AggregatedContext ac, SqlProjectable (p ac))
         => Record Flat (Maybe a) -> p ac (Maybe a)
minMaybe  =  unsafeAggregateOp SQL.MIN

-- | Aggregation function MIN.
min' :: (Ord a, AggregatedContext ac, SqlProjectable (p ac))
     => Record Flat a -> p ac (Maybe a)
min' =  minMaybe . Record.just

-- | Aggregation function EVERY.
every :: (AggregatedContext ac, SqlProjectable (p ac))
      => Predicate Flat -> p ac (Maybe Bool)
every =  unsafeAggregateOp SQL.EVERY

-- | Aggregation function ANY.
any' :: (AggregatedContext ac, SqlProjectable (p ac))
     => Predicate Flat -> p ac (Maybe Bool)
any'  =  unsafeAggregateOp SQL.ANY

-- | Aggregation function SOME.
some' :: (AggregatedContext ac, SqlProjectable (p ac))
      => Predicate Flat -> p ac (Maybe Bool)
some' =  unsafeAggregateOp SQL.SOME

-- | Get narrower record along with projection path.
(!) :: PersistableWidth a
    => Record c a -- ^ Source 'Record'
    -> Pi a b     -- ^ Record path
    -> Record c b -- ^ Narrower projected object
(!) = Record.pi

-- | Get narrower record along with projection path
--   'Maybe' phantom functor is 'map'-ed.
(?!) :: PersistableWidth a
     => Record c (Maybe a) -- ^ Source 'Record'. 'Maybe' type
     -> Pi a b             -- ^ Record path
     -> Record c (Maybe b) -- ^ Narrower projected object. 'Maybe' type result
(?!) = Record.piMaybe

-- | Get narrower record along with projection path
--   and project into result record type.
--   Source record 'Maybe' phantom functor and projection path leaf 'Maybe' functor are 'join'-ed.
(?!?) :: PersistableWidth a
      => Record c (Maybe a) -- ^ Source 'Record'. 'Maybe' phantom type
      -> Pi a (Maybe b)     -- ^ Record path. 'Maybe' type leaf
      -> Record c (Maybe b) -- ^ Narrower projected object. 'Maybe' phantom type result
(?!?) = Record.piMaybe'


-- | Interface to compose phantom 'Maybe' nested type.
class ProjectableFlattenMaybe a b where
  flatten :: ProjectableMaybe p => p a -> p b

-- | Compose 'Maybe' type in record phantom type.
instance ProjectableFlattenMaybe (Maybe a) b
         => ProjectableFlattenMaybe (Maybe (Maybe a)) b where
  flatten = flatten . flattenMaybe

-- | Not 'Maybe' type is not processed.
instance ProjectableFlattenMaybe (Maybe a) (Maybe a) where
  flatten = id

-- | Get narrower record with flatten leaf phantom Maybe types along with projection path.
flattenPiMaybe :: (PersistableWidth a, ProjectableMaybe (Record cont), ProjectableFlattenMaybe (Maybe b) c)
               => Record cont (Maybe a) -- ^ Source 'Record'. 'Maybe' phantom type
               -> Pi a b                -- ^ Projection path
               -> Record cont c         -- ^ Narrower 'Record'. Flatten 'Maybe' phantom type
flattenPiMaybe p = flatten . Record.piMaybe p

-- | Get narrower record with flatten leaf phantom Maybe types along with projection path.
(!??) :: (PersistableWidth a, ProjectableMaybe (Record cont), ProjectableFlattenMaybe (Maybe b) c)
      => Record cont (Maybe a) -- ^ Source 'Record'. 'Maybe' phantom type
      -> Pi a b                -- ^ Projection path
      -> Record cont c         -- ^ Narrower flatten and projected object.
(!??) = flattenPiMaybe


-- | Interface to run recursively identity element laws.
class ProjectableRunIdsZip a b where
  runIds :: ProjectableIdZip p => p a -> p b

-- | Run left identity element law.
instance ProjectableRunIdsZip a b => ProjectableRunIdsZip ((), a) b where
  runIds = runIds . leftId

-- | Run right identity element law.
instance ProjectableRunIdsZip a b => ProjectableRunIdsZip (a, ()) b where
  runIds = runIds . rightId

-- | Base case definition to run recursively identity element laws.
instance ProjectableRunIdsZip a a where
  runIds = id

-- | Specialize 'runIds' for 'PlaceHolders' type.
flattenPh :: ProjectableRunIdsZip a b => PlaceHolders a -> PlaceHolders b
flattenPh =  runIds

-- -- | Binary operator the same as 'generalizedZip'.
-- (>?<) :: (ProjectableIdZip p, ProjectableRunIdsZip (a, b) c)
--       => p a -> p b -> p c
-- (>?<) =  generalizedZip'

infixl 8 !, ?!, ?!?, !??
-- infixl 1 >?<