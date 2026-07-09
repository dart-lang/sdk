// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart' as engine;
import 'package:analyzer/dart/analysis/session.dart' as engine;
import 'package:analyzer/diagnostic/diagnostic.dart' as engine;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// Create a DiagnosticMessage based on an [engine.DiagnosticMessage].
DiagnosticMessage? newDiagnosticMessage(
  engine.DiagnosticMessage message,
  engine.AnalysisSession session, {
  LineInfo? lineInfo,
}) {
  var file = message.filePath;
  var offset = message.offset;
  var length = message.length;

  if (lineInfo == null) {
    var messageResult = session.getFile(message.filePath);
    if (messageResult is engine.FileResult) {
      lineInfo = messageResult.lineInfo;
    }
  }

  // If we don't have line info, we can't create a DiagnosticMessage.
  // If the diagnostic has other messages they may show but we skip this one.
  if (lineInfo == null) {
    assert(false, 'Could not get LineInfo for "$file"');
    return null;
  }

  var startLocation = lineInfo.getLocation(offset);
  var startLine = startLocation.lineNumber;
  var startColumn = startLocation.columnNumber;

  var endLocation = lineInfo.getLocation(offset + length);
  var endLine = endLocation.lineNumber;
  var endColumn = endLocation.columnNumber;

  return DiagnosticMessage(
    message.messageText(includeUrl: true),
    Location(
      file,
      offset,
      length,
      startLine,
      startColumn,
      endLine: endLine,
      endColumn: endColumn,
    ),
  );
}
