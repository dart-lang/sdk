// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/doc_comment.dart';

/// Compares to URI strings for a directive to produce the desired sort order.
///
/// Should keep these in sync! Copied from
/// https://github.com/dart-lang/linter/blob/658f497eef/lib/src/rules/directives_ordering.dart#L380-L387
/// Consider finding a way to share this code!
int compareDirectiveUri(String a, String b) {
  if (!a.startsWith('package:') || !b.startsWith('package:')) {
    if (!a.startsWith('/') && !b.startsWith('/')) {
      return a.compareTo(b);
    }
  }
  var indexA = a.indexOf('/');
  var indexB = b.indexOf('/');
  if (indexA == -1 || indexB == -1) return a.compareTo(b);
  var result = a.substring(0, indexA).compareTo(b.substring(0, indexB));
  if (result != 0) return result;
  return a.substring(indexA + 1).compareTo(b.substring(indexB + 1));
}

/// Returns the leading `///` or `*` marker of [lineText] (including any
/// leading whitespace and a single trailing space, if present), for use in
/// constructing new lines, or a blank separator line, in the same style.
///
/// Returns `'/// '` if [lineText] doesn't start with either marker.
String docCommentLinePrefix(String lineText) {
  var match = RegExp(r'^\s*(?:///|\*)\s?').firstMatch(lineText);
  return match?.group(0) ?? '/// ';
}

/// Returns the individual lines that make up [docComment], reading the text
/// from [code].
///
/// For a doc comment made up of `///` tokens, each token is already exactly
/// one line. For a `/** ... */` block doc comment, [Comment.tokens] contains
/// a single token spanning every line, so it is split here into one
/// [DocCommentLine] per physical line.
List<DocCommentLine> docCommentLines(Comment docComment, String code) {
  var tokens = docComment.tokens;
  if (tokens.length == 1 && !tokens.single.lexeme.startsWith('///')) {
    var token = tokens.single;
    var lines = <DocCommentLine>[];
    var lineStart = token.offset;
    for (var i = token.offset; i < token.end; i++) {
      if (code.codeUnitAt(i) == 0x0A) {
        var lineEnd = i;
        if (lineEnd > lineStart && code.codeUnitAt(lineEnd - 1) == 0x0D) {
          lineEnd--;
        }
        lines.add(DocCommentLine(lineStart, lineEnd));
        lineStart = i + 1;
      }
    }
    lines.add(DocCommentLine(lineStart, token.end));
    return lines;
  }
  return [for (var token in tokens) DocCommentLine(token.offset, token.end)];
}

/// Whether [text] is a blank comment line, that is, a `///` or `*` marker
/// with no other content.
bool isBlankCommentLine(String text) {
  var trimmed = text.trim();
  return trimmed == '///' || trimmed == '*';
}

/// Maps each of [docComment]'s `@docImport` directives to the [DocCommentLine]
/// that contains it, in file order.
///
/// Used to locate where an existing `@docImport` directive sits within a
/// doc comment so it can be reordered or used as an insertion point for a
/// new `@docImport` directive.
Map<DocCommentLine, DocImport> mapDocImportsToLines(
  Comment docComment,
  String code,
) {
  var docImports = docComment.docImports;
  var docImportByLine = <DocCommentLine, DocImport>{};
  var docImportIndex = 0;
  for (var line in docCommentLines(docComment, code)) {
    if (docImportIndex >= docImports.length) {
      break;
    }
    var docImport = docImports[docImportIndex];
    if (docImport.offset >= line.offset && docImport.offset < line.end) {
      docImportByLine[line] = docImport;
      docImportIndex++;
    }
  }
  return docImportByLine;
}

/// The kind of directive for sorting purposes.
enum DirectiveSortKind { import, export, part }

/// The priority used for grouping directives when sorting.
class DirectiveSortPriority {
  static const IMPORT_SDK = DirectiveSortPriority._('IMPORT_SDK', 0);
  static const IMPORT_PKG = DirectiveSortPriority._('IMPORT_PKG', 1);
  static const IMPORT_OTHER = DirectiveSortPriority._('IMPORT_OTHER', 2);
  static const IMPORT_REL = DirectiveSortPriority._('IMPORT_REL', 3);
  static const EXPORT_SDK = DirectiveSortPriority._('EXPORT_SDK', 4);
  static const EXPORT_PKG = DirectiveSortPriority._('EXPORT_PKG', 5);
  static const EXPORT_OTHER = DirectiveSortPriority._('EXPORT_OTHER', 6);
  static const EXPORT_REL = DirectiveSortPriority._('EXPORT_REL', 7);
  static const PART = DirectiveSortPriority._('PART', 8);

  final String name;
  final int ordinal;

  factory DirectiveSortPriority(String uri, DirectiveSortKind kind) {
    switch (kind) {
      case DirectiveSortKind.import:
        if (uri.startsWith('dart:')) {
          return DirectiveSortPriority.IMPORT_SDK;
        } else if (uri.startsWith('package:')) {
          return DirectiveSortPriority.IMPORT_PKG;
        } else if (uri.contains('://')) {
          return DirectiveSortPriority.IMPORT_OTHER;
        } else {
          return DirectiveSortPriority.IMPORT_REL;
        }
      case DirectiveSortKind.export:
        if (uri.startsWith('dart:')) {
          return DirectiveSortPriority.EXPORT_SDK;
        } else if (uri.startsWith('package:')) {
          return DirectiveSortPriority.EXPORT_PKG;
        } else if (uri.contains('://')) {
          return DirectiveSortPriority.EXPORT_OTHER;
        } else {
          return DirectiveSortPriority.EXPORT_REL;
        }
      case DirectiveSortKind.part:
        return DirectiveSortPriority.PART;
    }
  }

  const DirectiveSortPriority._(this.name, this.ordinal);

  @override
  String toString() => name;
}

/// A single physical line within a documentation comment.
///
/// Used as the unit for locating and reordering individual `@docImport`
/// directives, regardless of whether the enclosing doc comment is made up of
/// `///` line-comment tokens (one line per token, as reported by
/// [Comment.tokens]) or is a single `/** ... */` block-comment token, which
/// must be split into individual physical lines.
final class DocCommentLine {
  /// The offset of the start of this line (not including any preceding line
  /// terminator).
  final int offset;

  /// The offset just past the end of this line (not including its line
  /// terminator, if any).
  final int end;

  const DocCommentLine(this.offset, this.end);

  @override
  int get hashCode => Object.hash(offset, end);

  @override
  bool operator ==(Object other) =>
      other is DocCommentLine && other.offset == offset && other.end == end;
}
