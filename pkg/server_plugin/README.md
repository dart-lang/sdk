# server\_plugin package

This package is being developed for the second incarnation of Dart Analyzer
plugins. It is in an intermediate state, and a few things must be kept in mind
during this phase of development:

1. **This package is not to be published on pub.** Yet. We may decide to go
   forward with this package as a full replacement of the `analyzer_plugin`
   package, in which case we _would_ ultimately publish it. But we may choose a
   different plan.  Until we finalize, this package is not to be published.
2. **In order to support the above point, no pub-publishable code can depend on
   this package.** At no point can we introduce a dependency from a package
   like `analyzer` or `analyzer_plugin` to this package. If we did so, then at
   the next time we published _that_ package to pub, we would need to publish
   _this_ package to pub. No. In short, I think what this means is that only
   the `analsis_server` package can depend on this package (until we decide the
   final path to publishing the next Dart Analyzer plugins story.

## Migration of code between packages

As part of the design of the new Dart Analyzer plugins, much code will shift
around, in a few directions.

* **`analysis_server` package to `server_plugin` package:** The API of the new
  Dart Analyzer plugins focuses around two primary concepts: lint rules and
  quick fixes. Quick assists may be chosen as a third important concept.  Lint
  rule code has typically lived in the `analyzer` package, and does not need to
  move. (It's presense in the `analyzer` package could be deprecated in favor
  of this package, but it is not important for the implementation.)

  Quick fixes, however, have only existed in concept, and interface, and API,
  in the `analysis_server` package. That code needs to move to this package in
  order to be used in a Dart Analyzer plugin.

  **A move from the `analysis_server` package to this package is not a breaking
  change.**

* **`analyzer_plugin` package to `server_plugin` package:** Care is being taken
  to decide where Dart Analyzer plugin code will live and how it will be
  published. It is not decided yet what the ultimate package API will be. Some
  code from **analyzer_plugin** may move to this package.

  **A move from the `analyzer_plugin` package is a breaking change. Extreme
  care must be taken.**

* **`analyzer_plugin` package to `analysis_server` package:** There will be
  many components of the analysis server that currently live in
  `analyzer_plugin`, because they were necessary for the first version of Dart
  Analyzer plugins), but are not part of the new Dart Analyzer plugins. These
  components can be moved safely back into the `analysis_server` package.

  In terms of priority, it is not crucial for such code to be moved out of the
  `analyzer_plugin` package. It can live there indefinitely, and the
  `analysis_server` package can continue to depend on code from the
  `analyzer_plugin` package, as shipped in the SDK.

  **A move from the `analyzer_plugin` package is a breaking change. Extreme
  care must be taken.**
