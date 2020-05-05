// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/edit_plan.dart';

/// Information about the style in which we display diffs.
abstract class DiffStyle {
  /// Creates a DiffStyle suitable for use with a terminal whose ANSI support is
  /// indicated by [ansi].
  ///
  /// If the terminal supports ANSI, we use a compact diff style with intra-line
  /// diffs, where insertions are represented by green reversed text and
  /// deletions are represented by red reversed text.
  ///
  /// If the terminal does not support ANSI, we use a traditional diff style
  /// with before and after lines.
  factory DiffStyle(Ansi ansi) = _DiffStyleForProduction;

  /// Creates a DiffStyle suitable for unit testing.  Instead of using ANSI
  /// escape codes for color coding, we use `{+` and `+}` to surround added
  /// text, and `{-` and `-}` to surround deleted text.
  @visibleForTesting
  factory DiffStyle.forTesting(bool compact) = _DiffStyleForTesting;

  DiffStyle._();

  String get _bullet;

  /// Formats a diff showing the result of applying the given [edits] to the
  /// given [origText].
  List<String> formatDiff(String origText, Map<int, List<AtomicEdit>> edits) {
    return _createOutput()._processEdits(origText, edits);
  }

  _Output _createOutput();

  String _deleted(String text);

  String _inserted(String text);

  String _lineHeader(int lineNum, String separator) {
    const String emptyLineHeader = '         ';
    if (lineNum == null) {
      return emptyLineHeader + separator;
    } else {
      var text = 'line $lineNum';
      if (text.length < emptyLineHeader.length) {
        text = text + ' ' * (emptyLineHeader.length - text.length);
      }
      return text + separator;
    }
  }

  String _unchanged(String text);
}

/// Implementation of [_Output] for generating compact intra-line diffs.
class _CompactOutput extends _Output {
  final DiffStyle style;

  /// Output generated so far.
  final List<String> _lines = [];

  /// Accumulator for the current output line.
  final _currentLine = StringBuffer();

  /// True if the string in [_currentLine] indicates changes.
  bool _pendingChanges = false;

  /// The current line number, with reference to the original source text.
  int _lineNum = 1;

  _CompactOutput(this.style) {
    _writeLineHeader(true);
  }

  void _addDeletedNewline() {
    _flushLine();
    _lineNum++;
    _writeLineHeader(true);
  }

  void _addDeletedText(String text) {
    if (text.isNotEmpty) {
      _currentLine.write(style._deleted(text));
      _pendingChanges = true;
    }
  }

  void _addInsertedNewline() {
    _flushLine();
    _writeLineHeader(false);
  }

  void _addInsertedText(String text) {
    if (text.isNotEmpty) {
      _currentLine.write(style._inserted(text));
      _pendingChanges = true;
    }
  }

  void _addUnchangedText(String text) {
    if (text.isNotEmpty) {
      _currentLine.write(style._unchanged(text));
    }
  }

  @override
  List<String> _finish() {
    assert(!_pendingChanges);
    return _lines;
  }

  void _flushLine({bool suppressOutput = false}) {
    if (!suppressOutput) {
      _lines.add(_currentLine.toString());
    }
    _currentLine.clear();
    _pendingChanges = false;
  }

  void _skipUnchangedNewlines(int count) {
    _flushLine(suppressOutput: !_pendingChanges);
    _lineNum += count;
    _writeLineHeader(true);
  }

  void _writeLineHeader(bool includeLineNum) {
    _currentLine.write(style._lineHeader(
        includeLineNum ? _lineNum : null, '${style._bullet} '));
  }
}

/// Implementation of [DiffStyle] used in production.
class _DiffStyleForProduction extends DiffStyle {
  final Ansi _ansi;

  _DiffStyleForProduction(this._ansi) : super._();

  @override
  String get _bullet => '•';

  @override
  _Output _createOutput() =>
      _ansi.useAnsi ? _CompactOutput(this) : _TraditionalOutput(this);

  @override
  String _deleted(String text) =>
      '${_ansi.red}${_ansi.reversed}$text${_ansi.none}';

  @override
  String _inserted(String text) =>
      '${_ansi.green}${_ansi.reversed}$text${_ansi.none}';

  @override
  String _unchanged(String text) => text;
}

/// Implementation of [DiffStyle] used in unit tests.  Instead of using ANSI
/// escape sequences and unicode characters, we use characters easy to type into
/// unit tests.
class _DiffStyleForTesting extends DiffStyle {
  final bool _compact;

  _DiffStyleForTesting(this._compact) : super._();

