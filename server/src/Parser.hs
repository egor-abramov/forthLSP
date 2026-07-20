{-# LANGUAGE OverloadedStrings #-}

module Parser where

import Data.Text (Text)
import qualified Data.Text as T
import Data.Void (Void)
import Syntax
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

type Parser = Parsec Void Text

withLocation :: Parser a -> Parser (Located a)
withLocation parser = do
  startPos <- getSourcePos
  result <- parser
  endPos <- getSourcePos

  let toPosition pos =
        Position
          { line = unPos (sourceLine pos),
            character = unPos (sourceColumn pos)
          }
      locRange = Range (toPosition startPos) (toPosition endPos)

  return $ Located locRange result

pIdentifier :: Parser Text
pIdentifier = do
  ident <- some (alphaNumChar <|> char '_')
  return $ T.pack ident

pStringLiteral :: Parser Text
pStringLiteral = do
  _ <- char '"'
  content <- takeWhileP Nothing (/= '"')
  _ <- char '"'
  return content

pVarDefNum :: Parser VarDef
pVarDefNum = do
  _ <- string "var" <* notFollowedBy alphaNumChar
  space1
  VarDefNum <$> pIdentifier

pVarDefString :: Parser VarDef
pVarDefString = do
  _ <- string "string" <* notFollowedBy alphaNumChar
  space1
  strVal <- pStringLiteral
  space1
  VarDefString strVal <$> pIdentifier

pVarDefArray :: Parser VarDef
pVarDefArray = do
  _ <- string "array" <* notFollowedBy alphaNumChar
  space1
  VarDefArray <$> pIdentifier

pImportExp :: Parser ImportExp
pImportExp = do
  _ <- string "import" <* notFollowedBy alphaNumChar
  space1
  ImportExp <$> pIdentifier

pMathOp :: Parser Instruction
pMathOp =
  choice
    [ MathOp Add <$ string "+",
      MathOp Sub <$ string "-",
      MathOp Mul <$ string "*",
      MathOp Div <$ string "/",
      MathOp Mod <$ string "%",
      MathOp Cells <$ (string "cells" <* notFollowedBy alphaNumChar)
    ]

pLogicOp :: Parser Instruction
pLogicOp =
  choice
    [ LogicOp And <$ (string "and" <* notFollowedBy alphaNumChar),
      LogicOp Not <$ (string "not" <* notFollowedBy alphaNumChar)
    ]

pStackOp :: Parser Instruction
pStackOp =
  choice
    [ StackOp Dup <$ (string "dup" <* notFollowedBy alphaNumChar),
      StackOp Drop <$ (string "drop" <* notFollowedBy alphaNumChar),
      StackOp Swap <$ (string "swap" <* notFollowedBy alphaNumChar)
    ]

pMemOp :: Parser Instruction
pMemOp =
  choice
    [ MemOp MemWrite <$ string "!",
      MemOp MemRead <$ string "@"
    ]

pIoOp :: Parser Instruction
pIoOp =
  choice
    [ IoOp IoRead <$ (string "read" <* notFollowedBy alphaNumChar),
      IoOp IoNumWrite <$ string ".",
      IoOp IoCharWrite <$ (string "emit" <* notFollowedBy alphaNumChar)
    ]

pFlagOp :: Parser Instruction
pFlagOp =
  choice
    [ FlagOp EqZero <$ string "=0",
      FlagOp GtZero <$ string ">0",
      FlagOp LtZero <$ string "<0"
    ]

pContract :: Parser Contract
pContract = do
  _ <- string "("
  space
  t <- L.decimal
  space
  _ <- string "->"
  space
  p <- L.decimal
  _ <- string ")"
  return $ Contract t p

pProcedureDef :: Parser ProcedureDef
pProcedureDef = do
  _ <- string ":"
  space1
  name <- pIdentifier
  space
  cont <- pContract
  space1
  body <- manyTill (withLocation pInstruction <* space) (string ";")
  return $ ProcedureDef name cont body

pLoopExp :: Parser Instruction
pLoopExp = do
  _ <- string "loop" <* notFollowedBy alphaNumChar
  space1
  body <- manyTill (withLocation pInstruction <* space) (string "endloop" <* notFollowedBy alphaNumChar)
  return $ LoopExp body

pLitNumber :: Parser Instruction
pLitNumber = try $ do
  val <- L.signed (return ()) L.decimal
  return $ LitNumber val

pCallIdentifier :: Parser Instruction
pCallIdentifier = CallIdentifier <$> pIdentifier

pExecToken :: Parser Instruction
pExecToken = do
  _ <- string "'"
  ExecToken <$> pIdentifier

pExecuteOp :: Parser Instruction
pExecuteOp = do
  _ <- string "execute" <* notFollowedBy alphaNumChar
  return ExecuteOp

pCondExp :: Parser Instruction
pCondExp = do
  _ <- string "if" <* notFollowedBy alphaNumChar
  space1
  ifBody <-
    manyTill
      (withLocation pInstruction <* space)
      (lookAhead ((string "else" <* notFollowedBy alphaNumChar) <|> (string "then" <* notFollowedBy alphaNumChar)))
  elseBody <- parseElse <|> parseThen
  return $ CondExp ifBody elseBody
  where
    parseElse = do
      _ <- string "else" <* notFollowedBy alphaNumChar
      space1
      body <- manyTill (withLocation pInstruction <* space) (string "then")
      return $ Just body

    parseThen = do
      _ <- string "then" <* notFollowedBy alphaNumChar
      return Nothing

pInstruction :: Parser Instruction
pInstruction =
  pLitNumber
    <|> pMathOp
    <|> pLogicOp
    <|> pStackOp
    <|> pFlagOp
    <|> pMemOp
    <|> pIoOp
    <|> pLoopExp
    <|> pCondExp
    <|> pCallIdentifier
    <|> pExecToken
    <|> pExecuteOp

pVarDef :: Parser VarDef
pVarDef = pVarDefNum <|> pVarDefString <|> pVarDefArray

pTerm :: Parser Term
pTerm =
  TermProcedure
    <$> pProcedureDef
      <|> TermVar
    <$> pVarDef
      <|> TermImport
    <$> pImportExp
      <|> TermInstruction
    <$> pInstruction

sc :: Parser ()
sc = L.space space1 empty empty

pLocatedTerm :: Parser (Located Term)
pLocatedTerm = withLocation pTerm

pProgram :: Parser Program
pProgram = between sc eof (many (pLocatedTerm <* sc))

parseFile :: String -> Text -> Either String Program
parseFile fileName content =
  case parse pProgram fileName content of
    Left err -> Left (errorBundlePretty err)
    Right program -> Right program