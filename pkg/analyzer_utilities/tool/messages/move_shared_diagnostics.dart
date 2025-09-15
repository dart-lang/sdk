// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is a temporary utility script that moves entries from
/// `pkg/front_end/messages.yaml` to a new
/// `pkg/_fe_analyzer_shared/messages.yaml` file.
///
/// Only messages that are actually shared (those with an `index` parameter) are
/// moved.
library;

import 'dart:io';

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/messages.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:source_span/src/location.dart';
import 'package:yaml/yaml.dart';

void main() {
  Map<Uri, _EditAccumulator> editAccumulators = {};
  var sharedYamlContents = StringBuffer('''
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains error messages that are shared between the analyzer and the
# front end.

# See pkg/front_end/messages.yaml for documentation about this file.

# Currently, the code generation logic uses the presence of an `index` entry to
# determine whether a given error message should be generated into both the
# analyzer and the front end, so all error messages in this file should have a
# non-null `index`.
# TODO(paulberry): remove the need for the `index` field.

''');

  for (var MapEntry(key: name, value: message) in frontEndMessages.entries) {
    if (message.index != null) {
      var node = message.yamlNode!;
      sharedYamlContents.write('$name:\n  ${node.span.text}');
      var uri = node.span.sourceUrl!;
      (editAccumulators[uri] ??= _EditAccumulator(uri)).deleteMessage(node);
    }
  }
  for (var editAccumulator in editAccumulators.values) {
    editAccumulator.apply();
  }
  File(
    join(pkg_root.packageRoot, '_fe_analyzer_shared', 'messages.yaml'),
  ).writeAsStringSync(sharedYamlContents.toString());
}

class _EditAccumulator {
  final File _file;
  final Set<int> _nodeOffsetsToDelete = {};
  late final content = _file.readAsStringSync();

  _EditAccumulator(Uri uri) : _file = File(uri.toFilePath());

  void apply() {
    if (_nodeOffsetsToDelete.isEmpty) return;
    var document = loadYamlDocument(content);
    var edits = <SourceEdit>[];
    for (var entry in (document.contents as YamlMap).nodes.entries) {
      if (_nodeOffsetsToDelete.contains(entry.value.span.start.offset)) {
        var deletionStart = _startOfLine((entry.key as YamlScalar).span.start);
        var deletionEnd = entry.value.span.end.offset;
        edits.add(SourceEdit(deletionStart, deletionEnd - deletionStart, ''));
      }
    }
    edits.sortBy((e) => -e.offset);
    var newContent = SourceEdit.applySequence(content, edits);
    _file.writeAsStringSync(newContent);
    _nodeOffsetsToDelete.clear();
  }

  void deleteMessage(YamlNode node) {
    _nodeOffsetsToDelete.add(node.span.start.offset);
  }

  int _startOfLine(SourceLocation start) =>
      content.lastIndexOf('\n', start.offset) + 1;
}
