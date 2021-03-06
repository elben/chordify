module Component.Fretboards where

import Prelude

import Chords (Chord)
import Component.Fretboard as FB
import Data.Array as A
import Data.Maybe (Maybe(..))
import Halogen (ClassName(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP

-- Represents a fretboard's position. Used as the fretboard's ID and also the slot type.
type FretboardId = Int

-- This component displays a list of Fretboards. Keep track of them in the array of FretboardStates.
type State =
  { fretboards :: Array FretboardState
  }

-- The id is used as the slot index. We use this index to know which fretboard to delete when a user
-- clicks "X" on a fretboard.
type FretboardState =
  { chord :: Chord
  , id :: FretboardId }

-- Queries that this component needs to handle.
--
-- * HandleFretboardMessage captures Fretboard Messages.
-- * ReplaceChords is used by the parent component communicates with this component to give the list of
--   chords to render Fretboards for.
data Query a
  = HandleFretboardMessage FretboardId FB.Message a
  | ReplaceChords (Array Chord) a

-- The input to this component is the list of chords to render Fretboards for.
data Input
  = FretboardChords (Array Chord)

-- Messages this component raises to the parent.
-- * NotifyRemove - raised when a the inner Fretboard component clicks "X" to remove the fretboard.
data Message = NotifyRemove FretboardId

component :: forall m. H.Component HH.HTML Query Input Message m
component =
  H.parentComponent
    { initialState
    , render
    , eval
    , receiver
    }

  where

  initialState :: Input -> State
  initialState (FretboardChords chords) = { fretboards: A.mapWithIndex (\i c -> { chord: c, id: i } ) chords }

  render :: State -> H.ParentHTML Query FB.Query FretboardId m
  render s =
    HH.div
      [ HP.classes [ ClassName "added-fretboards" ] ]
      [ HH.h3 [] [ HH.text (if A.null s.fretboards then "" else "Added Chords") ]
      , HH.div [ HP.classes [ ClassName "fretboards" ] ] (map renderFretboard s.fretboards) ]

  renderFretboard :: FretboardState -> H.ParentHTML Query FB.Query FretboardId m
  renderFretboard fbState =
    HH.slot (fbState.id)
            FB.component
            { chord: fbState.chord, displayActions: true }
            (HE.input (HandleFretboardMessage fbState.id))

  eval :: Query ~> H.ParentDSL State Query FB.Query FretboardId Message m
  eval (HandleFretboardMessage fbId FB.NotifyRemove next) = do
    H.modify_ (\s -> s { fretboards = A.filter (\fb -> fb.id /= fbId) s.fretboards } )
    -- Tell parent that this fretboard was removed, so that parent can also update internal state
    H.raise (NotifyRemove fbId)
    pure next
  eval (ReplaceChords chords next) = do
    -- Replace the list of fretboards entirely with this new array of chords
    H.modify_ (_ { fretboards = A.mapWithIndex (\i c -> { chord: c, id: i }) chords } )
    pure next

  receiver :: Input -> Maybe (Query Unit)
  receiver (FretboardChords chords) = Just (ReplaceChords chords unit)