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
///
/// Arguments are separated from the directive name, and from each other, by
/// whitespace. There are two types of arguments: positional and named. Named
/// arguments are written as `NAME=VALUE`, without any internal whitespace.
/// Named arguments can be optional.
@experimental
final class DocDirective {
  /// The offset of the starting text, '@docImport'.
  final int offset;
  final int end;
  final int nameOffset;
  final int nameEnd;

  final DocDirectiveType type;

  final List<DocDirectiveArgument> positionalArguments;
  final List<DocDirectiveNamedArgument> namedArguments;

  DocDirective({
    required this.offset,
    required this.end,
    required this.nameOffset,
    required this.nameEnd,
    required this.type,
    required this.positionalArguments,
    required this.namedArguments,
  });
}

/// An argument in a doc directive. See [DocDirective] for their syntax.
@experimental
sealed class DocDirectiveArgument {
  /// The offset of the start of the argument, from the beginning of the
  /// compilation unit.
  final int offset;

  /// The offset just after the end of the argument, from the beginning of the
  /// compilation unit.
  final int end;

  /// The value of the argument.
  final String value;

  DocDirectiveArgument({
    required this.offset,
    required this.end,
    required this.value,
  });
}

/// A named argument in a doc directive. See [DocDirective] for their syntax.
@experimental
final class DocDirectiveNamedArgument extends DocDirectiveArgument {
  /// The name of the argument.
  final String name;

  DocDirectiveNamedArgument({
    required super.offset,
    required super.end,
    required this.name,
    required super.value,
  });
}

/// A positional argument in a doc directive. See [DocDirective] for their
/// syntax.
@experimental
final class DocDirectivePositionalArgument extends DocDirectiveArgument {
  DocDirectivePositionalArgument({
    required super.offset,
    required super.end,
    required super.value,
  });
}

@experimental
enum DocDirectiveType {
  /// A [DocDirective] declaring an embedded video with HTML video controls.
  ///
  /// This directive has three required arguments: the width, the height, and
  /// the URL. A named 'id' argument can also be given. For example:
  ///
  /// `{@animation 600 400 https://www.example.com/example.mp4 id=video1}`
  ///
  /// See documentation at
  /// https://github.com/dart-lang/dartdoc/wiki/Doc-comment-directives#animations.
  animation(
    'animation',
    positionalParameters: ['width', 'height', 'url'],
    namedParameters: ['id'],
  ),

  /// A [DocDirective] declaring the associated library is the "canonical"
  /// location for a certain element.
  ///
  /// Dartdoc uses some heuristics to decide what the public-facing libraries
  /// are, and which public-facing library is the "canonical" location for an
  /// element. When that heuristic needs to be overridden, a user can use this
  /// directive. Example:
  ///
  /// `{@canonicalFor some_library.SomeClass}`
  ///
  /// See documentation at
  /// https://github.com/dart-lang/dartdoc/wiki/Doc-comment-directives#canonicalization.
  canonicalFor(
    // TODO(srawlins): We have mostly used 'kebab-case' in directive names. This
    // directive name is a rare departure from that style. Migrate users to use
    // 'canonical-for'.
    'canonicalFor',
    positionalParameters: ['element'],
  ),

  /// A [DocDirective] declaring a categorization into a named category.
  ///
  /// This directive has one required argument: the category name. The category
  /// name is allowed to contain whitespace.
  // TODO(srawlins): I think allowing a category name, which is parsed as
  // multiple positional arguments (or I guess named arguments if one contains)
  // an equal sign!) is too loosy-goosey. We should just support quoting and
  // require that a category name with spaces be wrapped in quotes.
  ///
  /// See documentation at
  /// https://github.com/dart-lang/dartdoc/wiki/Doc-comment-directives#categories.
  category(
    'category',
    restParametersAllowed: true,
  ),

  /// A [DocDirective] declaring an example file.
  ///
  /// This directive has one required argument: the path. A named 'region'
  /// argument, and a named 'lang' argument can also be given. For example:
  ///
  /// `{@example abc/def/xyz_component.dart region=template lang=html}`
  ///
  /// See documentation at
  /// https://github.com/dart-lang/dartdoc/wiki/Doc-comment-directives#examples.
  example(
    'example',
    positionalParameters: ['path'],
    namedParameters: ['region', 'lang'],
  ),

  /// A [DocDirective] declaring amacro application.
  ///
  /// This directive has one required argument: the name. For example:
  ///
  /// `{@macro some-macro}`
  macro('macro', positionalParameters: ['name']),

  /// A [DocDirective] declaring a categorization into a named sub-category.
  ///
  /// This directive has one required argument: the sub-category name. The
  /// sub-category name is allowed to contain whitespace.
  ///
  /// See documentation at
  /// https://github.com/dart-lang/dartdoc/wiki/Doc-comment-directives#categories.
  subCategory(
    // TODO(srawlins): We have mostly used 'kebab-case' in directive names. This
    // directive name is the sole departure from that style. Migrate users to
    // use 'sub-category'.
    'subCategory',
    restParametersAllowed: true,
  ),

  /// A [DocDirective] declaring an embedded YouTube video.
  ///
  /// This directive has three required arguments: the width, the height, and
  /// the URL. For example:
  ///
  /// `{@youtube 600 400 https://www.youtube.com/watch?v=abc123}`
  ///
  /// See documentation at
  /// https://github.com/dart-lang/dartdoc/wiki/Doc-comment-directives#youtube-videos.
  youtube('youtube', positionalParameters: ['width', 'height', 'url']);

  /// The name of the directive, as written in a doc comment.
  final String name;

  /// The positional parameter names, which are each required.
  final List<String> positionalParameters;

  /// The named parameter names, which are each optional.
  final List<String> namedParameters;

  /// Whether "rest" parameters are allowed.
  ///
  /// In such a doc directive type, we do not enforce a maximum number of
  /// arguments.
  final bool restParametersAllowed;

  const DocDirectiveType(
    this.name, {
    this.positionalParameters = const <String>[],
    this.namedParameters = const <String>[],
    this.restParametersAllowed = false,
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
