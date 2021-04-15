module Server where

import Prelude
import Data.DateTime.Instant (unInstant)
import Data.Int (ceil, toNumber) as Int
import Data.Maybe (Maybe(..))
import Data.Time.Duration (Milliseconds)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Now (now)
import Effect.Random (random)
import Isomers.Node.Server (serve) as Isomers.Node.Server
import Isomers.Response.Types (HtmlString(..))
import Isomers.Web.Builder (webSpec)
import Isomers.Web.Server (renderToApi)
import Isomers.Web.Types (WebSpec(..))
import Pages (randomInt, serverTimestamp) as Pages
import React.Basic (JSX)
import React.Basic.DOM (body_, html) as DOM
import React.Basic.DOM.Server (renderToString) as DOM
import Spec (mkWebSpec) as Spec

handlers ∷
  { randomInt ∷ { "application/json" ∷ { max ∷ Int } → Aff Int }
  , serverTimestamp ∷ { "application/json" ∷ {} → Aff Milliseconds }
  }
handlers =
  { randomInt:
      { "application/json":
          \{ max } → do
            r ← liftEffect random
            pure $ Int.ceil $ Int.toNumber max * r
      }
  , serverTimestamp:
      { "application/json": const $ unInstant <$> liftEffect now }
  }

page ∷ JSX → JSX
page content = React.do
  DOM.html
    $ { lang: "en", children: _ }
        [ DOM.body_ [ content ] ]

main ∷ Effect Unit
main = do
  components ← { randomInt: _, serverTimestamp: _ } <$> Pages.randomInt <*> Pages.serverTimestamp
  let
    web = webSpec $ Spec.mkWebSpec components

    WebSpec { spec } = web

    renderComponent = HtmlString <<< append "<!DOCTYPE html>\n" <<< DOM.renderToString <<< page

    handlers' = renderToApi web handlers renderComponent unit
  onClose ← Isomers.Node.Server.serve spec handlers' { hostname: "127.0.0.1", port: 10000, backlog: Nothing } (log "127.0.0.1:10000")
  onClose (log "Closed")
