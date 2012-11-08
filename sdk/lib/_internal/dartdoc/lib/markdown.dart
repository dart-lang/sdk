// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Parses text in a markdown-like format and renders to HTML.
library markdown;

// TODO(rnystrom): Use "package:" URL (#4968).
part 'src/markdown/ast.dart';
part 'src/markdown/block_parser.dart';
part 'src/markdown/html_renderer.dart';
part 'src/markdown/inline_parser.dart';

/// Converts the given string of markdown to HTML.
String markdownToHtml(String markdown) {
  final document = new Document();

  final lines = markdown.split('\n');
  document.parseRefLinks(lines);
  final blocks = document.parseLines(lines);
  return renderToHtml(blocks);
}

/// Replaces `<`, `&`, and `>`, with their HTML entity equivalents.
String escapeHtml(String html) {
  return html.replaceAll('&', '&amp;')
             .replaceAll('<', '&lt;')
             .replaceAll('>', '&gt;');
}

var _implicitLinkResolver;

Node setImplicitLinkResolver(Node resolver(String text)) {
  _implicitLinkResolver = resolver;
}

/// Maintains the context needed to parse a markdown document.
class Document {
  final Map<String, Link> refLinks;

  Document()
    : refLinks = <String, Link>{};

  parseRefLinks(List<String> lines) {
    // This is a hideous regex. It matches:
    // [id]: http:foo.com "some title"
    // Where there may whitespace in there, and where the title may be in
    // single quotes, double quotes, or parentheses.
    final indent = r'^[ ]{0,3}'; // Leading indentation.
    final id = r'\[([^\]]+)\]';  // Reference id in [brackets].
    final quote = r'"[^"]+"';    // Title in "double quotes".
    final apos = r"'[^']+'";     // Title in 'single quotes'.
    final paren = r"\([^)]+\)";  // Title in (parentheses).
    final pattern = new RegExp(
        '$indent$id:\\s+(\\S+)\\s*($quote|$apos|$paren|)\\s*\$');

    for (int i = 0; i < lines.length; i++) {
      final match = pattern.firstMatch(lines[i]);
      if (match != null) {
        // Parse the link.
        var id = match[1];
        var url = match[2];
        var title = match[3];

        if (title == '') {
          // No title.
          title = null;
        } else {
          // Remove "", '', or ().
          title = title.substring(1, title.length - 1);
        }

        // References are case-insensitive.
        id = id.toLowerCase();

        refLinks[id] = new Link(id, url, title);

        // Remove it from the output. We replace it with a blank line which will
        // get consumed by later processing.
        lines[i] = '';
      }
    }
  }

  /// Parse the given [lines] of markdown to a series of AST nodes.
  List<Node> parseLines(List<String> lines) {
    final parser = new BlockParser(lines, this);

    final blocks = [];
    while (!parser.isDone) {
      for (final syntax in BlockSyntax.syntaxes) {
        if (syntax.canParse(parser)) {
          final block = syntax.parse(parser);
          if (block != null) blocks.add(block);
          break;
        }
      }
    }

    return blocks;
  }

  /// Takes a string of raw text and processes all inline markdown tags,
  /// returning a list of AST nodes. For example, given ``"*this **is** a*
  /// `markdown`"``, returns:
  /// `<em>this <strong>is</strong> a</em> <code>markdown</code>`.
  List<Node> parseInline(String text) => new InlineParser(text, this).parse();
}

class Link {
  final String id;
  final String url;
  final String title;
  Link(this.id, this.url, this.title);
}
