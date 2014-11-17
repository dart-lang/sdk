// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code for converting HTML into text, for use in doc comments.
 */
library text.formatter;

import 'package:html5lib/dom.dart' as dom;

import 'codegen_tools.dart';

final RegExp whitespace = new RegExp(r'\s');

/**
 * Convert the HTML in [desc] into text, word wrapping at width [width].
 *
 * If [javadocStyle] is true, then the output is compatable with Javadoc,
 * which understands certain HTML constructs.
 */
String nodesToText(List<dom.Node> desc, int width, bool javadocStyle) {
  _TextFormatter formatter = new _TextFormatter(width, javadocStyle);
  return formatter.collectCode(() {
    formatter.addAll(desc);
    formatter.lineBreak(false);
  });
}

/**
 * Engine that transforms HTML to text.  The input HTML is processed one
 * character at a time, gathering characters into words and words into lines.
 */
class _TextFormatter extends CodeGenerator {
  /**
   * Word-wrapping width.
   */
  final int width;

  /**
   * The word currently being gathered.
   */
  String word = '';

  /**
   * The line currently being gathered.
   */
  String line = '';

  /**
   * True if a blank line should be inserted before the next word.
   */
  bool verticalSpaceNeeded = false;

  /**
   * True if no text has been output yet.  This suppresses blank lines.
   */
  bool atStart = true;

  /**
   * True if we are processing a <pre> element, thus whitespace should be
   * preserved.
   */
  bool preserveSpaces = false;

  /**
   * True if the output should be Javadoc compatible.
   */
  final bool javadocStyle;

  _TextFormatter(this.width, this.javadocStyle);

  /**
   * Process an HTML node.
   */
  void add(dom.Node node) {
    if (node is dom.Text) {
      for (String char in node.text.split('')) {
        if (preserveSpaces) {
          wordBreak();
          write(escape(char));
        } else if (whitespace.hasMatch(char)) {
          wordBreak();
        } else {
          resolveVerticalSpace();
          word += escape(char);
        }
      }
    } else if (node is dom.Element) {
      switch (node.localName) {
        case 'br':
          lineBreak(false);
          break;
        case 'dl':
        case 'dt':
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'p':
          lineBreak(true);
          addAll(node.nodes);
          lineBreak(true);
          break;
        case 'div':
          lineBreak(false);
          if (node.classes.contains('hangingIndent')) {
            resolveVerticalSpace();
            indentSpecial('', '        ', () {
              addAll(node.nodes);
              lineBreak(false);
            });
          } else {
            addAll(node.nodes);
            lineBreak(false);
          }
          break;
        case 'ul':
          lineBreak(false);
          addAll(node.nodes);
          lineBreak(false);
          break;
        case 'li':
          lineBreak(false);
          resolveVerticalSpace();
          indentSpecial('- ', '  ', () {
            addAll(node.nodes);
            lineBreak(false);
          });
          break;
        case 'dd':
          lineBreak(true);
          indent(() {
            addAll(node.nodes);
            lineBreak(true);
          });
          break;
        case 'pre':
          lineBreak(false);
          resolveVerticalSpace();
          if (javadocStyle) {
            writeln('<pre>');
          }
          bool oldPreserveSpaces = preserveSpaces;
          try {
            preserveSpaces = true;
            addAll(node.nodes);
          } finally {
            preserveSpaces = oldPreserveSpaces;
          }
          writeln();
          if (javadocStyle) {
            writeln('</pre>');
          }
          lineBreak(false);
          break;
        case 'a':
        case 'b':
        case 'body':
        case 'html':
        case 'i':
        case 'span':
        case 'tt':
          addAll(node.nodes);
          break;
        case 'head':
          break;
        default:
          throw new Exception('Unexpected HTML element: ${node.localName}');
      }
    } else {
      throw new Exception('Unexpected HTML: $node');
    }
  }

  /**
   * Process a list of HTML nodes.
   */
  void addAll(List<dom.Node> nodes) {
    for (dom.Node node in nodes) {
      add(node);
    }
  }

  /**
   * Escape the given character for HTML.
   */
  String escape(String char) {
    if (javadocStyle) {
      switch (char) {
        case '<':
          return '&lt;';
        case '>':
          return '&gt;';
        case '&':
          return '&amp;';
      }
    }
    return char;
  }

  /**
   * Terminate the current word and/or line, if either is in progress.
   */
  void lineBreak(bool gap) {
    wordBreak();
    if (line.isNotEmpty) {
      writeln(line);
      line = '';
    }
    if (gap && !atStart) {
      verticalSpaceNeeded = true;
    }
  }

  /**
   * Insert vertical space if necessary.
   */
  void resolveVerticalSpace() {
    if (verticalSpaceNeeded) {
      writeln();
      verticalSpaceNeeded = false;
    }
  }

  /**
   * Terminate the current word, if a word is in progress.
   */
  void wordBreak() {
    if (word.isNotEmpty) {
      atStart = false;
      if (line.isNotEmpty) {
        if (indentWidth + line.length + 1 + word.length <= width) {
          line += ' $word';
        } else {
          writeln(line);
          line = word;
        }
      } else {
        line = word;
      }
      word = '';
    }
  }
}
