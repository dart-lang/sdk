// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

/// The text and location of trailing unstructured comment text in an ignore
/// comment.
class IgnoredDiagnosticComment implements IgnoredElement {
  final String text;

  final int offset;

  IgnoredDiagnosticComment(this.text, this.offset);

  @override
  bool _matches(DiagnosticCode diagnosticCode, {String? pluginName}) => false;
}

/// The name and location of a diagnostic name in an ignore comment.
class IgnoredDiagnosticName implements IgnoredElement {
  /// The name of the diagnostic being ignored.
  final String name;

  final String? pluginName;

  final int offset;

  IgnoredDiagnosticName(String name, this.offset, {this.pluginName})
    : name = name.toLowerCase();

  @override
  bool _matches(DiagnosticCode diagnosticCode, {String? pluginName}) {
    if (this.pluginName != pluginName) {
      return false;
    }
    if (name == diagnosticCode.name.toLowerCase()) {
      return true;
    }
    var uniqueName = diagnosticCode.uniqueName;
    var period = uniqueName.indexOf('.');
    if (period >= 0) {
      uniqueName = uniqueName.substring(period + 1);
    }
    return name == uniqueName.toLowerCase();
  }
}

/// The name and location of a diagnostic type in an ignore comment.
class IgnoredDiagnosticType implements IgnoredElement {
  final String type;

  final int offset;

  final int length;

  IgnoredDiagnosticType(String type, this.offset, this.length)
    : type = type.toLowerCase();

  @override
  bool _matches(DiagnosticCode diagnosticCode, {String? pluginName}) {
    // Ignore 'pluginName'; it is irrelevant in an IgnoredDiagnosticType.
    return switch (diagnosticCode.type) {
      DiagnosticType.HINT => type == 'hint',
      DiagnosticType.LINT => type == 'lint',
      DiagnosticType.STATIC_WARNING => type == 'warning',
      // Only errors with one of the above types can be ignored via the type.
      _ => false,
    };
  }
}

sealed class IgnoredElement {
  /// Returns whether this matches the given [diagnosticCode].
  bool _matches(DiagnosticCode diagnosticCode, {String? pluginName});
}

/// Information about analysis `//ignore:` and `//ignore_for_file:` comments
/// within a source file.
class IgnoreInfo {
  /// A regular expression for matching 'ignore' comments.
  ///
  /// Resulting codes may be in a list (e.g. 'error_code_1,error_code2').
  static final RegExp ignoreMatcher = RegExp(r'//+[ ]*ignore:');

  /// A regular expression for matching 'ignore_for_file' comments.
  ///
  /// Resulting codes may be in a list (e.g. 'error_code_1,error_code2').
  static final RegExp ignoreForFileMatcher = RegExp(r'//[ ]*ignore_for_file:');

  /// A regular expression for matching 'ignore' comments in a .yaml file.
  ///
  /// Resulting codes may be in a list (e.g. 'error_code_1,error_code2').
  static final RegExp _yamlIgnoreMatcher = RegExp(
    r'^(?<before>.*)#+[ ]*ignore:(?<ignored>.*)',
    multiLine: true,
  );

  /// A regular expression for matching 'ignore_for_file' comments.
  ///
  /// Resulting codes may be in a list (e.g. 'error_code_1,error_code2').
  static final RegExp _yamlIgnoreForFileMatcher = RegExp(
    r'#[ ]*ignore_for_file:(?<ignored>.*)',
  );

  static final _trimmedCommaSeparatedMatcher = RegExp(r'[^\s,]([^,]*[^\s,])?');

  /// A table mapping line numbers to the elements (diagnostics and diagnostic
  /// types) that are ignored on that line.
  final Map<int, List<IgnoredElement>> _ignoredOnLine = {};

  /// A list containing all of the elements (diagnostics and diagnostic types)
  /// that are ignored for the whole file.
  final List<IgnoredElement> _ignoredForFile = [];

  final LineInfo _lineInfo;

  IgnoreInfo.empty() : _lineInfo = LineInfo([]);

