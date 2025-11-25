// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is a temporary utility that modifies `messages.yaml` files in the
/// analyzer and related packages so that each message contains a `type` field
/// that identifies its type, rather than inferring the type from the message's
/// class name.
library;

import 'dart:io';

import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_utilities/analyzer_messages.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:collection/collection.dart';

void main() async {
  Map<Uri, Converter> converters = {};
  for (var message in [
    ...analyzerMessages,
    ...analysisServerMessages,
    ...feAnalyzerSharedMessages,
    ...lintMessages,
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
  late final String content = file.readAsStringSync();
  final List<SourceEdit> edits = [];

  Converter(this.file);

  void apply() {
    edits.sortBy((e) => -e.offset);
    file.writeAsStringSync(SourceEdit.applySequence(content, edits));
  }

  void convertMessage(Message message) {
    if (message is MessageWithAnalyzerCode) {
      var type = message.analyzerCode.diagnosticClass.type;
      var insertPosition = message.valueSpan.start.offset;
      var indentLevel = message.valueSpan.start.column;
      var indent = ' ' * indentLevel;
      edits.add(SourceEdit(insertPosition, 0, 'type: ${type.name}\n$indent'));
    }
  }
}
