// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The line contains only whitespace or is empty.
const _RE_EMPTY = const RegExp(@'^([ \t]*)$');

/// A series of `=` or `-` (on the next line) define setext-style headers.
const _RE_SETEXT = const RegExp(@'^((=+)|(-+))$');

/// Leading (and trailing) `#` define atx-style headers.
const _RE_HEADER = const RegExp(@'^(#{1,6})(.*?)#*$');

/// The line starts with `>` with one optional space after.
const _RE_BLOCKQUOTE = const RegExp(@'^[ ]{0,3}>[ ]?(.*)$');

/// A line indented four spaces. Used for code blocks and lists.
const _RE_INDENT = const RegExp(@'^(?:    |\t)(.*)$');

/// Three or more hyphens, asterisks or underscores by themselves. Note that
/// a line like `----` is valid as both HR and SETEXT. In case of a tie,
/// SETEXT should win.
const _RE_HR = const RegExp(@'^[ ]{0,3}((-+[ ]{0,2}){3,}|'
                                 @'(_+[ ]{0,2}){3,}|'
                                 @'(\*+[ ]{0,2}){3,})$');

/// Really hacky way to detect block-level embedded HTML. Just looks for
/// "<somename".
const _RE_HTML = const RegExp(@'^<[ ]*\w+[ >]');

/// A line starting with one of these markers: `-`, `*`, `+`. May have up to
/// three leading spaces before the marker and any number of spaces or tabs
/// after.
const _RE_UL = const RegExp(@'^[ ]{0,3}[*+-][ \t]+(.*)$');

/// A line starting with a number like `123.`. May have up to three leading
/// spaces before the marker and any number of spaces or tabs after.
const _RE_OL = const RegExp(@'^[ ]{0,3}\d+\.[ \t]+(.*)$');

/// Maintains the internal state needed to parse a series of lines into blocks
/// of markdown suitable for further inline parsing.
class BlockParser {
  final List<String> lines;

  /// The markdown document this parser is parsing.
  final Document document;

  /// Index of the current line.
  int pos;

  BlockParser(this.lines, this.document)
    : pos = 0;

  /// Gets the current line.
  String get current => lines[pos];

  /// Gets the line after the current one or `null` if there is none.
  String get next {
    // Don't read past the end.
    if (pos >= lines.length - 1) return null;
    return lines[pos + 1];
  }

  void advance() {
    pos++;
  }

  bool get isDone => pos >= lines.length;

  /// Gets whether or not the current line matches the given pattern.
  bool matches(RegExp regex) {
    if (isDone) return false;
    return regex.firstMatch(current) != null;
  }

  /// Gets whether or not the current line matches the given pattern.
  bool matchesNext(RegExp regex) {
    if (next == null) return false;
    return regex.firstMatch(next) != null;
  }
}

class BlockSyntax {
  /// Gets the collection of built-in block parsers. To turn a series of lines
  /// into blocks, each of these will be tried in turn. Order matters here.
  static List<BlockSyntax> get syntaxes {
    // Lazy initialize.
    if (_syntaxes == null) {
      _syntaxes = [
          new EmptyBlockSyntax(),
          new BlockHtmlSyntax(),
          new SetextHeaderSyntax(),
          new HeaderSyntax(),
          new CodeBlockSyntax(),
          new BlockquoteSyntax(),
          new HorizontalRuleSyntax(),
          new UnorderedListSyntax(),
          new OrderedListSyntax(),
          new ParagraphSyntax()
        ];
    }

    return _syntaxes;
  }

  static List<BlockSyntax> _syntaxes;

  /// Gets the regex used to identify the beginning of this block, if any.
  RegExp get pattern => null;

  bool get canEndBlock => true;

  bool canParse(BlockParser parser) {
    return pattern.firstMatch(parser.current) != null;
  }

  abstract Node parse(BlockParser parser);

  List<String> parseChildLines(BlockParser parser) {
    // Grab all of the lines that form the blockquote, stripping off the ">".
    final childLines = <String>[];

    while (!parser.isDone) {
      final match = pattern.firstMatch(parser.current);
      if (match == null) break;
      childLines.add(match[1]);
      parser.advance();
    }

    return childLines;
  }

  /// Gets whether or not [parser]'s current line should end the previous block.
  static bool isAtBlockEnd(BlockParser parser) {
    if (parser.isDone) return true;
    return syntaxes.some((s) => s.canParse(parser) && s.canEndBlock);
  }
}

