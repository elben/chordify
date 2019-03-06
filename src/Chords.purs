module Chords where

import Data.Maybe
import Prelude

import Data.List (List(..), (:))
import Data.List as L
import Data.Array as A
import Data.Map (Map)
import Data.Map as M
import Data.Tuple (Tuple(..))

-- Note position. C is position 0, C# and Db are position 1, and so on.
type Pos = Int

-- Represents a certain number of half-step.
type Step = Int

type Octave = Int

-- A Note consists of its letter, accidental, and position.
data Note = Note String Accidental Pos

c  :: Note
c  = Note "C" Natural 0
cs :: Note
cs = Note "C" Sharp   1
df :: Note
df = Note "D" Flat    1
d  :: Note
d  = Note "D" Natural 2
ds :: Note
ds = Note "D" Sharp   3
ef :: Note
ef = Note "E" Flat    3
e  :: Note
e  = Note "E" Natural 4
f  :: Note
f  = Note "F" Natural 5
fs :: Note
fs = Note "F" Sharp   6
gf :: Note
gf = Note "G" Flat    6
g  :: Note
g  = Note "G" Natural 7
gs :: Note
gs = Note "G" Sharp   8
af :: Note
af = Note "A" Flat    8
a  :: Note
a  = Note "A" Natural 9
as :: Note
as = Note "A" Sharp   10
bf :: Note
bf = Note "B" Flat    10
b  :: Note
b  = Note "B" Natural 11

allNotes :: Array Note
allNotes = [c, cs, df, d, ds, ef, e, f, fs, gf, g, gs, af, a, as, bf, b]

notes :: Array (Array Note)
notes = [
    [c]      -- 0
  , [cs, df] -- 1
  , [d]      -- 2
  , [ds, ef] -- 3
  , [e]      -- 4
  , [f]      -- 5
  , [fs, gf] -- 6
  , [g]      -- 7
  , [gs, af] -- 8
  , [a]      -- 9
  , [as, bf] -- 10
  , [b]      -- 11
  ]

-- Neutral keys have a default accidental. (E.g. C is flat, G is sharp).
defaultAccidental :: Pos -> Accidental
defaultAccidental 0 = Flat
defaultAccidental 2 = Sharp
defaultAccidental 4 = Sharp
defaultAccidental 5 = Flat
defaultAccidental 7 = Sharp
defaultAccidental 9 = Sharp
defaultAccidental 11 = Flat
defaultAccidental _ = Sharp

getNoteName :: Note -> String
getNoteName (Note name _ _) = name

getNoteAccidental :: Note -> Accidental
getNoteAccidental (Note _ accidental _) = accidental

humanNote :: Note -> String
humanNote (Note name acc pos) = name <> show acc

posToNote :: Pos -> Note
posToNote pos =
  let choices = fromMaybe [] (A.index notes pos)
  in fromMaybe (Note "?" Natural pos) (A.index choices 0)

