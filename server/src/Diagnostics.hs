{-# LANGUAGE OverloadedStrings #-}

module Diagnostics where

import Analyzer
import qualified Data.Text as T
import Language.LSP.Protocol.Types (Diagnostic (..), DiagnosticSeverity (..))
import qualified Language.LSP.Protocol.Types as L
import Syntax

toLspPosition :: Position -> L.Position
toLspPosition (Position l c) = L.Position (fromIntegral $ l - 1) (fromIntegral $ c - 1)

toLspRange :: Range -> L.Range
toLspRange (Range s e) = L.Range (toLspPosition s) (toLspPosition e)

mkDiagnostic :: Syntax.Range -> T.Text -> L.Diagnostic
mkDiagnostic r msg =
  Diagnostic
    { _range = toLspRange r,
      _severity = Just DiagnosticSeverity_Error,
      _code = Nothing,
      _codeDescription = Nothing,
      _source = Just "forth-analyzer",
      _message = msg,
      _tags = Nothing,
      _relatedInformation = Nothing,
      _data_ = Nothing
    }

convertAnalyzeError :: AnalyzeError -> Diagnostic
convertAnalyzeError (InstructionUnderflow r req act _) =
  mkDiagnostic r $ "Stack underflow: expected " <> T.pack (show req) <> " elements, but got " <> T.pack (show act) <> "."
convertAnalyzeError (BranchMismatch r left right) =
  mkDiagnostic r $ "Unbalanced branch: IF path left " <> T.pack (show left) <> " elements, while ELSE path left " <> T.pack (show right) <> "."
convertAnalyzeError (LoopMismatch r delta) =
  mkDiagnostic r $ "Loop body must have a net stack effect of exactly +1 (condition flag), but actual net effect is " <> T.pack (show delta) <> "."
convertAnalyzeError (UndefinedProcedure r name) =
  mkDiagnostic r $ "Undefined procedure: '" <> name <> "'."
convertAnalyzeError (ContractMismatch r name req act) =
  mkDiagnostic r $ "Contract violation in procedure '" <> name <> "': expected " <> T.pack (show req) <> " elements, but got " <> T.pack (show act) <> "."