// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/utilities/source_edit_diff_formatter.dart';

/// Implementation of [SourceEditDiffOutput] for generating compact intra-line diffs.
class CompactOutput extends SourceEditDiffOutput {
  final DiffStyleImpl style;

  /// Output generated so far.
  final List<String> _lines = [];

  /// Accumulator for the current output line.
  final _currentLine = StringBuffer();

  /// True if the string in [_currentLine] indicates changes.
  bool _pendingChanges = false;

  /// The current line number, with reference to the original source text.
  int _lineNum = 1;

  CompactOutput(this.style) {
    _writeLineHeader(true);
  }

  void addDeletedNewline() {
    _flushLine();
    _lineNum++;
    _writeLineHeader(true);
  }

  void addDeletedText(String text) {
    if (text.isNotEmpty) {
      _currentLine.write(style.deleted(text));
      _pendingChanges = true;
    }
  }

  void addInsertedNewline() {
    _flushLine();
    _writeLineHeader(false);
  }

  void addInsertedText(String text) {
    if (text.isNotEmpty) {
      _currentLine.write(style.inserted(text));
      _pendingChanges = true;
    }
  }

  void addUnchangedText(String text) {
    if (text.isNotEmpty) {
      _currentLine.write(style.unchanged(text));
    }
  }

  @override
  List<String> finish() {
    assert(!_pendingChanges);
    return _lines;
  }

  void skipUnchangedNewlines(int count) {
    _flushLine(suppressOutput: !_pendingChanges);
    _lineNum += count;
    _writeLineHeader(true);
  }

  void _flushLine({bool suppressOutput = false}) {
    if (!suppressOutput) {
      _lines.add(_currentLine.toString());
    }
    _currentLine.clear();
    _pendingChanges = false;
  }

  void _writeLineHeader(bool includeLineNum) {
    _currentLine.write(
        style.lineHeader(includeLineNum ? _lineNum : null, '${style.bullet} '));
  }
}

/// Abstract base class capable of generating diff output.
///
/// Clients shouldn't interact with this class directly; they should use
/// [DiffStyle.formatDiff] instead.
abstract class SourceEditDiffOutput {
  void addDeletedNewline();

  void addDeletedText(String text);

  void addInsertedNewline();

  void addInsertedText(String text);

  void addUnchangedText(String text);

  List<String> finish();

  void skipUnchangedNewlines(int count);
}

/// Implementation of [SourceEditDiffOutput] for generating traditional diffs that show
/// before and after lines.
class TraditionalOutput extends SourceEditDiffOutput {
  final DiffStyleImpl style;

  /// Output generated so far.
  final List<String> _lines = [];

  /// Accumulator for the "after" lines in the current diff hunk.
  final List<String> _afterLines = [];

  /// Accumulator for the current "before" line.
  final _currentBeforeLine = StringBuffer();

  /// Accumulator for the current "after" line.
  final _currentAfterLine = StringBuffer();

  /// True if a hunk is currently in progress that represents changes.
  bool _pendingChanges = false;

  /// The current line number, with reference to the original source text.
  int _lineNum = 1;

  TraditionalOutput(this.style);

  void addDeletedNewline() {
    _flushBeforeLine();
    _lineNum++;
    if (_currentAfterLine.isEmpty) {
      // After text is at a line break, so we can output pending changes
      _outputPendingChanges();
    }
  }

  void addDeletedText(String text) {
    if (text.isNotEmpty) {
      _currentBeforeLine.write(style.deleted(text));
      _pendingChanges = true;
    }
  }

  void addInsertedNewline() {
    if (_currentBeforeLine.isEmpty) {
      // Before text is at a line break, so we are adding a whole line
      _flushAfterLine(includeLineNum: true);
      _outputPendingChanges();
    } else {
      _flushAfterLine();
    }
  }

  void addInsertedText(String text) {
    if (text.isNotEmpty) {
      _currentAfterLine.write(style.inserted(text));
      _pendingChanges = true;
    }
  }

  void addUnchangedText(String text) {
    if (text.isNotEmpty) {
      var styledText = style.unchanged(text);
      _currentBeforeLine.write(styledText);
      _currentAfterLine.write(styledText);
    }
  }

  @override
  List<String> finish() {
    assert(!_pendingChanges);
    assert(_afterLines.isEmpty);
    return _lines;
  }

  void skipUnchangedNewlines(int count) {
    _flushBeforeLine(suppressOutput: !_pendingChanges);
    _flushAfterLine(suppressOutput: !_pendingChanges);
    _outputPendingChanges();
    _lineNum += count;
  }

  void _flushAfterLine(
      {bool suppressOutput = false, bool includeLineNum = false}) {
    if (!suppressOutput) {
      _afterLines.add(style.lineHeader(includeLineNum ? _lineNum : null, '+') +
          _currentAfterLine.toString());
    }
    _currentAfterLine.clear();
  }

  void _flushBeforeLine({bool suppressOutput = false}) {
    if (!suppressOutput) {
      _lines
          .add(style.lineHeader(_lineNum, '-') + _currentBeforeLine.toString());
    }
    _currentBeforeLine.clear();
  }

  void _outputPendingChanges() {
    _lines.addAll(_afterLines);
    _afterLines.clear();
    _pendingChanges = false;
  }
}
