## 0.13.1

* Only run `Transformer.isPrimary` once for each asset.

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
