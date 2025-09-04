// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is a temporary utility script that modifies
/// `pkg/front_end/messages.yaml`, inserting explicit "parameters" declarations
/// based on the existing parameter placeholders.
///
/// For example, a message like this:
/// ```
/// SwitchExpressionNotSubtype:
///   problemMessage: >
///     Type '#type' of the case expression is not a subtype of type '#type2'
///     of this switch expression.
///   ...
/// ```
///
/// will get converted into:
/// ```
/// SwitchExpressionNotSubtype:
///   parameters:
///     Type type: undocumented
///     Type type2: undocumented
///   problemMessage: >
///     Type '#type' of the case expression is not a subtype of type '#type2'
///     of this switch expression.
///   ...
/// ```
///
/// Messages that don't take any parameters will have an entry added of the form
/// `parameters: none`.
library;

import 'dart:io';

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:collection/collection.dart';

void main() {
  var edits = <Uri, List<SourceEdit>>{};

  for (var message in frontEndMessages.values) {
    if (message.parameters != null) {
      // Message already converted.
      continue;
    }
    var parameters = <String, String>{};
    for (var value in [message.problemMessage, message.correctionMessage]) {
      if (value == null) continue;
      for (Match match in placeholderPattern.allMatches(value)) {
        var parsedPlaceholder = ParsedPlaceholder.fromMatch(match);
        var type = parsedPlaceholder.templateParameterType.messagesYamlName;
        var name = parsedPlaceholder.name;
        parameters['$type $name'] = 'undocumented';
      }
    }
    List<String> linesToAdd;
    if (parameters.isEmpty) {
      linesToAdd = ['parameters: none'];
    } else {
      linesToAdd = [
        'parameters:',
        for (var entry in parameters.entries) '  ${entry.key}: ${entry.value}',
      ];
    }
    var span = message.yamlNode!.span;
    var indent = ' ' * span.start.column;
    var text = linesToAdd.map((line) => '$line\n$indent').join();
    (edits[span.sourceUrl!] ??= []).add(SourceEdit(span.start.offset, 0, text));
  }

  for (var entry in edits.entries) {
    var file = File(entry.key.toFilePath());
    stdout.write('Updating ${file.path}...');
    file.writeAsStringSync(
      SourceEdit.applySequence(
        file.readAsStringSync(),
        entry.value..sortBy((e) => -e.offset),
      ),
    );
    stdout.writeln('done!');
  }
}
