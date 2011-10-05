// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): stop extending eventTarget.
interface Node extends EventTarget {

  NodeList get nodes();
  // TODO(jacobr): add nodes setter that replaces all children.

  Node get nextNode();

  Document get document();

  // TODO(jacobr): should we remove parentElement?
  Element get parentElement();

  Node get parent();

  Node get previousNode();

  String get text();

  void set text(String value);

  Node replaceWith(Node otherNode);

  Node remove();

  bool get inDocument();

  bool contains(Node otherNode);

  // TODO(jacobr): remove when/if Array supports a method similar to
  // insertBefore or we switch NodeList to implement LinkedList rather than
  // array.
  Node insertBefore(Node newChild, Node refChild);
}
