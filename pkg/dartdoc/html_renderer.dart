// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String renderToHtml(List<Node> nodes) => new HtmlRenderer().render(nodes);

/// Translates a parsed AST to HTML.
class HtmlRenderer implements NodeVisitor {
  static const _BLOCK_TAGS = const RegExp(
      'blockquote|h1|h2|h3|h4|h5|h6|hr|p|pre');

  StringBuffer buffer;

  HtmlRenderer();

  String render(List<Node> nodes) {
    buffer = new StringBuffer();

    for (final node in nodes) node.accept(this);

    return buffer.toString();
  }

  void visitText(Text text) {
    buffer.add(text.text);
  }

  bool visitElementBefore(Element element) {
    // Hackish. Separate block-level elements with newlines.
    if (!buffer.isEmpty() &&
        _BLOCK_TAGS.firstMatch(element.tag) != null) {
      buffer.add('\n');
    }

    buffer.add('<${element.tag}');

    // Sort the keys so that we generate stable output.
    // TODO(rnystrom): This assumes getKeys() returns a fresh mutable
    // collection.
    final attributeNames = element.attributes.getKeys();
    attributeNames.sort((a, b) => a.compareTo(b));
    for (final name in attributeNames) {
      buffer.add(' $name="${element.attributes[name]}"');
    }

    if (element.isEmpty) {
      // Empty element like <hr/>.
      buffer.add(' />');
      return false;
    } else {
      buffer.add('>');
      return true;
    }
  }

  void visitElementAfter(Element element) {
    buffer.add('</${element.tag}>');
  }
}
