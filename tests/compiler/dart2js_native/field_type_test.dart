// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A native class has no defined constructor.
// This regression test verifies that compiler accounts for hidden constructor
// when analysing field values.

import "dart:_js_helper";
import "package:expect/expect.dart";

@Native("Node")
class Node {

  final Node parentNode;

  ModelSource _modelSource;  // If null, inherited from parent.

  ModelSource get modelSource {
    for (Node node = this; node != null; node = node.parentNode) {
      ModelSource source = node._modelSource;
      if (source != null) return source;
    }
    return null;
  }

  // Copy of above code renamed with suffix '2'.

  ModelSource _modelSource2;  // If null, inherited from parent.

  ModelSource get modelSource2 {
    for (Node node = this; node != null; node = node.parentNode) {
      ModelSource source = node._modelSource2;
      if (source != null) return source;
    }
    return null;
  }
}

makeNode(parent) native;

class ModelSource {
  var name;
  ModelSource(this.name);
  toString() => 'ModelSource($name)';
}

void setup() native """
// This code is all inside 'setup' and so not accesible from the global scope.
function Node(parent){ this.parentNode = parent; }
makeNode = function(p){return new Node(p);};
""";


main() {
  setup();

  var n1 = makeNode(null);
  var n2 = makeNode(n1);
  var n3 = makeNode(n2);

  var m1 = new ModelSource('1');
  n2._modelSource = null;        // null write.
  n2._modelSource = m1;          // Non-null write.
  var x1 = n3.modelSource;
  Expect.identical(m1, x1);

  var m2 = new ModelSource('2');
  n2._modelSource2 = m2;         // The only write is non-null.
  var x2 = n3.modelSource2;
  Expect.identical(m2, x2);
}
