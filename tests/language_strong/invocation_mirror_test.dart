// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Invocation and noSuchMethod testing.

Map<Symbol, dynamic> listToNamedArguments(list) {
  var iterator = list.iterator;
  var result = new Map<Symbol, dynamic>();
  while (iterator.moveNext()) {
    Symbol key = iterator.current;
    Expect.isTrue(iterator.moveNext());
    result[key] = iterator.current;
  }
  return result;
}

/** Class with noSuchMethod that returns the mirror */
class N {
  // Storage for the last argument to noSuchMethod.
  // Needed for setters, which don't evaluate to the return value.
  var last;
  noSuchMethod(Invocation m) => last = m;

  flif(int x) {
    Expect.fail("never get here");
  }

  flaf([int x]) {
    Expect.fail("never get here");
  }

  flof({int y}) {
    Expect.fail("never get here");
  }

  get wut => this;
  final int plif = 99;
  int get plaf {
    Expect.fail("never get here");
    return 0;
  }
}

/** As [N] but also implements 'call', so we can call it with wrong arguments.*/
class C extends N {
  call(int x) {
    Expect.fail("never get here");
  }
}

/**
 * Checks the data of an Invocation.
 *
 * Call without optionals for getters, with only positional for setters,
 * and with both optionals for everything else.
 */
testInvocationMirror(Invocation im, Symbol name,
    [List positional, List named, List typeArgs]) {
  Expect.isTrue(im is Invocation, "is Invocation");
  Expect.equals(name, im.memberName, "name");
  if (named == null) {
    Expect.isTrue(im.isAccessor, "$name:isAccessor");
    Expect.isFalse(im.isMethod, "$name:isMethod");
    if (positional == null) {
      Expect.isTrue(im.isGetter, "$name:isGetter");
      Expect.isFalse(im.isSetter, "$name:isSetter");
      Expect.equals(0, im.positionalArguments.length, "$name:#positional");
      Expect.equals(0, im.namedArguments.length, "$name:#named");
      return;
    }
    Expect.isTrue(im.isSetter, "$name:isSetter");
    Expect.isFalse(im.isGetter, "$name:isGetter");
    Expect.equals(1, im.positionalArguments.length, "$name:#positional");
    Expect.equals(
        positional[0], im.positionalArguments[0], "$name:positional[0]");
    Expect.equals(0, im.namedArguments.length, "$name:#named");
    return;
  }
  Map<Symbol, dynamic> namedArguments = listToNamedArguments(named);
  Expect.isTrue(im.isMethod, "$name:isMethod");
  Expect.isFalse(im.isAccessor, "$name:isAccessor");
  Expect.isFalse(im.isSetter, "$name:isSetter");
  Expect.isFalse(im.isGetter, "$name:isGetter");

  Expect.listEquals(positional, im.positionalArguments);

  Expect.equals(
      namedArguments.length, im.namedArguments.length, "$name:#named");
  namedArguments.forEach((k, v) {
    Expect.isTrue(
        im.namedArguments.containsKey(k), "$name:?namedArguments[$k]");
    Expect.equals(v, im.namedArguments[k], "$name:namedArguments[$k]");
  });
  var imTypeArgs = (im as dynamic).typeArguments as List<Type>;
  Expect.listEquals(typeArgs ?? [], imTypeArgs);
}

