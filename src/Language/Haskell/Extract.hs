module Language.Haskell.Extract (
  functionExtractor,
  functionExtractorMap,
  locationModule
) where
import Language.Haskell.TH
import Text.Regex.Posix
import Data.Maybe
import Data.List
import Data.Char
import Language.Haskell.Exts.Extension

extractAllFunctions :: String -> String-> [String]
extractAllFunctions pattern file  = 
  nub $ filter (\f->f=~pattern::Bool) $ map (fst . head . lex) $ lines file


onlyJust f = map fromJust . filter isJust . map f

-- | Extract the names and functions from the module where this function is called.
-- 
--  > foo = "test"
--  > boo = "testing"
--  > bar = $(functionExtractor "oo$")
-- 
-- will automagically extract the functions ending with "oo" such as
-- 
-- > bar = [("foo",foo), ("boo",boo)]
functionExtractor :: String -> ExpQ
functionExtractor pattern =
  do loc <- location
     moduleCode <- runIO $ readFile $ loc_filename loc
     let functions = extractAllFunctions pattern moduleCode
         makePair n = TupE [ LitE $ StringL n , VarE $ mkName n]
     return $ ListE $ map makePair functions


-- functionExtractor' :: String -> Q [String]
-- functionExtractor' pattern =
--   do loc <- location
--      moduleCode <- runIO $ readFile $ loc_filename loc
--      let functions = extractAllFunctions pattern moduleCode
--      return functions

-- | Extract the names and functions from the module and apply a function to every pair.
-- 
-- Is very useful if the common denominator of the functions is just a type class.
--
-- > secondTypeclassTest =
-- >   do let expected = ["45", "88.8", "\"hej\""]
-- >          actual = $(functionExtractorMap "^tc" [|\n f -> show f|] )
-- >      expected @=? actual
-- > 
-- > tcInt :: Integer
-- > tcInt = 45
-- > 
-- > tcDouble :: Double
-- > tcDouble = 88.8
-- > 
-- > tcString :: String
-- > tcString = "hej"
functionExtractorMap :: String -> ExpQ -> ExpQ
functionExtractorMap pattern funcName =
  do loc <- location
     moduleCode <- runIO $ readFile $ loc_filename loc
     let functions :: [String]
         functions = extractAllFunctions pattern moduleCode
     fn <- funcName
     let makePair n = AppE (AppE (fn) (LitE $ StringL n)) (VarE $ mkName n)
     return $ ListE $ map makePair functions 

-- functionExtractorExpMap :: String -> (Exp -> ExpQ) -> ExpQ
-- functionExtractorExpMap pattern func =
--   do loc <- location
--      moduleCode <- runIO $ readFile $ loc_filename loc
--      let functions :: [String]
--          functions = extractAllFunctions pattern moduleCode
--      fn <- funcName
--      let makePair n = AppE (AppE (fn) (LitE $ StringL n)) (VarE $ mkName n)
--      return $ ListE $ map makePair functions   

-- | Extract the name of the current module.
locationModule :: ExpQ
locationModule =
  do loc <- location
     return $ LitE $ StringL $ loc_module loc
