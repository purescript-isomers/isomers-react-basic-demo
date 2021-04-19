module Server where

import Prelude

import Data.DateTime.Instant (unInstant)
import Data.Either (Either(..))
import Data.Int (ceil, toNumber) as Int
import Data.Maybe (Maybe(..))
import Data.Time.Duration (Milliseconds)
import Debug.Trace (traceM)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Now (now)
import Effect.Random (random)
import Isomers.HTTP.ContentTypes (JavaScript)
import Isomers.Node.Server (serve) as Isomers.Node.Server
import Isomers.Response (Okayish)
import Isomers.Response.Okayish (fromEither) as Okayish
import Isomers.Response.Okayish.Type (NotFound) as Okayish.Type
import Isomers.Response.Okayish.Type (NotFound) as Okayish.Types
import Isomers.Response.Types (HtmlString(..), JavascriptString(..))
import Isomers.Web.Builder (webSpec)
import Isomers.Web.Client.Router (fakeWebRouter)
import Isomers.Web.Server (renderToApi)
import Isomers.Web.Types (WebSpec(..))
import Node.Path (FilePath)
import Pages (make) as Pages
import React.Basic (JSX)
import React.Basic.DOM (body_, head, html, meta, script, text) as DOM
import React.Basic.DOM.Server (renderToString) as DOM
import Server.Static (JSFileStream(..))
import Server.Static (serveFile, serveJsFile) as Server.Static
import Spec (make, mkWebSpec) as Spec
import Type.Row (type (+))

handlers ∷
  { static ∷ Array FilePath → Aff (Okayish (Okayish.Type.NotFound HtmlString + ()) (JSFileStream ()))
  , randomInt ∷ { "application/json" ∷ { max ∷ Int } → Aff Int }
  , serverTimestamp ∷ { "application/json" ∷ {} → Aff Milliseconds }
  }
handlers =
  { static: Server.Static.serveJsFile "/home/paluh/programming/purescript/projects/isomers-react-basic-examples/static"
    -- traceM segments
    -- pure $ JavascriptString "alert('TEST')"
  , randomInt:
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
        [ DOM.head
            $ { children: _ }
                [ DOM.meta { charSet: "utf-8" }
                ]
        , DOM.body_ [ content ]
        , DOM.script { defer: false, src: "/static/App.Client.js" }
        ]

main ∷ Effect Unit
main = do
  web ← Spec.make
  let
    clientRouter = fakeWebRouter (DOM.text "Test") web

    -- (WebSpec { spec } ∷ ?_) = web
    WebSpec { spec } = web

    renderComponent = HtmlString <<< append "<!DOCTYPE html>\n" <<< DOM.renderToString <<< page
    handlers' = renderToApi web handlers renderComponent clientRouter

  onClose ← Isomers.Node.Server.serve spec handlers' { hostname: "127.0.0.1", port: 10000, backlog: Nothing } (log "127.0.0.1:10000")
  onClose (log "Closed")
