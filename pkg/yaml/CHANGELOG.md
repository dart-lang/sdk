## 0.10.0

* Improve error messages when a file fails to parse.

## 0.9.0+2

* Ensure that maps are order-independent when used as map keys.

## 0.9.0+1

* The `YamlMap` class is deprecated. In a future version, maps returned by
  `loadYaml` and `loadYamlStream` will be Dart `HashMap`s with a custom equality
  operation.
