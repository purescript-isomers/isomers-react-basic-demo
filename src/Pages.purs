module Pages where

import Prelude

import Data.Array (singleton) as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Time.Duration (Milliseconds(..))
import Data.Tuple.Nested (type (/\), (/\))
import Data.Variant (Variant)
import Data.Variant (inj) as Variant
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Random (random)
import Effect.Random (randomInt) as Random
import Global.Unsafe (unsafeStringify)
import Isomers.HTTP (Exchange(..)) as HTTP
import React.Basic (JSX, fragment)
import React.Basic.DOM (a, div_, li, text, ul) as DOM
import React.Basic.DOM.Events (preventDefault)
import React.Basic.Events (handler, handler_) as RB.Events
import React.Basic.Events (syntheticEvent, unsafeEventFn)
import React.Basic.Hooks (bind, discard) as React
import React.Basic.Hooks (component, useState)
import Type.Prelude (SProxy(..))
import Web.HTML (window)
import Web.HTML.Window (alert)

randomInt ∷ Effect (_ /\ HTTP.Exchange { max ∷ Int } Int → JSX)
randomInt = do
  component "RandomInt" \(router /\ HTTP.Exchange _ res) → React.do
    pure $ case res of
      Just (Right i) → fragment
        [ DOM.div_ $ [ DOM.text $ "Server provided a random number: " <> show i ]
        , DOM.div_ $ Array.singleton $ DOM.a
          { onClick:
            RB.Events.handler
              preventDefault
              (const $ do
                -- | Here we are using the old one captured in closure
                router.navigate $ router.request.serverTimestamp {}
              )
          , href: "#"
          , children: [ DOM.text $ "Server timestamp" ]
          }
        ]
      Just (Left e) → fragment [ DOM.text $ "Problem?" ]
      Nothing → DOM.text "Waiting for data?"

serverTimestamp ∷ Effect (_ /\ HTTP.Exchange {} Milliseconds → JSX)
serverTimestamp =
  component "ServerTimestamp" \(router /\ HTTP.Exchange _ res) → React.do
    pure $ case res of
      Just (Right t) → fragment
        [ DOM.text $ "Server provided a current timestamp:" <> show t
        , DOM.div_ $ Array.singleton $ DOM.a
          { onClick:
            RB.Events.handler
              preventDefault
              (const $ do
                -- | Here we are using the old one captured in closure
                router.navigate $ router.request.randomInt { max: 100 }
              )
          , href: "#"
          , children: [ DOM.text $ "Random int" ]
          }
        ]
      Just (Left e) → DOM.text $ "Problem?" <> unsafeStringify e
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

make = { randomInt: _, serverTimestamp: _ } <$> randomInt <*> serverTimestamp
