-- | Test Suite for GraphProcess Module

import           Abstract.AdhesiveHLR
import           Abstract.Cocomplete
import           Data.List.NonEmpty   (fromList)
import           Graph.Graph
import           Graph.GraphMorphism
import           TypedGraph.Morphism


-- | COEQUALIZER TESTS

-- |  Case 1
--   -h->
-- A     B --> X
--   -h->

typeGraphOne = build [1] []

graphAOne = build [10,20,30,40] []
graphBOne = build [50,60,70,80] []

typedGraphAOne = buildGraphMorphism graphAOne typeGraphOne [(10,1),(20,1),(30,1),(40,1)] []
typedGraphBOne = buildGraphMorphism graphBOne typeGraphOne [(50,1),(60,1),(70,1),(80,1)] []

mappingMorphismHOne = buildGraphMorphism graphAOne graphBOne [(10,50),(20,60),(30,70),(40,80)] []
typedMorphismHOne = buildTypedGraphMorphism typedGraphAOne typedGraphBOne mappingMorphismHOne

testCaseOne = calculateCoequalizer typedMorphismHOne typedMorphismHOne



-- | Case 2
-- Same diagram that case 1, but graphs have edges

typeGraphTwo = build [1] [(1,1,1)]

graphATwo = build [10,20] [(100,20,10)]
graphBTwo = build [50,60,70] [(200,60,50),(300,60,50)]

typedGraphATwo = buildGraphMorphism graphATwo typeGraphTwo [(10,1),(20,1)] [(100,1)]
typedGraphBTwo = buildGraphMorphism graphBTwo typeGraphTwo [(50,1),(60,1),(70,1)] [(200,1),(300,1)]

mappingMorphismHTwo = buildGraphMorphism graphATwo graphBTwo [(10,50),(20,60)] [(100,200)]

typedMorphismHTwo = buildTypedGraphMorphism typedGraphATwo typedGraphBTwo mappingMorphismHTwo

testeCaseTwo = calculateCoequalizer typedMorphismHTwo typedMorphismHTwo



-- | Case 3 ( EXTRA TEST FOR PUSHOUT )

typeGraphThree = build [1] [(1,1,1)]

graphAThree = build [10,20,30] []
graphBThree = build [50,60,70,80] [(200,60,50),(300,70,60),(400,80,70)]

typedGraphAThree = buildGraphMorphism graphAThree typeGraphThree [(10,1),(20,1),(30,1)] []
typedGraphBThree = buildGraphMorphism graphBThree typeGraphThree [(50,1),(60,1),(70,1),(80,1)] [(200,1),(300,1),(400,1)]

mappingMorphismFThree = buildGraphMorphism graphAThree graphBThree [(10,50),(20,60),(30,70)] []
mappingMorphismGThree = buildGraphMorphism graphAThree graphBThree [(10,80),(20,50),(30,60)] []
mappingMorphismHThree = buildGraphMorphism graphAThree graphBThree [(10,60),(20,70),(30,80)] []

typedMorphismFThree = buildTypedGraphMorphism typedGraphAThree typedGraphBThree mappingMorphismFThree
typedMorphismGThree = buildTypedGraphMorphism typedGraphAThree typedGraphBThree mappingMorphismGThree
typedMorphismHThree = buildTypedGraphMorphism typedGraphAThree typedGraphBThree mappingMorphismHThree

testeCaseThreePUSHOUT = Abstract.AdhesiveHLR.calculatePushout typedMorphismFThree typedMorphismHThree
testCaseThree = calculateCoequalizer typedMorphismFThree typedMorphismGThree



-- | Case 4

typeGraphFour = build [1] [(1,1,1)]

graphAFour = build [10,20] [(100,20,10),(200,20,10),(300,20,10),(400,20,10)]
graphBFour = build [50,60] [(500,60,50),(600,60,50)]

typedGraphAFour = buildGraphMorphism graphAFour typeGraphFour [(10,1),(20,1)] [(100,1),(200,1),(300,1),(400,1)]
typedGraphBFour = buildGraphMorphism graphBFour typeGraphFour [(50,1),(60,1)] [(500,1),(600,1)]

mappingMorphismGFour = buildGraphMorphism graphAFour graphBFour [(10,50),(20,60)] [(100,600),(200,500),(300,600),(400,500)]
mappingMorphismHFour = buildGraphMorphism graphAFour graphBFour [(10,50),(20,60)] [(100,500),(200,500),(300,600),(400,500)]

typedMorphismGFour = buildTypedGraphMorphism typedGraphAFour typedGraphBFour mappingMorphismGFour
typedMorphismHFour = buildTypedGraphMorphism typedGraphAFour typedGraphBFour mappingMorphismHFour

testCaseFour = calculateCoequalizer typedMorphismHFour typedMorphismGFour



-- * N COEQUALIZER TESTS


-- | Test case 5

typeGraphFive = build [4,3,2,1] [(5,3,4),(4,2,4),(3,2,3),(2,2,1),(1,3,1)]

graphAFive = build [10,20,30,40] []
graphBFive = build [50,60,70,80] []

typedGraphAFive = buildGraphMorphism graphAFive typeGraphFive [(10,1),(20,1),(30,1),(40,1)] []
typedGraphBFive = buildGraphMorphism graphBFive typeGraphFive [(50,1),(60,1),(70,1),(80,1)] []

mappingMorphismFFive = buildGraphMorphism graphAFive graphBFive [(10,60),(20,50),(30,70),(40,80)] []
mappingMorphismGFive = buildGraphMorphism graphAFive graphBFive [(10,50),(20,60),(30,70),(40,80)] []
mappingMorphismHFive = buildGraphMorphism graphAFive graphBFive [(10,50),(20,80),(30,60),(40,70)] []

typedMorphismFFive = buildTypedGraphMorphism typedGraphAFive typedGraphBFive mappingMorphismFFive
typedMorphismGFive = buildTypedGraphMorphism typedGraphAFive typedGraphBFive mappingMorphismGFive
typedMorphismHFive = buildTypedGraphMorphism typedGraphAFive typedGraphBFive mappingMorphismHFive

testCaseFive = calculateNCoequalizer $ fromList [typedMorphismFFive, typedMorphismGFive, typedMorphismHFive]



-- | See COEqualizer test case One
testCaseSix = calculateNCoequalizer $ fromList [typedMorphismHOne,typedMorphismHOne]



-- | See COEqualizer test case Two
testCaseSeven = calculateNCoequalizer $ fromList [typedMorphismHTwo,typedMorphismHTwo]



-- | Test case 8

typeGraphEight = build [1] [(1,1,1)]

graphAEight = build [10,20] [(100,20,10)]
graphBEight = build [50,60,70,80] [(500,60,50),(600,70,60),(700,80,70)]

typedGraphAEight = buildGraphMorphism graphAEight typeGraphEight [(10,1),(20,1)] [(100,1)]
typedGraphBEight = buildGraphMorphism graphBEight typeGraphEight [(50,1),(60,1),(70,1),(80,1)] [(500,1),(600,1),(700,1)]

mappingMorphismFEight = buildGraphMorphism graphAEight graphBEight [(10,50),(20,60)] [(100,500)]

typedMorphismFEight = buildTypedGraphMorphism typedGraphAEight typedGraphBEight mappingMorphismFEight

testCaseEight = calculateNCoequalizer $ fromList [typedMorphismFEight]





main :: IO ()
main = return ()