// Test different ways that noSuchMethod can be called.
testInvocationMirrors() {
  dynamic n = new N();
  dynamic c = new C();

  // Missing property/method access.
  testInvocationMirror(n.bar, const Symbol('bar'));
  testInvocationMirror((n..bar = 42).last, const Symbol('bar='), [42]);
  testInvocationMirror(n.bar(), const Symbol('bar'), [], []);
  testInvocationMirror(n.bar(42), const Symbol('bar'), [42], []);
  testInvocationMirror(
      n.bar(x: 42), const Symbol('bar'), [], [const Symbol("x"), 42]);
  testInvocationMirror(
      n.bar(37, x: 42), const Symbol('bar'), [37], [const Symbol("x"), 42]);

  // Missing operator access.
  testInvocationMirror(n + 4, const Symbol('+'), [4], []);
  testInvocationMirror(n - 4, const Symbol('-'), [4], []);
  testInvocationMirror(-n, const Symbol('unary-'), [], []);
  testInvocationMirror(n[42], const Symbol('[]'), [42], []);
  testInvocationMirror((n..[37] = 42).last, const Symbol('[]='), [37, 42], []);

  // Calling as function when it's not.
  testInvocationMirror(n(), const Symbol('call'), [], []);
  testInvocationMirror(n(42), const Symbol('call'), [42], []);
  testInvocationMirror(
      n(x: 42), const Symbol('call'), [], [const Symbol("x"), 42]);
  testInvocationMirror(
      n(37, x: 42), const Symbol('call'), [37], [const Symbol("x"), 42]);

  // Calling with arguments not matching existing call method.
  testInvocationMirror(c(), const Symbol('call'), [], []);
  testInvocationMirror(c(37, 42), const Symbol('call'), [37, 42], []);
  testInvocationMirror(
      c(x: 42), const Symbol('call'), [], [const Symbol("x"), 42]);
  testInvocationMirror(
      c(37, x: 42), const Symbol('call'), [37], [const Symbol("x"), 42]);

  // Wrong arguments to existing function.
  testInvocationMirror(n.flif(), const Symbol("flif"), [], []);
  testInvocationMirror(n.flif(37, 42), const Symbol("flif"), [37, 42], []);
  testInvocationMirror(
      n.flif(x: 42), const Symbol("flif"), [], [const Symbol("x"), 42]);
  testInvocationMirror(
      n.flif(37, x: 42), const Symbol("flif"), [37], [const Symbol("x"), 42]);
  testInvocationMirror((n..flif = 42).last, const Symbol("flif="), [42]);

  testInvocationMirror(n.flaf(37, 42), const Symbol("flaf"), [37, 42], []);
  testInvocationMirror(
      n.flaf(x: 42), const Symbol("flaf"), [], [const Symbol("x"), 42]);
  testInvocationMirror(
      n.flaf(37, x: 42), const Symbol("flaf"), [37], [const Symbol("x"), 42]);
  testInvocationMirror((n..flaf = 42).last, const Symbol("flaf="), [42]);

  testInvocationMirror(n.flof(37, 42), const Symbol("flof"), [37, 42], []);
  testInvocationMirror(
      n.flof(x: 42), const Symbol("flof"), [], [const Symbol("x"), 42]);
  testInvocationMirror(
      n.flof(37, y: 42), const Symbol("flof"), [37], [const Symbol("y"), 42]);
  testInvocationMirror((n..flof = 42).last, const Symbol("flof="), [42]);

  // Reading works.
  Expect.isTrue(n.flif is Function);
  Expect.isTrue(n.flaf is Function);
  Expect.isTrue(n.flof is Function);

  // Writing to read-only fields.
  testInvocationMirror((n..wut = 42).last, const Symbol("wut="), [42]);
  testInvocationMirror((n..plif = 42).last, const Symbol("plif="), [42]);
  testInvocationMirror((n..plaf = 42).last, const Symbol("plaf="), [42]);

  // Trick call to n.call - wut is a getter returning n again.
  testInvocationMirror(n.wut(42), const Symbol("call"), [42], []);

  // Calling noSuchMethod itself, badly.
  testInvocationMirror(n.noSuchMethod(), const Symbol("noSuchMethod"), [], []);
  testInvocationMirror(
      n.noSuchMethod(37, 42), const Symbol("noSuchMethod"), [37, 42], []);
  testInvocationMirror(n.noSuchMethod(37, x: 42), const Symbol("noSuchMethod"),
      [37], [const Symbol("x"), 42]);
  testInvocationMirror(n.noSuchMethod(x: 42), const Symbol("noSuchMethod"), [],
      [const Symbol("x"), 42]);

  // Closurizing a method means that calling it badly will not hit the
  // original receivers noSuchMethod, only the one inherited from Object
  // by the closure object.
  Expect.throws(() {
    var x = n.flif;
    x(37, 42);
  }, (e) => e is NoSuchMethodError);
  Expect.throws(() {
    var x = c.call;
    x(37, 42);
  }, (e) => e is NoSuchMethodError);
}

