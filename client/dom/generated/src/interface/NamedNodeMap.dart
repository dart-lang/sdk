// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface NamedNodeMap extends List<Node> {

  int get length();

  Node getNamedItem(String name = null);

  Node getNamedItemNS(String namespaceURI = null, String localName = null);

  Node item(int index = null);

  Node removeNamedItem(String name = null);

  Node removeNamedItemNS(String namespaceURI = null, String localName = null);

  Node setNamedItem(Node node = null);

  Node setNamedItemNS(Node node = null);
}
