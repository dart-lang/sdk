// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NamedNodeMap extends List<Node> {

  int get length();

  Node getNamedItem([String name]);

  Node getNamedItemNS([String namespaceURI, String localName]);

  Node item([int index]);

  Node removeNamedItem([String name]);

  Node removeNamedItemNS([String namespaceURI, String localName]);

  Node setNamedItem([Node node]);

  Node setNamedItemNS([Node node]);
}
