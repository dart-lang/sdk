// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): stop extending eventTarget.
interface Node extends EventTarget {

  NodeList get nodes();

  // TODO: The type of value should be Collection<Node>. See http://b/5392897
  void set nodes(value);

  Node get nextNode();

  Document get document();

  Node get parent();

  Node get previousNode();

  String get text();

  void set text(String value);

  Node replaceWith(Node otherNode);

  Node remove();

  bool contains(Node otherNode);

  // TODO(jacobr): remove when/if Array supports a method similar to
  // insertBefore or we switch NodeList to implement LinkedList rather than
  // array.
  Node insertBefore(Node newChild, Node refChild);

  Node clone(bool deep);
}
