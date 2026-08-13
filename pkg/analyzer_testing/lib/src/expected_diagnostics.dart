// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_testing/utilities/extensions/diagnostic_code.dart';

/// Returns [content] with generated diagnostic expectation marker lines removed.
String removeDiagnosticExpectations(String content) {
  var allLines = _Line.parse(content);
  var codeLines = allLines
      .where((line) => !_LineMarker.isMarker(line))
      .toList();
  var buffer = StringBuffer();
  for (var i = 0; i < codeLines.length; i++) {
    var line = codeLines[i];
    buffer.write(line.text);
    // Write terminators as separators between retained lines; a terminator
    // before a removed marker line should not become a trailing terminator.
    if (i < codeLines.length - 1) {
      buffer.write(line.lineTerminator);
    }
  }
  return buffer.toString();
}

/// Returns [content] with one trailing line terminator removed, if present.
///
/// Diagnostic expectation tests often use multiline string literals where the
/// final line terminator exists only to keep the closing quote on its own line.
String removeTrailingLineTerminator(String content) {
  if (content.endsWith('\r\n')) {
    return content.substring(0, content.length - 2);
  } else if (content.endsWith('\n') || content.endsWith('\r')) {
    return content.substring(0, content.length - 1);
  }
  return content;
}

/// Returns [content] with canonical diagnostic expectation markers.
///
/// The [content] must not include diagnostic expectation marker lines. Use
/// [removeDiagnosticExpectations] before analysis, and pass the analyzed
/// content here.
String updateExpectedDiagnostics({
  required String content,
  required List<Diagnostic> actualDiagnostics,
}) {
  return _ExpectedDiagnosticsUpdater(content).update(actualDiagnostics);
}

/// Returns each file's content with canonical diagnostic expectation markers.
///
/// This is the multi-file form of [updateExpectedDiagnostics]. It supports
/// diagnostics whose context messages are located in another file in
/// [contentByFile].
Map<File, String> updateExpectedDiagnosticsForFiles({
  required Map<File, String> contentByFile,
  required Map<File, List<Diagnostic>> actualDiagnosticsByFile,
}) {
  return _ExpectedDiagnosticsForFilesUpdater(
    contentByFile,
  ).update(actualDiagnosticsByFile);
}

final class _ExpectedDiagnosticsForFilesUpdater {
  final Map<File, _ExpectedDiagnosticsUpdater> updatersByFile = {};
  final Map<String, _ExpectedDiagnosticsUpdater> updatersByPath = {};

  int nextMarkerIndex = 0;
  int nextContextId = 1;

  _ExpectedDiagnosticsForFilesUpdater(Map<File, String> contentByFile) {
    for (var entry in contentByFile.entries) {
      var updater = _ExpectedDiagnosticsUpdater(entry.value);
      updatersByFile[entry.key] = updater;
      updatersByPath[entry.key.path] = updater;
    }
  }

  Map<File, String> update(
    Map<File, List<Diagnostic>> actualDiagnosticsByFile,
  ) {
    for (var entry in actualDiagnosticsByFile.entries) {
      var updater = _updaterForPath(entry.key.path);
      var sortedDiagnostics = entry.value.toList()
        ..sort((first, second) => first.offset.compareTo(second.offset));
      for (var diagnostic in sortedDiagnostics) {
        _generateDiagnosticMarkers(updater, diagnostic);
      }
    }

    return {
      for (var entry in updatersByFile.entries)
        entry.key: entry.value._writeContent(),
    };
  }

  void _generateDiagnosticMarkers(
    _ExpectedDiagnosticsUpdater diagnosticUpdater,
    Diagnostic diagnostic,
  ) {
    var contextRefs = <int>[];
    for (var contextMessage in diagnostic.contextMessages) {
      var contextUpdater = _updaterForPath(contextMessage.filePath);
      var id = nextContextId++;
      contextRefs.add(id);
      contextUpdater._addContextMessageMarker(
        contextMessage,
        id: id,
        index: nextMarkerIndex++,
      );
    }

    diagnosticUpdater._addDiagnosticMarker(
      diagnostic,
      index: nextMarkerIndex++,
      contextRefs: contextRefs,
    );
  }

  _ExpectedDiagnosticsUpdater _updaterForPath(String path) {
    var updater = updatersByPath[path];
    if (updater == null) {
      throw StateError(
        'Cannot generate diagnostic expectations for $path: '
        'no content was provided.',
      );
    }
    return updater;
  }
}

