module Component.App where

import Prelude

import Chords (Chord, ChordInterval(..), ChordQuality(..))
import Component.ChordSelector as CS
import Component.Fretboard as FB
import Component.Fretboards as FBS
import Component.Search as S
import Data.Array as A
import Data.Either.Nested (Either4)
import Data.FoldableWithIndex (foldlWithIndex)
import Data.Functor.Coproduct.Nested (Coproduct4)
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.String (null)
import Effect.Class (class MonadEffect)
import Halogen (ClassName(..))
import Halogen as H
import Halogen.Component.ChildPath as CP
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Notes as N

-- The state of the app.
--
-- * chord  - the active chord selected.
--
-- * chords - the list of chords added. Both the App component and the
--   Fretboards component need to sync this list of saved chords. Perhaps there's
--   a way where only Fretboards needs to know, but I haven't found a way. The
--   reason is that in the render function of the App component, I must pass in an
--   Input to the Fretboards component. I also only have access to the current
--   State of App. So how do I say: the user hit "Add" for this chord, please
--   inject this into Fretboards' chords list? Other than using some temporary
--   variable in App's state? This means that when the user deletes a chord, we
--   need to update both App's and Fretboards' list of chords.
--
-- * lookaheadChord - the chord that was triggered by the look-ahead Search
--   query functionality. If there's a non-empty query string, we'll show the
--   lookahead chord. Otherwise, show the manually user-selected chord, in the
--   `chord` attribute.
--
-- * chordSelectorChanged - A "temporary" boolean. Used to tell the Search
--   component to clear its query string whenever the user usees the
--   ChordSelector to select a query. This prevents the weird scenario where the
--   Search bar says something different than the selected chord.
--
type State =
  { chord :: Chord
  , chords :: Array Chord
  , lookaheadChord :: Maybe Chord
  , chordSelectorChanged :: Boolean
  }

-- Queries App can make.
--
-- * HandleChordSelector, HandleFretboard, HandleFretboards are wrappers around the messages that
--   these components can raise.
-- * AddChord is triggered when the user hits the [Add] button.
--
data Query a
  = HandleChordSelector CS.Message a
  | HandleFretboard FB.Message a
  | HandleFretboards FBS.Message a
  | HandleSearch S.Message a
  | AddChord a

-- Halogen requires a coproduct type of all the queriers a component's children can make.
type ChildQuery = Coproduct4 CS.Query FB.Query FBS.Query S.Query

-- A slot for each child component.
type ChildSlot = Either4 Unit Unit Unit Unit

initialChord :: Chord
initialChord = { note: N.c, quality: Major, interval: Triad }

-- MonadEffect m evidence needed to use liftEffect (in Search component).
component :: forall m. MonadEffect m=> H.Component HH.HTML Query Unit Void m
component =
  H.parentComponent
    { initialState: const initialState
    , render
    , eval
    , receiver: const Nothing
    }
  where

  initialState :: State
  initialState =
    { chord: initialChord
    , chords: []
    , lookaheadChord: Nothing
    , chordSelectorChanged: false
    }

  render :: State -> H.ParentHTML Query ChildQuery ChildSlot m
  render state =
    let chordAlreadyAdded = maybe false (const true) (A.findIndex ((==) state.chord) state.chords)
        addBtnClasses = 
          [ ClassName "selection"
          , ClassName "wide"
          , ClassName "btn"
          , ClassName (if chordAlreadyAdded then "not-clickable" else "clickable")
          , ClassName "add-chord"
          , ClassName (if chordAlreadyAdded then "already-added" else "")
          ]
        onClickProp = if chordAlreadyAdded then [] else [ HE.onClick (HE.input_ AddChord) ]
        searchInput = if state.chordSelectorChanged then S.ClearQueryString else S.NoInput
    in
      HH.div
        [ HP.classes [ClassName "main-component"] ]
        [ HH.div
            [ HP.classes [ClassName "top-component"] ]
            [ HH.div
                [ HP.classes [ClassName "chord-selector-section"] ]

                [
                -- Render the Search component
                  HH.slot' CP.cp4 unit S.component searchInput (HE.input HandleSearch)
                
                -- Render the ChordSelector component. The input is the selected
                -- chord, which may have come from itself, or from the search
                -- component. It emits a message whenever a valid chord is
                -- selected, which is passed via the HandleChordSelector
                -- wrapper.
                , HH.slot' CP.cp1 unit CS.component (CS.ChordSelectedInput state.chord) (HE.input HandleChordSelector)

                -- Render the [Add] button.
                , HH.div
                    (append [ HP.classes addBtnClasses ] onClickProp)
                    [ HH.text (if chordAlreadyAdded then "Already Added" else "Add") ]
                ]

              -- Render the current fretboard. Use the lookahead chord if it
              -- exists; otherwise the user-selected chord.
              , HH.div
                  [ HP.classes [ ClassName "fretboard-active" ] ]
                  [ HH.slot' CP.cp2 unit FB.component { chord: fromMaybe state.chord state.lookaheadChord, displayActions: false } (HE.input HandleFretboard) ]
            ]

        -- Render all the fretboards. Passes in the list of chords to render as input to the
        -- fretboard.
        , HH.slot' CP.cp3 unit FBS.component (FBS.FretboardChords state.chords) (HE.input HandleFretboards)
        ]

  eval :: Query ~> H.ParentDSL State Query ChildQuery ChildSlot Void m
  eval = case _ of
    HandleChordSelector (CS.ChordSelected chord) next -> do
      H.modify_ (_ { chord = chord, chordSelectorChanged = true })
      pure next
    HandleChordSelector CS.NoMessage next -> do
      pure next
    HandleFretboard m next -> do
      pure next
    HandleFretboards (FBS.NotifyRemove fbId) next -> do
      -- Remove by index
      H.modify_ (\s -> s { chords = foldlWithIndex (\i acc c -> if fbId == i then acc else A.snoc acc c) [] s.chords } )
      pure next
    HandleSearch (S.ChordSelectedMessage chord) next -> do
      -- Chord selected. Clear the lookahead chord so that we display the actual
      -- chord.
      H.modify_ (_ { chord = chord, lookaheadChord = Nothing })
      pure next
    HandleSearch (S.ChordLookaheadMessage chord) next -> do
      H.modify_ (_ { lookaheadChord = Just chord })
      pure next
    HandleSearch (S.QueryStringChangedMessage qs) next -> do
      s <- H.get

      -- If the query string was changed to empty, then clear the lookahead chord.
      let lookaheadChord = if null qs then Nothing else s.lookaheadChord

      -- A search query was typed, so "reset" chordSelectorChanged so that we
      -- won't clear the search query.
      H.modify_ (_ { lookaheadChord = lookaheadChord, chordSelectorChanged = false })
      pure next
    AddChord next -> do
      -- Add the "active" chord into the list of archived chords.
      H.modify_ (\st -> st { chords = A.snoc st.chords st.chord })
      pure next