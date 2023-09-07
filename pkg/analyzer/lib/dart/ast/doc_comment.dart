// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Various classes for data computed for doc comments.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:meta/meta.dart';

/// A documentation directive, found in a doc comment.
///
/// Documentation directives are declared with `{@` at the start of a line of a
/// documentation comment, followed the name of a doc directive, arguments, and
/// finally a right curly brace (`}`).
@experimental
sealed class DocDirective {
  /// The offset of the starting text, '@docImport'.
  final int offset;
  final int end;
  final int nameOffset;
  final int nameEnd;

  DocDirective({
    required this.offset,
    required this.end,
    required this.nameOffset,
    required this.nameEnd,
  });
}

/// A documentation import, found in a doc comment.
///
/// Documentation imports are declared with `@docImport` at the start of a line
/// of a documentation comment, followed by regular import elements (URI,
/// optional prefix, optional combinators), ending with a semicolon.
@experimental
final class DocImport {
  /// The offset of the starting text, '@docImport'.
  int offset;

  ImportDirective import;

  DocImport({required this.offset, required this.import});
}

/// A Markdown fenced code block found in a documentation comment.
@experimental
final class MdCodeBlock {
  /// The 'info string'.
  ///
  /// This includes any text (trimming whitespace) following the opening
  /// backticks (for a fenced code block). For example, in a fenced code block
  /// starting with "```dart", the info string is "dart".
  ///
  /// If the code block is an indented code block, or a fenced code block with
  /// no text following the opening backticks, the info string is `null`.
  ///
  /// See CommonMark specification at
  /// <https://spec.commonmark.org/0.30/#fenced-code-blocks>.
  final String? infoString;

  /// Information about the comment lines that make up this code block.
  ///
  /// For a fenced code block, these lines include the opening and closing
  /// fence delimiter lines.
  final List<MdCodeBlockLine> lines;

  MdCodeBlock({
    required this.infoString,
    required List<MdCodeBlockLine> lines,
  }) : lines = List.of(lines, growable: false);
}

/// A Markdown code block line found in a documentation comment.
@experimental
final class MdCodeBlockLine {
  /// The offset of the start of the code block, from the beginning of the
  /// compilation unit.
  final int offset;

  /// The length of the fenced code block.
  final int length;

  MdCodeBlockLine({required this.offset, required this.length});
}

/// A [DocDirective] declaring an embedded YouTube video.
///
/// This directive has three required arguments: the width, the height, and the
/// URL. For example:
///
/// `{@youtube 600 400 https://www.youtube.com/watch?v=abc123}`
@experimental
final class YouTubeDocDirective extends DocDirective {
  final int? widthOffset;
  final int? widthEnd;
  final int? heightOffset;
  final int? heightEnd;
  final int? urlOffset;
  final int? urlEnd;

  YouTubeDocDirective({
    required super.offset,
    required super.end,
    required super.nameOffset,
    required super.nameEnd,
    required this.widthOffset,
    required this.widthEnd,
    required this.heightOffset,
    required this.heightEnd,
    required this.urlOffset,
    required this.urlEnd,
  });
}
