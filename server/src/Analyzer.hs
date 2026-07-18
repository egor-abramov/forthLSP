module Analyzer where

import Control.Monad (foldM)
import Syntax

stackEffect :: Instruction -> (Int, Int)
stackEffect (MathOp _) = (2, 1)
stackEffect (LogicOp Not) = (1, 1)
stackEffect (LogicOp _) = (2, 1)
stackEffect (FlagOp _) = (1, 1)
stackEffect (MemOp MemWrite) = (2, 0)
stackEffect (MemOp MemRead) = (1, 1)
stackEffect (IoOp IoRead) = (0, 1)
stackEffect (IoOp _) = (1, 0)
stackEffect (LitNumber _) = (1, 0)
stackEffect (CallIdentifier _) = (0, 1)
stackEffect (ExecToken _) = (0, 1)
stackEffect ExecuteOp = (1, 0)
stackEffect _ = (0, 0)

data AnalyzeError = AnalyzeError
  { errRange :: Range,
    expected :: Int,
    actual :: Int,
    instr :: Instruction
  }

analyzeInstruction :: Int -> Located Instruction -> Either AnalyzeError Int
analyzeInstruction depth (Located loc instruction) =
  case instruction of
    _
      | isSimple instruction ->
          let (takes, puts) = stackEffect instruction
           in if depth < takes
                then Left $ AnalyzeError loc takes depth instruction
                else Right $ depth - takes + puts
    CondExp ifBranch elseBranch -> analyzeCond loc depth ifBranch elseBranch
    LoopExp body -> Right depth
    _ -> Right depth
  where
    isSimple (CondExp _ _) = False
    isSimple (LoopExp _) = False
    isSimple _ = True

analyzeCond :: Range -> Int -> [Located Instruction] -> Maybe [Located Instruction] -> Either AnalyzeError Int
analyzeCond loc depth ifBranch elseBranch = do
    let depthAfterIf = depth - 1
    if depthAfterIf < 0
        then Left $ AnalyzeError loc 1 depth (CondExp [] Nothing)
        else do
            depthIfPath <- foldM analyzeInstruction depthAfterIf ifBranch

            depthElsePath <- case elseBranch of
                Just instructions -> foldM analyzeInstruction depthAfterIf instructions
                Nothing-> Right depthAfterIf
            if depthIfPath == depthElsePath
                then Right depthIfPath
                else Left $ error "If and else branches leave stack in different states"