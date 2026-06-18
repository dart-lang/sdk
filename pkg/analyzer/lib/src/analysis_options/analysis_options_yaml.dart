// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

/// Parses analysis options YAML into a map.
///
/// Returns an empty map if the content is valid YAML but is not a YAML map.
YamlMap parseAnalysisOptionsYaml(String content, {Uri? sourceUrl}) {
  try {
    var doc = loadYamlNode(content, sourceUrl: sourceUrl);
    return doc is YamlMap ? doc : YamlMap();
  } on YamlException catch (e) {
    throw OptionsFormatException(e.message, e.span);
  }
}

/// Thrown when analysis options content is not valid YAML.
class OptionsFormatException implements Exception {
  final String message;
  final SourceSpan? span;

  OptionsFormatException(this.message, [this.span]);

  @override
  String toString() => 'OptionsFormatException: $message, ${span?.toString()}';
}
