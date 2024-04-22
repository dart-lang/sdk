// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

/// The name and location of a diagnostic name in an ignore comment.
class IgnoredDiagnosticName implements IgnoredElement {
  /// The name of the diagnostic being ignored.
  final String name;

  final int offset;

  /// Initialize a newly created diagnostic name to have the given [name] and
  /// [offset].
  IgnoredDiagnosticName(String name, this.offset) : name = name.toLowerCase();

  /// Returns whether this diagnostic name matches the given error code.
  @override
  bool matches(ErrorCode errorCode) {
    if (name == errorCode.name.toLowerCase()) {
      return true;
    }
    var uniqueName = errorCode.uniqueName;
    var period = uniqueName.indexOf('.');
    if (period >= 0) {
      uniqueName = uniqueName.substring(period + 1);
    }
    return name == uniqueName.toLowerCase();
  }
}

class IgnoredDiagnosticType implements IgnoredElement {
  final String type;

  final int offset;

  final int length;

  IgnoredDiagnosticType(String type, this.offset, this.length)
      : type = type.toLowerCase();

  @override
  bool matches(ErrorCode errorCode) =>
      type == errorCode.type.name.toLowerCase();
}

sealed class IgnoredElement {
  bool matches(ErrorCode errorCode);
}

/// Information about analysis `//ignore:` and `//ignore_for_file:` comments
/// within a source file.
class IgnoreInfo {
  /// A regular expression for matching 'ignore' comments.
  ///
  /// Resulting codes may be in a list ('error_code_1,error_code2').
  static final RegExp ignoreMatcher = RegExp(r'//+[ ]*ignore:');

  /// A regular expression for matching 'ignore_for_file' comments.
  ///
  /// Resulting codes may be in a list ('error_code_1,error_code2').
  static final RegExp ignoreForFileMatcher = RegExp(r'//[ ]*ignore_for_file:');

  /// A regular expression for matching 'ignore' comments in a .yaml file.
  ///
  /// Resulting codes may be in a list ('error_code_1,error_code2').
  static final RegExp yamlIgnoreMatcher =
      RegExp(r'^(?<before>.*)#+[ ]*ignore:(?<ignored>.*)', multiLine: true);

  /// A regular expression for matching 'ignore_for_file' comments.
  ///
  /// Resulting codes may be in a list ('error_code_1,error_code2').
  static final RegExp yamlIgnoreForFileMatcher =
      RegExp(r'#[ ]*ignore_for_file:(?<ignored>.*)');

  static final _trimmedCommaSeparatedMatcher = RegExp(r'[^\s,]([^,]*[^\s,])?');

  /// A table mapping line numbers to the elements (diagnostics and diagnostic
  /// types) that are ignored on that line.
  final Map<int, List<IgnoredElement>> _ignoredOnLine = {};

  /// A list containing all of the elements (diagnostics and diagnostic types)
  /// that are ignored for the whole file.
  final List<IgnoredElement> _ignoredForFile = [];

  final LineInfo lineInfo;

  IgnoreInfo.empty() : lineInfo = LineInfo([]);

  /// Initializes a newly created instance of this class to represent the ignore
  /// comments in the given compilation [unit].
  IgnoreInfo.forDart(CompilationUnit unit, String content)
      : lineInfo = unit.lineInfo {
    for (var comment in unit.ignoreComments) {
      var lexeme = comment.lexeme;
      if (lexeme.contains('ignore:')) {
        var location = lineInfo.getLocation(comment.offset);
        var lineNumber = location.lineNumber;
        var offsetOfLine = lineInfo.getOffsetOfLine(lineNumber - 1);
        var beforeMatch = content.substring(
            offsetOfLine, offsetOfLine + location.columnNumber - 1);
        if (beforeMatch.trim().isEmpty) {
          // The comment is on its own line, so it refers to the next line.
          lineNumber++;
        }
        _ignoredOnLine
            .putIfAbsent(lineNumber, () => [])
            .addAll(comment.ignoredElements);
      } else if (lexeme.contains('ignore_for_file:')) {
        _ignoredForFile.addAll(comment.ignoredElements);
      }
    }
  }

  /// Initializes a newly created instance of this class to represent the ignore
  /// comments in the given YAML file.
  IgnoreInfo.forYaml(String content, this.lineInfo) {
    Iterable<IgnoredDiagnosticName> diagnosticNamesInMatch(RegExpMatch match) {
      var ignored = match.namedGroup('ignored')!;
      var offset = match.start;
      return _trimmedCommaSeparatedMatcher
          .allMatches(ignored)
          .map((m) => IgnoredDiagnosticName(m[0]!, offset + m.start));
    }

    for (var match in yamlIgnoreForFileMatcher.allMatches(content)) {
      _ignoredForFile.addAll(diagnosticNamesInMatch(match));
    }
    for (var match in yamlIgnoreMatcher.allMatches(content)) {
      var lineNumber = lineInfo.getLocation(match.start).lineNumber;
      var beforeComment = match.namedGroup('before')!;
      var nextLine = beforeComment.trim().isEmpty;
      _ignoredOnLine
          .putIfAbsent(nextLine ? lineNumber + 1 : lineNumber, () => [])
          .addAll(diagnosticNamesInMatch(match));
    }
  }

  /// Return `true` if there are any ignore comments in the file.
  bool get hasIgnores =>
      _ignoredOnLine.isNotEmpty || _ignoredForFile.isNotEmpty;

