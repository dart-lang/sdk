// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/characters.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/util/comment.dart';

/// Information about the directives found in Dartdoc comments.
class DartdocDirectiveInfo {
  // TODO(brianwilkerson): Consider moving the method
  //  DartUnitHoverComputer.computeDocumentation to this class.

  /// A regular expression used to match a macro directive. There is one group
  /// that contains the name of the template.
  static final macroRegExp = RegExp(r'{@macro\s+([^}]+)}');

  /// A regular expression used to match a youtube or animation directive.
  ///
  /// These are in the form:
  /// `{@youtube 560 315 https://www.youtube.com/watch?v=2uaoEDOgk_I}`.
  static final videoRegExp = RegExp(
    r'{@(youtube|animation)\s+[^}]+\s+[^}]+\s+([^}]+)}',
  );

  /// A table mapping the names of templates to the unprocessed bodies of the
  /// templates.
  final Map<String, String> templateMap = {};

  /// Initialize a newly created set of information about Dartdoc directives.
  DartdocDirectiveInfo();

  void addTemplate(String name, String value) {
    templateMap[name] = value;
  }

  /// Add corresponding pairs from the [names] and [values] to the set of
  /// defined templates.
  void addTemplateNamesAndValues(List<String> names, List<String> values) {
    int length = names.length;
    assert(length == values.length);
    for (int i = 0; i < length; i++) {
      addTemplate(names[i], values[i]);
    }
  }

  /// Process the given Dartdoc [comment], extracting the template directive if
  /// there is one.
  void extractTemplate(String? comment) {
    if (comment == null) return;
    int end = comment.length;

    // The smallest possible match is at least 28 characters long.
    if (end < 28) return;

    // Find all matches to "{@template\s+(.+?)}([\s\S]+?){@endtemplate}".
    int from = 0;
    while (true) {
      from = _nextAtTemplate(comment, from);
      if (from < 0) return;

      // If the string isn't actually long enough to match we can return.
      if (from + 17 > end) return;

      // Require at least 1 \s character.
      int char = comment.codeUnitAt(from++);
      if (char != $SPACE && char != $TAB && char != $LF && char != $CR) {
        continue;
      }

      // Allow more \s characters.
      for (; from < end; from++) {
        char = comment.codeUnitAt(from);
        if (char != $SPACE && char != $TAB && char != $LF && char != $CR) break;
      }

      int nameStart = from;

      // The next character (that is not a line-ending - but it can't be it
      // would have been passed above) is included in the name - and then
      // anything up to "}" that is not a line-ending is also included in the
      // name.
      int i = from + 1;

      for (; i < end; i++) {
        char = comment.codeUnitAt(i);
        if (char == $LF || char == $CR || char == $CLOSE_CURLY_BRACKET) break;
      }

      // If no name was found this wasn't a match.
      if (i == nameStart) continue;

      // If no end-brace was found this wasn't a match.
      if (char != $CLOSE_CURLY_BRACKET) continue;

      int nameEnd = i;

      // The body has at least 1 character.
      i++;

      // Find the end.
      int endIndex = from = _nextAtEndtemplate(comment, i);
      if (endIndex < 0) return;
      // The endIndex is after the match - don't include the string
      // "{@endtemplate}" though.
      endIndex -= 14;

      String name = comment.substring(nameStart, nameEnd).trim();
      String body = comment.substring(nameEnd + 1, endIndex).trim();
      templateMap[name] = _stripDelimiters(body).join('\n');
    }
  }

  /// Process the given Dartdoc [comment], replacing any known dartdoc
  /// directives with the associated content.
  ///
  /// Macro directives are replaced with the body of the corresponding template.
  ///
  /// Youtube and animation directives are replaced with markdown hyperlinks.
  Documentation processDartdoc(String comment, {bool includeSummary = false}) {
    List<String> lines = _stripDelimiters(comment);
    var firstBlankLine = lines.length;
    for (int i = lines.length - 1; i >= 0; i--) {
      String line = lines[i];
      if (line.isEmpty) {
        // Because we're iterating from the last line to the first, the last
        // blank line we find is the first.
        firstBlankLine = i;
      } else {
        var match = macroRegExp.firstMatch(line);
        if (match != null) {
          var name = match.group(1)!;
          var value = templateMap[name];
          if (value != null) {
            lines[i] = value;
          }
          continue;
        }

        match = videoRegExp.firstMatch(line);
        if (match != null) {
          var uri = match.group(2);
          if (uri != null && uri.isNotEmpty) {
            String label = uri;
            if (label.startsWith('https://')) {
              label = label.substring('https://'.length);
            }
            lines[i] = '[$label]($uri)';
          }
          continue;
        }
      }
    }
    if (includeSummary) {
      var full = lines.join('\n');
      var summary = firstBlankLine == lines.length
          ? full
          : lines.getRange(0, firstBlankLine).join('\n').trim();
      return DocumentationWithSummary(full: full, summary: summary);
    }
    return Documentation(full: lines.join('\n'));
  }

  bool _isWhitespace(String comment, int index, bool includeEol) {
    if (comment.startsWith(' ', index) ||
        comment.startsWith('\t', index) ||
        (includeEol && comment.startsWith('\n', index))) {
      return true;
    }
    return false;
  }

