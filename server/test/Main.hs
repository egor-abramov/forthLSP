{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.Aeson (Value, toJSON)
import qualified Data.ByteString.Lazy as BL
import Data.Char (isSpace)
import Data.List (dropWhileEnd)
import Data.Text (Text)
import Data.Yaml (FromJSON, ToJSON, decodeFileThrow, encode)
import Data.Yaml.Pretty (defConfig, encodePretty)
import GHC.Generics (Generic)
import Language.LSP.Protocol.Capabilities (fullLatestClientCaps)
import Language.LSP.Test
import System.Process (readProcess)
import Test.Tasty
import Test.Tasty.Golden

data TestCase = TestCase
  { code :: Text,
    expected :: Value
  }
  deriving (Generic, Show)

instance FromJSON TestCase

instance ToJSON TestCase

main :: IO ()
main = do
  rawBinPath <- readProcess "cabal" ["-v0", "list-bin", "server"] ""
  let serverCommand = dropWhileEnd isSpace rawBinPath

  defaultMain (tests serverCommand)

tests :: String -> TestTree
tests serverCommand =
  testGroup
    "Golden Tests"
    [ mkYamlTest serverCommand "Cat (S)" "test/golden/cat.yml",
      mkYamlTest serverCommand "Apply Twice (S)" "test/golden/apply_twice.yml",
      mkYamlTest serverCommand "Sort (S)" "test/golden/sort.yml",
      mkYamlTest serverCommand "Math (S)" "test/golden/math.yml",
      mkYamlTest serverCommand "Stack Underflow (F)" "test/golden/s_underflow.yml",
      mkYamlTest serverCommand "Stack Underflow In Function (F)" "test/golden/f_s_underflow.yml",
      mkYamlTest serverCommand "No Such Lib (F)" "test/golden/no_lib.yml",
      mkYamlTest serverCommand "Wrong Contract (F)" "test/golden/wrong_contract.yml"
    ]

mkYamlTest :: String -> String -> FilePath -> TestTree
mkYamlTest serverCommand testName yamlPath =
  goldenVsString testName yamlPath $ do
    testCase <- decodeFileThrow yamlPath

    diagnostics <- runSession serverCommand fullLatestClientCaps "test" $ do
      _doc <- createDoc "virtual.fth" "forth" (code testCase)
      waitForDiagnostics

    let actualTestCase =
          TestCase
            { code = code testCase,
              expected = toJSON diagnostics
            }

    pure $ BL.fromStrict (encodePretty defConfig actualTestCase)