module Loader where

import Analyzer (Env, buildEnv)
import qualified Data.Map as M
import Data.Maybe (mapMaybe)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Parser (parseFile)
import System.Directory (doesFileExist, doesDirectoryExist)
import System.FilePath ((<.>), (</>), takeDirectory)

findProjectRoot :: FilePath -> IO FilePath
findProjectRoot startPath = checkDir (takeDirectory startPath)
  where
    checkDir currentDir = do
      let parentDir = takeDirectory currentDir
      if currentDir == parentDir
        then return "."
        else do
          hasLibs <- doesDirectoryExist (currentDir </> "libs")
          if hasLibs
            then return currentDir
            else checkDir parentDir

loadSingleImport :: FilePath -> T.Text -> IO (Env, Maybe String)
loadSingleImport projectRoot moduleName = do
  let fileName = T.unpack moduleName
      path = projectRoot </> "libs" </> fileName <.> "fth"

  exists <- doesFileExist path
  if exists
    then do
      content <- TIO.readFile path
      case parseFile path content of
        Right program -> return (buildEnv program, Nothing)
        Left err -> return (M.empty, Just $ "Parse error in " ++ fileName ++ ".fth: " ++ err)
    else
      return (M.empty, Just $ "Library not found: " ++ path)

loadImports :: FilePath -> [T.Text] -> IO (Env, [String])
loadImports projectRoot paths = do
  results <- mapM (loadSingleImport projectRoot) paths
  let envs = map fst results
      errs = mapMaybe snd results
  return (M.unions envs, errs)