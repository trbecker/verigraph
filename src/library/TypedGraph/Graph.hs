module TypedGraph.Graph
  ( TypedGraph
  , untypedGraph
  , typeGraph
  , TypedGraph.Graph.null
  , newNodesTyped
  , newEdgesTyped
  , nodesWithType
  , edgesWithType
  ) where

import           Abstract.Morphism
import           Graph.Graph         as G
import           Graph.GraphMorphism


-- | A typed graph is a morphism whose codomain is the type graph.
type TypedGraph a b = GraphMorphism a b

-- | Obtain the untyped version of the typed graph
untypedGraph :: TypedGraph a b -> Graph a b
untypedGraph = domain

-- | Obtain the type graph from a typed graph
typeGraph :: TypedGraph a b -> Graph a b
typeGraph = codomain

-- | Test if the typed graph is empty
null :: TypedGraph a b -> Bool
null = G.null . untypedGraph

-- | Infinite list of new node instances of a typed graph
newNodesTyped :: TypedGraph a b -> [NodeId]
newNodesTyped tg = newNodes $ untypedGraph tg

-- | Infinite list of new edge instances of a typed graph
newEdgesTyped :: TypedGraph a b -> [EdgeId]
newEdgesTyped tg = newEdges $ untypedGraph tg


-- | Obtain a list of tuples @(nodeId, typeId)@ for nodes in the graph.
nodesWithType :: TypedGraph a b -> [(NodeId, NodeId)]
nodesWithType tg =
  let
    withType node =
      (node, applyNodeUnsafe tg node)
  in
    map withType $ nodes (untypedGraph tg)


-- | Obtain a list of tuples @(edgeId, srcId, tgtId, typeId)@ for edges in the graph.
edgesWithType :: TypedGraph a b -> [(EdgeId, NodeId, NodeId, EdgeId)]
edgesWithType tg =
  let
    graph =
      untypedGraph tg

    withType edge =
      (edge, sourceOfUnsafe graph edge, targetOfUnsafe graph edge, applyEdgeUnsafe tg edge)
  in
    map withType $ edges graph