final class _ExpectedDiagnosticsUpdater {
  final List<_Line> lines;
  final LineInfo lineInfo;
  final Map<int, List<_GeneratedMarker>> markersByLine = {};

  int nextMarkerIndex = 0;
  int nextContextId = 1;

  _ExpectedDiagnosticsUpdater(String content)
    : lines = _Line.parse(content),
      lineInfo = LineInfo.fromContent(content) {
    for (var line in lines) {
      if (_LineMarker.isMarker(line)) {
        throw StateError(
          'Expected content without diagnostic expectation markers, '
          'found one on line ${line.number}.',
        );
      }
    }
  }

  String update(List<Diagnostic> actualDiagnostics) {
    _generateMarkers(actualDiagnostics);
    return _writeContent();
  }

  void _addContextMessageMarker(
    DiagnosticMessage contextMessage, {
    required int id,
    required int index,
  }) {
    var location = _markerLocation(offset: contextMessage.offset);
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
        index: index,
        id: id,
        column: location.column,
        length: contextMessage.length,
        caretLength: presentation.caretLength,
        includeExplicitLocation: presentation.includeExplicitLocation,
        message: _messageText(contextMessage),
      ),
    );
  }

  void _addDiagnosticMarker(
    Diagnostic diagnostic, {
    required int index,
    required List<int> contextRefs,
  }) {
    var location = _markerLocation(offset: diagnostic.offset);
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
        index: index,
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
        throw StateError(
          'Cannot generate a diagnostic expectation with a context message '
          'in another file. Use updateExpectedDiagnosticsForFiles instead.',
        );
      }

      var id = nextContextId++;
      contextRefs.add(id);
      _addContextMessageMarker(
        contextMessage,
        id: id,
        index: nextMarkerIndex++,
      );
    }

    _addDiagnosticMarker(
      diagnostic,
      index: nextMarkerIndex++,
      contextRefs: contextRefs,
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
  ({int lineNumber, int column}) _markerLocation({required int offset}) {
    var location = lineInfo.getLocation(offset);
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

  String _writeContent() {
    var buffer = StringBuffer();
    for (var line in lines) {
      buffer.write(line.text);

      var markers = markersByLine[line.number];
      if (markers != null) {
        var markerLineTerminator = line.lineTerminator;

        // Use a separator when adding markers after an unterminated final line.
        if (markerLineTerminator.isEmpty) {
          markerLineTerminator = '\n';
        }

        markers.sort(_GeneratedMarker.compare);
        ({int column, int length})? currentCaret;
        for (var marker in markers) {
          if (marker.caretLength case var caretLength?) {
            var markerCaret = (column: marker.column, length: caretLength);
            if (markerCaret != currentCaret) {
              buffer.write(markerLineTerminator);
              buffer.write(_caretLine(marker.column, caretLength));
              currentCaret = markerCaret;
            }
          }
          buffer.write(markerLineTerminator);
          buffer.write(marker.expectationText);
        }
      }

      buffer.write(line.lineTerminator);
    }
    return buffer.toString();
  }

  static String _messageText(DiagnosticMessage message) {
    var text = message.messageText(includeUrl: false);
    text = _toPosixPaths(text).trim();
    text = LineSplitter.split(text).join(r'\n');
    return text;
  }

  static String _toPosixPaths(String message) {
    return message.replaceAllMapped(RegExp(r'C:\\([a-zA-Z0-9_.\\]*)'), (match) {
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

  /// The line terminator, if present.
  final String lineTerminator;

  _Line({
    required this.number,
    required this.text,
    required this.lineTerminator,
  });

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
        var lineText = content.substring(lineStart, index);

        var lineTerminator = content.substring(index, index + 1);
        if (codeUnit == 0x0D &&
            index + 1 < content.length &&
            content.codeUnitAt(index + 1) == 0x0A) {
          lineTerminator = content.substring(index, index + 2);
          index++;
        }

        result.add(
          _Line(
            number: lineNumber++,
            text: lineText,
            lineTerminator: lineTerminator,
          ),
        );
        lineStart = index + 1;
      }
    }

    result.add(
      _Line(
        number: lineNumber,
        text: content.substring(lineStart),
        lineTerminator: '',
      ),
    );
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
