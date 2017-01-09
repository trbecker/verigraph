module TypedGraph.DPO.GraphProcess

(nodesAndEgdesDependcyRelation)

where

import Abstract.DPO
import Abstract.DPO.Process
import Abstract.Morphism
import Abstract.Relation (Relation, empty)
import Data.List
import Data.Maybe (isNothing)
import Graph.Graph (NodeId, EdgeId)
import TypedGraph.DPO.GraphRule ()
import TypedGraph.Graph ()
import TypedGraph.Morphism as TGM

instance GenerateProcess (TypedGraphMorphism a b) where
  typing = retypeProduction
  productionTyping = retype
  restrictMorphisms = restrictMorphisms'

type OccurrenceRelation = Relation RelationItem

data RelationItem = Node NodeId
                  | Edge EdgeId
                  | Rule String
                  deriving (Eq, Ord, Show)

buildBasicRelation :: [NamedRuleWithMatches (TypedGraphMorphism a b)] -> OccurrenceRelation
buildBasicRelation namedRules =
  let
    base = empty [] []
  in base

-- use with the retyped rules
nodesAndEgdesDependcyRelation :: (String, Production (TypedGraphMorphism a b)) -> [(RelationItem, RelationItem)]
nodesAndEgdesDependcyRelation (name,rule) =
  let
    l = getLHS rule
    r = getRHS rule
    l' = invert l
    r' = invert r
    ln = filter (isNothing . applyNode l') (nodesFromDomain l')
    le = filter (isNothing . applyEdge l') (edgesFromDomain l')
    rn = filter (isNothing . applyNode r') (nodesFromDomain r')
    re = filter (isNothing . applyEdge r') (edgesFromDomain r')
    nodesAndEdges = [(Node a, Node b) | a <- ln, b <- rn] ++ [(Edge a, Edge b) | a <- le, b <- re]
                 ++ [(Node a, Edge b) | a <- ln, b <- re] ++ [(Edge a, Node b) | a <- le, b <- rn]
    putRule rel = [(fst rel, Rule name), (Rule name, snd rel)]
    withRules = concatMap putRule nodesAndEdges
  in nodesAndEdges ++ withRules

retypeProduction :: (Derivation (TypedGraphMorphism a b), (TypedGraphMorphism a b,TypedGraphMorphism a b,TypedGraphMorphism a b)) ->  Production (TypedGraphMorphism a b)
retypeProduction (derivation, (g1,_,g3)) = newProduction
  where
    p = production derivation
    oldL = getLHS p
    oldR = getRHS p
    mappingL = mapping oldL
    mappingR = mapping oldR
    m = match derivation
    h = comatch derivation
    newLType = compose (mapping m) (mapping g1)
    newRType = compose (mapping h) (mapping g3)
    newKType = compose mappingL newLType -- change it to use gluing and g2?
    newL = buildTypedGraphMorphism newKType newLType mappingL
    newR = buildTypedGraphMorphism newKType newRType mappingR
    newProduction = buildProduction newL newR []

retype :: (Production (TypedGraphMorphism a b), (TypedGraphMorphism a b,TypedGraphMorphism a b,TypedGraphMorphism a b)) ->  Production (TypedGraphMorphism a b)
retype (p, (g1,g2,g3)) = newProduction
  where
    oldL = getLHS p
    oldR = getRHS p
    newKType = mapping g2
    newL = buildTypedGraphMorphism newKType (mapping g1) (mapping oldL)
    newR = buildTypedGraphMorphism newKType (mapping g3) (mapping oldR)
    newProduction = buildProduction newL newR []

restrictMorphisms' :: (TypedGraphMorphism a b, TypedGraphMorphism a b) -> (TypedGraphMorphism a b, TypedGraphMorphism a b)
restrictMorphisms' (a,b) = (removeOrphans a, removeOrphans b)
  where
    orphanNodes = orphanTypedNodes a `intersect` orphanTypedNodes b
    orphanEdges = orphanTypedEdges a `intersect` orphanTypedEdges b
    removeOrphans m = foldr removeNodeFromCodomain (foldr removeEdgeFromCodomain m orphanEdges) orphanNodes
