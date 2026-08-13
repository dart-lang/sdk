// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/37455
// Verifies that TFA can infer type of a recursive call if it doesn't depend
// on the flow.

class A {
  // Should be inferred as _GrowableList.
  final List afield;

  A(this.afield);

  String toString() => afield.toString();
}

class B {
  List _foo(Iterator<int> iter) {
    List result = [];
    while (iter.moveNext()) {
      if (iter.current < 0) {
        return result;
      }
      // Do a recursive call with the same arguments.
      result.add(new A(_foo(iter)));
    }
    return result;
  }
}

void main() {
  var list = new B()._foo([1, 2, 3].iterator);
  print(list);
}
