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
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Now (now)
import Effect.Random (random)
import Heterogeneous.Mapping (class HMap, class Mapping, hmap)
import Isomers.Contrib.Type.Eval.Foldable (Foldl')
import Isomers.HTTP.ContentTypes (JavaScript)
import Isomers.Node.Server (serve) as Isomers.Node.Server
import Isomers.Response (Okayish)
import Isomers.Response.Okayish (fromEither) as Okayish
import Isomers.Response.Okayish.Type (NotFound) as Okayish.Type
import Isomers.Response.Okayish.Type (NotFound) as Okayish.Types
import Isomers.Response.Types (HtmlString(..), JavascriptString(..))
import Isomers.Server.Handler (unifyMonad) as Isomers.Server
import Isomers.Web.Builder (webSpec)
import Isomers.Web.Client.Router (fakeWebRouter)
import Isomers.Web.Server (renderToApi)
import Isomers.Web.Types (WebSpec(..))
import Node.Path (FilePath)
import Pages (make) as Pages
import Prim.Row (class Lacks) as Row
import React.Basic (JSX)
import React.Basic.DOM (body_, head, html, meta, script, text) as DOM
import React.Basic.DOM.Server (renderToString) as DOM
import Run (Run(..))
import Server.Static (JSFileStream(..))
import Server.Static (serveFile, serveJsFile) as Server.Static
import Spec (make, mkWebSpec) as Spec
import Type.Equality (to) as Type.Equality
import Type.Eval (class Eval, Lift, kind TypeExpr)
import Type.Eval.Foldable (Foldr)
import Type.Eval.Function (type (<<<)) as E
import Type.Eval.RowList (FromRow)
import Type.Prelude (class TypeEquals, RProxy(..))
import Type.Row (type (+))
import Unsafe.Coerce (unsafeCoerce)
import WebRow.Logger (runToConsole, warning) as Logger
import WebRow.Resource (runBaseResource')

randomInt { max } = do
  Logger.warning "log from webrow"
  r ← liftEffect random
  pure $ Int.ceil $ Int.toNumber max * r

-- | We can interpret handlers locally
-- | using this mapping.
data InterpretHandler m m'
  = InterpretHandler (m ~> m')

instance mappingInterpretHandler ∷ TypeEquals (n a) (m a) ⇒ Mapping (InterpretHandler m m') (req → n a) (req → m' a) where
  mapping (InterpretHandler interpreter) f = map (interpreter <<< Type.Equality.to) f
else instance mappingInterpretHandlerRec ∷ HMap (InterpretHandler m m') { | rec } { | rec' } ⇒ Mapping (InterpretHandler m m') { | rec } { | rec' } where
  mapping i rec = hmap i rec

handlers =
  hmap (InterpretHandler (Logger.runToConsole))
    { static:
        Server.Static.serveJsFile "/home/paluh/programming/purescript/projects/isomers-react-basic-examples/static"
    , randomInt:
        { "application/json": randomInt
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

interpret = runBaseResource' <<< Logger.runToConsole

main ∷ Effect Unit
main = do
  web ← Spec.make
  let
    clientRouter = fakeWebRouter (DOM.text "Test") web

    -- (WebSpec { spec } ∷ ?_) = web
    WebSpec { spec } = web

    renderComponent = HtmlString <<< append "<!DOCTYPE html>\n" <<< DOM.renderToString <<< page

    handlers' = renderToApi web handlers renderComponent clientRouter
  onClose ← Isomers.Node.Server.serve spec handlers' interpret { hostname: "127.0.0.1", port: 10000, backlog: Nothing } (log "127.0.0.1:10000")
  onClose (log "Closed")
