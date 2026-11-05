// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer_utilities/analyzer_messages.dart';
import 'package:analyzer_utilities/lint_messages.dart';
import 'package:analyzer_utilities/messages.dart';

/// A utility to list the names of existing warnings. This list is used to
/// populate the Github issues titled
/// "[featureName] Analysis Server - Existing warnings" that are created to
/// track the implementation of new language features.
void main(List<String> args) {
  listWarnings(sink: stdout);
}

void listWarnings({required StringSink sink}) {
  var warningCodes = <String>{};
  _addWarnings(warningCodes, feAnalyzerSharedMessages);
  _addWarnings(warningCodes, analyzerMessages);
  _addWarnings(warningCodes, analysisServerMessages);
  _addWarnings(warningCodes, lintMessages);

  for (var code in warningCodes.toList()..sort()) {
    sink.writeln('- [ ] $code');
  }
}

void _addWarnings(Set<String> warningCodes, List<Message> messages) {
  // TODO(brianwilkerson): Update this to separate analysis options, pubspec,
  //  and manifest file warnings into separate lists (they can mostly be ruled
  //  out as a group). We might also want to separate other groups, such as
  //  warnings related to API usage (though I don't know whether we can).
  //
  // TODO(brianwilkerson): Filter out any warnings that have been removed.
  for (var message in messages) {
    if (message is AnalyzerMessage &&
        message.type == AnalyzerDiagnosticType.staticWarning) {
      var name = message.sharedName?.camelCaseName ?? message.constantName;
      warningCodes.add(name);
    } else if (message is SharedMessage &&
        message.type == AnalyzerDiagnosticType.staticWarning) {
      var name = message.sharedName?.camelCaseName ?? message.constantName;
      warningCodes.add(name);
    }
  }
}
