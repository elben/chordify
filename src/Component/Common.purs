module Component.Common where

import Prelude

import Chords (ChordInterval(..), ChordQuality(..))
import Halogen.HTML as HH
import Notes (Note(..), humanNote)

chordHtml :: forall p i. Note -> ChordQuality -> ChordInterval -> Array (HH.HTML p i)
chordHtml note@(Note name acc pos) q i =
  [ HH.text (humanNote note)
  , keyType
  , divide
  ] <> mod
  where
    keyType = case q of
                Minor -> HH.text "m"
                Suspended -> HH.text "sus"
                Augmented -> HH.text "sus"
                _ -> HH.text ""
    divide = case q of
               Minor ->
                 case i of
                   Maj7 -> HH.text "/"
                   _ -> HH.text ""
               _ -> HH.text ""
    mod = case i of
            Triad ->  [ HH.text "" ]
            Dom7 ->   [ HH.sup [] [ HH.text "7" ] ]
            Maj7 ->   [ HH.text "M", HH.sup [] [ HH.text "7" ] ]
            Second -> [ HH.text "2" ]
            Fourth -> [ HH.text "4" ]
            Dom9 ->   [ HH.text "9" ]