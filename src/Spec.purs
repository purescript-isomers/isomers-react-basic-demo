module Spec where

import Prelude

import Data.Argonaut (fromNumber, toNumber) as Argonaut
import Data.Either (note)
import Data.Int (ceil, fromNumber, toNumber) as Int
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Maybe (Maybe(..))
import Data.Time.Duration (Milliseconds(..))
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Random (random)
import Isomers.Contrib.Heterogeneous.List (HNil(..), (:))
import Isomers.Node.Server (serve) as Isomers.Node.Server
import Isomers.Request (Accum(..)) as Request
import Isomers.Request.Duplex (int, segment) as Request.Duplex
import Isomers.Response (Duplex(..), RawServer(..)) as Response
import Isomers.Response.Duplex (asJson) as Response.Duplex
import Isomers.Response.Types (HtmlString(..))
import Isomers.Spec.Builder (insert) as Web.Builder
import Isomers.Web (Rendered(..)) as Isomers.Web
import Isomers.Web.Builder (webSpec)
import Isomers.Web.Server (renderToApi)
import Isomers.Web.Types (WebSpec(..))
import Network.HTTP.Types (ok200)
import Pages (randomInt) as Pages
import Pages (serverTimestamp)
import React.Basic.DOM.Server (renderToString) as DOM
import Type.Prelude (SProxy(..))

intResponse ∷ Response.Duplex "application/json" Int Int
intResponse = Response.Duplex.asJson
  (Argonaut.fromNumber <<< Int.toNumber)
  (map (note "Expecting an int") $ Int.fromNumber <=< Argonaut.toNumber)

numberResponse ∷ Response.Duplex "application/json" Number Number
numberResponse = Response.Duplex.asJson
  (Argonaut.fromNumber)
  (map (note "Expecting a number") Argonaut.toNumber)

millisecondsResponse ∷ Response.Duplex "application/json" Milliseconds Milliseconds
millisecondsResponse = _Newtype numberResponse

routeOnly ∷ ∀ body route. Request.Accum body route route route
routeOnly = Request.Accum (pure identity) identity

ok ∷ ∀ doc. doc → Response.RawServer doc
ok doc = Response.RawServer { status: ok200, body: doc, headers: mempty }

mkWebSpec components =
  { randomInt:
      Web.Builder.insert (SProxy ∷ SProxy "max") (Request.Duplex.int Request.Duplex.segment) $
         routeOnly /\ (Isomers.Web.Rendered intResponse (\(_ /\ i) → ok (components.randomInt i)) : HNil)
  -- | TODO: the below line fails here. Why?
  -- | timestamp: webSpec $
  , serverTimestamp:
      routeOnly /\ ((Isomers.Web.Rendered millisecondsResponse (\(_ /\ i) → ok ((components.serverTimestamp i)))) : HNil)
  }

