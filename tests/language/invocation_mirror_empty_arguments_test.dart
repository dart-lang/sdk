// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Getter {
  noSuchMethod(invocation) {
    Expect.isTrue(invocation.isGetter);
    Expect.identical(const [], invocation.positionalArguments);
    Expect.identical(const {}, invocation.namedArguments);
  }
}

class Setter {
  noSuchMethod(invocation) {
    Expect.isTrue(invocation.isSetter);
    Expect.identical(const {}, invocation.namedArguments);
  }
}

class Method {
  noSuchMethod(invocation) {
    Expect.isTrue(invocation.isMethod);
    Expect.identical(const [], invocation.positionalArguments);
    Expect.identical(const {}, invocation.namedArguments);
  }
}

class Operator {
  noSuchMethod(invocation) {
    Expect.isTrue(invocation.isMethod);
    Expect.identical(const {}, invocation.namedArguments);
  }
}

main() {
  var g = new Getter();
  print(g.getterThatDoesNotExist);
  var s = new Setter();
  print(s.setterThatDoesNotExist = 42);
  var m = new Method();
  print(m.methodThatDoesNotExist());
  var o = new Operator();
  print(o + 42); // Operator that does not exist.
}
