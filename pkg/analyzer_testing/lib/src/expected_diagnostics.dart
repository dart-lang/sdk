// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_testing/utilities/extensions/diagnostic_code.dart';

/// Returns [content] with canonical diagnostic expectation markers.
///
/// Existing diagnostic expectation marker lines are removed before the new
/// markers are inserted, so [content] can be either unmarked or already marked.
String updateExpectedDiagnostics({
  required String content,
  required List<Diagnostic> actualDiagnostics,
}) {
  return _ExpectedDiagnosticsUpdater(content).update(actualDiagnostics);
}

final class _ExpectedDiagnosticsUpdater {
  final List<_Line> lines;
  final LineInfo lineInfo;
  final Map<int, List<_GeneratedMarker>> markersByLine = {};

  int nextMarkerIndex = 0;
  int nextContextId = 1;

  _ExpectedDiagnosticsUpdater(String content)
    : lines = _Line.parse(content),
      lineInfo = LineInfo.fromContent(content);

  String update(List<Diagnostic> actualDiagnostics) {
    _generateMarkers(actualDiagnostics);
    return _writeContent();
  }

  void _addMarker(int lineNumber, _GeneratedMarker marker) {
    markersByLine.putIfAbsent(lineNumber, () => []).add(marker);
  }

  /// Builds a caret marker line for a one-based [column] and [length].
  String _caretLine(int column, int length) {
    return '//${' ' * (column - 3)}${'^' * length}';
  }

  void _generateDiagnosticMarkers(Diagnostic diagnostic) {
    var contextRefs = <int>[];
    for (var contextMessage in diagnostic.contextMessages) {
      if (contextMessage.filePath != diagnostic.problemMessage.filePath) {
        // TODO(scheglov): Support generating expectations for context
        // messages in other files.
        throw StateError(
          'Cannot generate a diagnostic expectation with a context message '
          'in another file.',
        );
      }

      var id = nextContextId++;
      contextRefs.add(id);
      var location = _markerLocation(
        offset: contextMessage.offset,
        length: contextMessage.length,
      );
      var line = lines[location.lineNumber - 1];
      var presentation = _markerPresentation(
        line,
        column: location.column,
        length: contextMessage.length,
      );
      _addMarker(
        location.lineNumber,
        _GeneratedMarker.context(
          offset: contextMessage.offset,
          index: nextMarkerIndex++,
          id: id,
          column: location.column,
          length: contextMessage.length,
          caretLength: presentation.caretLength,
          includeExplicitLocation: presentation.includeExplicitLocation,
          message: _messageText(contextMessage),
        ),
      );
    }

    var location = _markerLocation(
      offset: diagnostic.offset,
      length: diagnostic.length,
    );
    var line = lines[location.lineNumber - 1];
    var presentation = _markerPresentation(
      line,
      column: location.column,
      length: diagnostic.length,
    );
    _addMarker(
      location.lineNumber,
      _GeneratedMarker.diagnostic(
        offset: diagnostic.offset,
        index: nextMarkerIndex++,
        constantName: diagnostic.diagnosticCode.constantName,
        column: location.column,
        length: diagnostic.length,
        caretLength: presentation.caretLength,
        includeExplicitLocation: presentation.includeExplicitLocation,
        contextRefs: contextRefs,
        message: _messageText(diagnostic.problemMessage),
      ),
    );
  }

  void _generateMarkers(List<Diagnostic> actualDiagnostics) {
    var sortedDiagnostics = actualDiagnostics.toList()
      ..sort((first, second) => first.offset.compareTo(second.offset));
    for (var diagnostic in sortedDiagnostics) {
      _generateDiagnosticMarkers(diagnostic);
    }
  }

  /// Returns where a generated marker should be written for an actual range.
  ///
  /// For a normal diagnostic range, the marker belongs on the line reported by
  /// [LineInfo]. For a zero-length diagnostic, the diagnostic is often an
  /// insertion point rather than a source span. If the input is already
  /// marked, that insertion point can be pushed into the existing marker
  /// comments, or to the empty line after them, even though the marker should
  /// still be attached to the preceding real source line. In that case, keep
  /// the marker on the source line and express the insertion point as the
  /// column after its last character.
  ({int lineNumber, int column}) _markerLocation({
    required int offset,
    required int length,
  }) {
    var location = lineInfo.getLocation(offset);
    if (length == 0) {
      // Only zero-length diagnostics can legitimately move onto marker-only
      // text from a previous update. A non-zero range on a marker line would
      // describe the marker comment itself, not an insertion point in code.
      var targetLine = _targetLineForMarkerShift(location.lineNumber);
      if (targetLine != null) {
        return (
          lineNumber: targetLine.number,
          column: targetLine.text.length + 1,
        );
      }
    }
    return (lineNumber: location.lineNumber, column: location.columnNumber);
  }

