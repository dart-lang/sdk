// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.shadow_root;

import 'dart:html';

import 'selection.dart' show
    TrySelection;

import 'html_to_text.dart' show
    htmlToText;

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
  htmlToText(node, buffer, new TrySelection.empty(node));
  return '$buffer';
}
