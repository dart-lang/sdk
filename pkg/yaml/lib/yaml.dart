// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A parser for [YAML](http://www.yaml.org/).
///
/// Use [loadYaml] to load a single document, or [loadYamlStream] to load a
/// stream of documents. For example:
///
///     import 'package:yaml/yaml.dart';
///     main() {
///       var doc = loadYaml("YAML: YAML Ain't Markup Language");
///       print(doc['YAML']);
///     }
///
/// This library currently doesn't support dumping to YAML. You should use
/// `stringify` from `dart:json` instead:
///
///     import 'dart:json' as json;
///     import 'package:yaml/yaml.dart';
///     main() {
///       var doc = loadYaml("YAML: YAML Ain't Markup Language");
///       print(json.stringify(doc));
///     }
library yaml;

import 'dart:math' as Math;
import 'dart:collection' show Queue;

import 'deep_equals.dart';

part 'yaml_map.dart';
part 'model.dart';
part 'parser.dart';
part 'visitor.dart';
part 'composer.dart';
part 'constructor.dart';

/// Loads a single document from a YAML string. If the string contains more than
/// one document, this throws an error.
///
/// The return value is mostly normal Dart objects. However, since YAML mappings
/// support some key types that the default Dart map implementation doesn't
/// (null, NaN, booleans, lists, and maps), all maps in the returned document
/// are YamlMaps. These have a few small behavioral differences from the default
/// Map implementation; for details, see the YamlMap class.
loadYaml(String yaml) {
  var stream = loadYamlStream(yaml);
  if (stream.length != 1) {
    throw new YamlException("Expected 1 document, were ${stream.length}");
  }
  return stream[0];
}

/// Loads a stream of documents from a YAML string.
///
/// The return value is mostly normal Dart objects. However, since YAML mappings
/// support some key types that the default Dart map implementation doesn't
/// (null, NaN, booleans, lists, and maps), all maps in the returned document
/// are YamlMaps. These have a few small behavioral differences from the default
/// Map implementation; for details, see the YamlMap class.
List loadYamlStream(String yaml) {
  return new _Parser(yaml).l_yamlStream().mappedBy((doc) =>
      new _Constructor(new _Composer(doc).compose()).construct())
      .toList();
}

/// An error thrown by the YAML processor.
class YamlException implements Exception {
  String msg;

  YamlException(this.msg);

  String toString() => msg;
}
