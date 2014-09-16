## 0.15.2+1

* Properly handle logs from a transformer that's been canceled.

## 0.15.2

* Add a `StaticPackageProvider` class to more efficiently handle immutable,
  untransformed packages.

## 0.15.0+1

* Widen the version constraint on the `collection` package.

## 0.15.0

* Fully switch from `source_maps`' `Span` class to `source_span`'s `SourceSpan`
  class.

## 0.14.2

* All TransformLogger methods now accept SourceSpans from the source_span
  package in addition to Spans from the source_maps package. In 0.15.0, only
  SourceSpans will be accepted.

## 0.14.1+3

* Add a dependency on the `pool` package.

## 0.14.1+2

* Automatically log how long it takes long-running transforms to run.

## 0.14.1+1

* Fix a bug where an event could be added to a closed stream.

## 0.14.1

* Add an `AggregateTransformer` type. Aggregate transformers transform groups of
  assets for which no single asset is primary. For example, one could be used to
  merge all images in a directory into a single file.

* Add a `message` getter to `TransformerException` and `AssetLoadException`.

* Fix a bug where transformers would occasionally emit stale output after their
  inputs changed.

## 0.14.0+3

* Properly handle synchronous errors in `PackageProvider.getAsset()`.

## 0.14.0+2

* Fix a bug with the previous bug fix.

## 0.14.0+1

* Fix a bug where a transformer group preceded by another transformer group
  would sometimes fail to load secondary assets.

## 0.14.0

* **Breaking change**: when an output of a lazy transformer is requested, that
  transformer will run long enough to generate the output, then become lazy
  again. Previously, it would become eager as soon as an asset had been
  requested.

* Only run `Transformer.isPrimary` and `Transformer.declareOutputs` once for
  each asset.

* Lazy transformers' laziness is preserved when followed by
  declaring transformers, or by normal transformers for which the lazy outputs
  aren't primary.

* Fix a bug where reading the primary input using `Transform.readInputAsString`
  had slightly different behavior than reading it using
  `Transform.primary.readAsString`.

* Fix a crashing bug when `Barback.getAllAssets` is called synchronously after
  creating a new `Barback` instance.

* Don't warn if a lazy or declaring transformer doesn't emit outputs that it has
  declared. This is valid for transformers like dart2js that need to read their
  primary input in order to determine whether they should run.

* Allow `Transformer.isPrimary`, `Transformer.apply`, and
  `DeclaringTransformer.declareOutputs` to return non-`Future` values if they
  run synchronously.

* Fix a deadlock bug when a lazy primary input to a lazy transformer became
  dirty while the transformer's `apply` method was running.

* Run declaring transformers with lazy inputs eagerly if the inputs become
  available.

## 0.13.0

* `Transformer.isPrimary` now takes an `AssetId` rather than an `Asset`.

* `DeclaringTransform` now only exposes the primary input's `AssetId`, rather
  than the primary `Asset` object.

* `DeclaringTransform` no longer supports `getInput`, `readInput`,
  `readInputAsString`, or `hasInput`.

## 0.12.0

* Add a `Transform.logger.fine` function that doesn't print its messages by
  default. When using Barback with pub in verbose mode, these messages will be
  printed.

* Add a `Transform.hasInput` function that returns whether or not a given
  secondary input exists.

* `Transformer.allowedExtensions` now supports extensions containing multiple
  periods, such as `.dart.js`.

* Transforms now pass their primary inputs through to the next phase by default.
  A transformer may still overwrite its primary input without causing a
  collision. If a transformer doesn't overwrite its primary input, it may cause
  it not to be passed through by calling `Transform.consumePrimary`. The primary
  input will be consumed by default if a transformer throws an error.

* If an input requested with `Transform.getInput`, `Transform.readInput`, or
  `Transform.readInputAsString` cannot be found, an `AssetNotFoundException`
  will be thrown. This was always what the documentation said, but previously a
  `MissingInputException` was thrown instead.

* If a transformer calls `Transform.logger.error`, the transformer will now be
  considered to have failed after it finishes running `apply()`. This means that
  its outputs will not be consumed by future transformers and its primary input
  will not be passed through to the next phase.

* If a transform calls `Transform.getInput`, `Transform.readInput`,
  `Transform.readInputAsString`, or `Transform.hasInput` on an input that
  doesn't exist, the transform will be re-run if that input is created in the
  future.