  /// Returns how [column] and [length] should be shown after [line].
  ///
  /// Caret lines start with `//`, so columns 1 and 2 cannot be represented. A
  /// zero-length range may still use a one-character caret as a visual anchor,
  /// but must keep explicit `[column ...][length 0]` metadata.
  ({int? caretLength, bool includeExplicitLocation}) _markerPresentation(
    _Line line, {
    required int column,
    required int length,
  }) {
    int? caretLength;
    if (column > 2) {
      if (length == 0 && column <= line.text.length + 1) {
        caretLength = 1;
      } else if (length > 0 && column + length - 1 <= line.text.length) {
        caretLength = length;
      }
    }

    return (
      caretLength: caretLength,
      includeExplicitLocation: caretLength != length,
    );
  }

  /// Finds the real source line that owns a shifted zero-length marker.
  ///
  /// The updater accepts both clean source and source that already contains
  /// diagnostic expectation comments. Existing marker comments are removed when
  /// the new content is written, but actual diagnostics are computed before
  /// that removal. This matters for zero-length diagnostics near the end of a
  /// line or file: after a previous update, the analyzer may report the same
  /// insertion point as being on a marker line, or on the empty line
  /// immediately following marker lines.
  ///
  /// This method recognizes only those shifted positions. If [lineNumber]
  /// points at ordinary source text, or at an empty line that is not directly
  /// after a marker, there is nothing to repair and `null` is returned.
  /// Otherwise the search walks backward over marker lines and returns the
  /// nearest preceding non-marker line, which is where the regenerated marker
  /// should be attached.
  _Line? _targetLineForMarkerShift(int lineNumber) {
    if (lineNumber < 1 || lineNumber > lines.length) {
      return null;
    }

    var line = lines[lineNumber - 1];
    if (!_LineMarker.isMarker(line)) {
      // A non-marker line normally owns the reported offset. The one exception
      // is the synthetic empty line after existing markers, which can be where
      // EOF-style zero-length diagnostics land.
      var previousLine = lineNumber > 1 ? lines[lineNumber - 2] : null;
      if (line.text.isNotEmpty ||
          previousLine == null ||
          !_LineMarker.isMarker(previousLine)) {
        return null;
      }
    }

    // The reported line is either a marker line or the empty line just after
    // marker lines. Walk back to the line these markers annotate.
    for (var index = lineNumber - 2; index >= 0; index--) {
      var previousLine = lines[index];
      if (!_LineMarker.isMarker(previousLine)) {
        return previousLine;
      }
    }
    return null;
  }

  String _writeContent() {
    var buffer = StringBuffer();
    var isFirstLine = true;
    for (var line in lines) {
      if (_LineMarker.isMarker(line)) {
        continue;
      }

      if (isFirstLine) {
        isFirstLine = false;
      } else {
        buffer.writeln();
      }
      buffer.write(line.text);

      var markers = markersByLine[line.number];
      if (markers != null) {
        markers.sort(_GeneratedMarker.compare);
        ({int column, int length})? currentCaret;
        for (var marker in markers) {
          if (marker.caretLength case var caretLength?) {
            var markerCaret = (column: marker.column, length: caretLength);
            if (markerCaret != currentCaret) {
              buffer.writeln();
              buffer.write(_caretLine(marker.column, caretLength));
              currentCaret = markerCaret;
            }
          }
          buffer.writeln();
          buffer.write(marker.expectationText);
        }
      }
    }
    return buffer.toString();
  }

  static String _messageText(DiagnosticMessage message) {
    var text = message.messageText(includeUrl: false);
    return _toPosixPaths(text).trim();
  }

  static String _toPosixPaths(String message) {
    return message.replaceAllMapped(RegExp(r'C:\\([a-zA-Z0-9_.\\]+)'), (match) {
      var path = match.group(1)!;
      var posixPath = path.replaceAll(r'\', '/');
      return '/$posixPath';
    });
  }
}

/// Generated expectation marker text for one diagnostic or context message.
final class _GeneratedMarker {
  /// The zero-based offset of the diagnostic or context message being marked.
  final int offset;

  /// The marker kind, used as a stable secondary sort key.
  final _GeneratedMarkerKind kind;

  /// The order in which this marker was generated.
  final int index;

