// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test computation of the correct this class within nested closures.

class Super {
  noSuchMethod(im) => true;
}

class Sub extends Super {
  noSuchMethod(im) => false;

  superNoSuchMethod() {
    return () {
      return () {
        return super.foo;
      }();
    }();
  }
}

void main() {
  Expect.isTrue(new Sub().superNoSuchMethod());
}

