// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';

const _desc = r'Use of angle brackets in a doc comment is treated as HTML by '
    'Markdown.';

const _details = r'''
**DO** reference only in-scope identifiers in doc comments.

When a developer writes a reference with angle brackets within a doc comment,
the angle brackets are interpreted as HTML. The text within pairs of opening and
closing angle brackets generally get swallowed by the browser, and will not be
displayed.

You can use a code block or code span to wrap the text containing angle
brackets. You can also replace `<` with `&lt;` and `>` with `&gt;`.

**BAD:**
```dart
/// Text List<int>.
/// Text [List<int>].
/// <assignment> -> <variable> = <expression>
```

**GOOD:**
```dart
/// Text `List<int>`.
/// `<assignment> -> <variable> = <expression>`
/// <http://foo.bar.baz>
```

''';

/// Valid HTML tags that should not be linted.
///
/// These tags are from
/// [CommonMark 0.30](https://spec.commonmark.org/0.30/#raw-html).
const _validHtmlTags = [
  'a',
  'abbr',
  'address',
  'area',
  'article',
  'aside',
  'audio',
  'b',
  'bdi',
  'bdo',
  'blockquote',
  'br',
  'button',
  'canvas',
  'caption',
  'cite',
  'code',
  'col',
  'colgroup',
  'data',
  'datalist',
  'dd',
  'del',
  'dfn',
  'div',
  'dl',
  'dt',
  'em',
  'fieldset',
  'figcaption',
  'figure',
  'footer',
  'form',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'header',
  'hr',
  'i',
  'iframe',
  'img',
  'input',
  'ins',
  'kbd',
  'keygen',
  'label',
  'legend',
  'li',
  'link',
  'main',
  'map',
  'mark',
  'meta',
  'meter',
  'nav',
  'noscript',
  'object',
  'ol',
  'optgroup',
  'option',
  'output',
  'p',
  'param',
  'pre',
  'progress',
  'q',
  's',
  'samp',
  'script',
  'section',
  'select',
  'small',
  'source',
  'span',
  'strong',
  'style',
  'sub',
  'sup',
  'table',
  'tbody',
  'td',
  'template',
  'textarea',
  'tfoot',
  'th',
  'thead',
  'time',
  'title',
  'tr',
  'track',
  'u',
  'ul',
  'var',
  'video',
  'wbr',
];

class UnintendedHtmlInDocComment extends LintRule {
  static const LintCode code = LintCode('unintended_html_in_doc_comment',
      'Angle brackets will be interpreted as HTML.',
      correctionMessage:
          'Try using backticks around the content with angle brackets, or '
          'try replacing `<` with `&lt;` and `>` with `&gt;`.');

  UnintendedHtmlInDocComment()
      : super(
            name: 'unintended_html_in_doc_comment',
            description: _desc,
            details: _details,
            categories: {Category.error_prone});

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addComment(this, visitor);
  }
}

/// Represents the [offset] and [length] of an unintended HTML tag in a doc
/// comment.
class _UnintendedTag {
  final int offset;
  final int length;
  _UnintendedTag(this.offset, this.length);
}

class _Visitor extends SimpleAstVisitor<void> {
  // Matches autolinks: starting angle bracket, starting alphabetic character,
  // any alphabetic character or `-`, `+`, `.`, a semi-colon with optionally two
  // `/`s then anything but whitespace until a closing angle bracket.
  static final _autoLinkPattern =
      RegExp(r'<(([a-zA-Z][a-zA-Z\-\+\.]+):(?://)?[^\s>]*)>');

  // Matches codespans: starting backtick with anything but a backtick until a
  // closing backtick.
  static final _codeSpanPattern = RegExp(r'`([^`]+)`');

  // Matches unintential tags: starting `>`, optionally an opening `/` then one
  // or more valid tag characters then anything but a `>` until a closing `>`.
  static final _nonHtmlPattern =
      RegExp("<(?!/?(${_validHtmlTags.join("|")})[>])[^>]*[>]");

  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitComment(Comment node) {
    var codeBlockLines =
        node.codeBlocks.map((codeBlock) => codeBlock.lines).flattened;

    for (var token in node.tokens) {
      // Make sure that the current doc comment line isn't contained in a code
      // block.
      var offsetAfterSlash = token.offset + 3;
      var inCodeBlock = codeBlockLines.any((codeBlockLine) =>
          codeBlockLine.offset <= offsetAfterSlash &&
          offsetAfterSlash <= codeBlockLine.offset + codeBlockLine.length);
      if (inCodeBlock) continue;

      var tags = _findUnintendedHtmlTags(token.lexeme);
      for (var tag in tags) {
        rule.reportLintForOffset(token.offset + tag.offset, tag.length);
      }
    }
  }

  /// Finds tags that are not valid HTML tags, not contained in a code span, and
  /// are not autolinks.
  List<_UnintendedTag> _findUnintendedHtmlTags(String text) {
    var codeSpanOrAutoLink = [
      ..._codeSpanPattern.allMatches(text),
      ..._autoLinkPattern.allMatches(text)
    ];
    var unintendedHtmlTags = _nonHtmlPattern.allMatches(text);

    var matches = <_UnintendedTag>[];
    for (var htmlTag in unintendedHtmlTags) {
      // If the tag is in a code span or is an autolink, we won't report it.
      if (!codeSpanOrAutoLink.any((match) =>
          match.start <= htmlTag.start && htmlTag.end <= match.end)) {
        matches.add(_UnintendedTag(htmlTag.start, htmlTag.end - htmlTag.start));
      }
    }
    return matches;
  }
}
