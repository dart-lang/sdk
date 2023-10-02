// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Various classes for data computed for doc comments.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:meta/meta.dart';

/// A block doc directive, denoted by an opening tag, and a closing tag.
///
/// The text in between the two tags is not explicitly called out. It can be
/// read from the original compilation unit, between the offsets of the opening
/// and closing tags.
@experimental
final class BlockDocDirective implements DocDirective {
  final DocDirectiveTag openingTag;
  final DocDirectiveTag? closingTag;

  BlockDocDirective(this.openingTag, this.closingTag);

  @override
  DocDirectiveType get type => openingTag.type;
}

/// An instance of a [DocDirectiveType] in the text of a doc comment, either
/// as a [SimpleDocDirective], represented by a single [DocDirectiveTag], or a
/// [BlockDocDirective], represented by an opening [DocDirectiveTag] and a
/// closing one (in well-formed text).
@experimental
sealed class DocDirective {
  DocDirectiveType get type;
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

/// A parameter in a doc directive, with it's expected format, if it has one.
@experimental
final class DocDirectiveParameter {
  final String name;
  final DocDirectiveParameterFormat expectedFormat;

  const DocDirectiveParameter(this.name, this.expectedFormat);
}

/// The expected format of a doc directive parameter, which indicates some
/// minimal validation that can produce diagnostics.
@experimental
enum DocDirectiveParameterFormat {
  /// A format indicating that arguments are not validated.
  any('any'),

  /// A format indicating that an argument must be parsable as an integer.
  integer('an integer'),

  /// A format indicating that an argument must be parsable as a URI.
  uri('a URI'),

  /// A format indicating that an argument must be parsable as a URI, and be in
  /// the format of a YouTube video URL.
  youtubeUrl("a YouTube URL, starting with '$youtubeUrlPrefix'");

  static const youtubeUrlPrefix = 'https://www.youtube.com/watch?v=';

  final String displayString;

  const DocDirectiveParameterFormat(this.displayString);
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
final class DocDirectiveTag {
  /// The offset of the starting text; for example: '@animation'.
  final int offset;
  final int end;
  final int nameOffset;
  final int nameEnd;

  final DocDirectiveType type;

  final List<DocDirectiveArgument> positionalArguments;
  final List<DocDirectiveNamedArgument> namedArguments;

