module Server.Static where

import Prelude

import Data.Array (unsnoc) as Array
import Data.Either (Either(..))
import Data.Int (floor) as Int
import Data.Maybe (Maybe(..), isJust)
import Data.Profunctor (lcmap)
import Data.String (Pattern(..), length, stripPrefix) as String
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (liftEffect)
import Effect.Unsafe (unsafePerformEffect)
import Isomers.HTTP.ContentTypes (JavascriptMime)
import Isomers.Response (Duplex(..), Okayish) as Response
import Isomers.Response (Okayish)
import Isomers.Response.Duplex (Printer, html) as Response.Duplex
import Isomers.Response.Duplex.Parser (blob) as Response.Duplex.Parser
import Isomers.Response.Duplex.Printer (header, stream) as Response.Duplex.Printer
import Isomers.Response.Okayish.Duplexes (notFound', ok) as Response.Okayish.Duplexes
import Isomers.Response.Okayish.Type (fromEither) as Response.Okayish.Type
import Isomers.Response.Okayish.Type (notFound)
import Isomers.Response.Types (HtmlString(..))
import Network.HTTP.Types (hContentLength)
import Node.FS.Aff (exists, stat) as FS.Aff
import Node.FS.Stats (Stats(..))
import Node.FS.Stream (createReadStream) as FS.Stream
import Node.Path (FilePath)
import Node.Path (resolve) as FS
import Node.Stream (Readable) as Stream
import Prim.Row (class Lacks) as Row
import Web.File.Blob (Blob) as Web.File

type ReadableFileStream r
  = { size ∷ Int, stream ∷ Stream.Readable r }

-- | A plain response duplex for serving files.
unsafeFileStream ∷ ∀ mime r. Response.Duplex mime (ReadableFileStream r) Web.File.Blob
unsafeFileStream = Response.Duplex fileStream Response.Duplex.Parser.blob

fileStream ∷ ∀ r. ReadableFileStream r → Response.Duplex.Printer
fileStream { stream, size } = Response.Duplex.Printer.header hContentLength (Just $ show size) <> Response.Duplex.Printer.stream stream

-- | `Okayish` duplex which handles encoding of a stream and decoding into a blob.
-- | TODO: add support for filename through `Content-Disposition: inline; filename=FILENAME`
staticFile ∷
  ∀ mime r.
  Response.Duplex
    mime
    (Response.Okayish ( notFound ∷ HtmlString ) (ReadableFileStream r))
    (Okayish ( notFound ∷ HtmlString ) Web.File.Blob)
staticFile = Response.Okayish.Duplexes.notFound' Response.Duplex.html (Response.Okayish.Duplexes.ok unsafeFileStream)

newtype JSFileStream r
  = JSFileStream (ReadableFileStream r)

jsFile ∷
  ∀ r.
  Response.Duplex
    JavascriptMime
    (Response.Okayish ( notFound ∷ HtmlString ) (JSFileStream r))
    (Okayish ( notFound ∷ HtmlString ) Web.File.Blob)
jsFile = lcmap unJS staticFile
  where
  unJS = map (\(JSFileStream s) → s)

type Root
  = FilePath

-- | `Nodejs.path.resolve` is uneffectful I think ;-)
resolve ∷ Array FilePath → FilePath → FilePath
resolve ps to = unsafePerformEffect $ FS.resolve ps to

createFileStream ∷ ∀ m. MonadAff m ⇒ Root → Array FilePath → m (Maybe { stream ∷ Stream.Readable (), size ∷ Int })
createFileStream root segments = liftAff do
  absRoot ← liftEffect $ FS.resolve [] root
  absPath ← case Array.unsnoc segments of
    Just { init, last } → liftEffect $ FS.resolve ([ absRoot ] <> init) last
    Nothing → pure absRoot
  let
    isSubPath r s = isJust (String.stripPrefix (String.Pattern r) s) && String.length r < String.length s
  correct ← (_ && isSubPath absRoot absPath) <$> FS.Aff.exists absPath
  if not correct then
    pure $ Nothing
  else do
    let
      unStats (Stats s) = s
    stream ← liftEffect $ FS.Stream.createReadStream absPath
    size ← (Int.floor <<< _.size <<< unStats) <$> FS.Aff.stat absPath
    pure $ Just { size, stream }

serveFile ∷
  ∀ m res.
  Row.Lacks "ok" res ⇒
  MonadAff m ⇒
  String →
  Array String →
  m
    ( Response.Okayish
        ( notFound ∷ HtmlString | res )
        (ReadableFileStream ())
    )
serveFile root segments = liftAff do
  createFileStream root segments
    <#> case _ of
        Nothing → notFound $ HtmlString "Not found"
        Just res → Response.Okayish.Type.fromEither $ Right res

serveJsFile ∷
  ∀ m res.
  Row.Lacks "ok" res ⇒
  MonadAff m ⇒
  String →
  Array String →
  m (Response.Okayish ( notFound ∷ HtmlString | res ) (JSFileStream ()))
serveJsFile root segments = map JSFileStream <$> serveFile root segments
