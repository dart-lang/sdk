// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/annotation_target.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError, Element;
import 'package:analyzer_plugin/src/utilities/directive_sort.dart';
import 'package:meta/meta_meta.dart';

/// Organizes imports (and other directives) in the [unit].
class ImportOrganizer {
  final String initialCode;

  final CompilationUnit unit;

  final List<Diagnostic> diagnostics;

  final bool removeUnused;

  String code;

  String endOfLine = '\n';

  bool hasUnresolvedIdentifierError = false;

  new(this.initialCode, this.unit, this.diagnostics, {this.removeUnused = true})
    : code = initialCode {
    endOfLine = getEOL(code);
    hasUnresolvedIdentifierError = diagnostics.any(
      (d) => d.diagnosticCode.isUnresolvedIdentifier,
    );
  }

  /// Return the [SourceEdit]s that organize imports in the [unit].
  List<SourceEdit> organize() {
    _organizeDirectives();
    // prepare edits
    var edits = <SourceEdit>[];
    if (code != initialCode) {
      var suffixLength = findCommonSuffix(initialCode, code);
      var edit = SourceEdit(
        0,
        initialCode.length - suffixLength,
        code.substring(0, code.length - suffixLength),
      );
      edits.add(edit);
    }
    return edits;
  }

  bool _isUnusedImport(UriBasedDirective directive) {
    for (var diagnostic in diagnostics) {
      if ((diagnostic.diagnosticCode == diag.duplicateImport ||
              diagnostic.diagnosticCode == diag.unusedImport ||
              diagnostic.diagnosticCode == diag.unnecessaryImport) &&
          directive.uri.offset == diagnostic.offset) {
        return true;
      }
    }
    return false;
  }

  bool _isUnusedShowName(SimpleIdentifier name) {
    for (var diagnostic in diagnostics) {
      if ((diagnostic.diagnosticCode == diag.unusedShownName) &&
          name.offset == diagnostic.offset) {
        return true;
      }
    }
    return false;
  }