  DocDirectiveTag({
    required this.offset,
    required this.end,
    required this.nameOffset,
    required this.nameEnd,
    required this.type,
    required this.positionalArguments,
    required this.namedArguments,
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
    positionalParameters: [
      DocDirectiveParameter('width', DocDirectiveParameterFormat.integer),
      DocDirectiveParameter('height', DocDirectiveParameterFormat.integer),
      DocDirectiveParameter('url', DocDirectiveParameterFormat.uri),
    ],
    namedParameters: [
      DocDirectiveParameter('id', DocDirectiveParameterFormat.any),
    ],
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
    positionalParameters: [
      DocDirectiveParameter('element', DocDirectiveParameterFormat.any),
    ],
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

  /// The end tag for the [DocDirectiveType.injectHtml] tag.
  ///
  /// This tag should not really constitute a "type" of doc directive, but this
  /// implementation is a one-to-one mapping of "types" and "tags", so end tags
  /// are included. This also allows us to parse (erroneous) dangling end tags.
  endInjectHtml.end('end-inject-html', openingTag: 'inject-html'),

  /// The end tag for the [DocDirectiveType.tool] tag.
  ///
  /// This tag should not really constitute a "type" of doc directive, but this
  /// implementation is a one-to-one mapping of "types" and "tags", so end tags
  /// are included. This also allows us to parse (erroneous) dangling end tags.
  endTool.end('end-tool', openingTag: 'tool'),

  /// The end tag for the [DocDirectiveType.template] tag.
  ///
  /// This tag should not really constitute a "type" of doc directive, but this
  /// implementation is a one-to-one mapping of "types" and "tags", so end tags
  /// are included. This also allows us to parse (erroneous) dangling end tags.
  endTemplate.end('endtemplate', openingTag: 'template'),

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
    positionalParameters: [
      DocDirectiveParameter('path', DocDirectiveParameterFormat.any)
    ],
    namedParameters: [
      DocDirectiveParameter('region', DocDirectiveParameterFormat.any),
      DocDirectiveParameter('lang', DocDirectiveParameterFormat.any),
    ],
  ),

  /// A [DocDirective] indicating that constants should not have their own
  /// pages or implementations displayed.
  hideConstantImplementations('hideConstantImplementations'),

  /// A [DocDirective] declaring a block of HTML content which is to be inserted
  /// after all other processing, including Markdown parsing.
  ///
  /// See documentation at
  /// https://github.com/dart-lang/dartdoc/wiki/Doc-comment-directives#injected-html.
  injectHtml.block('inject-html', 'end-inject-html'),

  /// A [DocDirective] declaring amacro application.
  ///
  /// This directive has one required argument: the name. For example:
  ///
  /// `{@macro some-macro}`
  macro(
    'macro',
    positionalParameters: [
      DocDirectiveParameter('name', DocDirectiveParameterFormat.any),
    ],
  ),

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

  /// A [DocDirective] declaring a template of text which can be applied to
  /// other doc comments with a macro.
  ///
  /// A template can contain any recognized doc comment content between the
  /// opening and closing tags, like Markdown text, comment references, and
  /// simple doc directives.
  ///
  /// See documentation at
  /// https://github.com/dart-lang/dartdoc/wiki/Doc-comment-directives#templates-and-macros.
  // TODO(srawlins): Migrate users to use 'end-template'.
  template.block(
    'template',
    'endtemplate',
    positionalParameters: [
      DocDirectiveParameter('name', DocDirectiveParameterFormat.any),
    ],
  ),

  /// A [DocDirective] declaring a tool.
  ///
  /// A tool directive invokes an external tool, with the text between the
  /// opening and closing tags as stdin, and replaces the directive with the
  /// output of the tool.
  ///
  /// See documentation at
  /// https://github.com/dart-lang/dartdoc/wiki/Doc-comment-directives#external-tools.
  tool.block(
    'tool',
    'end-tool',
    positionalParameters: [
      DocDirectiveParameter('name', DocDirectiveParameterFormat.any),
    ],
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
  youtube(
    'youtube',
    positionalParameters: [
      DocDirectiveParameter('width', DocDirectiveParameterFormat.integer),
      DocDirectiveParameter('height', DocDirectiveParameterFormat.integer),
      DocDirectiveParameter('url', DocDirectiveParameterFormat.youtubeUrl),
    ],
  );

  /// Whether this starts a block directive, which must be closed by a specific
  /// closing directive.
  ///
  /// For example, the 'inject-html' directive begins with `{@inject-html}` and
  /// ends with `{@end-inject-html}`.
  final bool isBlock;

  /// The name of the directive, as written in a doc comment.
  final String name;

  /// The name of the directive that ends this one, in the case of a block
  /// directive's opening tag, the name of the directive that starts this one,
  /// in the case of a block directive's closing tag, and `null` otherwise.
  final String? opposingName;

  /// The positional parameters, which are each required.
  final List<DocDirectiveParameter> positionalParameters;

  /// The named parameters, which are each optional.
  final List<DocDirectiveParameter> namedParameters;

  /// Whether "rest" parameters are allowed.
  ///
  /// In such a doc directive type, we do not enforce a maximum number of
  /// arguments.
  final bool restParametersAllowed;

  const DocDirectiveType(
    this.name, {
    this.positionalParameters = const <DocDirectiveParameter>[],
    this.namedParameters = const <DocDirectiveParameter>[],
    this.restParametersAllowed = false,
  })  : isBlock = false,
        opposingName = null;

  const DocDirectiveType.block(
    this.name,
    this.opposingName, {
    this.positionalParameters = const <DocDirectiveParameter>[],
    this.restParametersAllowed = false,
  })  : isBlock = true,
        namedParameters = const <DocDirectiveParameter>[];

  const DocDirectiveType.end(
    this.name, {
    required String openingTag,
  })  : opposingName = openingTag,
        isBlock = false,
        positionalParameters = const <DocDirectiveParameter>[],
        namedParameters = const <DocDirectiveParameter>[],
        restParametersAllowed = false;
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

@experimental
final class SimpleDocDirective implements DocDirective {
  final DocDirectiveTag tag;

  SimpleDocDirective(this.tag);

  @override
  DocDirectiveType get type => tag.type;
}
