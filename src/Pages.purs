module Pages where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Isomers.HTTP (Exchange(..)) as HTTP
import React.Basic (JSX)
import React.Basic.DOM (li, text, ul) as DOM
import React.Basic.Hooks (component)

randomInt ∷ Effect (HTTP.Exchange { max ∷ Int } Int → JSX)
randomInt =
  component "RandomInt" \(HTTP.Exchange _ res) → React.do
    pure $ case res of
      Just (Right i) → DOM.text $ "Server provided a random number: " <> show i
      Just (Left e) → DOM.text $ "Problem?"
      Nothing → DOM.text "Waiting for data?"

serverTimestamp ∷ Effect (HTTP.Exchange {} Milliseconds → JSX)
serverTimestamp =
  component "ServerTimestamp" \(HTTP.Exchange _ res) → React.do
    pure $ case res of
      Just (Right t) → DOM.text $ "Server provided a current timestamp:" <> show t
      Just (Left e) → DOM.text $ "Problem?"
      Nothing → DOM.text "Waiting for data?"

httpStats ∷ Effect ({ ips ∷ Int, requests ∷ Int } → JSX)
httpStats = do
  component "HTTPStats" \r → React.do
    pure
      $ DOM.ul
      $ { children: _ }
          [ DOM.li { children: [ DOM.text $ "Ips:" <> show r.ips ] }
          , DOM.li { children: [ DOM.text $ "Requests:" <> show r.requests ] }
          ]
