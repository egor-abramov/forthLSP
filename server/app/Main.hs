{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Analyzer
import Control.Monad.IO.Class (liftIO)
import Data.Maybe
import qualified Data.Text as T
import Diagnostics
import Language.LSP.Protocol.Message
import Language.LSP.Protocol.Types
import Language.LSP.Server
import Language.LSP.VFS
import Parser
import State
import qualified Syntax as S

processDocument :: ServerState -> Uri -> T.Text -> LspM () ()
processDocument state uri text = do
  let fileName = fromMaybe "<unknown>" (uriToFilePath uri)

  case parseFile fileName text of
    Left parseErr -> do
      let fallbackRange = S.Range (S.Position 1 1) (S.Position 1 2)
          diag = mkDiagnostic fallbackRange (T.pack parseErr)

      liftIO $ updateDocument state uri text Nothing
      sendDiagnostics uri [diag]
    Right program -> do
      liftIO $ updateDocument state uri text (Just program)

      case analyzeProgram program of
        Left analyzeError -> do
          let diag = convertAnalyzeError analyzeError
          sendDiagnostics uri [diag]
        Right _ -> do
          sendDiagnostics uri []

sendDiagnostics :: Uri -> [Diagnostic] -> LspM () ()
sendDiagnostics uri diags = do
  sendNotification SMethod_TextDocumentPublishDiagnostics $
    PublishDiagnosticsParams uri Nothing diags

serverHandlers :: ServerState -> Handlers (LspM ())
serverHandlers state =
  mconcat
    [ notificationHandler SMethod_TextDocumentDidOpen $ \msg -> do
        let doc = msg._params._textDocument
        processDocument state doc._uri doc._text,
      notificationHandler SMethod_TextDocumentDidChange $ \msg -> do
        let uri = msg._params._textDocument._uri
        mdoc <- getVirtualFile (toNormalizedUri uri)
        case mdoc of
          Just vf -> processDocument state uri (virtualFileText vf)
          Nothing -> pure (),
      notificationHandler SMethod_Initialized $ \_msg -> do
        pure (),
     notificationHandler SMethod_TextDocumentDidSave $ \_msg -> do
        pure ()
    ]

main :: IO Int
main = do
  state <- newServerState

  runServer $
    ServerDefinition
      { defaultConfig = (),
        configSection = "forthServer",
        parseConfig = \_ _ -> Right (),
        onConfigChange = \_ -> pure (),
        doInitialize = \env _req -> pure $ Right env,
        staticHandlers = \_env -> serverHandlers state,
        interpretHandler = \env -> Iso (runLspT env) liftIO,
        options =
          defaultOptions
            { optTextDocumentSync =
                Just $
                  TextDocumentSyncOptions
                    { _openClose = Just True,
                      _change = Just TextDocumentSyncKind_Full,
                      _willSave = Just False,
                      _willSaveWaitUntil = Just False,
                      _save = Just $ InR $ SaveOptions $ Just False
                    }
            }
      }