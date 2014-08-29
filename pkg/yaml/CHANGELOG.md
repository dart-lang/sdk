## 2.0.1+1

* Fix an import in a test.

* Widen the version constraint on the `collection` package.

## 2.0.1

* Fix a few lingering references to the old `Span` class in documentation and
  tests.

## 2.0.0

* Switch from `source_maps`' `Span` class to `source_span`'s `SourceSpan` class.

* For consistency with `source_span` and `string_scanner`, all `sourceName`
  parameters have been renamed to `sourceUrl`. They now accept Urls as well as
  Strings.

## 1.1.1

* Fix broken type arguments that caused breakage on dart2js.

* Fix an analyzer warning in `yaml_node_wrapper.dart`.

## 1.1.0

* Add new publicly-accessible constructors for `YamlNode` subclasses. These
  constructors make it possible to use the same API to access non-YAML data as
  YAML data.

* Make `YamlException` inherit from source_map's [`SpanFormatException`][]. This
  improves the error formatting and allows callers access to source range
  information.

[SpanFormatException]: (http://www.dartdocs.org/documentation/source_maps/0.9.2/index.html#source_maps/source_maps.SpanFormatException)

## 1.0.0+1

* Fix a variable name typo.

## 1.0.0

* **Backwards incompatibility**: The data structures returned by `loadYaml` and
  `loadYamlStream` are now immutable.

* **Backwards incompatibility**: The interface of the `YamlMap` class has
  changed substantially in numerous ways. External users may no longer construct
  their own instances.

* Maps and lists returned by `loadYaml` and `loadYamlStream` now contain
  information about their source locations.

* A new `loadYamlNode` function returns the source location of top-level scalars
  as well.

## 0.10.0

* Improve error messages when a file fails to parse.

## 0.9.0+2

* Ensure that maps are order-independent when used as map keys.

## 0.9.0+1

* The `YamlMap` class is deprecated. In a future version, maps returned by
  `loadYaml` and `loadYamlStream` will be Dart `HashMap`s with a custom equality
  operation.
