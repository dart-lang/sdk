// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class ExpandoTest {
  static Expando<int> visits;

  static testMain() {
    visits = new Expando<int>('visits');
    var legal = [
      new Object(),
      new List(),
      [1, 2, 3],
      const [1, 2, 3],
      new Map(),
      {'x': 1, 'y': 2},
      const {'x': 1, 'y': 2},
      new Expando(),
      new Expando('horse')
    ];
    for (var object in legal) {
      testNamedExpando(object);
      testUnnamedExpando(object);
    }
    for (var object in legal) {
      Expect.equals(2, visits[object], "$object");
    }
    testIllegal();
    testIdentity();
  }

  static visit(object) {
    int count = visits[object];
    count = (count == null) ? 1 : count + 1;
    visits[object] = count;
  }

  static testNamedExpando(object) {
    Expando<int> expando = new Expando<int>('myexpando');
    Expect.equals('myexpando', expando.name);
    Expect.isTrue(expando.toString().startsWith('Expando:myexpando'));
    testExpando(expando, object);
  }

  static testUnnamedExpando(object) {
    Expando<int> expando = new Expando<int>();
    Expect.isNull(expando.name);
    Expect.isTrue(expando.toString().startsWith('Expando:'));
    testExpando(expando, object);
  }

  static testExpando(Expando<int> expando, object) {
    visit(object);

    Expect.isNull(expando[object]);
    expando[object] = 42;
    Expect.equals(42, expando[object]);
    expando[object] = null;
    Expect.isNull(expando[object]);

    Expando<int> alternative = new Expando('myexpando');
    Expect.isNull(alternative[object]);
    alternative[object] = 87;
    Expect.isNull(expando[object]);
    expando[object] = 99;
    Expect.equals(99, expando[object]);
    Expect.equals(87, alternative[object]);
  }

  static testIllegal() {
    Expando<int> expando = new Expando<int>();
    Expect.throwsArgumentError(() => expando[null], "null");
    Expect.throwsArgumentError(() => expando['string'], "'string'");
    Expect.throwsArgumentError(() => expando[42], "42");
    Expect.throwsArgumentError(() => expando[42.87], "42.87");
    Expect.throwsArgumentError(() => expando[true], "true");
    Expect.throwsArgumentError(() => expando[false], "false");
  }

  static testIdentity() {
    // Expando only depends on identity of object.
    Expando<int> expando = new Expando<int>();
    var m1 = new Mutable(1);
    var m2 = new Mutable(7);
    var m3 = new Mutable(13);
    expando[m1] = 42;
    Expect.equals(42, expando[m1]);
    m1.id = 37;
    Expect.equals(42, expando[m1]);
    expando[m2] = 37;
    expando[m3] = 10;
    m3.id = 1;
    Expect.equals(42, expando[m1]);
    Expect.equals(37, expando[m2]);
    Expect.equals(10, expando[m3]);
  }
}

main() => ExpandoTest.testMain();

class Mutable {
  int id;
  Mutable(this.id);
  int get hashCode => id;
  bool operator ==(other) => other is Mutable && other.id == id;
}
