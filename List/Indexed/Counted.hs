{-# LANGUAGE ConstraintKinds       #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE PolyKinds             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE TypeOperators         #-} 

module Data.List.Indexed.Counted where

import Data.Numeric.Witness.Peano

import Control.Applicative
import Data.List hiding ( replicate , zip )
import Prelude   hiding ( replicate , zip )

-- Counted lists: indexed by length in the type.

infixr 5 :::

data CountedList n a where
   (:::) :: a -> CountedList n a -> CountedList (Succ n) a
   CountedNil :: CountedList Zero a

instance (Show x) => Show (CountedList n x) where
   showsPrec p xs = showParen (p > 10) $
      (showString $ ( intercalate " ::: "
                    $ map show
                    $ unCount xs ) ++ " ::: CountedNil")

count :: CountedList n a -> Natural n
count CountedNil = Zero
count (x ::: xs) = Succ (count xs)

unCount :: CountedList n a -> [a]
unCount CountedNil       = []
unCount (x ::: xs) = x : unCount xs

replicate :: Natural n -> x -> CountedList n x
replicate Zero     _ = CountedNil
replicate (Succ n) x = x ::: replicate n x

append :: CountedList n a -> CountedList m a -> CountedList (m + n) a
append CountedNil       ys = ys
append (x ::: xs) ys = x ::: append xs ys

nth :: (n < m) => Natural n -> CountedList m a -> a
nth Zero     (a ::: _)  = a
nth (Succ n) (_ ::: as) = nth n as
nth _ _ = error "nth: the impossible occurred" -- like in minus, GHC can't prove this is unreachable

padTo :: (m <= n) => Natural n -> x -> CountedList m x -> CountedList ((n - m) + m) x
padTo n x list =
   list `append` replicate (n `minus` count list) x

zip :: CountedList n a -> CountedList n b -> CountedList n (a,b)
zip (a ::: as) (b ::: bs) = (a,b) ::: zip as bs
zip CountedNil _ = CountedNil
zip _ CountedNil = CountedNil

instance Functor (CountedList n) where
   fmap f CountedNil = CountedNil
   fmap f (a ::: as) = f a ::: fmap f as

instance (ReifyNatural n) => Applicative (CountedList n) where
   pure x    = replicate (reifyNatural :: Natural n) x
   fs <*> xs = uncurry id <$> zip fs xs