  /// Organize all [Directive]s.
  void _organizeDirectives() {
    var lineInfo = unit.lineInfo;
    LibraryDirective? libraryDirective;
    var directives = <_DirectiveInfo>[];
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        libraryDirective = directive;
      }
      if (directive is UriBasedDirective) {
        // Track the end offset of any library-level comment/annotations that should
        // remain at the top of the file regardless of whether it was attached to a
        // directive that's moved/removed.
        // Code up to this offset will be excluded from the comment/docs/annotation
        // text for the computed DirectiveInfo and also its range for replacement
        // in the document.
        int? libraryDocsAndAnnotationsEndOffset;
        var uriContent = directive.uri.stringValue ?? '';
        var priority = switch (directive) {
          ImportDirective() => DirectiveSortPriority(
            uriContent,
            DirectiveSortKind.import,
          ),
          ExportDirective() => DirectiveSortPriority(
            uriContent,
            DirectiveSortKind.export,
          ),
          PartDirective() => DirectiveSortPriority(
            uriContent,
            DirectiveSortKind.part,
          ),
        };

        var offset = directive.offset;
        var end = directive.end;

        var isPseudoLibraryDirective =
            (libraryDirective == null) && directive == unit.directives.first;
        Annotation? lastLibraryAnnotation;
        if (isPseudoLibraryDirective) {
          // Find the last library-level annotation that does not come
          // after any non-library annotation. If there are already
          // non-library annotations before library annotations, we will not
          // try to correct those.
          lastLibraryAnnotation = directive.metadata
              .takeWhile(_isLibraryTargetAnnotation)
              .lastOrNull;

          // If there is no annotation, use the end of the doc text (since the
          // doc text is considered library-level here).
          libraryDocsAndAnnotationsEndOffset =
              lastLibraryAnnotation?.end ?? directive.documentationComment?.end;

          // Fix up the offset to be after the line end.
          if (libraryDocsAndAnnotationsEndOffset != null) {
            libraryDocsAndAnnotationsEndOffset = lineInfo.getOffsetOfLineAfter(
              libraryDocsAndAnnotationsEndOffset,
            );
            // In the case of a blank line after the annotation/doc text
            // we should include that in the library part. Otherwise it will
            // be included in the top of the following directive and may
            // result in an extra blank line in the annotation block if it
            // is moved.
            var nextLineOffset = lineInfo.getOffsetOfLineAfter(
              libraryDocsAndAnnotationsEndOffset,
            );
            if (code
                .substring(libraryDocsAndAnnotationsEndOffset, nextLineOffset)
                .trim()
                .isEmpty) {
              libraryDocsAndAnnotationsEndOffset = nextLineOffset;
            }
          }
        }

        // Usually we look for leading comments on the directive. However if
        // some library annotations were trimmed off, those comments are part
        // of that and should not also be included here.
        var leadingToken = lastLibraryAnnotation == null
            ? directive.beginToken
            : null;
        var leadingComment = leadingToken != null
            ? getLeadingComment(
                unit,
                leadingToken,
                lineInfo,
                isPseudoLibraryDirective: isPseudoLibraryDirective,
              )
            : null;
        var trailingComment = getTrailingComment(unit, directive, lineInfo);

        if (leadingComment != null && leadingToken != null) {
          offset = libraryDocsAndAnnotationsEndOffset != null
              ? math.max(
                  libraryDocsAndAnnotationsEndOffset,
                  leadingComment.offset,
                )
              : leadingComment.offset;
        }
        if (trailingComment != null) {
          end = trailingComment.end;
        }
        offset = libraryDocsAndAnnotationsEndOffset ?? offset;
        var text = code.substring(offset, end);
        directives.add(
          _DirectiveInfo(directive, priority, uriContent, offset, end, text),
        );
      }
    }
    _organizeDocImports(libraryDirective);

    // nothing to do
    if (directives.isEmpty) {
      return;
    }
    var firstDirectiveOffset = directives.first.offset;
    var lastDirectiveEnd = directives.last.end;

    // sort
    directives.sort();
    // append directives with grouping
    String directivesCode;
    {
      var sb = StringBuffer();
      DirectiveSortPriority? currentPriority;
      var previousDirectiveText = '';
      var showCombinators = <ImportDirective, List<SimpleIdentifier>>{};
      for (var directiveInfo in directives) {
        if (!hasUnresolvedIdentifierError) {
          var directive = directiveInfo.directive;
          if (removeUnused && _isUnusedImport(directive) ||
              (removeUnused && previousDirectiveText == directiveInfo.text)) {
            continue;
          }
          if (directive is ImportDirective) {
            var combinators = directive.combinators;
            if (combinators.isNotEmpty) {
              var shownNames = combinators
                  .whereType<ShowCombinator>()
                  .map((combinator) => combinator.shownNames)
                  .expand((names) => names);
              var list = shownNames.where(_isUnusedShowName).toList();
              showCombinators[directive] = list;
            }
          }
        }
        if (currentPriority != directiveInfo.priority) {
          if (currentPriority != null) {
            sb.write(endOfLine);
          }
          currentPriority = directiveInfo.priority;
        }
        var text = directiveInfo.text;
        if (showCombinators.containsKey(directiveInfo.directive)) {
          var showCombinatorList = showCombinators[directiveInfo.directive]!;
          var showOffset = text.indexOf('show');
          for (var name in showCombinatorList) {
            if (text.contains('${name.name},')) {
              text = text.replaceFirst('${name.name}, ', '', showOffset);
            } else if (text.contains(', ${name.name}')) {
              text = text.replaceFirst(', ${name.name}', '', showOffset);
            }
          }
        }
        sb.write(text);
        sb.write(endOfLine);
        previousDirectiveText = text;
      }
      directivesCode = sb.toString();
      directivesCode = directivesCode.trimRight();
    }
    // prepare code
    var beforeDirectives = code.substring(0, firstDirectiveOffset);
    var afterDirectives = code.substring(lastDirectiveEnd);
    code = beforeDirectives + directivesCode + afterDirectives;
  }

  /// Sorts the `@docImport` directives in the documentation comment of
  /// [libraryDirective], if any.
  void _organizeDocImports(LibraryDirective? libraryDirective) {
    var docComment = libraryDirective?.documentationComment;
    if (docComment == null) {
      return;
    }
    var docImports = docComment.docImports;
    if (docImports.isEmpty) {
      return;
    }

    var lines = docCommentLines(docComment, code);
    var docImportByLine = mapDocImportsToLines(docComment, code);

    var isBlockComment =
        docComment.tokens.length == 1 &&
        !docComment.tokens.single.lexeme.startsWith('///');
    if (isBlockComment) {
      _organizeDocImportsInBlockComment(docComment, lines, docImportByLine);
      return;
    }

    var sortedInfos = [
      for (var entry in docImportByLine.entries)
        _DocImportInfo(
          entry.value,
          code.substring(entry.key.offset, entry.key.end),
        ),
    ]..sort();

    // A blank comment line separates groups of `@docImport` directives with
    // different sort priorities, just like blank lines separate groups of
    // regular imports.
    var blankLine = docCommentLinePrefix(sortedInfos.first.text).trimRight();
    var sortedTexts = <String>[];
    DirectiveSortPriority? previousPriority;
    for (var info in sortedInfos) {
      if (previousPriority != null && previousPriority != info.priority) {
        sortedTexts.add(blankLine);
      }
      sortedTexts.add(info.text);
      previousPriority = info.priority;
    }

    // Comment lines that don't contain an `@docImport` keep their relative
    // order, but the sorted `@docImport` lines are grouped together and
    // moved to sit where the first `@docImport` line originally was. Blank
    // lines between `@docImport` lines are dropped, since grouping already
    // inserts the blank lines needed to separate priority groups.
    var firstDocImportIndex = lines.indexWhere(docImportByLine.containsKey);
    var lastDocImportIndex = lines.lastIndexWhere(docImportByLine.containsKey);
    bool isBlankLineBetweenDocImports(int index) =>
        index > firstDocImportIndex &&
        index < lastDocImportIndex &&
        isBlankCommentLine(
          code.substring(lines[index].offset, lines[index].end),
        );
    var otherTexts = [
      for (var i = 0; i < lines.length; i++)
        if (!docImportByLine.containsKey(lines[i]) &&
            !isBlankLineBetweenDocImports(i))
          code.substring(lines[i].offset, lines[i].end),
    ];
    var otherTextsBeforeFirstDocImport = lines
        .take(firstDocImportIndex)
        .where((line) => !docImportByLine.containsKey(line))
        .length;

    var newTexts = [
      ...otherTexts.take(otherTextsBeforeFirstDocImport),
      ...sortedTexts,
      ...otherTexts.skip(otherTextsBeforeFirstDocImport),
    ];

    var eol = getEOL(code);
    code =
        code.substring(0, docComment.offset) +
        newTexts.join(eol) +
        code.substring(docComment.end);
  }

  /// Sorts the `@docImport` directives in [docComment], a single `/** ... */`
  /// block doc comment.
  ///
  /// Unlike a `///`-style doc comment, a block comment's opening `/**` and
  /// closing `*/` markers may share a physical line with real content (for
  /// example `/** @docImport 'a.dart'; */`), so lines can't just be moved
  /// around as-is the way [_organizeDocImports] does for `///` comments.
  /// Instead, each line's content is extracted without its `/**`, `*`, or
  /// `*/` marker, reordered, and then re-marked, with the closing `*/`
  /// always placed on its own trailing line.
  void _organizeDocImportsInBlockComment(
    Comment docComment,
    List<DocCommentLine> lines,
    Map<DocCommentLine, DocImport> docImportByLine,
  ) {
    // Returns the content of [line], with its `/**`, `*`, and/or `*/`
    // marker(s) removed.
    String rawContent(DocCommentLine line) {
      var text = code.substring(line.offset, line.end);
      if (line == lines.last) {
        text = text.replaceFirst(RegExp(r'\s*\*/$'), '');
      }
      if (line == lines.first) {
        text = text.replaceFirst(RegExp(r'^/\*\*\s?'), '');
      } else {
        text = text.replaceFirst(RegExp(r'^\s*\*\s?'), '');
      }
      return text;
    }

    var sortedInfos = [
      for (var entry in docImportByLine.entries)
        _DocImportInfo(entry.value, rawContent(entry.key)),
    ]..sort();

    // A blank comment line separates groups of `@docImport` directives with
    // different sort priorities, just like blank lines separate groups of
    // regular imports. An empty string stands in for a blank line here; it
    // is formatted along with every other line below.
    var sortedContents = <String>[];
    DirectiveSortPriority? previousPriority;
    for (var info in sortedInfos) {
      if (previousPriority != null && previousPriority != info.priority) {
        sortedContents.add('');
      }
      sortedContents.add(info.text);
      previousPriority = info.priority;
    }

    // Comment lines that don't contain an `@docImport` keep their relative
    // order, but the sorted `@docImport` lines are grouped together and
    // moved to sit where the first `@docImport` line originally was. Blank
    // lines between `@docImport` lines are dropped, since grouping already
    // inserts the blank lines needed to separate priority groups.
    var firstDocImportIndex = lines.indexWhere(docImportByLine.containsKey);
    var lastDocImportIndex = lines.lastIndexWhere(docImportByLine.containsKey);
    bool isBlankLineBetweenDocImports(int index) =>
        index > firstDocImportIndex &&
        index < lastDocImportIndex &&
        isBlankCommentLine(
          code.substring(lines[index].offset, lines[index].end),
        );
    var otherContents = [
      for (var i = 0; i < lines.length; i++)
        if (!docImportByLine.containsKey(lines[i]) &&
            !isBlankLineBetweenDocImports(i) &&
            // The closing `*/` is always re-added on its own line below, so
            // a last line that contained nothing but that marker doesn't
            // need a placeholder line of its own here.
            !(lines[i] == lines.last && rawContent(lines[i]).isEmpty))
          rawContent(lines[i]),
    ];
    var otherContentsBeforeFirstDocImport = lines
        .take(firstDocImportIndex)
        .where((line) => !docImportByLine.containsKey(line))
        .length;

    var newContents = [
      ...otherContents.take(otherContentsBeforeFirstDocImport),
      ...sortedContents,
      ...otherContents.skip(otherContentsBeforeFirstDocImport),
    ];

    var newLines = [
      for (var (index, content) in newContents.indexed)
        if (index == 0)
          content.isEmpty ? '/**' : '/** $content'
        else
          content.isEmpty ? ' *' : ' * $content',
      ' */',
    ];

    var eol = getEOL(code);
    code =
        code.substring(0, docComment.offset) +
        newLines.join(eol) +
        code.substring(docComment.end);
  }

  /// Return the EOL to use for [code].
  static String getEOL(String code) {
    if (code.contains('\r\n')) {
      return '\r\n';
    } else {
      return '\n';
    }
  }

  /// Gets the first comment token considered to be the leading comment for this
  /// token.
  ///
  /// Leading comments for the first directive in a file with no library
  /// directive (indicated with [isPseudoLibraryDirective]) are considered
  /// library comments and not included unless they contain blank lines, in
  /// which case only the last part of the comment will be returned (unless it
  /// is a language directive comment, in which case it will also be skipped),
  /// or an '// ignore:' comment which should always be treated as attached to
  /// the import.
  static Token? getLeadingComment(
    CompilationUnit unit,
    Token beginToken,
    LineInfo lineInfo, {
    required bool isPseudoLibraryDirective,
  }) {
    if (beginToken.precedingComments == null) {
      return null;
    }

    Token? firstComment = beginToken.precedingComments;
    var comment = firstComment;
    var nextComment = comment?.next;
    // Don't connect comments that have a blank line between them if this is
    // a pseudo-library directive.
    while (isPseudoLibraryDirective && comment != null && nextComment != null) {
      if (lineInfo.lineNumberDifference(comment.offset, nextComment.offset) >
          1) {
        firstComment = nextComment;
      }
      comment = nextComment;
      nextComment = comment.next;
    }

    // Language version tokens should never be attached so skip over.
    if (firstComment is LanguageVersionToken) {
      firstComment = firstComment.next;
    }

    // If the comment is the first comment in the document then whether we
    // consider it the leading comment depends on whether it's an ignore comment
    // or not.
    if (firstComment != null &&
        firstComment == unit.beginToken.precedingComments) {
      return _isIgnoreComment(firstComment) ? firstComment : null;
    }

    // Skip over any comments on the same line as the previous directive
    // as they will be attached to the end of it.
    comment = firstComment;
    // For first directive, do not attach comment if there is a line break
    // between comment and directive.
    if (isPseudoLibraryDirective && comment != null) {
      if (lineInfo.lineNumberDifference(beginToken.offset, comment.offset) ==
          -1) {
        return comment;
      } else {
        return null;
      }
    }
    while (comment != null &&
        lineInfo.onSameLine(beginToken.previous!.end, comment.offset)) {
      comment = comment.next;
    }
    return comment;
  }

  /// Gets the last comment token considered to be the trailing comment for this
  /// directive.
  ///
  /// To be considered a trailing comment, the comment must be on the same line
  /// as the directive.
  static Token? getTrailingComment(
    CompilationUnit unit,
    UriBasedDirective directive,
    LineInfo lineInfo,
  ) {
    Token? comment = directive.endToken.next!.precedingComments;
    while (comment != null) {
      if (lineInfo.onSameLine(comment.offset, directive.end)) {
        return comment;
      }
      comment = comment.next;
    }
    return null;
  }

  /// Returns whether this token is a '// ignore:' comment (but not an
  /// '// ignore_for_file:' comment).
  static bool _isIgnoreComment(Token token) =>
      IgnoreInfo.isIgnoreComment(token.lexeme);

  static bool _isLibraryTargetAnnotation(Annotation annotation) =>
      annotation.elementAnnotation?.targetKinds?.contains(TargetKind.library) ??
      false;
}

