// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that the constructor body of a superclass is invoked.

class Super {
  final superArgument;
  var superField;

  Super() : this.named(''); // Redirection is required to trigger the bug.

  Super.named(this.superArgument) {
    superField = 'fisk';
  }
}

class Sub extends Super {
  var subField;

  // Test for a bug when super() is the first initializer.
  Sub.first()
      : super(),
        subField = [];

  Sub.last()
      : subField = [],
        super();
}

main() {
  Expect.equals('fisk', new Sub.last().superField);
  Expect.equals('fisk', new Sub.first().superField);
}
