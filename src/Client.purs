module Client where

import Prelude

import Control.Comonad (extract) as Comonad
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Debug.Trace (traceM)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Isomers.Client.Fetch (Scheme(..))
import Isomers.Response (RawServer(..)) as Response
import Isomers.Spec (Spec(..))
import Isomers.Spec (client) as Isomers.Spec
import Isomers.Web.Client.Router (webRouter)
import Isomers.Web.Types (WebSpec(..))
import Network.HTTP.Types (ok200)
import React.Basic (fragment)
import React.Basic.DOM (hydrate, render, text) as DOM
import React.Basic.Hooks (bind, discard) as React
import React.Basic.Hooks (component) as React
import Spec (make) as Spec
import Web.HTML (window) as HTML
import Web.HTML.HTMLDocument (body) as HTMLDocument
import Web.HTML.HTMLElement (toElement) as HTMLElement
import Web.HTML.Window (document) as Window
import Wire.React (useSignal)

rawOk body = Response.RawServer
  { body: body
  , headers: mempty
  , status: ok200
  }

main ∷ Effect Unit
main = do
  web@(WebSpec { spec }) ← Spec.make
  let
    hostInfo = { scheme: HTTP, hostName: "127.0.0.1", port: 10000 }
    client = Isomers.Spec.client hostInfo spec

  body ← HTMLDocument.body =<< Window.document =<< HTML.window
  launchAff_ $ do
    webRouter { doc: rawOk $ DOM.text "LOADING" } web hostInfo >>= case _, body of
      Right router, Just appContainer → do
        app ← liftEffect $ React.component "App" \_ → React.do
          page ← useSignal router.signal
          pure $ fragment
            [ router.component
            , Comonad.extract page
            ]

        liftEffect $ DOM.hydrate (app {}) (HTMLElement.toElement appContainer)
      Right router, Nothing → do
        traceM "no body?"
        pure unit
      Left err, _ → do
        traceM err
        pure unit
