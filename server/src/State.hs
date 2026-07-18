module State where

import Control.Concurrent.STM (TVar, atomically, modifyTVar', newTVarIO, readTVarIO)
import qualified Data.Map as M
import Data.Text (Text)
import Language.LSP.Protocol.Types (Uri)
import Syntax (Program)

data DocumentState = DocumentState
  { docText :: Text,
    docProgram :: Maybe Program
  }

newtype ServerState = ServerState
  { vfs :: TVar (M.Map Uri DocumentState)
  }

newServerState :: IO ServerState
newServerState = do
  tvar <- newTVarIO M.empty
  return $ ServerState tvar

getDocument :: ServerState -> Uri -> IO (Maybe DocumentState)
getDocument state uri = do
  documentMap <- readTVarIO (vfs state)
  return $ M.lookup uri documentMap

updateDocument :: ServerState -> Uri -> Text -> Maybe Program -> IO ()
updateDocument state uri text program = do
  let newState = DocumentState {docText = text, docProgram = program}
  atomically $ modifyTVar' (vfs state) (M.insert uri newState)