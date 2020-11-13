// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/source.dart';

/// The name and location of a diagnostic name in an ignore comment.
class DiagnosticName {
  /// The name of the diagnostic being ignored.
  final String name;

  /// The offset of the diagnostic in the source file.
  final int offset;

  /// Initialize a newly created diagnostic name to have the given [name] and
  /// [offset].
  DiagnosticName(this.name, this.offset);

  /// Return `true` if this diagnostic name matches the given error code.
  bool matches(String errorCode) => name == errorCode;
}

/// Information about analysis `//ignore:` and `//ignore_for_file` comments
/// within a source file.
class IgnoreInfo {
  ///  Instance shared by all cases without matches.
  // ignore: deprecated_member_use_from_same_package
  static final IgnoreInfo _EMPTY_INFO = IgnoreInfo();

  /// A regular expression for matching 'ignore' comments.  Produces matches
  /// containing 2 groups.  For example:
  ///
  ///     * ['//ignore: error_code', 'error_code']
  ///
  /// Resulting codes may be in a list ('error_code_1,error_code2').
  static final RegExp _IGNORE_MATCHER =
      RegExp(r'//+[ ]*ignore:(.*)$', multiLine: true);

  /// A regular expression for matching 'ignore_for_file' comments.  Produces
  /// matches containing 2 groups.  For example:
  ///
  ///     * ['//ignore_for_file: error_code', 'error_code']
  ///
  /// Resulting codes may be in a list ('error_code_1,error_code2').
  static final RegExp _IGNORE_FOR_FILE_MATCHER =
      RegExp(r'//[ ]*ignore_for_file:(.*)$', multiLine: true);

  /// A table mapping line numbers to the diagnostics that are ignored on that
  /// line.
  final Map<int, List<DiagnosticName>> _ignoredOnLine = {};

  /// A list containing all of the diagnostics that are ignored for the whole
  /// file.
  final List<DiagnosticName> _ignoredForFile = [];

  @Deprecated('Use the constructor IgnoreInfo.forDart')
  IgnoreInfo();

  /// Initialize a newly created instance of this class to represent the ignore
  /// comments in the given compilation [unit].
  IgnoreInfo.forDart(CompilationUnit unit, String content) {
    var lineInfo = unit.lineInfo;
    for (var comment in unit.ignoreComments) {
      var lexeme = comment.lexeme;
      if (lexeme.contains('ignore:')) {
        var location = lineInfo.getLocation(comment.offset);
        var lineNumber = location.lineNumber;
        String beforeMatch = content.substring(
            lineInfo.getOffsetOfLine(lineNumber - 1),
            lineInfo.getOffsetOfLine(lineNumber - 1) +
                location.columnNumber -
                1);
        if (beforeMatch.trim().isEmpty) {
          // The comment is on its own line, so it refers to the next line.
          lineNumber++;
        }
        _ignoredOnLine
            .putIfAbsent(lineNumber, () => [])
            .addAll(comment.diagnosticNames);
      } else if (lexeme.contains('ignore_for_file:')) {
        _ignoredForFile.addAll(comment.diagnosticNames);
      }
    }
  }

  /// Return `true` if there are any ignore comments in the file.
  bool get hasIgnores =>
      _ignoredOnLine.isNotEmpty || _ignoredForFile.isNotEmpty;

  /// Return a list containing all of the diagnostics that are ignored for the
  /// whole file.
  List<DiagnosticName> get ignoredForFile => _ignoredForFile.toList();

  /// Return a table mapping line numbers to the diagnostics that are ignored on
  /// that line.
  Map<int, List<DiagnosticName>> get ignoredOnLine {
    Map<int, List<DiagnosticName>> ignoredOnLine = {};
    for (var entry in _ignoredOnLine.entries) {
      ignoredOnLine[entry.key] = entry.value.toList();
    }
    return ignoredOnLine;
  }

