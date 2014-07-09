// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.shadow_root;

import 'dart:html';

import 'selection.dart' show
    TrySelection;

import 'html_to_text.dart' show
    htmlToText;

const int WALKER_NEXT = 0;
const int WALKER_RETURN = 1;
const int WALKER_SKIP_NODE = 2;

void setShadowRoot(Element node, text) {
  if (text is String) {
    text = new Text(text);
  }
  getShadowRoot(node)
      ..nodes.clear()
      ..append(text);
}


/* ShadowRoot or Element */ getShadowRoot(Element node) {
  if (ShadowRoot.supported) {
    ShadowRoot root = node.shadowRoot;
    return root != null ? root : node.createShadowRoot();
  } else {
    Element root = node.querySelector('[try-dart-shadow-root]');
    if (root == null) {
      root = new SpanElement()
          ..setAttribute('try-dart-shadow-root', '');
      node.append(root);
    }
    return root;
  }
}

void removeShadowRootPolyfill(Element root) {
  if (!ShadowRoot.supported) {
    List<Node> polyfill = root.querySelectorAll('[try-dart-shadow-root]');
    for (Element element in polyfill) {
      element.remove();
    }
  }
}

String getText(Element node) {
  if (ShadowRoot.supported) return node.text;
  StringBuffer buffer = new StringBuffer();
  htmlToText(
      node, buffer, new TrySelection.empty(node), treatRootAsInline: true);
  return '$buffer';
}

/// Position [walker] at the last predecessor (that is, child of child of
/// child...) of [node]. The next call to walker.nextNode will return the first
/// node after [node].
void skip(Node node, TreeWalker walker) {
  if (walker.nextSibling() != null) {
    walker.previousNode();
    return;
  }
  for (Node current = walker.nextNode();
       current != null;
       current = walker.nextNode()) {
    if (!node.contains(current)) {
      walker.previousNode();
      return;
    }
  }
}

/// Call [f] on each node in [root] in same order as [TreeWalker].  Skip any
/// nodes used to implement shadow root polyfill.
void walkNodes(Node root, int f(Node node)) {
  TreeWalker walker = new TreeWalker(root, NodeFilter.SHOW_ALL);

  for (Node node = root; node != null; node = walker.nextNode()) {
    if (!ShadowRoot.supported &&
        node is Element &&
        node.getAttribute('try-dart-shadow-root') != null) {
      skip(node, walker);
    }
    int action = f(node);
    switch (action) {
      case WALKER_RETURN:
        return;
      case WALKER_SKIP_NODE:
        skip(node, walker);
        break;
      case WALKER_NEXT:
        break;
      default:
        throw 'Unexpected action returned from [f]: $action';
    }
  }
}