class EmptyBlockSyntax extends BlockSyntax {
  RegExp get pattern => _RE_EMPTY;

  Node parse(BlockParser parser) {
    parser.advance();

    // Don't actually emit anything.
    return null;
  }
}

/// Parses setext-style headers.
class SetextHeaderSyntax extends BlockSyntax {
  bool canParse(BlockParser parser) {
    // Note: matches *next* line, not the current one. We're looking for the
    // underlining after this line.
    return parser.matchesNext(_RE_SETEXT);
  }

  Node parse(BlockParser parser) {
    final match = _RE_SETEXT.firstMatch(parser.next);

    final tag = (match[1][0] == '=') ? 'h1' : 'h2';
    final contents = parser.document.parseInline(parser.current);
    parser.advance();
    parser.advance();

    return new Element(tag, contents);
  }
}

/// Parses atx-style headers: `## Header ##`.
class HeaderSyntax extends BlockSyntax {
  RegExp get pattern => _RE_HEADER;

  Node parse(BlockParser parser) {
    final match = pattern.firstMatch(parser.current);
    parser.advance();
    final level = match[1].length;
    final contents = parser.document.parseInline(match[2].trim());
    return new Element('h$level', contents);
  }
}

/// Parses email-style blockquotes: `> quote`.
class BlockquoteSyntax extends BlockSyntax {
  RegExp get pattern => _RE_BLOCKQUOTE;

  Node parse(BlockParser parser) {
    final childLines = parseChildLines(parser);

    // Recursively parse the contents of the blockquote.
    final children = parser.document.parseLines(childLines);

    return new Element('blockquote', children);
  }
}

/// Parses preformatted code blocks that are indented four spaces.
class CodeBlockSyntax extends BlockSyntax {
  RegExp get pattern => _RE_INDENT;

  Node parse(BlockParser parser) {
    final childLines = parseChildLines(parser);

    // The Markdown tests expect a trailing newline.
    childLines.add('');

    // Escape the code.
    final escaped = escapeHtml(Strings.join(childLines, '\n'));

    return new Element('pre', [new Element.text('code', escaped)]);
  }
}

/// Parses horizontal rules like `---`, `_ _ _`, `*  *  *`, etc.
class HorizontalRuleSyntax extends BlockSyntax {
  RegExp get pattern => _RE_HR;

  Node parse(BlockParser parser) {
    final match = pattern.firstMatch(parser.current);
    parser.advance();
    return new Element.empty('hr');
  }
}

/// Parses inline HTML at the block level. This differs from other markdown
/// implementations in several ways:
///
/// 1.  This one is way way WAY simpler.
/// 2.  All HTML tags at the block level will be treated as blocks. If you
///     start a paragraph with `<em>`, it will not wrap it in a `<p>` for you.
///     As soon as it sees something like HTML, it stops mucking with it until
///     it hits the next block.
/// 3.  Absolutely no HTML parsing or validation is done. We're a markdown
///     parser not an HTML parser!
class BlockHtmlSyntax extends BlockSyntax {
  RegExp get pattern => _RE_HTML;

  bool get canEndBlock => false;

  Node parse(BlockParser parser) {
    final childLines = [];

    // Eat until we hit a blank line.
    while (!parser.isDone && !parser.matches(_RE_EMPTY)) {
      childLines.add(parser.current);
      parser.advance();
    }

    return new Text(Strings.join(childLines, '\n'));
  }
}

class ListItem {
  bool forceBlock = false;
  final List<String> lines;

  ListItem(this.lines);
}

/// Base class for both ordered and unordered lists.
class ListSyntax extends BlockSyntax {
  bool get canEndBlock => false;

  abstract String get listTag;