-- Find the note for the given root key's accidental. For example, if we are in G major,
-- our accidental would be Sharp for G. So if the Pos we are looking for is 6 (F# or Gb),
-- we should choose F#.
findNoteForAccidental :: Pos
                      -> Accidental
                      -> Maybe Note
findNoteForAccidental pos accidental = do
  choices <- A.index notes pos
  if A.length choices == 1
    -- If there's only one choice, it's the Natural note. We don't care about which accidental we
    -- came from.
    then A.index choices 0
    -- If there are multiple choices, choose the one that fits the accidental of the root key.
    else A.find (\(Note _ acc p) -> p == pos && acc == accidental) choices

derive instance eqNote :: Eq Note

instance showNote :: Show Note where
  show (Note name acc pos) = "Note " <> name <> show acc <> " " <> show pos

data Accidental = Natural | Sharp | Flat

derive instance eqAccidental :: Eq Accidental

instance showAccidental :: Show Accidental where
  show Natural = ""
  show Sharp = "♯"
  show Flat = "♭"

-- Pitch is a position plus an octave. "Middle C" on the piano is C4, or the
-- fourth octave.
data Pitch = Pitch Pos Octave

derive instance eqPitch :: Eq Pitch

instance showPitch :: Show Pitch where
  show (Pitch pos oct) = "Pitch " <> show pos <> " " <> show oct

-- Define the various chords we can make. Though the precise definition of "chord quality" differs than the ones listed
-- here, we use "chord quality" to mean various ways we currently support a chord can be created.
--
-- References:
--
-- https://en.wikipedia.org/wiki/Chord_(music)#Symbols
-- https://en.wikipedia.org/wiki/Chord_(music)#Basics
-- https://en.wikipedia.org/wiki/Interval_(music)#Quality
--
data ChordQuality =
    Major
  | Minor
  | Suspended
  | Augmented
  | Diminished

instance chordQualityShow :: Show ChordQuality where
  show Major = "Major"
  show Minor = "Minor"
  show Suspended = "Sus"
  show Augmented = "Aug"
  show Diminished = "Dim"
derive instance chordQualityEq :: Eq ChordQuality
derive instance chordQualityOrd :: Ord ChordQuality

humanChordQuality :: ChordQuality -> String
humanChordQuality Major = ""
humanChordQuality Minor = "m"
humanChordQuality Suspended = "sus"
humanChordQuality Augmented = "aug"
humanChordQuality Diminished = "dim"

chordQualities :: Array ChordQuality
chordQualities = [ Major, Minor, Suspended, Augmented, Diminished ]

data ChordInterval =
    Triad
  -- Seventh
  | Dom7
  | Maj7
  -- Addition
  -- Second and Fourth also works with Suspended quality to make sus2 and sus4.
  | Second
  | Fourth
  | Dom9 -- The dominant 9th (e.g. in C major: C, E, G, Bb, D)
  -- | Maj9

chordIntervals :: Array ChordInterval
chordIntervals = [ Triad, Dom7, Maj7, Second, Fourth, Dom9 ]

instance chordIntervalShow :: Show ChordInterval where
  show Triad = ""
  show Dom7 = "7"
  show Maj7 = "M7"
  show Second = "2"
  show Fourth = "4"
  show Dom9 = "9"

derive instance chordIntervalEq :: Eq ChordInterval
derive instance chordIntervalOrd :: Ord ChordInterval

-- https://en.wikipedia.org/wiki/Chord_(music)#Examples
humanChordInterval :: ChordInterval -> String
humanChordInterval Triad = ""
humanChordInterval Dom7 = "7"
humanChordInterval Maj7 = "M7"
humanChordInterval Second = "2"
humanChordInterval Fourth = "4"
humanChordInterval Dom9 = "9"

humanChordMod :: ChordQuality -> ChordInterval -> String
humanChordMod q i =
  let divide = case q of
                 Minor ->
                   case i of
                     Triad -> ""
                     Dom7 -> ""
                     _ -> "/"
                 _ -> ""
  in humanChordQuality q <> divide <> humanChordInterval i

-- Represents a fingering on a string. (F 0) is equivalent to the open string. X means don't
-- play that string.
data Finger = F Int
            | X

getFingerPos :: Finger -> Int
getFingerPos (F n) = n
getFingerPos X = -1

fingNoPlay :: Finger -> Boolean
fingNoPlay X = true
fingNoPlay _ = false

instance fingerShow :: Show Finger where
  show (F pos) = show pos
  show X = "X"
derive instance fingerEq :: Eq Finger
derive instance fingerOrd :: Ord Finger

-- Specifies a barre fingering. The three Ints are:
-- * The fret number that is barred
-- * The left-most string index (starting at 0)
-- * The right-most string index
data Barre = Barre Int Int Int

-- The fingering from left-most string when looking at the fretboard.
data Fingering = Fingering (Maybe Barre) (Array Finger)

getBarre :: Fingering -> Maybe Barre
getBarre (Fingering barre _) = barre

-- Easier way of defining tuples. Precedence is *lower* than List's (:), so that we can create
-- tuples in lists like this:
--
-- 1 ==> 10 : 2 ==> 20 : Nil
--
infix 7 Tuple as ==>

-- Mapping of Note, ChordQuality to the fingering.
ukeChords :: Map Pos (Map ChordQuality (Map ChordInterval Fingering))
ukeChords = M.fromFoldable
    [
    -- C
      0 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> fing 0 0 0 3
            , Dom7   ==> fing 0 0 0 1
            , Maj7   ==> fing 0 0 0 2
            , Dom9   ==> fing 3 2 0 3
            ]
        , Minor      ==> M.fromFoldable
            [ Triad  ==> fing 0 3 3 3
            , Dom7   ==> fing 3 3 3 3
            , Maj7   ==> fing 4 3 3 3
            , Dom9   ==> fing 5 3 6 5
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> fing 0 2 3 3
            , Fourth ==> fing 0 0 1 3
            ]
        ]

    -- C# / Db
    , 1 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> finb 1 1 1 4 (Barre 1 0 3)
            , Dom7   ==> finb 1 1 1 2 (Barre 1 0 3)
            , Maj7   ==> finb 1 1 1 3 (Barre 1 0 3)
            , Dom9   ==> fing 4 3 1 4
            ]
        , Minor      ==> M.fromFoldable
            [ Triad  ==> fini (F 1) (F 1) (F 0) X Nothing
            , Dom7   ==> fing 1 1 0 2
            , Maj7   ==> fing 1 0 0 4
            , Dom9   ==> fing 4 3 0 4
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> fing 1 3 4 4
            , Fourth ==> fing 1 1 2 4
            ]
        ]

    -- D
    , 2 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> fing 2 2 2 0
            , Dom7   ==> finb 2 2 2 3 (Barre 2 0 3)
            , Maj7   ==> finb 2 2 2 4 (Barre 2 0 3)
            , Dom9   ==> fing 5 4 2 5
            ]
        , Minor      ==> M.fromFoldable
            [ Triad  ==> fing 2 2 1 0
            , Dom7   ==> fing 2 2 1 3
            , Maj7   ==> finb 6 5 5 5 (Barre 5 1 3)
            , Dom9   ==> fing 5 4 1 5
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> fing 2 2 0 0
            , Fourth ==> fing 0 2 3 0
            ]
        ]

    -- D# / Eb
    , 3 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> fing 3 3 3 1
            , Dom7   ==> finb 3 3 3 4 (Barre 3 0 3)
            , Maj7   ==> finb 3 3 3 5 (Barre 3 0 3)
            , Dom9   ==> fing 0 3 1 4
            ]
        , Minor      ==> M.fromFoldable
            [ Triad  ==> fing 3 3 2 1
            , Dom7   ==> fing 3 3 2 4
            , Maj7   ==> finb 3 2 2 6 (Barre 2 1 3)
            , Dom9   ==> fing 6 5 1 6
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> finb 3 3 1 1 (Barre 1 2 3)
            , Fourth ==> finb 1 3 4 1 (Barre 1 0 3)
            ]
        ]

    -- E
    , 4 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> fing 1 4 0 2
            , Dom7   ==> fing 1 2 0 2
            , Maj7   ==> fing 1 3 0 2
            , Dom9   ==> fing 7 6 4 7
            ]
        , Minor      ==> M.fromFoldable
            [ Triad  ==> fing 0 4 3 2
            , Dom7   ==> fing 0 2 0 2
            , Maj7   ==> fing 1 3 0 2
            , Dom9   ==> fing 0 6 0 5
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> finb 4 4 2 2 (Barre 2 2 3)
            , Fourth ==> fing 4 4 0 0
            ]
        ]

    -- F
    , 5 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> fing 2 0 1 0
            , Dom7   ==> fing 2 3 1 3
            , Maj7   ==> fing 2 4 1 3
            , Dom9   ==> fing 0 3 1 0
            ]
        , Minor      ==> M.fromFoldable
            [ Triad  ==> fing 1 0 1 3
            , Dom7   ==> finb 1 3 1 3 (Barre 1 0 3)
            , Maj7   ==> finb 1 4 1 3 (Barre 1 0 3)
            , Dom9   ==> fing 0 5 4 6
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> fing 0 0 1 3
            , Fourth ==> fing 3 0 1 1
            ]
        ]

    -- F# / Gb
    , 6 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> finb 3 1 2 1 (Barre 1 1 3)
            , Dom7   ==> fing 3 4 1 4
            , Maj7   ==> fing 3 5 1 4
            , Dom9   ==> finb 1 4 2 1 (Barre 1 0 3)
            ]
        , Minor      ==> M.fromFoldable
            [ Triad  ==> fing 2 1 2 0
            , Dom7   ==> fing 2 4 2 4
            , Maj7   ==> finb 2 5 2 4 (Barre 2 0 3)
            , Dom9   ==> fing 11 9 12 11
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> finb 1 1 2 4 (Barre 1 0 3)
            , Fourth ==> fing 4 1 2 2
            ]
        ]

    -- G
    , 7 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> fing 0 2 3 2
            , Dom7   ==> fing 0 2 1 2
            , Maj7   ==> fing 0 2 2 2
            , Dom9   ==> fing 0 2 5 2
            ]
        , Minor      ==> M.fromFoldable
            [ Triad  ==> fing 0 2 3 1
            , Dom7   ==> fing 0 2 1 1
            , Maj7   ==> fing 0 2 2 1
            , Dom9   ==> fing 0 5 5 1
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> fing 0 2 3 0
            , Fourth ==> fing 0 2 3 3
            ]
        ]

    -- G# / Ab
    , 8 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> finb 5 3 4 3 (Barre 3 1 3)
            , Dom7   ==> fing 1 3 4 3
            , Maj7   ==> finb 1 3 3 3 (Barre 1 0 3)
            , Dom9   ==> fing 1 0 2 1
            ]
        , Minor      ==> M.fromFoldable
            [ Triad  ==> fing 4 3 4 2
            , Dom7   ==> fing 1 3 2 2
            , Maj7   ==> fing 0 3 4 2
            , Dom9   ==> fing 11 10 7 11
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> finb 1 3 4 1 (Barre 1 0 3)
            , Fourth ==> fing 1 3 4 4
            ]
        ]

    -- A
    , 9 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> fing 2 1 0 0
            , Dom7   ==> fing 0 1 0 0
            , Maj7   ==> fing 1 1 0 0
            , Dom9   ==> fing 2 1 3 2
            ]
        , Minor      ==> M.fromFoldable
            [ Triad  ==> fing 2 0 0 0
            , Dom7   ==> fing 0 0 0 0
            , Maj7   ==> fing 1 0 0 0
            , Dom9   ==> fing 2 0 3 2
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> finb 2 4 5 2 (Barre 2 0 3)
            , Fourth ==> fing 2 2 0 0
            ]
        ]

    -- A# / Bb
    , 10 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> finb 3 2 1 1 (Barre 1 2 3)
            , Dom7   ==> finb 1 2 1 1 (Barre 1 0 3)
            , Maj7   ==> fing 3 2 1 0
            , Dom9   ==> fing 3 2 4 3
            ]
        , Minor ==> M.fromFoldable
            [ Triad  ==> finb 3 1 1 1 (Barre 1 1 3)
            , Dom7   ==> finb 1 1 1 1 (Barre 1 0 3)
            , Maj7   ==> fing 3 1 1 0
            , Dom9   ==> fing 3 1 4 3
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> fing 3 0 1 1
            , Fourth ==> fing 0 2 3 3
            ]
        ]

    -- B
    , 11 ==> M.fromFoldable
        [ Major      ==> M.fromFoldable
            [ Triad  ==> finb 4 3 2 2 (Barre 2 2 3)
            , Dom7   ==> finb 2 3 2 2 (Barre 2 0 3)
            , Maj7   ==> fing 4 3 2 1
            , Dom9   ==> fing 4 3 5 4
            ]
        , Minor ==> M.fromFoldable
            [ Triad  ==> finb 4 3 3 3 (Barre 3 1 3)
            , Dom7   ==> finb 1 1 1 1 (Barre 1 0 3)
            , Maj7   ==> finb 3 2 2 2 (Barre 2 1 3)
            , Dom9   ==> fing 4 2 5 4
            ]
        , Suspended  ==> M.fromFoldable
            [ Second ==> fing 4 1 2 2
            , Fourth ==> finb 4 4 2 2 (Barre 2 2 3)
            ]
        ]
    ]

fini :: Finger -> Finger -> Finger -> Finger -> Maybe Barre -> Fingering
fini a b c d barre = Fingering barre [a, b, c, d]

-- Fingering without barre.
fing :: Int -> Int -> Int -> Int -> Fingering
fing a b c d = Fingering Nothing [intToFinger a, intToFinger b, intToFinger c, intToFinger d]

-- Fingering with barre.
finb :: Int -> Int -> Int -> Int -> Barre -> Fingering
finb a b c d barre = Fingering (Just barre) [intToFinger a, intToFinger b, intToFinger c, intToFinger d]

ukeChord :: ChordQuality
         -> ChordInterval
         -> Int -> Int -> Int -> Int
         -> Tuple (Tuple ChordQuality ChordInterval) Fingering
ukeChord q i a b c d = (q ==> i) ==> Fingering Nothing [intToFinger a, intToFinger b, intToFinger c, intToFinger d]

intToFinger :: Int -> Finger
intToFinger n = if n < 0 then X else F n

findUkeChord :: Pos -> ChordQuality -> ChordInterval -> Maybe Fingering
findUkeChord p q i = M.lookup p ukeChords >>= M.lookup q >>= M.lookup i