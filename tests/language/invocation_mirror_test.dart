// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// InvocationMirror and noSuchMethod testing.

/** Class with noSuchMethod that returns the mirror */
class N {
  // Storage for the last argument to noSuchMethod.
  // Needed for setters, which don't evaluate to the return value.
  var last;
  noSuchMethod(InvocationMirror m) => last = m;

  get wut => this;

  flif(int x) { Expect.fail("never get here"); }
  flaf([int x]) { Expect.fail("never get here"); }
  flof({int y}) { Expect.fail("never get here"); }

  final int plif = 99;
  int get plaf { Expect.fail("never get here"); return 0; }
}

/** As [N] but also implements 'call', so we can call it with wrong arguments.*/
class C extends N {
  call(int x) { Expect.fail("never get here"); }
}

/**
 * Checks the data of an InvocationMirror.
 *
 * Call without optionals for getters, with only positional for setters,
 * and with both optionals for everything else.
 */
testInvocationMirror(InvocationMirror im, String name,
                     [List positional, Map named]) {
  Expect.isTrue(im is InvocationMirror, "is InvocationMirror");
  Expect.equals(name, im.memberName, "name");
  if (named == null) {
    Expect.isTrue(im.isAccessor, "$name:isAccessor");
    Expect.isFalse(im.isMethod, "$name:isMethod");
    if (positional == null) {
      Expect.isTrue(im.isGetter, "$name:isGetter");
      Expect.isFalse(im.isSetter, "$name:isSetter");
      Expect.equals(null, im.positionalArguments, "$name:positional");
      Expect.equals(null, im.namedArguments, "$name:named");
      return;
    }
    Expect.isTrue(im.isSetter, "$name:isSetter");
    Expect.isFalse(im.isGetter, "$name:isGetter");
    Expect.equals(1, im.positionalArguments.length, "$name:#positional");
    Expect.equals(positional[0], im.positionalArguments[0],
                  "$name:positional[0]");
    Expect.equals(null, im.namedArguments, "$name:named");
    return;
  }
  Expect.isTrue(im.isMethod, "$name:isMethod");
  Expect.isFalse(im.isAccessor, "$name:isAccessor");
  Expect.isFalse(im.isSetter, "$name:isSetter");
  Expect.isFalse(im.isGetter, "$name:isGetter");

  Expect.equals(positional.length, im.positionalArguments.length);
  for (int i = 0; i < positional.length; i++) {
    Expect.equals(positional[i], im.positionalArguments[i],
                  "$name:positional[$i]");
  }
  Expect.equals(named.length, im.namedArguments.length, "$name:#named");
  named.forEach((k, v) {
    Expect.isTrue(im.namedArguments.containsKey(k), "$name:?named[$k]");
    Expect.equals(v, im.namedArguments[k], "$name:named[$k]");
  });
}


// Test different ways that noSuchMethod can be called.
testInvocationMirrors() {
  var n = new N();
  var c = new C();

  // Missing property/method access.
  testInvocationMirror(n.bar, 'bar');
  testInvocationMirror((n..bar = 42).last, 'bar=', [42]);
  testInvocationMirror(n.bar(), 'bar', [], {});
  testInvocationMirror(n.bar(42), 'bar', [42], {});
  testInvocationMirror(n.bar(x: 42), 'bar', [], {"x": 42});
  testInvocationMirror(n.bar(37, x: 42), 'bar', [37], {"x": 42});
  testInvocationMirror((n.bar)(), 'bar', [], {});
  testInvocationMirror((n.bar)(42), 'bar', [42]);
  testInvocationMirror((n.bar)(x: 42), 'bar', [], {"x": 42});
  testInvocationMirror((n.bar)(37, x: 42), 'bar', [37], {"x": 42});

  // Missing operator access.
  testInvocationMirror(n + 4, '+', [4], {});
  testInvocationMirror(n - 4, '-', [4], {});
  testInvocationMirror(-n, '-', [], {});
  testInvocationMirror(n[42], '[]', [42], {});
  testInvocationMirror((n..[37] = 42).last, '[]=', [37, 42], {});

  // Calling as function when it's not.
  testInvocationMirror(n(), 'call', [], {});
  testInvocationMirror(n(42), 'call', [42], {});
  testInvocationMirror(n(x: 42), 'call', [], {"x": 42});
  testInvocationMirror(n(37, x: 42), 'call', [37], {"x": 42});

  // Calling with arguments not matching existing call method.
  testInvocationMirror(c(), 'call', [], {});
  testInvocationMirror(c(37, 42), 'call', [37, 42], {});
  testInvocationMirror(c(x: 42), 'call', [], {"x": 42});
  testInvocationMirror(c(37, x: 42), 'call', [37], {"x": 42});

  // Wrong arguments to existing function.
  testInvocationMirror(n.flif(), "flif", [], {});
  testInvocationMirror(n.flif(37, 42), "flif", [37, 42], {});
  testInvocationMirror(n.flif(x: 42), "flif", [], {"x": 42});
  testInvocationMirror(n.flif(37, x: 42), "flif", [37], {"x": 42});
  testInvocationMirror((n..flif = 42).last, "flif=", [42]);

  testInvocationMirror(n.flaf(37, 42), "flaf", [37, 42], {});
  testInvocationMirror(n.flaf(x: 42), "flaf", [], {"x": 42});
  testInvocationMirror(n.flaf(37, x: 42), "flaf", [37], {"x": 42});
  testInvocationMirror((n..flaf = 42).last, "flaf=", [42]);

  testInvocationMirror(n.flof(37, 42), "flof", [37, 42], {});
  testInvocationMirror(n.flof(x: 42), "flof", [], {"x": 42});
  testInvocationMirror(n.flof(37, y: 42), "flof", [37], {"y": 42});
  testInvocationMirror((n..flof = 42).last, "flof=", [42]);

  // Reading works.
  Expect.isTrue(n.flif is Function);
  Expect.isTrue(n.flaf is Function);
  Expect.isTrue(n.flof is Function);

  // Writing to read-only fields.
  testInvocationMirror((n..wut = 42).last, "wut=", [42]);
  testInvocationMirror((n..plif = 42).last, "plif=", [42]);
  testInvocationMirror((n..plaf = 42).last, "plaf=", [42]);

  // Trick call to n.call - wut is a getter returning n again.
  testInvocationMirror(n.wut(42), "call", [42], {});

  // Closurizing a method means that calling it badly will not hit the
  // original receivers noSuchMethod, only the one inherited from Object
  // by the closure object.
  Expect.throws(() { var x = n.flif; x(37, 42); },
                (e) => e is NoSuchMethodError);
  Expect.throws(() { var x = c.call; x(37, 42); },
                (e) => e is NoSuchMethodError);
}

// Test the NoSuchMethodError thrown by different incorrect calls.
testNoSuchMethodErrors() {
  test(Function block) {
    Expect.throws(block, (e) => e is NoSuchMethodError);
  }

  var o = new Object();
  test(() => o.bar);
  test(() => o.bar = 42);
  test(() => o.bar());
  test(() => o.toString = 42);
  test(() => o.toString(42));
  test(() => o.toString(x: 37));
  test(() => o.hashCode = 42);
  test(() => o.hashCode());  // Thrown by int.noSuchMethod.
  test(() => o());
}

main() {
  testInvocationMirrors();
  testNoSuchMethodErrors();
}