  Node parse(BlockParser parser) {
    final items = <ListItem>[];
    var childLines = <String>[];

    endItem() {
      if (childLines.length > 0) {
        items.add(new ListItem(childLines));
        childLines = <String>[];
      }
    }

    var match;
    tryMatch(RegExp pattern) {
      match = pattern.firstMatch(parser.current);
      return match != null;
    }

    bool afterEmpty = false;
    while (!parser.isDone) {
      if (tryMatch(_RE_EMPTY)) {
        // Add a blank line to the current list item.
        childLines.add('');
      } else if (tryMatch(_RE_UL) || tryMatch(_RE_OL)) {
        // End the current list item and start a new one.
        endItem();
        childLines.add(match[1]);
      } else if (tryMatch(_RE_INDENT)) {
        // Strip off indent and add to current item.
        childLines.add(match[1]);
      } else if (BlockSyntax.isAtBlockEnd(parser)) {
        // Done with the list.
        break;
      } else {
        // Anything else is paragraph text or other stuff that can be in a list
        // item. However, if the previous item is a blank line, this means we're
        // done with the list and are starting a new top-level paragraph.
        if ((childLines.length > 0) && (childLines.last() == '')) break;
        childLines.add(parser.current);
      }
      parser.advance();
    }

    endItem();

    // Markdown, because it hates us, specifies two kinds of list items. If you
    // have a list like:
    //
    // * one
    // * two
    //
    // Then it will insert the conents of the lines directly in the <li>, like:
    // <ul>
    //   <li>one</li>
    //   <li>two</li>
    // <ul>
    //
    // If, however, there are blank lines between the items, each is wrapped in
    // paragraphs:
    //
    // * one
    //
    // * two
    //
    // <ul>
    //   <li><p>one</p></li>
    //   <li><p>two</p></li>
    // <ul>
    //
    // In other words, sometimes we parse the contents of a list item like a
    // block, and sometimes line an inline. The rules our parser implements are:
    //
    // - If it has more than one line, it's a block.
    // - If the line matches any block parser (BLOCKQUOTE, HEADER, HR, INDENT,
    //   UL, OL) it's a block. (This is for cases like "* > quote".)
    // - If there was a blank line between this item and the previous one, it's
    //   a block.
    // - If there was a blank line between this item and the next one, it's a
    //   block.
    // - Otherwise, parse it as an inline.

    // Remove any trailing empty lines and note which items are separated by
    // empty lines. Do this before seeing which items are single-line so that
    // trailing empty lines on the last item don't force it into being a block.
    for (int i = 0; i < items.length; i++) {
      for (int j = items[i].lines.length - 1; j > 0; j--) {
        if (_RE_EMPTY.firstMatch(items[i].lines[j]) != null) {
          // Found an empty line. Item and one after it are blocks.
          if (i < items.length - 1) {
            items[i].forceBlock = true;
            items[i + 1].forceBlock = true;
          }
          items[i].lines.removeLast();
        } else {
          break;
        }
      }
    }

    // Convert the list items to Nodes.
    final itemNodes = <Node>[];
    for (final item in items) {
      bool blockItem = item.forceBlock || (item.lines.length > 1);

      // See if it matches some block parser.
      final blocksInList = const [
        _RE_BLOCKQUOTE,
        _RE_HEADER,
        _RE_HR,
        _RE_INDENT,
        _RE_UL,
        _RE_OL
      ];

      if (!blockItem) {
        for (final pattern in blocksInList) {
          if (pattern.firstMatch(item.lines[0]) != null) {
            blockItem = true;
            break;
          }
        }
      }

      // Parse the item as a block or inline.
      if (blockItem) {
        // Block list item.
        final children = parser.document.parseLines(item.lines);
        itemNodes.add(new Element('li', children));
      } else {
        // Raw list item.
        final contents = parser.document.parseInline(item.lines[0]);
        itemNodes.add(new Element('li', contents));
      }
    }

    return new Element(listTag, itemNodes);
  }
}

/// Parses unordered lists.
class UnorderedListSyntax extends ListSyntax {
  RegExp get pattern => _RE_UL;
  String get listTag => 'ul';
}

/// Parses ordered lists.
class OrderedListSyntax extends ListSyntax {
  RegExp get pattern => _RE_OL;
  String get listTag => 'ol';
}

/// Parses paragraphs of regular text.
class ParagraphSyntax extends BlockSyntax {
  bool get canEndBlock => false;

  bool canParse(BlockParser parser) => true;

  Node parse(BlockParser parser) {
    final childLines = [];

    // Eat until we hit something that ends a paragraph.
    while (!BlockSyntax.isAtBlockEnd(parser)) {
      childLines.add(parser.current);
      parser.advance();
    }

    final contents = parser.document.parseInline(
        Strings.join(childLines, '\n'));
    return new Element('p', contents);
  }
}