class _DirectiveInfo implements Comparable<_DirectiveInfo> {
  final UriBasedDirective directive;
  final DirectiveSortPriority priority;
  final String uri;

  /// The offset of the first token, usually the keyword but may include leading comments.
  final int offset;

  /// The offset after the last token, including the end-of-line comment.
  final int end;

  /// The text excluding comments, documentation and annotations.
  final String text;

  new(
    this.directive,
    this.priority,
    this.uri,
    this.offset,
    this.end,
    this.text,
  );

  @override
  int compareTo(_DirectiveInfo other) {
    if (priority == other.priority) {
      var compare = compareDirectiveUri(uri, other.uri);
      if (compare != 0) {
        return compare;
      }
      return text.compareTo(other.text);
    }
    return priority.ordinal - other.priority.ordinal;
  }

  @override
  String toString() => '(priority=$priority; text=$text)';
}

class _DocImportInfo implements Comparable<_DocImportInfo> {
  final DirectiveSortPriority priority;
  final String uri;

  /// The text of the comment line containing the `@docImport`, for example
  /// `/// @docImport 'a.dart';`.
  final String text;

  new(DocImport docImport, this.text)
    : uri = docImport.import.uri.stringValue ?? '',
      priority = DirectiveSortPriority(
        docImport.import.uri.stringValue ?? '',
        DirectiveSortKind.import,
      );

  @override
  int compareTo(_DocImportInfo other) {
    if (priority == other.priority) {
      var compare = compareDirectiveUri(uri, other.uri);
      if (compare != 0) {
        return compare;
      }
      return text.compareTo(other.text);
    }
    return priority.ordinal - other.priority.ordinal;
  }
}
