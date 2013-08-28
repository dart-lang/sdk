// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A parser for [YAML](http://www.yaml.org/).
///
/// ## Installing ##
///
/// Use [pub][] to install this package. Add the following to your
/// `pubspec.yaml` file.
///
///     dependencies:
///       yaml: any
///
/// Then run `pub install`.
///
/// For more information, see the
/// [yaml package on pub.dartlang.org][pkg].
///
/// ## Using ##
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
/// `JSON.encode` from `dart:convert` instead:
///
///     import 'dart:convert';
///     import 'package:yaml/yaml.dart';
///     main() {
///       var doc = loadYaml("YAML: YAML Ain't Markup Language");
///       print(JSON.encode(doc));
///     }
///
/// [pub]: http://pub.dartlang.org
/// [pkg]: http://pub.dartlang.org/packages/yaml
library yaml;

import 'src/composer.dart';
import 'src/constructor.dart';
import 'src/parser.dart';
import 'src/yaml_exception.dart';

export 'src/yaml_exception.dart';
export 'src/yaml_map.dart';

/// Loads a single document from a YAML string. If the string contains more than
/// one document, this throws an error.
///
/// The return value is mostly normal Dart objects. However, since YAML mappings
/// support some key types that the default Dart map implementation doesn't
/// (null, NaN, booleans, lists, and maps), all maps in the returned document
/// are [YamlMap]s. These have a few small behavioral differences from the
/// default Map implementation; for details, see the [YamlMap] class.
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
/// are [YamlMap]s. These have a few small behavioral differences from the
/// default Map implementation; for details, see the [YamlMap] class.
List loadYamlStream(String yaml) {
  return new Parser(yaml).l_yamlStream()
      .map((doc) => new Constructor(new Composer(doc).compose()).construct())
      .toList();
}
