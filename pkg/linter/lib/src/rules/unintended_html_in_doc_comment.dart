// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';

const _desc = r'Use of angle brackets in a doc comment is treated as HTML by '
    'Markdown.';

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
  UnintendedHtmlInDocComment()
      : super(
          name: LintNames.unintended_html_in_doc_comment,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unintended_html_in_doc_comment;

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
  /// Pattern for HTML-tags and non-HTML regions.
  ///
  /// Pattern which matches sequences of characters with content that is known
  /// to *not* be interpreted as Markdown or HTML tags,  and anything else that
  /// looks like an HTML tag.
  /// Because [RegExp.allMatches] matches do not overlap, including the
  /// non-HTML sections in the same RegExp ensures that the HTML tag match
  /// will not be matched against the non-HTML content.
  static final _markdownTokenPattern = RegExp(
      // Escaped Markdown character, including `\<` and `\\`.
      r'\\.'

      // Or a Markdown code span, from "`"*N to "`"*N.
      // Also matches an unterminated start tag to avoid "```a``"
      // being matched as "``a``".
      // The ```-sequence is atomic.
      r'|(?<cq>`+)(?:[^]+?\k<cq>)?'

      // Or autolink, starting with scheme + `:`, followed by non-whitespace/
      // control characters until a closing `>`.
      r'|<[a-z][a-z\d\-+.]+:[^\x00-\x20\x7f<>]*>'

      // Or HTML comments.
      r'|<!--(?:-?>|[^]*?-->)'

      // Or HTML declarations, like `<!DOCTYPE ...>`.
      r'|<![a-z][^]*?!>'

      // Or HTML processing instructions.
      r'|<\?[^]*?\?>'

      // Or HTML CDATA sections sections.
      r'|<\[CDATA[^]*\]>'

      // Or plain `[...]` which DartDoc interprets as Dart source links,
      // and which can contain type parameters like `... [List<int>] ...`.
      // Here recognized as `[...]` with no `]` inside, not preceded by `]`
      // or followed by `(` or `[`.
      r'|(?<!\])\[[^\]]*\](?![(\[])'

      // Or valid HTML tag.
      // Matches `<validTag>`, `<validTag ...>`, `<validTag/>`, `</validTag>`
      // and `</validTag ...>.
      r'|<(?<et>/?)(?:'
      '${_validHtmlTags.join('|')}'
      r')'
      r'(?:/(?=\k<et>)>|>|[\x20\r\n\t][^]*?>)'

      // Or any of the following matches which are considered invalid tags.
      // If the "nh" capture group is participating, one of these matched.
      r'|(?<nh>)(?:'

      // Any other `</?tag ...>` sequence.
      r'</?[a-z][^]*?>'
      r')', caseSensitive: false);

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
    var matches = <_UnintendedTag>[];
    for (var match in _markdownTokenPattern.allMatches(text)) {
      if (match.namedGroup('nh') != null) {
        matches.add(_UnintendedTag(match.start, match.end - match.start));
      }
    }
    return matches;
  }
}
