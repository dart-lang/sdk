// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Maintains the internal state needed to parse inline span elements in
/// markdown.
class InlineParser {
  static List<InlineSyntax> get syntaxes() {
    // Lazy initialize.
    if (_syntaxes == null) {
      _syntaxes = <InlineSyntax>[
        new AutolinkSyntax(),
        new LinkSyntax(),
        // "*" surrounded by spaces is left alone.
        new TextSyntax(@' \* '),
        // "_" surrounded by spaces is left alone.
        new TextSyntax(@' _ '),
        // Leave already-encoded HTML entities alone. Ensures we don't turn
        // "&amp;" into "&amp;amp;"
        new TextSyntax(@'&[#a-zA-Z0-9]*;'),
        // Encode "&".
        new TextSyntax(@'&', sub: '&amp;'),
        // Encode "<". (Why not encode ">" too? Gruber is toying with us.)
        new TextSyntax(@'<', sub: '&lt;'),
        // Parse "**strong**" tags.
        new TagSyntax(@'\*\*',                  tag: 'strong'),
        // Parse "__strong__" tags.
        new TagSyntax(@'__',                    tag: 'strong'),
        // Parse "*emphasis*" tags.
        new TagSyntax(@'\*',                    tag: 'em'),
        // Parse "_emphasis_" tags.
        // TODO(rnystrom): Underscores in the middle of a word should not be
        // parsed as emphasis like_in_this.
        new TagSyntax(@'_',                     tag: 'em'),
        // Parse inline code within double backticks: "``code``".
        new CodeSyntax(@'``[ ]?(.*?)[ ]?``'),
        // Parse inline code within backticks: "`code`".
        new CodeSyntax(@'`([^`]*)`')
      ];
    }

    return _syntaxes;
  }

  static List<InlineSyntax> _syntaxes;

  /// The string of markdown being parsed.
  final String source;

  /// The markdown document this parser is parsing.
  final Document document;

  /// The current read position.
  int pos = 0;

  /// Starting position of the last unconsumed text.
  int start = 0;

  final List<TagState> _stack;

  InlineParser(this.source, this.document)
    : _stack = <TagState>[];

  List<Node> parse() {
    // Make a fake top tag to hold the results.
    _stack.add(new TagState(0, null));

    while (!isDone) {
      bool matched = false;

      // See if any of the current tags on the stack match. We don't allow tags
      // of the same kind to nest, so this takes priority over other possible // matches.
      for (int i = _stack.length - 1; i > 0; i--) {
        if (_stack[i].tryMatch(this)) {
          matched = true;
          break;
        }
      }
      if (matched) continue;

      // See if the current text matches any defined markdown syntax.
      for (final syntax in syntaxes) {
        if (syntax.tryMatch(this)) {
          matched = true;
          break;
        }
      }
      if (matched) continue;

      // If we got here, it's just text.
      advanceBy(1);
    }

    // Unwind any unmatched tags and get the results.
    return _stack[0].close(this, null);
  }

  writeText() {
    if (pos > start) {
      final text = source.substring(start, pos);
      final nodes = _stack.last().children;

      // If the previous node is text too, just append.
      if ((nodes.length > 0) && (nodes.last() is Text)) {
        final newNode = new Text('${nodes.last().text}$text');
        nodes[nodes.length - 1] = newNode;
      } else {
        nodes.add(new Text(text));
      }

      start = pos;
    }
  }

  /// Removes the top tag from the stack, reverts it to plain text and adds it
  /// to the output.
  discardUnmatchedTag() {
    final unfinished = _stack.removeLast();
    start = unfinished.startPos;
  }

  addNode(Node node) {
    _stack.last().children.add(node);
  }

  // TODO(rnystrom): Only need this because RegExp doesn't let you start
  // searching from a given offset.
  String get currentSource() => source.substring(pos, source.length);

  bool get isDone() => pos == source.length;

  void advanceBy(int length) => pos += length;
  void consume(int length) {
    pos += length;
    start = pos;
  }
}

/// Represents one kind of markdown tag that can be parsed.
class InlineSyntax {
  final RegExp pattern;

  InlineSyntax(String pattern)
    : pattern = new RegExp(pattern, true);
  // TODO(rnystrom): Should use named arg for RegExp multiLine.

  bool tryMatch(InlineParser parser) {
    final startMatch = pattern.firstMatch(parser.currentSource);
    if ((startMatch != null) && (startMatch.start() == 0)) {
      // Write any existing plain text up to this point.
      parser.writeText();

      if (onMatch(parser, startMatch)) {
        parser.consume(startMatch.group(0).length);
      }
      return true;
    }
    return false;
  }

  abstract bool match(InlineParser parser, Match match);
}

/// Matches stuff that should just be passed through as straight text.
class TextSyntax extends InlineSyntax {
  String substitute;
  TextSyntax(String pattern, [String sub])
    : super(pattern),
      substitute = sub;

  bool onMatch(InlineParser parser, Match match) {
    if (substitute == null) {
      // Just use the original matched text.
      parser.advanceBy(match.group(0).length);
      return false;
    }

    // Insert the substitution.
    parser.addNode(new Text(substitute));
    return true;
  }
}

