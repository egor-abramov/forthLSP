module Analyzer where

import Control.Monad (foldM)
import qualified Data.Map as M
import Data.Text (Text)
import Syntax

data SymbolInfo = ProcSymbol Contract | VarSymbol

type Env = M.Map Text SymbolInfo

buildEnv :: Program -> Env
buildEnv terms = M.fromList $ concatMap extract terms
  where
    extract (Located _ (TermProcedure p)) = [(procName p, ProcSymbol (contract p))]
    extract (Located _ (TermVar v)) = case v of
      VarDefNum name -> [(name, VarSymbol)]
      VarDefString _ name -> [(name, VarSymbol)]
      VarDefArray name -> [(name, VarSymbol)]
    extract _ = []

stackEffect :: Instruction -> (Int, Int)
stackEffect (MathOp _) = (2, 1)
stackEffect (LogicOp Not) = (1, 1)
stackEffect (LogicOp _) = (2, 1)
stackEffect (StackOp Dup) = (0, 1)
stackEffect (StackOp Drop) = (1, 0)
stackEffect (StackOp Swap) = (2, 2)
stackEffect (FlagOp _) = (1, 1)
stackEffect (MemOp MemWrite) = (2, 0)
stackEffect (MemOp MemRead) = (1, 1)
stackEffect (IoOp IoRead) = (0, 1)
stackEffect (IoOp _) = (1, 0)
stackEffect (LitNumber _) = (0, 1)
stackEffect (ExecToken _) = (0, 1)
stackEffect ExecuteOp = (1, 0)
stackEffect _ = (0, 0)

data AnalyzeError
  = InstructionUnderflow Range Int Int Instruction
  | BranchMismatch Range Int Int
  | LoopMismatch Range Int
  | ContractMismatch Range Text Int Int
  | UndefinedProcedure Range Text

analyzeInstruction :: Env -> Int -> Located Instruction -> Either AnalyzeError Int
analyzeInstruction env depth (Located loc instruction) =
  case instruction of
    CondExp ifBranch elseBranch -> analyzeCond env loc depth ifBranch elseBranch
    LoopExp body -> analyzeLoop env loc depth body
    CallIdentifier name ->
      case M.lookup name env of
        Just (ProcSymbol (Contract t p)) ->
          if depth < t
            then Left $ InstructionUnderflow loc t depth instruction
            else Right $ depth - t + p
        Just VarSymbol ->
          Right $ depth + 1
        Nothing -> Left $ UndefinedProcedure loc name
    _ ->
      let (t, p) = stackEffect instruction
       in if depth < t
            then Left $ InstructionUnderflow loc t depth instruction
            else Right $ depth - t + p

analyzeCond :: Env -> Range -> Int -> [Located Instruction] -> Maybe [Located Instruction] -> Either AnalyzeError Int
analyzeCond env loc depth ifBranch elseBranch = do
  let depthAfterIf = depth - 1
  if depthAfterIf < 0
    then Left $ InstructionUnderflow loc 1 depth (CondExp [] Nothing)
    else do
      depthIfPath <- foldM (analyzeInstruction env) depthAfterIf ifBranch

      depthElsePath <- case elseBranch of
        Just instructions -> foldM (analyzeInstruction env) depthAfterIf instructions
        Nothing -> Right depthAfterIf
      if depthIfPath == depthElsePath
        then Right depthIfPath
        else Left $ BranchMismatch loc depthIfPath depthElsePath

analyzeLoop :: Env -> Range -> Int -> [Located Instruction] -> Either AnalyzeError Int
analyzeLoop env loc depth body = do
  depthAfteIteration <- foldM (analyzeInstruction env) depth body
  let delta = depthAfteIteration - depth
  if delta == 1
    then Right depth
    else Left $ LoopMismatch loc delta

containsExecute :: [Located Instruction] -> Bool
containsExecute = any check
  where
    check (Located _ instr) = case instr of
      ExecuteOp -> True
      CondExp ifBody elseBody ->
        containsExecute ifBody || maybe False containsExecute elseBody
      LoopExp body -> containsExecute body
      _ -> False

analyzeProcedure :: Env -> Range -> ProcedureDef -> Either AnalyzeError Int
analyzeProcedure env loc procedure = do
  let c = contract procedure
      t = takes c
      p = puts c
      name = procName procedure
      isUnsafe = containsExecute (procBody procedure)

  finalDepth <- foldM (analyzeInstruction env) t (procBody procedure)
  if isUnsafe
    then Right p
    else do
      if finalDepth == p
        then Right finalDepth
        else Left $ ContractMismatch loc name p finalDepth

analyzeTerm :: Env -> Int -> Located Term -> Either AnalyzeError Int
analyzeTerm env depth (Located loc term) = do
  case term of
    TermProcedure proc -> do
      _ <- analyzeProcedure env loc proc
      Right depth
    TermInstruction instr -> do
      analyzeInstruction env depth (Located loc instr)
    TermVar _ -> do
      Right depth
    TermImport _ -> do
      Right depth

analyzeProgram :: Program -> Either AnalyzeError Int
analyzeProgram program = do
  let env = buildEnv program
  foldM (analyzeTerm env) 0 program