  int _nextAtEndtemplate(String comment, int offset) {
    int end = comment.length;
    while (true) {
      for (; offset < end; offset++) {
        if (comment.codeUnitAt(offset) == $OPEN_CURLY_BRACKET) break;
      }
      if (offset + 13 >= end) return -1;
      if (comment.codeUnitAt(++offset) != $AT) continue;
      if (comment.codeUnitAt(++offset) != $e) continue;
      if (comment.codeUnitAt(++offset) != $n) continue;
      if (comment.codeUnitAt(++offset) != $d) continue;
      if (comment.codeUnitAt(++offset) != $t) continue;
      if (comment.codeUnitAt(++offset) != $e) continue;
      if (comment.codeUnitAt(++offset) != $m) continue;
      if (comment.codeUnitAt(++offset) != $p) continue;
      if (comment.codeUnitAt(++offset) != $l) continue;
      if (comment.codeUnitAt(++offset) != $a) continue;
      if (comment.codeUnitAt(++offset) != $t) continue;
      if (comment.codeUnitAt(++offset) != $e) continue;
      if (comment.codeUnitAt(++offset) != $CLOSE_CURLY_BRACKET) continue;
      return offset + 1;
    }
  }

  int _nextAtTemplate(String comment, int offset) {
    int end = comment.length;
    while (true) {
      for (; offset < end; offset++) {
        if (comment.codeUnitAt(offset) == $OPEN_CURLY_BRACKET) break;
      }
      if (offset + 9 >= end) return -1;
      if (comment.codeUnitAt(++offset) != $AT) continue;
      if (comment.codeUnitAt(++offset) != $t) continue;
      if (comment.codeUnitAt(++offset) != $e) continue;
      if (comment.codeUnitAt(++offset) != $m) continue;
      if (comment.codeUnitAt(++offset) != $p) continue;
      if (comment.codeUnitAt(++offset) != $l) continue;
      if (comment.codeUnitAt(++offset) != $a) continue;
      if (comment.codeUnitAt(++offset) != $t) continue;
      if (comment.codeUnitAt(++offset) != $e) continue;
      return offset + 1;
    }
  }

  int _skipWhitespaceBackward(
    String comment,
    int start,
    int end, [
    bool skipEol = false,
  ]) {
    while (start < end && _isWhitespace(comment, end, skipEol)) {
      end--;
    }
    return end;
  }

  int _skipWhitespaceForward(
    String comment,
    int start,
    int end, [
    bool skipEol = false,
  ]) {
    while (start < end && _isWhitespace(comment, start, skipEol)) {
      start++;
    }
    return start;
  }

  /// Remove the delimiters from the given [comment].
  List<String> _stripDelimiters(String comment) {
    var start = 0;
    var end = comment.length;
    if (comment.startsWith('/**')) {
      start = _skipWhitespaceForward(comment, 3, end, true);
      if (comment.endsWith('*/')) {
        end = _skipWhitespaceBackward(comment, start, end - 2, true);
      }
    }
    var line = -1;
    var firstNonEmpty = -1;
    var lastNonEmpty = -1;
    var lines = <String>[];
    while (start < end) {
      line++;
      var eolIndex = comment.indexOf('\n', start);
      if (eolIndex < 0) {
        eolIndex = end;
      }
      var lineStart = _skipWhitespaceForward(comment, start, eolIndex);
      if (comment.startsWith('///', lineStart)) {
        lineStart += 3;
        if (_isWhitespace(comment, lineStart, false)) {
          lineStart++;
        }
      } else if (comment.startsWith('*', lineStart)) {
        lineStart += 1;
        if (_isWhitespace(comment, lineStart, false)) {
          lineStart++;
        }
      }
      var lineEnd =
          _skipWhitespaceBackward(comment, lineStart, eolIndex - 1) + 1;
      if (lineStart < lineEnd) {
        // If the line is not empty, update the line range.
        if (firstNonEmpty < 0) {
          firstNonEmpty = line;
        }
        if (line > lastNonEmpty) {
          lastNonEmpty = line;
        }
        lines.add(comment.substring(lineStart, lineEnd));
      } else {
        lines.add('');
      }
      start = eolIndex + 1;
    }
    if (firstNonEmpty < 0 || lastNonEmpty < firstNonEmpty) {
      // All of the lines are empty.
      return const <String>[];
    }
    return lines.sublist(firstNonEmpty, lastNonEmpty + 1);
  }

  static DartdocDirectiveInfo extractFromUnit(CompilationUnit unit) {
    var result = DartdocDirectiveInfo();

    for (var directive in unit.directives) {
      var comment = directive.documentationComment;
      var rawText = getCommentNodeRawText(comment);
      result.extractTemplate(rawText);
    }

    for (var declaration in unit.declarations) {
      var comment = declaration.documentationComment;
      var rawText = getCommentNodeRawText(comment);
      result.extractTemplate(rawText);

      var members = switch (declaration) {
        ClassDeclaration() => declaration.body.members,
        EnumDeclaration() => [
          ...declaration.body.constants,
          ...declaration.body.members,
        ],
        MixinDeclaration() => declaration.body.members,
        ExtensionDeclaration() => declaration.body.members,
        ExtensionTypeDeclaration() => declaration.body.members,
        _ => null,
      };

      if (members != null) {
        for (var member in members) {
          var comment = member.documentationComment;
          var rawText = getCommentNodeRawText(comment);
          result.extractTemplate(rawText);
        }
      }
    }

    return result;
  }
}

/// A representation of the documentation for an element.
class Documentation {
  String full;

  Documentation({required this.full});
}

/// A representation of the documentation for an element that includes a
/// summary.
class DocumentationWithSummary extends Documentation {
  final String summary;

  DocumentationWithSummary({required super.full, required this.summary});
}