/// Matches autolinks like <http://foo.com>.
class AutolinkSyntax extends InlineSyntax {
  AutolinkSyntax()
    : super(@'<((http|https|ftp)://[^>]*)>');
  // TODO(rnystrom): Make case insensitive.

  bool onMatch(InlineParser parser, Match match) {
    final url = match.group(1);

    final anchor = new Element.text('a', escapeHtml(url));
    anchor.attributes['href'] = url;
    parser.addNode(anchor);

    return true;
  }
}

/// Matches syntax that has a pair of tags and becomes an element, like '*' for
/// `<em>`. Allows nested tags.
class TagSyntax extends InlineSyntax {
  final RegExp endPattern;
  final String tag;

  TagSyntax(String pattern, [String tag, String end = null])
    : super(pattern),
      endPattern = new RegExp((end != null) ? end : pattern, true),
      tag = tag;
    // TODO(rnystrom): Doing this.field doesn't seem to work with named args.
    // TODO(rnystrom): Should use named arg for RegExp multiLine.

  bool onMatch(InlineParser parser, Match match) {
    parser._stack.add(new TagState(parser.pos, this));
    return true;
  }

  bool onMatchEnd(InlineParser parser, Match match, TagState state) {
    parser.addNode(new Element(tag, state.children));
    return true;
  }
}

/// Matches inline links like [blah] [id] and [blah] (url).
class LinkSyntax extends TagSyntax {
  /// The regex for the end of a link needs to handle both reference style and
  /// inline styles as well as optional titles for inline links. To make that
  /// a bit more palatable, this breaks it into pieces.
  static get linkPattern() {
    final bracket    = @'\][ \n\t]?';          // "]" with optional space after.
    final refLink    = @'\[([^\]]*)\]';        // "[id]" reflink id.
    final title      = @'(?:[ ]*"([^"]+)"|)';  // Optional title in quotes.
    final inlineLink = '\\(([^ )]+)$title\\)'; // "(url "title")" inline link.
    return '$bracket(?:$refLink|$inlineLink)';
  }

  LinkSyntax()
    : super(@'\[', end: linkPattern);

  bool onMatchEnd(InlineParser parser, Match match, TagState state) {
    var url;
    var title;

    if (match.group(2) != '') {
      // Inline link like [foo](url).
      url = match.group(2);
      title = match.group(3);

      // For whatever reason, markdown allows angle-bracketed URLs here.
      if (url.startsWith('<') && url.endsWith('>')) {
        url = url.substring(1, url.length - 1);
      }
    } else {
      // Reference link like [foo] [bar].
      var id = match.group(1);
      if (id == '') {
        // The id is empty ("[]") so infer it from the contents.
        id = parser.source.substring(state.startPos + 1, parser.pos);
      }

      // Look up the link.
      final link = parser.document.refLinks[id];
      // If it's an unknown link just emit plaintext.
      if (link == null) return false;

      url = link.url;
      title = link.title;
    }

    final anchor = new Element('a', state.children);
    anchor.attributes['href'] = escapeHtml(url);
    if ((title != null) && (title != '')) {
      anchor.attributes['title'] = escapeHtml(title);
    }

    parser.addNode(anchor);
    return true;
  }
}

/// Matches backtick-enclosed inline code blocks.
class CodeSyntax extends InlineSyntax {
  CodeSyntax(String pattern)
    : super(pattern);

  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(new Element.text('code', escapeHtml(match.group(1))));
    return true;
  }
}

/// Keeps track of a currently open tag while it is being parsed. The parser
/// maintains a stack of these so it can handle nested tags.
class TagState {
  /// The point in the original source where this tag started.
  int startPos;

  /// The syntax that created this node.
  final TagSyntax syntax;

  /// The children of this node. Will be `null` for text nodes.
  final List<Node> children;

  TagState(this.startPos, this.syntax)
    : children = <Node>[];

  /// Attempts to close this tag by matching the current text against its end
  /// pattern.
  bool tryMatch(InlineParser parser) {
    Match endMatch = syntax.endPattern.firstMatch(parser.currentSource);
    if ((endMatch != null) && (endMatch.start() == 0)) {
      // Close the tag.
      close(parser, endMatch);
      return true;
    }

    return false;
  }

  /// Pops this tag off the stack, completes it, and adds it to the output.
  /// Will discard any unmatched tags that happen to be above it on the stack.
  /// If this is the last node in the stack, returns its children.
  List<Node> close(InlineParser parser, Match endMatch) {
    // Found a match. If there is anything above this tag on the stack,
    // discard it. For example, given '*a _b*...' when we reach the second
    // '*', '_' will be on the top of the stack. It's mismatched, so we
    // just treat it as text.
    while (parser._stack.last() != this) parser.discardUnmatchedTag();

    // Pop this off the stack.
    parser.writeText();
    parser._stack.removeLast();

    // If the stack is empty now, this is the special "results" node.
    if (parser._stack.length == 0) return children;

    // We are still parsing, so add this to its parent's children.
    if (syntax.onMatchEnd(parser, endMatch, this)) {
      parser.consume(endMatch.group(0).length);
    } else {
      // Didn't close correctly so revert to text.
      parser.start = startPos;
      parser.advanceBy(endMatch.group(0).length);
    }

    return null;
  }
}
