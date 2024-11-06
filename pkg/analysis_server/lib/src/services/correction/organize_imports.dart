// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError, Element;
import 'package:analyzer_plugin/src/utilities/directive_sort.dart';
import 'package:meta/meta_meta.dart';

/// Organizes imports (and other directives) in the [unit], using sorting
/// rules from [DirectiveSorter].
class ImportOrganizer {
  final String initialCode;

  final CompilationUnit unit;

  final List<AnalysisError> errors;

  final bool removeUnused;

  String code;

  String endOfLine = '\n';

  bool hasUnresolvedIdentifierError = false;

  ImportOrganizer(
    this.initialCode,
    this.unit,
    this.errors, {
    this.removeUnused = true,
  }) : code = initialCode {
    endOfLine = getEOL(code);
    hasUnresolvedIdentifierError = errors.any((error) {
      return error.errorCode.isUnresolvedIdentifier;
    });
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
    for (var error in errors) {
      if ((error.errorCode == WarningCode.DUPLICATE_IMPORT ||
              error.errorCode == WarningCode.UNUSED_IMPORT ||
              error.errorCode == HintCode.UNNECESSARY_IMPORT) &&
          directive.uri.offset == error.offset) {
        return true;
      }
    }
    return false;
  }

  bool _isUnusedShowName(SimpleIdentifier name) {
    for (var error in errors) {
      if ((error.errorCode == WarningCode.UNUSED_SHOWN_NAME) &&
          name.offset == error.offset) {
        return true;
      }
    }
    return false;
  }

  /// Organize all [Directive]s.
  void _organizeDirectives() {
    var lineInfo = unit.lineInfo;
    var hasLibraryDirective = false;
    var directives = <_DirectiveInfo>[];
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) {
        hasLibraryDirective = true;
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
            !hasLibraryDirective && directive == unit.directives.first;
        Annotation? lastLibraryAnnotation;
        if (isPseudoLibraryDirective) {
          // Find the last library-level annotation that does not come
          // after any non-library annotation. If there are already
          // non-library annotations before library annotations, we will not
          // try to correct those.
          lastLibraryAnnotation =
              directive.metadata
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
        var leadingToken =
            lastLibraryAnnotation == null ? directive.beginToken : null;
        var leadingComment =
            leadingToken != null
                ? getLeadingComment(
                  unit,
                  leadingToken,
                  lineInfo,
                  isPseudoLibraryDirective: isPseudoLibraryDirective,
                )
                : null;
        var trailingComment = getTrailingComment(unit, directive, lineInfo);

        if (leadingComment != null && leadingToken != null) {
          offset =
              libraryDocsAndAnnotationsEndOffset != null
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
      var currentLine = lineInfo.getLocation(comment.offset).lineNumber;
      var nextLine = lineInfo.getLocation(nextComment.offset).lineNumber;
      if (nextLine - currentLine > 1) {
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
    var previousDirectiveLine =
        lineInfo.getLocation(beginToken.previous!.end).lineNumber;
    comment = firstComment;
    // For first directive, do not attach comment if there is a line break
    // between comment and directive.
    if (isPseudoLibraryDirective && comment != null) {
      var directiveLine = lineInfo.getLocation(beginToken.offset).lineNumber;
      if ((directiveLine - 1) ==
          lineInfo.getLocation(comment.offset).lineNumber) {
        return comment;
      } else {
        return null;
      }
    }
    while (comment != null &&
        previousDirectiveLine ==
            lineInfo.getLocation(comment.offset).lineNumber) {
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
    var line = lineInfo.getLocation(directive.end).lineNumber;
    Token? comment = directive.endToken.next!.precedingComments;
    while (comment != null) {
      if (lineInfo.getLocation(comment.offset).lineNumber == line) {
        return comment;
      }
      comment = comment.next;
    }
    return null;
  }

  /// Returns whether this token is a '// ignore:' comment (but not an
  /// '// ignore_for_file:' comment).
  static bool _isIgnoreComment(Token token) =>
      IgnoreInfo.ignoreMatcher.matchAsPrefix(token.lexeme) != null;

  static bool _isLibraryTargetAnnotation(Annotation annotation) =>
      annotation.elementAnnotation?.targetKinds.contains(TargetKind.library) ??
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

  _DirectiveInfo(
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
