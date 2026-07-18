module Syntax where

import Data.Text (Text)

data Position = Position {line :: Int, character :: Int}
  deriving (Show, Eq)

data Range = Range {start :: Position, end :: Position}
  deriving (Show, Eq)

data Located a = Located {range :: Range, unLoc :: a}
  deriving (Show, Eq)

data MathOpType = Add | Sub | Mul | Div | Mod | Cells
  deriving (Show, Eq)

data LogicOpType = And | Not
  deriving (Show, Eq)

data StackOpType = Dup | Drop | Swap
  deriving (Show, Eq)

data MemOpType = MemWrite | MemRead
  deriving (Show, Eq)

data IoOpType = IoRead | IoNumWrite | IoCharWrite
  deriving (Show, Eq)

data FlagOpType = EqZero | GtZero | LtZero
  deriving (Show, Eq)

data Instruction
  = MathOp MathOpType
  | LogicOp LogicOpType
  | StackOp StackOpType
  | FlagOp FlagOpType
  | MemOp MemOpType
  | IoOp IoOpType
  | LoopExp [Located Instruction]
  | CondExp [Located Instruction] (Maybe [Located Instruction])
  | LitNumber Int
  | CallIdentifier Text
  | ExecToken Text
  | ExecuteOp
  deriving (Show, Eq)

newtype ImportExp = ImportExp Text deriving (Show, Eq)

data VarDef = VarDefNum Text | VarDefString Text Text | VarDefArray Text
  deriving (Show, Eq)

data Contract = Contract
  { takes :: Int,
    puts :: Int
  }
  deriving (Show, Eq)

data ProcedureDef = ProcedureDef
  { procName :: Text,
    contract :: Contract,
    procBody :: [Located Instruction]
  }
  deriving (Show, Eq)

data Term
  = TermProcedure ProcedureDef
  | TermVar VarDef
  | TermImport ImportExp
  | TermInstruction Instruction
  deriving (Show, Eq)

type Program = [Located Term]