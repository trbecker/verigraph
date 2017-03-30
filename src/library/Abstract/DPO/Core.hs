{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE UndecidableInstances #-}
module Abstract.DPO.Core

where

import           Abstract.AdhesiveHLR
import           Abstract.Morphism
import           Abstract.Valid

-- | A Double-Pushout production.
--
-- Consists of two morphisms /'left' : K -> L/ and /'right' : K -> R/,
-- as well as a set of 'nacs' /L -> Ni/.
data Production m = Production
  { left  :: m   -- ^ The morphism /K -> L/ of a production
  , right :: m  -- ^ The morphism /K -> R/ of a production
  , nacs  :: [m] -- ^ The set of nacs /L -> Ni/ of a production
  }
  deriving (Eq, Show, Read)

-- | Construct a production from the morphism /l : K -> L/,
-- the morphism /r : K -> R/, and the nacs /L -> Ni/, respectively.
--
-- Note: this doesn't check that the production is valid.
buildProduction :: m -> m -> [m] -> Production m
buildProduction = Production

-- | Returns the morphism /K -> L/ of the given production
getLHS :: Production m -> m
getLHS = left

-- | Returns the morphism /K -> R/ of the given production
getRHS :: Production m -> m
getRHS = right

-- | Returns the set of nacs /L -> Ni/ of the given production
getNACs :: Production m -> [m]
getNACs = nacs

instance (Morphism m, Valid m, Eq (Obj m)) => Valid (Production m) where
  validate (Production l r nacs) =
    mconcat $
      [ withContext "left morphism" (validate l)
      , withContext "right morphism" (validate r)
      , ensure (isMonomorphism l) "The left side of the production is not monic"
      , ensure (isMonomorphism r) "The right side of the production is not monic"
      , ensure (domain l == domain r) "The domains of the left and right morphisms aren't the same"
      ] ++ zipWith validateNac nacs ([1..] :: [Int])
    where
      validateNac nac index =
        mconcat
          [ withContext ("NAC #" ++ show index) (validate nac)
          , ensure (codomain l == domain nac) ("The domain of NAC #" ++ show index ++ " is not the left side of the rule")
          ]

-- | Class for morphisms whose category is Adhesive-HLR, and which can be
-- used for double-pushout transformations.
class (AdhesiveHLR m, FindMorphism m) => DPO m where
  -- | Inverts a production, adjusting the NACs accordingly.
  -- Needs information of nac injective satisfaction (in second order)
  -- and matches injective.
  invertProduction :: MorphismsConfig -> Production m -> Production m

  -- | Given a production /L ←l- K -r→ R/ and a NAC morphism /n : L -> N/, obtain
  -- a set of NACs /n'i : R -> N'i/ that is equivalent to the original NAC.
  shiftNacOverProduction :: MorphismsConfig -> Production m -> m -> [m]

  -- TODO : Verify why this function continues to be used
  -- | Check if the second morphism is monomorphic outside the image of the
  -- first morphism.
  isPartiallyMonomorphic :: m -> m -> Bool
--{-# WARNING isPartiallyMonomorphic "Only necessary until 'partialInjectiveMatches' is corrected" #-}


-- | Obtain all matches from the production into the given object, even if they
-- aren't applicable.
--
-- When given `MonoMatches`, only obtains monomorphic matches.
findAllMatches :: (DPO m) => MorphismsConfig -> Production m -> Obj m -> [m]
findAllMatches conf production =
  findMorphisms
    (matchRestrictionToMorphismType $ matchRestriction conf)
    (codomain $ left production)

-- | Obtain the matches from the production into the given object that satisfiy the NACs
-- and gluing conditions.
--
-- When given `MonoMatches`, only obtains monomorphic matches.
findApplicableMatches :: (DPO m) => MorphismsConfig -> Production m -> Obj m -> [m]
findApplicableMatches conf production obj =
  filter (satisfiesRewritingConditions conf production) (findAllMatches conf production obj)



-- | Given a match and a production, calculates the double-pushout diagram
-- for the corresponding transformation.
--
-- Given match /m : L -> G/ and the production /L ←l- K -r→ R/ such that
-- @'satisfiesRewritingConditions' _ _ p m == True@, returns /k/, /n/, /f/ and /g/ (respectively)
-- such that the following two squares are pushouts.
--
-- @
--       l        r
--    L◀──────K──────▶R
--    │       │       │
--  m │       │ k     │ n
--    ▼       ▼       ▼
--    G◀──────D──────▶H
--         f     g
-- @
--
-- Note: this doesn't test whether the match is for the actual production,
-- nor if the match satisfies all application conditions.
calculateDPO :: AdhesiveHLR m => m -> Production m -> (m, m, m, m)
calculateDPO m (Production l r _) =
  let (k, f) = calculatePushoutComplement m l
      (n, g) = calculatePushout k r
  in (k, n, f, g)

-- | True if the given match satisfies the gluing condition and NACs of the
-- given production.
satisfiesRewritingConditions :: DPO m => MorphismsConfig -> Production m -> m -> Bool
satisfiesRewritingConditions conf production match =
  satisfiesGluingConditions conf production match && satisfiesNACs conf production match

-- | Verifies if the gluing conditions for a production /p/ are satisfied by a match /m/
satisfiesGluingConditions :: DPO m => MorphismsConfig -> Production m -> m -> Bool
satisfiesGluingConditions conf production match =
  hasPushoutComplement (matchIsMono, match) (GenericMorphism, left production)
  where
    matchIsMono =
      matchRestrictionToMorphismType (matchRestriction conf)

-- | True if the given match satisfies all NACs of the given production.
satisfiesNACs :: DPO m => MorphismsConfig -> Production m -> m -> Bool
satisfiesNACs conf production match =
  all (satisfiesSingleNac conf match) (nacs production)

satisfiesSingleNac :: DPO m => MorphismsConfig -> m -> m -> Bool
satisfiesSingleNac conf match nac =
  let nacMatches =
        case nacSatisfaction conf of
          MonomorphicNAC ->
            findMonomorphisms (codomain nac) (codomain match)
          PartiallyMonomorphicNAC ->
            partialInjectiveMatches nac match
      commutes nacMatch =
        compose nac nacMatch == match
  in
    not $ any commutes nacMatches

-- | Given a match and a production, calculate the calculateComatch for the
-- corresponding transformation.
--
-- Given match /m : L -> G/ and the production @p = /L ←l- K -r→ R/@ such that
-- @'satisfiesRewritingConditions' _ _ p m == True@, returns /n/ such that the following two
-- squares are pushouts.
--
-- @
--       l        r
--    L◀──────K──────▶R
--    │       │       │
--  m │       │       │ n
--    ▼       ▼       ▼
--    G◀──────D──────▶H
-- @
--
-- Note: this doesn't test whether the match is for the actual production,
-- nor if the match satisfies all application conditions.
calculateComatch :: AdhesiveHLR m => m -> Production m -> m
calculateComatch m prod = let (_,m',_,_) = calculateDPO m prod in m'

-- | Given a match and a production, obtain the rewritten object.
--
-- @rewrite match production@ is equivalent to @'codomain' ('calculateComatch' match production)@
rewrite :: AdhesiveHLR m => m -> Production m -> Obj m
rewrite m prod =
  codomain (calculateComatch m prod)

-- | Discards the NACs of a production and inverts it.
invertProductionWithoutNacs :: Production m -> Production m
invertProductionWithoutNacs p = Production (right p) (left p) []
