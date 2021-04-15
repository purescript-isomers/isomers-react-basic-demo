{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "my-project"
, dependencies = [ "argonaut", "console", "effect", "isomers", "psci-support", "record-prefix", "react-basic-dom", "react-basic-hooks" ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
