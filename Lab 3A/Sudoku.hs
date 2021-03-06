module Sudoku where

import Test.QuickCheck
import Data.Char(digitToInt)
import Data.List
import Data.Maybe

------------------------------------------------------------------------------

-- | Representation of sudoku puzzles (allows some junk)
type Cell = Maybe Int -- a single cell
type Row  = [Cell]    -- a row is a list of cells

data Sudoku = Sudoku [Row]
 deriving ( Show, Eq )

rows :: Sudoku -> [Row]
rows (Sudoku ms) = ms

-- | A sample sudoku puzzle
example :: Sudoku
example =
    Sudoku
      [ [j 3,j 6,n  ,n  ,j 7,j 1,j 2,n  ,n  ]
      , [n  ,j 5,n  ,n  ,n  ,n  ,j 1,j 8,n  ]
      , [n  ,n  ,j 9,j 2,n  ,j 4,j 7,n  ,n  ]
      , [n  ,n  ,n  ,n  ,j 1,j 3,n  ,j 2,j 8]
      , [j 4,n  ,n  ,j 5,n  ,j 2,n  ,n  ,j 9]
      , [j 2,j 7,n  ,j 4,j 6,n  ,n  ,n  ,n  ]
      , [n  ,n  ,j 5,j 3,n  ,j 8,j 9,n  ,n  ]
      , [n  ,j 8,j 3,n  ,n  ,n  ,n  ,j 6,n  ]
      , [n  ,n  ,j 7,j 6,j 9,n  ,n  ,j 4,j 3]
      ]
  where
    n = Nothing
    j = Just


-- * A1

-- | allBlankSudoku is a sudoku with just blanks
allBlankSudoku :: Sudoku
allBlankSudoku = Sudoku (replicate 9 row)
  where row = replicate 9 Nothing

-- * A2

-- | isSudoku sud checks if sud is really a valid representation of a sudoku
-- puzzle
isSudoku :: Sudoku -> Bool
isSudoku (Sudoku [])   = False
isSudoku (Sudoku rows) = checkValidNumbers rows && checkSize (Sudoku rows)

-- Checks if a list of rows contains valid numbers
checkValidNumbers :: [Row] -> Bool
checkValidNumbers = foldr ((&&) . all validNumber) True

-- Checks if a Cell contains a valid number, 
-- helper function for checkValidNumber 
validNumber :: Cell -> Bool
validNumber cell = isNothing cell || checkIfCellIsFilled cell

-- Check if whole Sudoku board is a 9x9 board
checkSize :: Sudoku -> Bool
checkSize (Sudoku [])                      = False 
checkSize (Sudoku rows) | length rows /= 9 = False
                        | otherwise        = checkRowSize rows

-- Checks to see if all row sizes are equal to 9,
-- helper function for checkSize
checkRowSize :: [Row] -> Bool
checkRowSize []         = True
checkRowSize (row:rows) = length row == 9 && checkRowSize rows


-- * A3

-- | isFilled sud checks if sud is completely filled in,
-- i.e. there are no blanks
isFilled :: Sudoku -> Bool
isFilled (Sudoku [])         = True
isFilled (Sudoku (row:rows)) = all checkIfCellIsFilled row
                               && isFilled (Sudoku rows)

-- Helper functions for isFilled, checks if a cell is filled
checkIfCellIsFilled :: Cell -> Bool
checkIfCellIsFilled cell = cell `elem` validCells
    where validCells = [Just n | n <- [1..9]]


------------------------------------------------------------------------------

-- * B1

-- | printSudoku sud prints a nice representation of the sudoku sud on
-- the screen
printSudoku :: Sudoku -> IO ()
printSudoku (Sudoku [])         = putStrLn ""
printSudoku (Sudoku rows) = putStrLn (buildRows rows)

-- Convert each row into a string
buildRows :: [Row] -> String
buildRows []         = ""
buildRows (row:rows) = rowString ++ "\n" ++ buildRows rows
     where rowString = unwords [cellToString cells | cells <- row]

-- Converts the cell to a String representing that value
cellToString :: Cell -> String
cellToString Nothing   = "."
cellToString (Just a)  = show a


