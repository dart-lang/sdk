// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ExpandoTest {
  static Expando<int> visits;

  static testMain() {
    visits = new Expando<int>('visits');
    var legal = [ new Object(),
                  new List(), [1,2,3], const [1,2,3],
                  new Map(), {'x':1,'y':2}, const {'x':1,'y':2},
                  new Expando(), new Expando('horse') ];
    for (var object in legal) {
      testNamedExpando(object);
      testUnnamedExpando(object);
    }
    for (var object in legal) {
      Expect.equals(2, visits[object]);
    }
    testIllegal();
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
    Expect.throws(() => expando[null], (exception)
                  => exception is NullPointerException);
    Expect.throws(() => expando['string'], (exception)
                  => exception is ArgumentError);
    Expect.throws(() => expando['string'], (exception)
                  => exception is ArgumentError);
    Expect.throws(() => expando[42], (exception)
                  => exception is ArgumentError);
    Expect.throws(() => expando[42.87], (exception)
                  => exception is ArgumentError);
    Expect.throws(() => expando[true], (exception)
                  => exception is ArgumentError);
    Expect.throws(() => expando[false], (exception)
                  => exception is ArgumentError);
  }
}

main() => ExpandoTest.testMain();
