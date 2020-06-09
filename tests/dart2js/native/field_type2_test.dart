// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a closure call on a native field is recognized by the
// type inferrer.

import 'native_testing.dart';

@Native("Node")
class Node {
  final parentNode;
}

makeNode(parent) native;

void setup() {
  JS('', r"""
(function(){
// This code is all inside 'setup' and so not accessible from the global scope.
function Node(parent){ this.parentNode = parent; }
makeNode = function(p){return new Node(p);};

self.nativeConstructor(Node);
})()""");
}

main() {
  nativeTesting();
  setup();
  var node = makeNode(null);
  if (node.parentNode != null) {
    node = node.parentNode();
  }
}
