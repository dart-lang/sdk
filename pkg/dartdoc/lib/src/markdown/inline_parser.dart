part of markdown;

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Maintains the internal state needed to parse inline span elements in
/// markdown.
class InlineParser {
  static List<InlineSyntax> get syntaxes {
    // Lazy initialize.
    if (_syntaxes == null) {
      _syntaxes = <InlineSyntax>[
        // This first regexp matches plain text to accelerate parsing.  It must
        // be written so that it does not match any prefix of any following
        // syntax.  Most markdown is plain text, so it is faster to match one
        // regexp per 'word' rather than fail to match all the following regexps
        // at each non-syntax character position.  It is much more important
        // that the regexp is fast than complete (for example, adding grouping
        // is likely to slow the regexp down enough to negate its benefit).
        // Since it is purely for optimization, it can be removed for debugging.
        new TextSyntax(r'\s*[A-Za-z0-9]+'),

        // The real syntaxes.

        new AutolinkSyntax(),
        new LinkSyntax(),
        // "*" surrounded by spaces is left alone.
        new TextSyntax(r' \* '),
        // "_" surrounded by spaces is left alone.
        new TextSyntax(r' _ '),
        // Leave already-encoded HTML entities alone. Ensures we don't turn
        // "&amp;" into "&amp;amp;"
        new TextSyntax(r'&[#a-zA-Z0-9]*;'),
        // Encode "&".
        new TextSyntax(r'&', sub: '&amp;'),
        // Encode "<". (Why not encode ">" too? Gruber is toying with us.)
        new TextSyntax(r'<', sub: '&lt;'),
        // Parse "**strong**" tags.
        new TagSyntax(r'\*\*', tag: 'strong'),
        // Parse "__strong__" tags.
        new TagSyntax(r'__', tag: 'strong'),
        // Parse "*emphasis*" tags.
        new TagSyntax(r'\*', tag: 'em'),
        // Parse "_emphasis_" tags.
        // TODO(rnystrom): Underscores in the middle of a word should not be
        // parsed as emphasis like_in_this.
        new TagSyntax(r'_', tag: 'em'),
        // Parse inline code within double backticks: "``code``".
        new CodeSyntax(r'``\s?((?:.|\n)*?)\s?``'),
        // Parse inline code within backticks: "`code`".
        new CodeSyntax(r'`([^`]*)`')
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
    _stack.add(new TagState(0, 0, null));

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
    writeTextRange(start, pos);
    start = pos;
  }

  writeTextRange(int start, int end) {
    if (end > start) {
      final text = source.substring(start, end);
      final nodes = _stack.last().children;

      // If the previous node is text too, just append.
      if ((nodes.length > 0) && (nodes.last() is Text)) {
        final newNode = new Text('${nodes.last().text}$text');
        nodes[nodes.length - 1] = newNode;
      } else {
        nodes.add(new Text(text));
      }
    }
  }

  addNode(Node node) {
    _stack.last().children.add(node);
  }

  // TODO(rnystrom): Only need this because RegExp doesn't let you start
  // searching from a given offset.
  String get currentSource => source.substring(pos, source.length);

  bool get isDone => pos == source.length;

  void advanceBy(int length) {
    pos += length;
  }

  void consume(int length) {
    pos += length;
    start = pos;
  }
}

/// Represents one kind of markdown tag that can be parsed.
class InlineSyntax {
  final RegExp pattern;

  InlineSyntax(String pattern)
    : pattern = new RegExp(pattern, multiLine: true);

  bool tryMatch(InlineParser parser) {
    final startMatch = pattern.firstMatch(parser.currentSource);
    if ((startMatch != null) && (startMatch.start() == 0)) {
      // Write any existing plain text up to this point.
      parser.writeText();

      if (onMatch(parser, startMatch)) {
        parser.consume(startMatch[0].length);
      }
      return true;
    }
    return false;
  }

  abstract bool onMatch(InlineParser parser, Match match);
}

/// Matches stuff that should just be passed through as straight text.
class TextSyntax extends InlineSyntax {
  String substitute;
  TextSyntax(String pattern, {String sub})
    : super(pattern),
      substitute = sub;

  bool onMatch(InlineParser parser, Match match) {
    if (substitute == null) {
      // Just use the original matched text.
      parser.advanceBy(match[0].length);
      return false;
    }

    // Insert the substitution.
    parser.addNode(new Text(substitute));
    return true;
  }
}

/// Matches autolinks like `<http://foo.com>`.
class AutolinkSyntax extends InlineSyntax {
  AutolinkSyntax()
    : super(r'<((http|https|ftp)://[^>]*)>');
  // TODO(rnystrom): Make case insensitive.

  bool onMatch(InlineParser parser, Match match) {
    final url = match[1];

    final anchor = new Element.text('a', escapeHtml(url));
    anchor.attributes['href'] = url;
    parser.addNode(anchor);

    return true;
  }
}

/// Matches syntax that has a pair of tags and becomes an element, like `*` for
/// `<em>`. Allows nested tags.
class TagSyntax extends InlineSyntax {
  final RegExp endPattern;
  final String tag;

  TagSyntax(String pattern, {String tag, String end})
    : super(pattern),
      endPattern = new RegExp((end != null) ? end : pattern, multiLine: true),
      tag = tag;
    // TODO(rnystrom): Doing this.field doesn't seem to work with named args.

  bool onMatch(InlineParser parser, Match match) {
    parser._stack.add(new TagState(parser.pos,
      parser.pos + match[0].length, this));
    return true;
  }

  bool onMatchEnd(InlineParser parser, Match match, TagState state) {
    parser.addNode(new Element(tag, state.children));
    return true;
  }
}

/// Matches inline links like `[blah] [id]` and `[blah] (url)`.
class LinkSyntax extends TagSyntax {
  /// The regex for the end of a link needs to handle both reference style and
  /// inline styles as well as optional titles for inline links. To make that
  /// a bit more palatable, this breaks it into pieces.
  static get linkPattern {
    final refLink    = r'\s?\[([^\]]*)\]';        // "[id]" reflink id.
    final title      = r'(?:[ ]*"([^"]+)"|)';     // Optional title in quotes.
    final inlineLink = '\\s?\\(([^ )]+)$title\\)'; // "(url "title")" link.
    return '\](?:($refLink|$inlineLink)|)';

    // The groups matched by this are:
    // 1: Will be non-empty if it's either a ref or inline link. Will be empty
    //    if it's just a bare pair of square brackets with nothing after them.
    // 2: Contains the id inside [] for a reference-style link.
    // 3: Contains the URL for an inline link.
    // 4: Contains the title, if present, for an inline link.
  }

  LinkSyntax()
    : super(r'\[', end: linkPattern);

  bool onMatchEnd(InlineParser parser, Match match, TagState state) {
    var url;
    var title;

    // If we didn't match refLink or inlineLink, then it means there was
    // nothing after the first square bracket, so it isn't a normal markdown
    // link at all. Instead, we allow users of the library to specify a special
    // resolver function ([setImplicitLinkResolver]) that may choose to handle
    // this. Otherwise, it's just treated as plain text.
    if ((match[1] == null) || (match[1] == '')) {
      if (_implicitLinkResolver == null) return false;

      // Only allow implicit links if the content is just text.
      // TODO(rnystrom): Do we want to relax this?
      if (state.children.length != 1) return false;
      if (state.children[0] is! Text) return false;

      Text link = state.children[0];

      // See if we have a resolver that will generate a link for us.
      final node = _implicitLinkResolver(link.text);
      if (node == null) return false;

      parser.addNode(node);
      return true;
    }

    if ((match[3] != null) && (match[3] != '')) {
      // Inline link like [foo](url).
      url = match[3];
      title = match[4];

      // For whatever reason, markdown allows angle-bracketed URLs here.
      if (url.startsWith('<') && url.endsWith('>')) {
        url = url.substring(1, url.length - 1);
      }
    } else {
      // Reference link like [foo] [bar].
      var id = match[2];
      if (id == '') {
        // The id is empty ("[]") so infer it from the contents.
        id = parser.source.substring(state.startPos + 1, parser.pos);
      }

      // References are case-insensitive.
      id = id.toLowerCase();

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
    parser.addNode(new Element.text('code', escapeHtml(match[1])));
    return true;
  }
}

/// Keeps track of a currently open tag while it is being parsed. The parser
/// maintains a stack of these so it can handle nested tags.
class TagState {
  /// The point in the original source where this tag started.
  int startPos;

  /// The point in the original source where open tag ended.
  int endPos;

  /// The syntax that created this node.
  final TagSyntax syntax;

  /// The children of this node. Will be `null` for text nodes.
  final List<Node> children;

  TagState(this.startPos, this.endPos, this.syntax)
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
    // If there are unclosed tags on top of this one when it's closed, that
    // means they are mismatched. Mismatched tags are treated as plain text in
    // markdown. So for each tag above this one, we write its start tag as text
    // and then adds its children to this one's children.
    int index = parser._stack.indexOf(this);

    // Remove the unmatched children.
    final unmatchedTags = parser._stack.getRange(index + 1,
        parser._stack.length - index - 1);
    parser._stack.removeRange(index + 1, parser._stack.length - index - 1);

    // Flatten them out onto this tag.
    for (final unmatched in unmatchedTags) {
      // Write the start tag as text.
      parser.writeTextRange(unmatched.startPos, unmatched.endPos);

      // Bequeath its children unto this tag.
      children.addAll(unmatched.children);
    }

    // Pop this off the stack.
    parser.writeText();
    parser._stack.removeLast();

    // If the stack is empty now, this is the special "results" node.
    if (parser._stack.length == 0) return children;

    // We are still parsing, so add this to its parent's children.
    if (syntax.onMatchEnd(parser, endMatch, this)) {
      parser.consume(endMatch[0].length);
    } else {
      // Didn't close correctly so revert to text.
      parser.start = startPos;
      parser.advanceBy(endMatch[0].length);
    }

    return null;
  }
}
