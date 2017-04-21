// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tools for manipulating HTML during code generation of analyzer and analysis
 * server.
 */
library analyzer.src.codegen.html;

import 'package:html/dom.dart' as dom;

/**
 * Make a deep copy of the given HTML nodes.
 */
List<dom.Node> cloneHtmlNodes(List<dom.Node> nodes) =>
    nodes.map((dom.Node node) => node.clone(true)).toList();

/**
 * Return true if the given iterable contains only whitespace text nodes.
 */
bool containsOnlyWhitespace(Iterable<dom.Node> nodes) {
  for (dom.Node node in nodes) {
    if (!isWhitespaceNode(node)) {
      return false;
    }
  }
  return true;
}

/**
 * Get the text contents of the element, ignoring all markup.
 */
String innerText(dom.Element parent) {
  StringBuffer buffer = new StringBuffer();
  void recurse(dom.Element parent) {
    for (dom.Node child in parent.nodes) {
      if (child is dom.Text) {
        buffer.write(child.text);
      } else if (child is dom.Element) {
        recurse(child);
      }
    }
  }

  recurse(parent);
  return buffer.toString();
}

/**
 * Return true if the given node is a text node containing only whitespace, or
 * a comment.
 */
bool isWhitespaceNode(dom.Node node) {
  if (node is dom.Element) {
    return false;
  } else if (node is dom.Text) {
    return node.text.trim().isEmpty;
  }
  // Treat all other types of nodes (e.g. comments) as whitespace.
  return true;
}

/**
 * Create an HTML element with the given name, attributes, and child nodes.
 */
dom.Element makeElement(
    String name, Map<dynamic, String> attributes, List<dom.Node> children) {
  dom.Element result = new dom.Element.tag(name);
  result.attributes.addAll(attributes);
  for (dom.Node child in children) {
    result.append(child);
  }
  return result;
}

/**
 * Mixin class for generating HTML.
 */
class HtmlGenerator {
  List<dom.Node> _html;

  /**
   * Add the given [node] to the HTML output.
   */
  void add(dom.Node node) {
    _html.add(node);
  }

  /**
   * Add the given [nodes] to the HTML output.
   */
  void addAll(Iterable<dom.Node> nodes) {
    for (dom.Node node in nodes) {
      add(node);
    }
  }

  /**
   * Execute [callback], collecting any code that is output using [write],
   * [writeln], [add], [addAll] or [element], and return the result as a list
   * of HTML nodes.
   */
  List<dom.Node> collectHtml(void callback()) {
    List<dom.Node> oldHtml = _html;
    try {
      _html = <dom.Node>[];
      if (callback != null) {
        callback();
      }
      return _html;
    } finally {
      _html = oldHtml;
    }
  }

  /**
   * Execute [callback], wrapping its output in an element with the given
   * [name] and [attributes].
   */
  void element(String name, Map<dynamic, String> attributes,
      [void callback()]) {
    add(makeElement(name, attributes, collectHtml(callback)));
  }

  /**
   * Output text without ending the current line.
   */
  void write(String text) {
    _html.add(new dom.Text(text));
  }

  /**
   * Output text, ending the current line.
   */
  void writeln([Object obj = '']) {
    write('$obj\n');
  }
}
