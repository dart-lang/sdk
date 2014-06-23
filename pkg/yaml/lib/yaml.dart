// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml;

import 'package:string_scanner/string_scanner.dart';

import 'src/composer.dart';
import 'src/constructor.dart';
import 'src/parser.dart';
import 'src/yaml_exception.dart';
import 'src/yaml_node.dart';

export 'src/yaml_exception.dart';
export 'src/yaml_node.dart';

/// Loads a single document from a YAML string.
///
/// If the string contains more than one document, this throws a
/// [YamlException]. In future releases, this will become an [ArgumentError].
///
/// The return value is mostly normal Dart objects. However, since YAML mappings
/// support some key types that the default Dart map implementation doesn't
/// (NaN, lists, and maps), all maps in the returned document are [YamlMap]s.
/// These have a few small behavioral differences from the default Map
/// implementation; for details, see the [YamlMap] class.
///
/// In future versions, maps will instead be [HashMap]s with a custom equality
/// operation.
///
/// If [sourceName] is passed, it's used as the name of the file or URL from
/// which the YAML originated for error reporting.
loadYaml(String yaml, {String sourceName}) =>
    loadYamlNode(yaml, sourceName: sourceName).value;

/// Loads a single document from a YAML string as a [YamlNode].
///
/// This is just like [loadYaml], except that where [loadYaml] would return a
/// normal Dart value this returns a [YamlNode] instead. This allows the caller
/// to be confident that the return value will always be a [YamlNode].
YamlNode loadYamlNode(String yaml, {String sourceName}) {
  var stream = loadYamlStream(yaml, sourceName: sourceName);
  if (stream.length != 1) {
    throw new YamlException("Expected 1 document, were ${stream.length}.",
        stream.span);
  }
  return stream.nodes[0];
}

/// Loads a stream of documents from a YAML string.
///
/// The return value is mostly normal Dart objects. However, since YAML mappings
/// support some key types that the default Dart map implementation doesn't
/// (NaN, lists, and maps), all maps in the returned document are [YamlMap]s.
/// These have a few small behavioral differences from the default Map
/// implementation; for details, see the [YamlMap] class.
///
/// In future versions, maps will instead be [HashMap]s with a custom equality
/// operation.
///
/// If [sourceName] is passed, it's used as the name of the file or URL from
/// which the YAML originated for error reporting.
YamlList loadYamlStream(String yaml, {String sourceName}) {
  var pair;
  try {
    pair = new Parser(yaml, sourceName).l_yamlStream();
  } on StringScannerException catch (error) {
    throw new YamlException(error.message, error.span);
  }

  var nodes = pair.first
      .map((doc) => new Constructor(new Composer(doc).compose()).construct())
      .toList();
  return new YamlList(nodes, pair.last);
}
