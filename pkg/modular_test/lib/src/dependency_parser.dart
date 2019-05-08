// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines how to read module dependencies from a Yaml
/// specification. We expect to find specifications written in this format:
///
///    dependencies:
///      b: a
///      main: [b, expect]
///
/// Where:
///   - Each name corresponds to a module.
///   - Module names correlate to either a file, a folder, or a package.
///   - A map entry contains all the dependencies of a module, if any.
///   - If a module has a single dependency, it can be written as a single
///     value.
///
/// The logic in this library mostly treats these names as strings, separately
/// `loader.dart` is responsible for validating and attaching this dependency
/// information to a set of module definitions.
import 'package:yaml/yaml.dart';

/// Parses [contents] containing a module dependencies specification written in
/// yaml, and returns a normalized dependency map.
///
/// Note: some values in the map may not have a corresponding key. That may be
/// the case for modules that have no dependencies and modules that are not
/// specified in [contents] (e.g. modules that are supported by default).
Map<String, List<String>> parseDependencyMap(String contents) {
  var spec = loadYaml(contents);
  if (spec is! YamlMap) {
    return _invalidSpecification("spec is not a map");
  }
  var dependencies = spec['dependencies'];
  if (dependencies == null) {
    return _invalidSpecification("no dependencies section");
  }
  if (dependencies is! YamlMap) {
    return _invalidSpecification("dependencies is not a map");
  }

  Map<String, List<String>> normalizedMap = {};
  dependencies.forEach((key, value) {
    if (key is! String) {
      _invalidSpecification("key: '$key' is not a string");
    }
    normalizedMap[key] = [];
    if (value is String) {
      normalizedMap[key].add(value);
    } else if (value is List) {
      value.forEach((entry) {
        if (entry is! String) {
          _invalidSpecification("entry: '$entry' is not a string");
        }
        normalizedMap[key].add(entry);
      });
    } else {
      _invalidSpecification(
          "entry: '$value' is not a string or a list of strings");
    }
  });
  return normalizedMap;
}

_invalidSpecification(String message) {
  throw new InvalidSpecificationError(message);
}

class InvalidSpecificationError extends Error {
  final String message;
  InvalidSpecificationError(this.message);
  String toString() => "Invalid specification: $message";
}