  @override
  String get _bullet => '*';

  @override
  _Output _createOutput() =>
      _compact ? _CompactOutput(this) : _TraditionalOutput(this);

  @override
  String _deleted(String text) => '{-$text-}';

  @override
  String _inserted(String text) => '{+$text+}';

  @override
  String _unchanged(String text) => text;
}

/// Abstract base class capable of generating diff output.
abstract class _Output {
  void _addDeletedNewline();

  void _addDeletedText(String text);

  void _addInsertedNewline();

  void _addInsertedText(String text);

  void _addUnchangedText(String text);

  List<String> _finish();

  List<String> _processEdits(
      String origText, Map<int, List<AtomicEdit>> edits) {
    int prevOffset = 0;
    for (var offset in edits.keys.toList()..sort()) {
      if (offset > prevOffset) {
        var text = origText.substring(prevOffset, offset);
        var splitText = text.split('\n');
        _addUnchangedText(splitText.first);
        if (splitText.length > 1) {
          _skipUnchangedNewlines(splitText.length - 1);
          _addUnchangedText(splitText.last);
        }
        prevOffset = offset;
      }
      for (var edit in edits[offset]) {
        if (edit.length > 0) {
          var offset = prevOffset + edit.length;
          var text = origText.substring(prevOffset, offset);
          var splitText = text.split('\n');
          _addDeletedText(splitText.first);
          for (int i = 1; i < splitText.length; i++) {
            _addDeletedNewline();
            _addDeletedText(splitText[i]);
          }
          prevOffset = offset;
        }
        if (edit.replacement.isNotEmpty) {
          var splitText = edit.replacement.split('\n');
          _addInsertedText(splitText.first);
          for (int i = 1; i < splitText.length; i++) {
            _addInsertedNewline();
            _addInsertedText(splitText[i]);
          }
        }
      }
    }
    var text = origText.substring(prevOffset);
    var splitText = text.split('\n');
    _addUnchangedText(splitText.first);
    _skipUnchangedNewlines(splitText.length - 1);
    if (splitText.length > 1) {
      _addUnchangedText(splitText.last);
    }
    return _finish();
  }

  void _skipUnchangedNewlines(int count);
}

/// Implementation of [_Output] for generating traditional diffs that show
/// before and after lines.
class _TraditionalOutput extends _Output {
  final DiffStyle style;

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

  _TraditionalOutput(this.style);

  void _addDeletedNewline() {
    _flushBeforeLine();
    _lineNum++;
    if (_currentAfterLine.isEmpty) {
      // After text is at a line break, so we can output pending changes
      _outputPendingChanges();
    }
  }

  void _addDeletedText(String text) {
    if (text.isNotEmpty) {
      _currentBeforeLine.write(style._deleted(text));
      _pendingChanges = true;
    }
  }

  void _addInsertedNewline() {
    if (_currentBeforeLine.isEmpty) {
      // Before text is at a line break, so we are adding a whole line
      _flushAfterLine(includeLineNum: true);
      _outputPendingChanges();
    } else {
      _flushAfterLine();
    }
  }

  void _addInsertedText(String text) {
    if (text.isNotEmpty) {
      _currentAfterLine.write(style._inserted(text));
      _pendingChanges = true;
    }
  }

  void _addUnchangedText(String text) {
    if (text.isNotEmpty) {
      var styledText = style._unchanged(text);
      _currentBeforeLine.write(styledText);
      _currentAfterLine.write(styledText);
    }
  }

  @override
  List<String> _finish() {
    assert(!_pendingChanges);
    assert(_afterLines.isEmpty);
    return _lines;
  }

  void _flushAfterLine(
      {bool suppressOutput = false, bool includeLineNum = false}) {
    if (!suppressOutput) {
      _afterLines.add(style._lineHeader(includeLineNum ? _lineNum : null, '+') +
          _currentAfterLine.toString());
    }
    _currentAfterLine.clear();
  }

  void _flushBeforeLine({bool suppressOutput = false}) {
    if (!suppressOutput) {
      _lines.add(
          style._lineHeader(_lineNum, '-') + _currentBeforeLine.toString());
    }
    _currentBeforeLine.clear();
  }

  void _outputPendingChanges() {
    _lines.addAll(_afterLines);
    _afterLines.clear();
    _pendingChanges = false;
  }

  void _skipUnchangedNewlines(int count) {
    _flushBeforeLine(suppressOutput: !_pendingChanges);
    _flushAfterLine(suppressOutput: !_pendingChanges);
    _outputPendingChanges();
    _lineNum += count;
  }
}