  /// Return a list containing all of the diagnostics that are ignored for the
  /// whole file.
  List<IgnoredElement> get ignoredForFile => _ignoredForFile.toList();

  /// Return a table mapping line numbers to the diagnostics that are ignored on
  /// that line.
  Map<int, List<IgnoredElement>> get ignoredOnLine {
    Map<int, List<IgnoredElement>> ignoredOnLine = {};
    for (var entry in _ignoredOnLine.entries) {
      ignoredOnLine[entry.key] = entry.value.toList();
    }
    return ignoredOnLine;
  }

  bool ignored(AnalysisError error) {
    var line = lineInfo.getLocation(error.offset).lineNumber;
    return ignoredAt(error.errorCode, line);
  }

  /// Return `true` if the [errorCode] is ignored at the given [line].
  bool ignoredAt(ErrorCode errorCode, int line) {
    var ignoredDiagnostics = _ignoredOnLine[line];
    if (ignoredForFile.isEmpty && ignoredDiagnostics == null) {
      return false;
    }
    if (ignoredForFile.any((name) => name.matches(errorCode))) {
      return true;
    }
    if (ignoredDiagnostics == null) {
      return false;
    }
    return ignoredDiagnostics.any((name) => name.matches(errorCode));
  }
}

extension CommentTokenExtension on CommentToken {
  /// The elements ([IgnoredDiagnosticName]s and [IgnoredDiagnosticType]s) cited
  /// by this comment, if it is a correctly formatted ignore comment.
  // Use of `sync*` should not be non-performant; the vast majority of ignore
  // comments cite a single diagnostic name. Ignore comments that cite multiple
  // diagnostic names typically cite only a handful.
  Iterable<IgnoredElement> get ignoredElements sync* {
    var offset = lexeme.indexOf(':') + 1;

    void skipPastWhitespace() {
      while (offset < lexeme.length) {
        if (!lexeme.codeUnitAt(offset).isWhitespace) {
          return;
        }
        offset++;
      }
    }

    void readWord() {
      if (!lexeme.codeUnitAt(offset).isLetter) {
        // Must start with a letter.
        return;
      }
      offset++;
      while (offset < lexeme.length) {
        if (!lexeme.codeUnitAt(offset).isLetterOrDigitOrUnderscore) {
          return;
        }
        offset++;
      }
    }

    while (true) {
      skipPastWhitespace();
      if (offset == lexeme.length) {
        // Reached the end without finding any ignored elements.
        return;
      }
      var wordOffset = offset;
      // Parse each comma-separated diagnostic code, and diagnostic type.
      readWord();
      if (wordOffset == offset) {
        // There is a non-word (other characters) at `offset`.
        return;
      }
      var word = lexeme.substring(wordOffset, offset);
      if (word.toLowerCase() == 'type') {
        // Parse diagnostic type.
        skipPastWhitespace();
        if (offset == lexeme.length) return;
        var equalSign = lexeme.codeUnitAt(offset);
        if (equalSign != 0x3D) return;
        offset++;
        skipPastWhitespace();
        if (offset == lexeme.length) return;
        var typeOffset = offset;
        readWord();
        if (typeOffset == offset) {
          // There is a non-word (other characters) at `offset`.
          return;
        }
        if (offset < lexeme.length) {
          var nextChar = lexeme.codeUnitAt(offset);
          if (!nextChar.isSpace && !nextChar.isComma) {
            // There are non-identifier characters at the end of this word,
            // like `ignore: http://google.com`. This is not a diagnostic name.
            return;
          }
        }
        var type = lexeme.substring(typeOffset, offset);
        yield IgnoredDiagnosticType(
            type, this.offset + wordOffset, offset - wordOffset);
      } else {
        if (offset < lexeme.length) {
          var nextChar = lexeme.codeUnitAt(offset);
          if (!nextChar.isSpace && !nextChar.isComma) {
            // There are non-identifier characters at the end of this word,
            // like `ignore: http://google.com`. This is not a diagnostic name.
            return;
          }
        }
        yield IgnoredDiagnosticName(word, this.offset + wordOffset);
      }

      if (offset == lexeme.length) return;
      skipPastWhitespace();
      if (offset == lexeme.length) return;

      var nextChar = lexeme.codeUnitAt(offset);
      if (!nextChar.isComma) return;
      // We've reached the end of the comma-separated codes and types. What
      // follows is unstructured comment text.
      offset++;
      if (offset == lexeme.length) return;
    }
  }
}

extension CompilationUnitExtension on CompilationUnit {
  /// Returns all of the ignore comments in this compilation unit.
  List<CommentToken> get ignoreComments {
    var result = <CommentToken>[];

    void processPrecedingComments(Token currentToken) {
      var comment = currentToken.precedingComments;
      while (comment != null) {
        var lexeme = comment.lexeme;
        if (lexeme.startsWith(IgnoreInfo.ignoreMatcher)) {
          result.add(comment);
        } else if (lexeme.startsWith(IgnoreInfo.ignoreForFileMatcher)) {
          result.add(comment);
        }
        comment = comment.next as CommentToken?;
      }
    }

    var currentToken = beginToken;
    while (currentToken != currentToken.next) {
      processPrecedingComments(currentToken);
      currentToken = currentToken.next!;
    }
    processPrecedingComments(currentToken);

    return result;
  }
}