-- * B2

-- | readSudoku file reads from the file, and either delivers it, or stops
-- if the file did not contain a sudoku
readSudoku :: FilePath -> IO Sudoku
readSudoku fileName = do
  string <- readFile fileName
  if string == ""
    then error "Not a valid sudoku"
  else
    (if isSudoku (Sudoku (readRows (lines string)))
       then return (Sudoku (readRows (lines string)))
     else error "Not a valid sudoku"
    )



-- Taken from Test.LeanCheck.Core module. Maps a function to a matrix
mapT :: (a -> b) -> [[a]] -> [[b]]
mapT  =  map . map

-- Convert a list of strings into a list of Rows
readRows :: [[Char]] -> [Row]
readRows = mapT charToCell

-- Converts a char to a cell of the same value
charToCell :: Char -> Cell
charToCell '.'   = Nothing
charToCell char  = Just (digitToInt char)


------------------------------------------------------------------------------

-- * C1

-- | cell generates an arbitrary cell in a Sudoku
cell :: Gen Cell
cell = frequency [(1, digits), (9, empty)]
  where
    digits = Just <$> choose (1,9)
    empty = return Nothing

-- * C2

-- | an instance for generating Arbitrary Sudokus
instance Arbitrary Sudoku where
  arbitrary = do
    row <- vectorOf 9 cell
    let rows = [row | n <- [1..9]]
    return (Sudoku rows)

 -- hint: get to know the QuickCheck function vectorOf

-- * C3

-- Property for sudokus
prop_Sudoku :: Sudoku -> Bool
prop_Sudoku = isSudoku


------------------------------------------------------------------------------

type Block = [Cell] -- a Row is also a Cell


-- * D1

-- Removes the Nothings, then removes duplicates.
-- If after duplicate removal the length is shorter, then
-- the block had duplicates and is not an okay block
isOkayBlock :: Block -> Bool
isOkayBlock block = length (nub specialBlock) >= length specialBlock
  where specialBlock = filter isJust block

-- * D2

-- Gets the blocks of a sudoku
blocks :: Sudoku -> [Block]
blocks (Sudoku [])         = []
blocks (Sudoku rows) = rows ++ trasposed ++ getSquare rows
  where trasposed    = transpose rows

-- Helper function for blocks, gets all the squares(3x3) of a sudoku
getSquare :: [Row] -> [Block]
getSquare []         = [] 
getSquare rows = 
  [concatMap (take 3 . drop i) ((take 3 . drop j) rows)
  | i <- [0, 3, 6], j <- [0, 3, 6]]

-- Verifies that there are a total of 27 blocks for a suduko and
-- that the length of every block is 9
prop_blocks_lengths :: Sudoku -> Bool
prop_blocks_lengths (Sudoku [])         = False
prop_blocks_lengths (Sudoku rows) = length sudBlocks == 27  && 
                                  all (\ x -> length x == 9) sudBlocks
   where sudBlocks = blocks (Sudoku rows)

-- * D3

-- Checks if all blocks in a sudoku is valid 
isOkay :: Sudoku -> Bool
isOkay (Sudoku [])   = False
isOkay (Sudoku rows) = all isOkayBlock (blocks (Sudoku rows))


---- Part A ends here --------------------------------------------------------
------------------------------------------------------------------------------
---- Part B starts here ------------------------------------------------------


-- | Positions are pairs (row,column),
-- (0,0) is top left corner, (8,8) is bottom left corner
type Pos = (Int,Int)

-- * E1

blanks :: Sudoku -> [Pos]
blanks = undefined

--prop_blanks_allBlanks :: ...
--prop_blanks_allBlanks =


-- * E2

(!!=) :: [a] -> (Int,a) -> [a]
xs !!= (i,y) = undefined

--prop_bangBangEquals_correct :: ...
--prop_bangBangEquals_correct =


-- * E3

update :: Sudoku -> Pos -> Cell -> Sudoku
update = undefined

--prop_update_updated :: ...
--prop_update_updated =


------------------------------------------------------------------------------

-- * F1


-- * F2


-- * F3


-- * F4
