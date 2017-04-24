module SndOrder.Morphism.AdhesiveHLR where

import           Abstract.AdhesiveHLR
import           Abstract.Cocomplete
import           Abstract.DPO
import           Abstract.Morphism                  ()
import           Graph.Graph                        as G
import qualified Graph.GraphMorphism                as GM
import           TypedGraph.Morphism

import           SndOrder.Morphism.Cocomplete       ()
import           SndOrder.Morphism.CommutingSquares
import           SndOrder.Morphism.Core
import           SndOrder.Morphism.NACmanipulation

instance AdhesiveHLR (RuleMorphism a b) where

  -- Pushout for second-order with creation of NACs.
  -- It runs the pushout without NACs (from cocomplete),
  -- generates all NACs (considering arbitrary matches) for the rule P,
  -- and updates the morphisms f and g to get the new NACs.
  --
  -- @
  --       g
  --    K──────▶R
  --    │       │
  --  f │       │ f'
  --    ▼       ▼
  --    D──────▶P
  --       g'
  -- @
  calculatePushout f@(RuleMorphism _ ruleD _ _ _) g@(RuleMorphism _ ruleR _ _ _) = (f',g')
    where
      (RuleMorphism _ preRuleP f'L f'K f'R,RuleMorphism _ _ g'L g'K g'R) =
        Abstract.Cocomplete.calculatePushout f g

      ruleP = buildProduction (getLHS preRuleP) (getRHS preRuleP) nacsToAdd

      f' = RuleMorphism ruleR ruleP f'L f'K f'R
      g' = RuleMorphism ruleD ruleP g'L g'K g'R
      
      transposedNACs = map (\nac -> fst (Abstract.Cocomplete.calculatePushout nac g'L)) (getNACs ruleD)

      createdNACs = createStep ShiftNACs f'L (getNACs ruleR)

      nacsToAdd = transposedNACs ++ createdNACs

  -- This function for second-order must run the first-order initial
  -- pushouts and after add elements to the boundary (B) rule if
  -- it was generated with dangling span condition
  --
  -- @
  --        d
  --    B──────▶C
  --    │       │
  --  b │  (1)  │ c
  --    ▼       ▼
  --    A──────▶A'
  --        f
  -- @
  calculateInitialPushout f@(RuleMorphism fA fA' fL fK fR) = (b,d,c)
    where
      nodeTypesInAL = GM.applyNodeUnsafe (domain fL)
      edgeTypesInAL = GM.applyEdgeUnsafe (domain fL)
      nodeTypesInAR = GM.applyNodeUnsafe (domain fR)
      edgeTypesInAR = GM.applyEdgeUnsafe (domain fR)

      (initBL, _, _) = calculateInitialPushout fL
      (bK, _, _) = calculateInitialPushout fK
      (initBR, _, _) = calculateInitialPushout fR

      nodesBL = [n | n <- nodeIdsFromDomain fL, isOrphanNode (getLHS fA) n, not (isOrphanNode (getLHS fA') (applyNodeUnsafe fL n))]
      edgesBL = [e | e <- edgesFromDomain fL, isOrphanEdge (getLHS fA) (edgeId e), not (isOrphanEdge (getLHS fA') (applyEdgeUnsafe fL (edgeId e)))]

      nodesBR = [n | n <- nodeIdsFromDomain fR, isOrphanNode (getRHS fA) n, not (isOrphanNode (getRHS fA') (applyNodeUnsafe fR n))]
      edgesBR = [e | e <- edgesFromDomain fR, isOrphanEdge (getRHS fA) (edgeId e), not (isOrphanEdge (getRHS fA') (applyEdgeUnsafe fR (edgeId e)))]

      prebL = foldr (\n -> createNodeOnDomain n (nodeTypesInAL n) n) initBL nodesBL
      bL = foldr (\e -> createEdgeOnDomain (edgeId e) (sourceId e) (targetId e) (edgeTypesInAL (edgeId e)) (edgeId e)) prebL edgesBL

      prebR = foldr (\n -> createNodeOnDomain n (nodeTypesInAR n) n) initBR nodesBR
      bR = foldr (\e -> createEdgeOnDomain (edgeId e) (sourceId e) (targetId e) (edgeTypesInAR (edgeId e)) (edgeId e)) prebR edgesBR

      l = searchMorphism (compose bK (getLHS fA)) bL
      r = searchMorphism (compose bK (getRHS fA)) bR
      searchMorphism a b = commutingMorphism a b a b

      ruleB = buildProduction l r []
      b = RuleMorphism ruleB fA bL bK bR

      (d,c) = calculatePushoutComplement f b

  -- Pushout Complement for second-order with deletion and transposing of NACs.
  -- It runs the pushout complement without NACs,
  -- filters the NACs in the matched rule (ruleG) selecting the non deleted,
  -- and updates the rule H with the transposed NACs.
  --
  -- @
  --        l
  --    L◀──────K
  --    │       │
  --  m │       │ k
  --    ▼       ▼
  --    G◀──────H
  --        l'
  -- @
  -- calculatePushoutComplement m l = (k,l')
  calculatePushoutComplement (RuleMorphism _ ruleG matchL matchK matchR) (RuleMorphism ruleK ruleL leftL leftK leftR) = (k,l')
     where
       (matchL', leftL') = calculatePushoutComplement matchL leftL
       (matchK', leftK') = calculatePushoutComplement matchK leftK
       (matchR', leftR') = calculatePushoutComplement matchR leftR
       leftH = commutingMorphismSameCodomain
             (compose leftK' (getLHS ruleG)) leftL'
             matchK' (compose (getLHS ruleK) matchL')
       rightH = commutingMorphismSameCodomain
             (compose leftK' (getRHS ruleG)) leftR'
             matchK' (compose (getRHS ruleK) matchR')

       notDeletedNACs = deleteStep InitialPushouts (getNACs ruleL) (getNACs ruleG)

       validNACs = filter (satisfiesNACRewriting leftL') notDeletedNACs

       newRuleNACs = map (\nac -> fst (calculatePushoutComplement nac leftL')) validNACs

       ruleH = buildProduction leftH rightH newRuleNACs
       k = RuleMorphism ruleK ruleH matchL' matchK' matchR'
       l' = RuleMorphism ruleH ruleG leftL' leftK' leftR'

  -- @
  --        g'
  --     X──────▶A
  --     │       │
  --  f' │       │ f
  --     ▼       ▼
  --     B──────▶C
  --        g
  -- @
  calculatePullback (RuleMorphism fA _ fL fK fR) (RuleMorphism gB _ gL gK gR) = (f',g')
    where
      (f'L, g'L) = calculatePullback fL gL
      (f'K, g'K) = calculatePullback fK gK
      (f'R, g'R) = calculatePullback fR gR

      l = commutingMorphism
            (compose f'K (getLHS gB)) f'L
            (compose g'K (getLHS fA)) g'L

      r = commutingMorphism
            (compose f'K (getRHS gB)) f'R
            (compose g'K (getRHS fA)) g'R

      x = buildProduction l r []
      f' = RuleMorphism x gB f'L f'K f'R
      g' = RuleMorphism x fA g'L g'K g'R

  hasPushoutComplement (restrictionG, g) (restrictionF, f) =
    hasPushoutComplement (restrictionG, mappingLeft g) (restrictionF, mappingLeft f)
    && hasPushoutComplement (restrictionG, mappingRight g) (restrictionF, mappingRight f)
    && hasPushoutComplement (restrictionG, mappingInterface g) (restrictionF, mappingInterface f)
    && danglingSpan (getLHS $ codomain g) (mappingLeft g) (mappingInterface g) (mappingLeft f) (mappingInterface f)
    && danglingSpan (getRHS $ codomain g) (mappingRight g) (mappingInterface g) (mappingRight f) (mappingInterface f)

-- | A gluing condition for pushout complements of rule morphisms
danglingSpan :: TypedGraphMorphism a b -> TypedGraphMorphism a b -> TypedGraphMorphism a b -> TypedGraphMorphism a b -> TypedGraphMorphism a b -> Bool
danglingSpan matchRuleSide matchMorp matchK l k = deletedNodesInK && deletedEdgesInK
  where
    deletedNodes = filter (checkDeletion l matchMorp applyNode nodeIdsFromDomain) (nodeIdsFromCodomain matchMorp)
    nodesInK = [a | a <- nodeIdsFromDomain matchRuleSide, applyNodeUnsafe matchRuleSide a `elem` deletedNodes]
    deletedNodesInK = all (checkDeletion k matchK applyNode nodeIdsFromDomain) nodesInK

    deletedEdges = filter (checkDeletion l matchMorp applyEdge edgeIdsFromDomain) (edgeIdsFromCodomain matchMorp)
    edgesInK = [a | a <- edgeIdsFromDomain matchRuleSide, applyEdgeUnsafe matchRuleSide a `elem` deletedEdges]
    deletedEdgesInK = all (checkDeletion k matchK applyEdge edgeIdsFromDomain) edgesInK

isOrphanNode :: TypedGraphMorphism a b -> NodeId -> Bool
isOrphanNode m n = n `elem` orphanTypedNodeIds m

isOrphanEdge :: TypedGraphMorphism a b -> EdgeId -> Bool
isOrphanEdge m e = e `elem` orphanTypedEdgeIds m