  /// Initializes a newly created instance of this class to represent the ignore
  /// comments in the given compilation [unit].
  IgnoreInfo.forDart(CompilationUnit unit, String content)
    : _lineInfo = unit.lineInfo {
    for (var comment in unit.ignoreComments) {
      var lexeme = comment.lexeme;
      if (lexeme.contains('ignore:')) {
        var location = _lineInfo.getLocation(comment.offset);
        var lineNumber = location.lineNumber;
        var offsetOfLine = _lineInfo.getOffsetOfLine(lineNumber - 1);
        var beforeMatch = content.substring(
          offsetOfLine,
          offsetOfLine + location.columnNumber - 1,
        );
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
  IgnoreInfo.forYaml(String content, this._lineInfo) {
    Iterable<IgnoredDiagnosticName> diagnosticNamesInMatch(RegExpMatch match) {
      var ignored = match.namedGroup('ignored')!;
      var offset = match.start;
      return _trimmedCommaSeparatedMatcher
          .allMatches(ignored)
          .map((m) => IgnoredDiagnosticName(m[0]!, offset + m.start));
    }

    for (var match in _yamlIgnoreForFileMatcher.allMatches(content)) {
      _ignoredForFile.addAll(diagnosticNamesInMatch(match));
    }
    for (var match in _yamlIgnoreMatcher.allMatches(content)) {
      var lineNumber = _lineInfo.getLocation(match.start).lineNumber;
      var beforeComment = match.namedGroup('before')!;
      var nextLine = beforeComment.trim().isEmpty;
      _ignoredOnLine
          .putIfAbsent(nextLine ? lineNumber + 1 : lineNumber, () => [])
          .addAll(diagnosticNamesInMatch(match));
    }
  }

  /// Whether there are any ignore comments in the file.
  bool get hasIgnores =>
      _ignoredOnLine.isNotEmpty || _ignoredForFile.isNotEmpty;

  /// A list containing all of the diagnostics that are ignored for the whole
  /// file.
  List<IgnoredElement> get ignoredForFile => _ignoredForFile.toList();

  /// A table mapping line numbers to the diagnostics that are ignored on that
  /// line.
  Map<int, List<IgnoredElement>> get ignoredOnLine {
    Map<int, List<IgnoredElement>> ignoredOnLine = {};
    for (var entry in _ignoredOnLine.entries) {
      ignoredOnLine[entry.key] = entry.value.toList();
    }
    return ignoredOnLine;
  }

  /// Whether [diagnostic] is ignored via an inline "ignore" comment.
  bool ignored(Diagnostic diagnostic, {String? pluginName}) {
    var line = _lineInfo.getLocation(diagnostic.offset).lineNumber;
    return _ignoredAt(diagnostic.diagnosticCode, line, pluginName: pluginName);
  }

  /// Returns whether the [diagnosticCode] is ignored at the given [line].
  bool _ignoredAt(
    DiagnosticCode diagnosticCode,
    int line, {
    String? pluginName,
  }) {
    var ignoredDiagnostics = _ignoredOnLine[line];
    if (ignoredForFile.isEmpty && ignoredDiagnostics == null) {
      return false;
    }
    if (ignoredForFile.any(
      (name) => name._matches(diagnosticCode, pluginName: pluginName),
    )) {
      return true;
    }
    if (ignoredDiagnostics == null) {
      return false;
    }
    return ignoredDiagnostics.any(
      (name) => name._matches(diagnosticCode, pluginName: pluginName),
    );
  }
}

extension CommentTokenExtension on CommentToken {
  /// The elements ([IgnoredDiagnosticName]s and [IgnoredDiagnosticType]s) cited
  /// by this comment, if it is a correctly formatted ignore comment.
  List<IgnoredElement> get ignoredElements {
    List<IgnoredElement> result = [];
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
      if (!lexeme.codeUnitAt(offset).isLetter &&
          !lexeme.codeUnitAt(offset).isUnderscore) {
        // Must start with a letter or underscore.
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

    // We only want to add an `IgnoredDiagnosticComment` if it is preceded by
    // one or more `IgnoredDiagnosticName`s or `IgnoredDiagnosticType`s.
    var hasIgnoredElements = false;

    while (true) {
      skipPastWhitespace();
      if (offset == lexeme.length) {
        // Reached the end without finding any ignored elements.
        return result;
      }
      var wordOffset = offset;
      // Parse each comma-separated diagnostic code, and diagnostic type.
      readWord();
      if (wordOffset == offset) {
        // There is a non-word (other characters) at `offset`.
        if (hasIgnoredElements) {
          result.add(
            IgnoredDiagnosticComment(
              lexeme.substring(offset),
              this.offset + wordOffset,
            ),
          );
        }
        return result;
      }
      var word = lexeme.substring(wordOffset, offset);
      if (word.toLowerCase() == 'type') {
        // Parse diagnostic type.
        skipPastWhitespace();
        if (offset == lexeme.length) return result;
        var nextChar = lexeme.codeUnitAt(offset);
        if (!nextChar.isEqual) return result;
        offset++;
        skipPastWhitespace();
        if (offset == lexeme.length) return result;
        var typeOffset = offset;
        readWord();
        if (typeOffset == offset) {
          // There is a non-word (other characters) at `offset`.
          if (hasIgnoredElements) {
            result.add(
              IgnoredDiagnosticComment(
                lexeme.substring(offset),
                this.offset + wordOffset,
              ),
            );
          }
          return result;
        }
        if (offset < lexeme.length) {
          var nextChar = lexeme.codeUnitAt(offset);
          if (!nextChar.isSpace && !nextChar.isComma) {
            // There are non-identifier characters at the end of this word,
            // like `ignore: http://google.com`. This is not a diagnostic name.
            if (hasIgnoredElements) {
              result.add(
                IgnoredDiagnosticComment(
                  lexeme.substring(wordOffset),
                  this.offset + wordOffset,
                ),
              );
            }
            return result;
          }
        }
        var type = lexeme.substring(typeOffset, offset);
        hasIgnoredElements = true;
        result.add(
          IgnoredDiagnosticType(
            type,
            this.offset + wordOffset,
            offset - wordOffset,
          ),
        );
      } else {
        String? pluginName;
        if (offset < lexeme.length) {
          var nextChar = lexeme.codeUnitAt(offset);
          if (nextChar.isSlash) {
            // We may be looking at a plugin-name-prefixed code, like
            // 'plugin_one/foo'.
            pluginName = word;
            offset++;
            if (offset == lexeme.length) return result;
            var nameOffset = offset;
            readWord();
            word = lexeme.substring(nameOffset, offset);
            if (nameOffset == offset) {
              // There is a non-word (other characters) at `offset`.
              if (hasIgnoredElements) {
                result.add(
                  IgnoredDiagnosticComment(
                    lexeme.substring(offset),
                    this.offset + nameOffset,
                  ),
                );
              }
              return result;
            }
          }
        }
        if (offset < lexeme.length) {
          var nextChar = lexeme.codeUnitAt(offset);
          if (!nextChar.isSpace && !nextChar.isComma) {
            // There are non-identifier characters at the end of this word,
            // like `ignore: http://google.com`. This is not a diagnostic name.
            if (hasIgnoredElements) {
              result.add(
                IgnoredDiagnosticComment(
                  lexeme.substring(wordOffset),
                  this.offset + wordOffset,
                ),
              );
            }
            return result;
          }
        }
        hasIgnoredElements = true;
        result.add(
          IgnoredDiagnosticName(
            word,
            this.offset + wordOffset,
            pluginName: pluginName,
          ),
        );
      }

      if (offset == lexeme.length) return result;
      skipPastWhitespace();
      if (offset == lexeme.length) return result;

      var nextChar = lexeme.codeUnitAt(offset);
      if (!nextChar.isComma) {
        // We've reached the end of the comma-separated codes and types. What
        // follows is unstructured comment text.
        if (hasIgnoredElements) {
          result.add(
            IgnoredDiagnosticComment(
              lexeme.substring(offset),
              this.offset + wordOffset,
            ),
          );
        }
        return result;
      }
      offset++;
      if (offset == lexeme.length) return result;
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
