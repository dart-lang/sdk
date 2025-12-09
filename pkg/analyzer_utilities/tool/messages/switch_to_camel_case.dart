// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is a temporary utility script that modifies error codes in
/// `messages.yaml` files, changing analyzer error codes from UPPER_SNAKE_CASE
/// to camelCase.
library;

import 'dart:io';

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_utilities/analyzer_messages.dart';
import 'package:analyzer_utilities/extensions/string.dart';
import 'package:analyzer_utilities/lint_messages.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:collection/collection.dart';
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

void main() {
  Map<Uri, Converter> converters = {};
  for (var message in [
    ...analyzerMessages,
    ...analysisServerMessages,
    ...feAnalyzerSharedMessages,
    ...lintMessages,
    ...frontEndMessages,
  ]) {
    var sourceUrl = message.keySpan.sourceUrl;
    (converters[sourceUrl!] ??= Converter(
      File(sourceUrl.toFilePath()),
    )).convertMessage(message);
  }
  for (var converter in converters.values) {
    converter.apply();
  }
}

class Converter {
  final File file;
  late final isAnalyzerFormat = switch (Uri.file(file.path).pathSegments) {
    [..., '_fe_analyzer_shared', 'messages.yaml'] => false,
    [..., 'analyzer', 'messages.yaml'] => true,
    [..., 'analysis_server', 'messages.yaml'] => true,
    [..., 'linter', 'messages.yaml'] => true,
    _ => throw 'Unexpected path ${file.path}',
  };
  late final String content = file.readAsStringSync();
  late final yaml = loadYamlNode(content) as YamlMap;
  late final messageMaps = isAnalyzerFormat ? yaml.nodes.values : [yaml];
  late final Map<String, YamlMap> messageNodesByName = {
    for (var messageMap in messageMaps)
      for (var MapEntry(:key, :value) in (messageMap as YamlMap).nodes.entries)
        (key as YamlScalar).value as String: value as YamlMap,
  };
  final List<SourceEdit> edits = [];

  Converter(this.file);

  void apply() {
    edits.sortBy((e) => -e.offset);
    file.writeAsStringSync(SourceEdit.applySequence(content, edits));
  }

  void convertMessage(Message message) {
    if (message is AnalyzerMessage && !message.keyString.isCamelCase) {
      _edit(message.keySpan, message.keyString.toCamelCase());
    } else if (message is CfeStyleMessage) {
      _edit(message.keySpan, message.keyString.toSnakeCase().toCamelCase());
    }
    if (message is SharedMessage) {
      var messageNode = yaml.nodes[message.keyString] as YamlMap;
      _edit(
        messageNode.nodes['analyzerCode']!.span,
        message.analyzerCode.camelCaseName,
      );
    }
    if (message.sharedName case var sharedName?) {
      var messageNode = messageNodesByName[message.keyString] as YamlMap;
      _edit(messageNode.nodes['sharedName']!.span, sharedName.camelCaseName);
    }
  }

  void _edit(SourceSpan span, String newText) {
    edits.add(SourceEdit(span.start.offset, span.length, newText));
  }
}
