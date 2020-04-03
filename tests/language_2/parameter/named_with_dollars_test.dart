// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test to stress Frog's named parameter scheme.

main() {
  testDollar();
  testPsycho();
}

class TestClass {
  method({a, b, a$b, a$$b}) => [a, b, a$b, a$$b];

  psycho({$, $$, $$$, $$$$}) => [$, $$, $$$, $$$$];
}

globalMethod({a, b, a$b, a$$b}) => [a, b, a$b, a$$b];

format(thing) {
  if (thing == null) return '-';
  if (thing is List) {
    var fragments = ['['];
    var sep;
    for (final item in thing) {
      if (sep != null) fragments.add(sep);
      sep = ', ';
      fragments.add(format(item));
    }
    fragments.add(']');
    return fragments.join();
  }
  return thing.toString();
}

// Hopefully inscrutable to static analysis.
makeTestClass(n) => [new TestClass(), new Decoy(), 'string'][n % 3];

class Decoy {
  method([a$b, b, a]) {
    throw new UnimplementedError();
  }

  psycho([$$$, $$, $]) {
    throw new UnimplementedError();
  }
}

testDollar() {
  Expect.equals('[]', format([]));

  Expect.equals('[-, -, -, -]', format(globalMethod()));
  Expect.equals('[1, 2, -, -]', format(globalMethod(a: 1, b: 2)));
  Expect.equals('[1, 2, -, -]', format(globalMethod(b: 2, a: 1)));
  Expect.equals('[-, -, 3, -]', format(globalMethod(a$b: 3)));
  Expect.equals('[-, -, -, 4]', format(globalMethod(a$$b: 4)));

  TestClass t = new TestClass(); // Statically typed.

  Expect.equals('[-, -, -, -]', format(t.method()));
  Expect.equals('[1, 2, -, -]', format(t.method(a: 1, b: 2)));
  Expect.equals('[1, 2, -, -]', format(t.method(b: 2, a: 1)));
  Expect.equals('[-, -, 3, -]', format(t.method(a$b: 3)));
  Expect.equals('[-, -, -, 4]', format(t.method(a$$b: 4)));

  var obj = makeTestClass(0);

  Expect.equals('[-, -, -, -]', format(obj.method()));
  Expect.equals('[1, 2, -, -]', format(obj.method(a: 1, b: 2)));
  Expect.equals('[1, 2, -, -]', format(obj.method(b: 2, a: 1)));
  Expect.equals('[-, -, 3, -]', format(obj.method(a$b: 3)));
  Expect.equals('[-, -, -, 4]', format(obj.method(a$$b: 4)));
}

testPsycho() {
  TestClass t = new TestClass(); // Statically typed.

  Expect.equals('[1, 2, 3, -]', format(t.psycho($: 1, $$: 2, $$$: 3)));
  Expect.equals('[1, 2, 3, -]', format(t.psycho($$$: 3, $$: 2, $: 1)));
  Expect.equals('[1, 2, -, -]', format(t.psycho($: 1, $$: 2)));
  Expect.equals('[-, -, -, 4]', format(t.psycho($$$$: 4)));

  var obj = makeTestClass(0);

  Expect.equals('[1, 2, -, -]', format(obj.psycho($: 1, $$: 2)));
  Expect.equals('[-, -, -, 4]', format(obj.psycho($$$$: 4)));
  Expect.equals('[1, 2, 3, -]', format(obj.psycho($: 1, $$: 2, $$$: 3)));
  Expect.equals('[1, 2, 3, -]', format(obj.psycho($$$: 3, $$: 2, $: 1)));
}