  /// The one-based column of the diagnostic or context message range.
  final int column;

  /// The length of the visual caret marker, or `null` if none should be shown.
  ///
  /// For zero-length diagnostics, a one-character caret is useful as a visual
  /// anchor, but the exact `[column ...][length 0]` metadata must still be
  /// emitted.
  final int? caretLength;

  /// The expectation comment inserted after the target line.
  final String expectationText;

  /// Creates a marker for a diagnostic context message.
  factory _GeneratedMarker.context({
    required int offset,
    required int index,
    required int id,
    required int column,
    required int length,
    required int? caretLength,
    required bool includeExplicitLocation,
    required String message,
  }) {
    var buffer = StringBuffer();
    buffer.write('// [context $id]');
    if (includeExplicitLocation) {
      buffer.write('[column $column][length $length]');
    }
    buffer.write(' $message');

    return _GeneratedMarker._(
      offset: offset,
      kind: _GeneratedMarkerKind.context,
      index: index,
      column: column,
      caretLength: caretLength,
      expectationText: buffer.toString(),
    );
  }

  /// Creates a marker for a diagnostic.
  factory _GeneratedMarker.diagnostic({
    required int offset,
    required int index,
    required String constantName,
    required int column,
    required int length,
    required int? caretLength,
    required bool includeExplicitLocation,
    required List<int> contextRefs,
    required String message,
  }) {
    var buffer = StringBuffer();
    buffer.write('// [$constantName]');
    if (includeExplicitLocation) {
      buffer.write('[column $column][length $length]');
    }
    for (var id in contextRefs) {
      buffer.write('[context $id]');
    }
    buffer.write(' $message');

    return _GeneratedMarker._(
      offset: offset,
      kind: _GeneratedMarkerKind.diagnostic,
      index: index,
      column: column,
      caretLength: caretLength,
      expectationText: buffer.toString(),
    );
  }

  _GeneratedMarker._({
    required this.offset,
    required this.kind,
    required this.index,
    required this.column,
    required this.caretLength,
    required this.expectationText,
  });

  /// Orders generated markers in the order they should appear after a line.
  static int compare(_GeneratedMarker first, _GeneratedMarker second) {
    var offsetResult = first.offset.compareTo(second.offset);
    if (offsetResult != 0) {
      return offsetResult;
    }
    var kindResult = first.kind.index.compareTo(second.kind.index);
    if (kindResult != 0) {
      return kindResult;
    }
    return first.index.compareTo(second.index);
  }
}

enum _GeneratedMarkerKind { context, diagnostic }

/// A line of text in the input content.
final class _Line {
  /// The one-based line number in the input content.
  final int number;

  /// The line text without the trailing newline characters.
  final String text;

  _Line({required this.number, required this.text});

  /// Splits [content] into lines while preserving each line's offset.
  ///
  /// Lines may end with `\r`, `\n`, or `\r\n`. The newline characters are not
  /// included in [text], but they still contribute to offsets in [content].
  static List<_Line> parse(String content) {
    var result = <_Line>[];
    var lineStart = 0;
    var lineNumber = 1;

    for (var index = 0; index < content.length; index++) {
      var codeUnit = content.codeUnitAt(index);
      if (codeUnit == 0x0D || codeUnit == 0x0A) {
        result.add(
          _Line(
            number: lineNumber++,
            text: content.substring(lineStart, index),
          ),
        );

        // Consume the `\n` in a `\r\n` line break.
        if (codeUnit == 0x0D &&
            index + 1 < content.length &&
            content.codeUnitAt(index + 1) == 0x0A) {
          index++;
        }
        lineStart = index + 1;
      }
    }

    result.add(_Line(number: lineNumber, text: content.substring(lineStart)));
    return result;
  }
}

abstract final class _LineMarker {
  /// Matches a caret marker line such as `//   ^^^`.
  static final _caretPattern = RegExp(r'^[ \t]*//[ \t]*\^+[ \t]*$');

  /// Matches generated expectation comments for diagnostics and contexts.
  ///
  /// The updater only needs to recognize lines to remove before regeneration.
  /// It intentionally does not validate the full marker syntax.
  static final _expectationPattern = RegExp(
    r'^[ \t]*//[ \t]*\[(?:diag\.[A-Za-z_][A-Za-z0-9_]*|context[ \t]+[0-9]+)\]',
  );

  static bool isMarker(_Line line) {
    return _caretPattern.hasMatch(line.text) ||
        _expectationPattern.hasMatch(line.text);
  }
}
