// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/utilities/source_edit_diff_output.dart';

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

  /// Formats a diff showing the result of applying the given [edits] to the
  /// given [origText].
  List<String> formatDiff(String origText, Map<int, List<AtomicEdit>> edits);
}

abstract class DiffStyleImpl extends DiffStyle {
  DiffStyleImpl._() : super._();

  String get bullet;

  String deleted(String text);

  @override
  List<String> formatDiff(String origText, Map<int, List<AtomicEdit>> edits) {
    var output = _createOutput();
    int prevOffset = 0;
    for (var offset in edits.keys.toList()..sort()) {
      if (offset > prevOffset) {
        var text = origText.substring(prevOffset, offset);
        var splitText = text.split('\n');
        output.addUnchangedText(splitText.first);
        if (splitText.length > 1) {
          output.skipUnchangedNewlines(splitText.length - 1);
          output.addUnchangedText(splitText.last);
        }
        prevOffset = offset;
      }
      for (var edit in edits[offset]) {
        if (edit.length > 0) {
          var offset = prevOffset + edit.length;
          var text = origText.substring(prevOffset, offset);
          var splitText = text.split('\n');
          output.addDeletedText(splitText.first);
          for (int i = 1; i < splitText.length; i++) {
            output.addDeletedNewline();
            output.addDeletedText(splitText[i]);
          }
          prevOffset = offset;
        }
        if (edit.replacement.isNotEmpty) {
          var splitText = edit.replacement.split('\n');
          output.addInsertedText(splitText.first);
          for (int i = 1; i < splitText.length; i++) {
            output.addInsertedNewline();
            output.addInsertedText(splitText[i]);
          }
        }
      }
    }
    var text = origText.substring(prevOffset);
    var splitText = text.split('\n');
    output.addUnchangedText(splitText.first);
    output.skipUnchangedNewlines(splitText.length - 1);
    if (splitText.length > 1) {
      output.addUnchangedText(splitText.last);
    }
    return output.finish();
  }

  String inserted(String text);

  String lineHeader(int lineNum, String separator) {
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

  String unchanged(String text);

  SourceEditDiffOutput _createOutput();
}

/// Implementation of [DiffStyle] used in production.
class _DiffStyleForProduction extends DiffStyleImpl {
  final Ansi _ansi;

  _DiffStyleForProduction(this._ansi) : super._();

  @override
  String get bullet => '•';

  @override
  String deleted(String text) =>
      '${_ansi.red}${_ansi.reversed}$text${_ansi.none}';

  @override
  String inserted(String text) =>
      '${_ansi.green}${_ansi.reversed}$text${_ansi.none}';

  @override
  String unchanged(String text) => text;

  @override
  SourceEditDiffOutput _createOutput() =>
      _ansi.useAnsi ? CompactOutput(this) : TraditionalOutput(this);
}

/// Implementation of [DiffStyle] used in unit tests.  Instead of using ANSI
/// escape sequences and unicode characters, we use characters easy to type into
/// unit tests.
class _DiffStyleForTesting extends DiffStyleImpl {
  final bool _compact;

  _DiffStyleForTesting(this._compact) : super._();

  @override
  String get bullet => '*';

  @override
  String deleted(String text) => '{-$text-}';

  @override
  String inserted(String text) => '{+$text+}';

  @override
  String unchanged(String text) => text;

  @override
  SourceEditDiffOutput _createOutput() =>
      _compact ? CompactOutput(this) : TraditionalOutput(this);
}