  /// Return `true` if the [errorCode] is ignored at the given [line].
  bool ignoredAt(String errorCode, int line) {
    for (var name in _ignoredForFile) {
      if (name.matches(errorCode)) {
        return true;
      }
    }
    var ignoredOnLine = _ignoredOnLine[line];
    if (ignoredOnLine != null) {
      for (var name in ignoredOnLine) {
        if (name.matches(errorCode)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Ignore these [errorCodes] at [line].
  void _addAll(int line, Iterable<DiagnosticName> errorCodes) {
    _ignoredOnLine.putIfAbsent(line, () => []).addAll(errorCodes);
  }

  /// Ignore these [errorCodes] in the whole file.
  void _addAllForFile(Iterable<DiagnosticName> errorCodes) {
    _ignoredForFile.addAll(errorCodes);
  }

  /// Calculate ignores for the given [content] with line [info].
  @Deprecated('Use the constructor IgnoreInfo.forDart')
  static IgnoreInfo calculateIgnores(String content, LineInfo info) {
    Iterable<Match> matches = _IGNORE_MATCHER.allMatches(content);
    Iterable<Match> fileMatches = _IGNORE_FOR_FILE_MATCHER.allMatches(content);
    if (matches.isEmpty && fileMatches.isEmpty) {
      return _EMPTY_INFO;
    }

    IgnoreInfo ignoreInfo = IgnoreInfo();
    for (Match match in matches) {
      // See _IGNORE_MATCHER for format --- note the possibility of error lists.
      // Note that the offsets are not being computed here. This shouldn't
      // affect older clients of this class because none of the previous APIs
      // depended on having offsets.
      Iterable<DiagnosticName> codes = match
          .group(1)
          .split(',')
          .map((String code) => DiagnosticName(code.trim().toLowerCase(), -1));
      CharacterLocation location = info.getLocation(match.start);
      int lineNumber = location.lineNumber;
      String beforeMatch = content.substring(
          info.getOffsetOfLine(lineNumber - 1),
          info.getOffsetOfLine(lineNumber - 1) + location.columnNumber - 1);

      if (beforeMatch.trim().isEmpty) {
        // The comment is on its own line, so it refers to the next line.
        ignoreInfo._addAll(lineNumber + 1, codes);
      } else {
        // The comment sits next to code, so it refers to its own line.
        ignoreInfo._addAll(lineNumber, codes);
      }
    }
    // Note that the offsets are not being computed here. This shouldn't affect
    // older clients of this class because none of the previous APIs depended on
    // having offsets.
    for (Match match in fileMatches) {
      Iterable<DiagnosticName> codes = match
          .group(1)
          .split(',')
          .map((String code) => DiagnosticName(code.trim().toLowerCase(), -1));
      ignoreInfo._addAllForFile(codes);
    }
    return ignoreInfo;
  }
}

extension on CompilationUnit {
  /// Return all of the ignore comments in this compilation unit.
  Iterable<CommentToken> get ignoreComments sync* {
    Iterable<CommentToken> processPrecedingComments(Token currentToken) sync* {
      var comment = currentToken.precedingComments;
      while (comment != null) {
        var lexeme = comment.lexeme;
        var match = IgnoreInfo._IGNORE_MATCHER.matchAsPrefix(lexeme);
        if (match != null) {
          yield comment;
        } else {
          match = IgnoreInfo._IGNORE_FOR_FILE_MATCHER.matchAsPrefix(lexeme);
          if (match != null) {
            yield comment;
          }
        }
        comment = comment.next;
      }
    }

    var currentToken = beginToken;
    while (currentToken != currentToken.next) {
      yield* processPrecedingComments(currentToken);
      currentToken = currentToken.next;
    }
    yield* processPrecedingComments(currentToken);
  }
}

extension on CommentToken {
  /// Return the diagnostic names contained in this comment, assuming that it is
  /// a correctly formatted ignore comment.
  Iterable<DiagnosticName> get diagnosticNames sync* {
    int offset = lexeme.indexOf(':') + 1;
    var names = lexeme.substring(offset).split(',');
    offset += this.offset;
    for (var name in names) {
      var trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        var innerOffset = name.indexOf(trimmedName);
        yield DiagnosticName(trimmedName.toLowerCase(), offset + innerOffset);
      }
      offset += name.length + 1;
    }
  }
}
