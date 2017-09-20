// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Validates that positional arguments are an empty immutable list.
void expectEmptyPositionalArguments(Invocation invocation) {
  Expect.isTrue(invocation.positionalArguments.isEmpty);
  Expect.throwsUnsupportedError(() => invocation.positionalArguments.clear());
}

// Validates that positional arguments are an empty immutable map.
void expectEmptyNamedArguments(Invocation invocation) {
  Expect.isTrue(invocation.namedArguments.isEmpty);
  Expect.throwsUnsupportedError(() => invocation.namedArguments.clear());
}

class Getter {
  get getterThatDoesNotExist;

  noSuchMethod(invocation) {
    Expect.isTrue(invocation.isGetter);
    expectEmptyPositionalArguments(invocation);
    expectEmptyNamedArguments(invocation);
  }
}

class Setter {
  set setterThatDoesNotExist(value);

  noSuchMethod(invocation) {
    Expect.isTrue(invocation.isSetter);
    expectEmptyNamedArguments(invocation);
  }
}

class Method {
  methodThatDoesNotExist();

  noSuchMethod(invocation) {
    Expect.isTrue(invocation.isMethod);
    expectEmptyPositionalArguments(invocation);
    expectEmptyNamedArguments(invocation);
  }
}

class Operator {
  operator +(other);

  noSuchMethod(invocation) {
    Expect.isTrue(invocation.isMethod);
    expectEmptyNamedArguments(invocation);
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
