// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a closure call on a native field is recognized by the
// type inferrer.

import 'dart:_js_helper';

@Native("Node")
class Node {
  final parentNode;
}

makeNode(parent) native;

void setup() native """
// This code is all inside 'setup' and so not accesible from the global scope.
function Node(parent){ this.parentNode = parent; }
makeNode = function(p){return new Node(p);};
""";


main() {
  setup();
  var node = makeNode(null);
  if (node.parentNode != null) {
    node = node.parentNode();
  }
}
