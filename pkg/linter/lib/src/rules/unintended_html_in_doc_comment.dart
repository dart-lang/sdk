// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Use of angle brackets in a doc comment is treated as HTML by '
    'Markdown.';

const _details = r'''
**DON'T** use angle-bracketed text, `<…>`, in a doc comment unless you want to
write an HTML tag or link.

Markdown allows HTML tags as part of the Markdown code, so you can write, for
example, `T<sub>1</sub>`. Markdown does not restrict the allowed tags, it just
includes the tags verbatim in the output.

Dartdoc only allows some known and valid HTML tags, and will omit any disallowed
HTML tag from the output. See the list of allowed tags and directives below.
Your doc comment should not contain any HTML tags that are not on this list.

Markdown also allows you to write an "auto-link" to an URL as for example
`<https://example.com/page.html>`, delimited only by `<...>`. Such a link is
allowed by Dartdoc as well.
A `<...>` delimited text is an auto-link if it is a valid absolute URL, starting
with a scheme of at least two characters followed by a colon, like
`<mailto:mr_example@example.com>`.

Any other other occurrence of `<word...>` or `</word...>` is likely a mistake
and this lint will warn about it.
If something looks like an HTML tag, meaning it starts with `<` or `</` 
and then a letter, and it has a later matching `>`, then it's considered an
invalid HTML tag unless it is an auto-link, or it starts with an *allowed*
HTML tag.

Such a mistake can, for example, happen if writing Dart code with type arguments
outside of a code span, for example `The type List<int> is ...`, where `<int>`
looks like an HTML tag. Missing the end quote of a code span can have the same
effect: ``The type `List<int> is ...`` will also treat `<int>` as an HTML tag.

Allowed HTML directives are: HTML comments, `<!-- text -->`, processing
instructions, `<?...?>`, CDATA-sections, `<[CDATA...]>`, and the allowed HTML
tags are:
`a`, `abbr`, `address`, `area`, `article`, `aside`, `audio`, `b`,
`bdi`, `bdo`, `blockquote`, `br`, `button`, `canvas`, `caption`,
`cite`, `code`, `col`, `colgroup`, `data`, `datalist`, `dd`, `del`,
`dfn`, `div`, `dl`, `dt`, `em`, `fieldset`, `figcaption`, `figure`,
`footer`, `form`, `h1`, `h2`, `h3`, `h4`, `h5`, `h6`, `header`, `hr`,
`i`, `iframe`, `img`, `input`, `ins`, `kbd`, `keygen`, `label`,
`legend`, `li`, `link`, `main`, `map`, `mark`, `meta`, `meter`, `nav`,
`noscript`, `object`, `ol`, `optgroup`, `option`, `output`, `p`,
`param`, `pre`, `progress`, `q`, `s`, `samp`, `script`, `section`,
`select`, `small`, `source`, `span`, `strong`, `style`, `sub`, `sup`,
`table`, `tbody`, `td`, `template`, `textarea`, `tfoot`, `th`, `thead`,
`time`, `title`, `tr`, `track`, `u`, `ul`, `var`, `video` and `wbr`.

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
  UnintendedHtmlInDocComment()
      : super(
            name: 'unintended_html_in_doc_comment',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.errorProne});

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
  static final _markdownTokenPattern = RegExp(
      // Escaped Markdown character.
      r'\\.'

      // Or code span, from "`"*N to "`"*N or just the start if it's
      // unterminated, to avoid "```a``" matching the "``a``".
      // The ```-sequence is atomic.
      r'|(?<cq>`+)(?:[^]*?\k<cq>)?'

      // Or autolink, start with scheme + `:`.
      r'|<[a-z][a-z\d\-+.]+:[^\x00-\x20\x7f<>]*>'

      // Or HTML comments.
      r'|<!--(?:-?>|[^]*?-->)'

      // Or HTML declarations.
      r'|<![a-z][^]*?!>'

      // Or HTML processing instructions.
      r'|<\?[^]*?\?>'

      // Or HTML CDATA sections sections.
      r'|<\[CDATA[^]*\]>'

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
