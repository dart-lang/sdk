/// Configuration of DDC rule set.
library ddc.config;

class Configuration {
  // TODO(vsm): Configure via compiler flag?
  static const nonnullableTypes = const <String>['int', 'double'];
}
