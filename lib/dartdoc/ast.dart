// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Base class for any AST item. Roughly corresponds to Node in the DOM. Will
/// be either an Element or Text.
interface Node {
  void accept(NodeVisitor visitor);
}

/// A named tag that can contain other nodes.
class Element implements Node {
  final String tag;
  final List<Node> children;
  final Map<String, String> attributes;

  Element(this.tag, this.children)
    : attributes = <String>{};

  Element.empty(this.tag)
    : children = null,
      attributes = <String>{};

  Element.tag(this.tag)
    : children = [],
      attributes = <String>{};

  Element.text(this.tag, String text)
    : children = [new Text(text)],
      attributes = <String>{};

  bool get isEmpty() => children == null;

  void accept(NodeVisitor visitor) {
    if (visitor.visitElementBefore(this)) {
      for (final child in children) child.accept(visitor);
      visitor.visitElementAfter(this);
    }
  }
}

/// A plain text element.
class Text implements Node {
  final String text;
  Text(this.text);

  void accept(NodeVisitor visitor) => visitor.visitText(this);
}

/// Visitor pattern for the AST. Renderers or other AST transformers should
/// implement this.
interface NodeVisitor {
  /// Called when a Text node has been reached.
  void visitText(Text text);

  /// Called when an Element has been reached, before its children have been
  /// visited. Return `false` to skip its children.
  bool visitElementBefore(Element element);

  /// Called when an Element has been reached, after its children have been
  /// visited. Will not be called if [visitElementBefore] returns `false`.
  void visitElementAfter(Element element);
}
