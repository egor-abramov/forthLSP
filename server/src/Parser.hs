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

wordBoundary :: Parser ()
wordBoundary = notFollowedBy (alphaNumChar <|> char '_')

keyword :: Text -> Parser Text
keyword kw = try (string' kw <* wordBoundary)

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
  return $ T.toLower $ T.pack ident

pStringLiteral :: Parser Text
pStringLiteral = do
  _ <- char '"'
  content <- takeWhileP Nothing (/= '"')
  _ <- char '"'
  return content

pVarDefNum :: Parser VarDef
pVarDefNum = do
  _ <- keyword "var"
  space1
  VarDefNum <$> pIdentifier

pVarDefString :: Parser VarDef
pVarDefString = do
  _ <- keyword "string"
  space1
  strVal <- pStringLiteral
  space1
  VarDefString strVal <$> pIdentifier

pVarDefArray :: Parser VarDef
pVarDefArray = do
  _ <- keyword "array"
  space1
  VarDefArray <$> pIdentifier

pImportExp :: Parser ImportExp
pImportExp = do
  _ <- keyword "import"
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
      MathOp Cells <$ keyword "cells"
    ]

pLogicOp :: Parser Instruction
pLogicOp =
  choice
    [ LogicOp And <$ keyword "and",
      LogicOp Not <$ keyword "not"
    ]

pStackOp :: Parser Instruction
pStackOp =
  choice
    [ StackOp Dup <$ keyword "dup",
      StackOp Drop <$ keyword "drop",
      StackOp Swap <$ keyword "swap"
    ]

pMemOp :: Parser Instruction
pMemOp =
  choice
    [ MemOp MemWrite <$ keyword "!",
      MemOp MemRead <$ keyword "@"
    ]

pIoOp :: Parser Instruction
pIoOp =
  choice
    [ IoOp IoRead <$ keyword "read",
      IoOp IoNumWrite <$ keyword ".",
      IoOp IoCharWrite <$ keyword "emit"
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
  _ <- keyword "loop"
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
  space1
  ExecToken <$> pIdentifier

pExecuteOp :: Parser Instruction
pExecuteOp = do
  _ <- keyword "execute"
  return ExecuteOp

pCondExp :: Parser Instruction
pCondExp = do
  _ <- keyword "if"
  space1
  ifBody <-
    manyTill
      (withLocation pInstruction <* space)
      (lookAhead (keyword "else" <|> keyword "then"))
  elseBody <- parseElse <|> parseThen
  return $ CondExp ifBody elseBody
  where
    parseElse = do
      _ <- keyword "else"
      space1
      body <- manyTill (withLocation pInstruction <* space) (string "then")
      return $ Just body

    parseThen = do
      _ <- keyword "then"
      return Nothing

pInstruction :: Parser Instruction
pInstruction =
  pLitNumber
    <|> pExecToken
    <|> pExecuteOp
    <|> pMathOp
    <|> pLogicOp
    <|> pStackOp
    <|> pFlagOp
    <|> pMemOp
    <|> pIoOp
    <|> pLoopExp
    <|> pCondExp
    <|> pCallIdentifier

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

extractImports :: Program -> [Text]
extractImports terms = [path | Located _ (TermImport (ImportExp path)) <- terms]
