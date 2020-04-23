// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/protocol.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as path;

/// Given a Logger and an analysis issue, render the issue to the logger.
class IssueRenderer {
  final Logger logger;
  final String rootDirectory;

  IssueRenderer(this.logger, this.rootDirectory);

  void render(AnalysisError issue) {
    // severity • Message ... at foo/bar.dart:6:1 • (error_code)

    final Ansi ansi = logger.ansi;

    logger.stdout(
      '  ${ansi.error(issue.severity.name.toLowerCase())} • '
      '${ansi.emphasized(_removePeriod(issue.message))} '
      'at ${path.relative(issue.location.file, from: rootDirectory)}'
      ':${issue.location.startLine}:'
      '${issue.location.startColumn} '
      '• (${issue.code})',
    );
  }
}

typedef LineProcessor = void Function(int lineNumber, String lineText);

class SourcePrinter {
  static final String red = '\u001b[31m';
  static final String bold = '\u001b[1m';
  static final String reversed = '\u001b[7m';
  static final String none = '\u001b[0m';

  String source;

  SourcePrinter(this.source);

  void applyEdits(List<SourceEdit> edits) {
    for (SourceEdit edit in edits) {
      if (edit.replacement.isNotEmpty) {
        // an addition
        insertText(edit.offset + edit.length, edit.replacement);
      }

      if (edit.length != 0) {
        // a removal
        deleteRange(edit.offset, edit.length);
      }
    }
  }

  void deleteRange(int offset, int length) {
    source = source.substring(0, offset) +
        red +
        reversed +
        source.substring(offset, offset + length) +
        none +
        source.substring(offset + length);
  }

  void insertText(int offset, String text) {
    text = '$reversed$text$none';
    source = source.substring(0, offset) + text + source.substring(offset);
  }

  void processChangedLines(LineProcessor callback) {
    List<String> lines = source.split('\n');
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (line.contains(none)) {
        callback(i + 1, line);
      }
    }
  }
}

String _removePeriod(String value) {
  return value.endsWith('.') ? value.substring(0, value.length - 1) : value;
}