class M extends N {
  testSelfCalls() {
    // Missing property/method access.
    dynamic self = this;
    testInvocationMirror(self.bar, const Symbol('bar'));
    testInvocationMirror(() {
      self.bar = 42;
      return last;
    }(), const Symbol('bar='), [42]);
    testInvocationMirror(self.bar(), const Symbol('bar'), [], []);
    testInvocationMirror(self.bar(42), const Symbol('bar'), [42], []);
    testInvocationMirror(
        self.bar(x: 42), const Symbol('bar'), [], [const Symbol("x"), 42]);
    testInvocationMirror(self.bar(37, x: 42), const Symbol('bar'), [37],
        [const Symbol("x"), 42]);

    // Missing operator access.
    testInvocationMirror(self + 4, const Symbol('+'), [4], []);
    testInvocationMirror(self - 4, const Symbol('-'), [4], []);
    testInvocationMirror(-self, const Symbol('unary-'), [], []);
    testInvocationMirror(self[42], const Symbol('[]'), [42], []);
    testInvocationMirror(() {
      self[37] = 42;
      return last;
    }(), const Symbol('[]='), [37, 42], []);

    // Wrong arguments to existing function.
    testInvocationMirror(self.flif(), const Symbol("flif"), [], []);
    testInvocationMirror(self.flif(37, 42), const Symbol("flif"), [37, 42], []);
    testInvocationMirror(
        self.flif(x: 42), const Symbol("flif"), [], [const Symbol("x"), 42]);
    testInvocationMirror(self.flif(37, x: 42), const Symbol("flif"), [37],
        [const Symbol("x"), 42]);
    testInvocationMirror(() {
      self.flif = 42;
      return last;
    }(), const Symbol("flif="), [42]);

    testInvocationMirror(self.flaf(37, 42), const Symbol("flaf"), [37, 42], []);
    testInvocationMirror(
        self.flaf(x: 42), const Symbol("flaf"), [], [const Symbol("x"), 42]);
    testInvocationMirror(self.flaf(37, x: 42), const Symbol("flaf"), [37],
        [const Symbol("x"), 42]);
    testInvocationMirror(() {
      self.flaf = 42;
      return last;
    }(), const Symbol("flaf="), [42]);

    testInvocationMirror(self.flof(37, 42), const Symbol("flof"), [37, 42], []);
    testInvocationMirror(
        self.flof(x: 42), const Symbol("flof"), [], [const Symbol("x"), 42]);
    testInvocationMirror(self.flof(37, y: 42), const Symbol("flof"), [37],
        [const Symbol("y"), 42]);
    testInvocationMirror(() {
      self.flof = 42;
      return last;
    }(), const Symbol("flof="), [42]);

    // Reading works.
    Expect.isTrue(self.flif is Function);
    Expect.isTrue(self.flaf is Function);
    Expect.isTrue(self.flof is Function);

    // Writing to read-only fields.
    testInvocationMirror(() {
      self.wut = 42;
      return last;
    }(), const Symbol("wut="), [42]);
    testInvocationMirror(() {
      self.plif = 42;
      return last;
    }(), const Symbol("plif="), [42]);
    testInvocationMirror(() {
      self.plaf = 42;
      return last;
    }(), const Symbol("plaf="), [42]);

    // Calling noSuchMethod itself, badly.
    testInvocationMirror(
        self.noSuchMethod(), const Symbol("noSuchMethod"), [], []);
    testInvocationMirror(
        self.noSuchMethod(37, 42), const Symbol("noSuchMethod"), [37, 42], []);
    testInvocationMirror(self.noSuchMethod(37, x: 42),
        const Symbol("noSuchMethod"), [37], [const Symbol("x"), 42]);
    testInvocationMirror(self.noSuchMethod(x: 42), const Symbol("noSuchMethod"),
        [], [const Symbol("x"), 42]);

    // Closurizing a method means that calling it badly will not hit the
    // original receivers noSuchMethod, only the one inherited from Object
    // by the closure object.
    Expect.throws(() {
      var x = self.flif;
      x(37, 42);
    }, (e) => e is NoSuchMethodError);
  }
}

// Test the NoSuchMethodError thrown by different incorrect calls.
testNoSuchMethodErrors() {
  test(block()) {
    Expect.throws(block, (e) => e is NoSuchMethodError);
  }

  dynamic n = new N();
  dynamic o = new Object();
  test(() => o.bar);
  test(() => o.bar = 42);
  test(() => o.bar());
  test(() => o + 2);
  test(() => -o);
  test(() => o[0]);
  test(() => o[0] = 42);
  test(() => o());
  test(() => o.toString = 42);
  test(() => o.toString(42));
  test(() => o.toString(x: 37));
  test(() => o.hashCode = 42);
  test(() => o.hashCode()); // Thrown by int.noSuchMethod.
  test(() => (n.flif)()); // Extracted method has no noSuchMethod.
}

main() {
  testInvocationMirrors();
  testNoSuchMethodErrors();
  new M().testSelfCalls();
}
