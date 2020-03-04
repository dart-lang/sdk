// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, Platform;

import 'package:analysis_server_client/protocol.dart';
import 'package:path/path.dart' as path;

int compareSuggestions(DartFixSuggestion s1, DartFixSuggestion s2) {
  int result = s1.description.compareTo(s2.description);
  if (result != 0) {
    return result;
  }
  return (s2.location?.offset ?? 0) - (s1.location?.offset ?? 0);
}

int compareFixes(DartFix s1, DartFix s2) {
  return s1.name.compareTo(s2.name);
}

/// Return the analysis_server executable by proceeding upward until finding the
/// Dart SDK repository root, then returning the analysis_server executable
/// within the repository.
///
/// Return `null` if it cannot be found.
String findServerPath() {
  String pathname = Platform.script.toFilePath();
  while (true) {
    String parent = path.dirname(pathname);
    if (parent.length >= pathname.length) {
      return null;
    }
    String serverPath =
        path.join(parent, 'pkg', 'analysis_server', 'bin', 'server.dart');
    if (File(serverPath).existsSync()) {
      return serverPath;
    }
    pathname = parent;
  }
}

bool shouldShowError(AnalysisError error) {
  // Only show diagnostics that will affect the fixes.
  return error.type.name != 'HINT' &&
      error.type.name != 'LINT' &&
      error.type.name != 'TODO' &&
      // TODO(danrubel): Rather than checking the error.code with
      // specific strings, add something to the error indicating that
      // it will be automatically fixed by edit.dartfix.
      error.code != 'wrong_number_of_type_arguments_constructor';
}

String toSentenceFragment(String message) {
  return message.endsWith('.')
      ? message.substring(0, message.length - 1)
      : message;
}

String pluralize(String word, int count) => count == 1 ? word : '${word}s';

List<SourceEdit> sortEdits(SourceFileEdit sourceFileEdit) {
  // Sort edits in reverse offset order.
  List<SourceEdit> edits = sourceFileEdit.edits.toList();
  edits.sort((a, b) {
    return b.offset - a.offset;
  });
  return edits;
}
