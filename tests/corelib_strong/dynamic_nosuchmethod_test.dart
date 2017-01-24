// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:mirrors';

// Test that noSuchMethod calls behave as expected for dynamic object invocations.
class BaseClass {
  final dynamic finalField = "final!";

  baz() => "baz!!";
  get bla => (() => "bla!!");
}

class ReturnInvocationName extends BaseClass {
  var _bar;

  ReturnInvocationName(this._bar);

  noSuchMethod(Invocation invocation) {
    return MirrorSystem.getName(invocation.memberName);
  }

  bar() {
    return _bar;
  }
}

class Foo {}

main() {
  dynamic x = new ReturnInvocationName(42);
  Expect.equals('final!', x.finalField);

  // https://github.com/dart-lang/sdk/issues/28363
  // Expect.throws(() => x.finalField = "foo",
  //              (e) => e is NoSuchMethodError);
  Expect.equals('final!', x.finalField);

  Expect.equals('_prototype', x._prototype);
  Expect.equals('_prototype', x._prototype());

  Expect.equals('prototype', x.prototype);
  Expect.equals('prototype', x.prototype());

  Expect.equals('constructor', x.constructor);
  Expect.equals('constructor', x.constructor());

  Expect.equals('__proto__', x.__proto__);
  Expect.equals('__proto__', x.__proto__);

  Expect.equals(42, x.bar());
  Expect.equals(42, (x.bar)());

  Expect.equals('unary-', -x);
  Expect.equals('+', x + 42);
  Expect.equals('[]', x[4]);

  // Verify that noSuchMethod errors are triggered even when the JS object
  // happens to have a matching member name.
  dynamic f = new Foo();
  Expect.throws(() => f.prototype, (e) => e is NoSuchMethodError);
  Expect.throws(() => f.prototype(), (e) => e is NoSuchMethodError);
  Expect.throws(() => f.prototype = 42, (e) => e is NoSuchMethodError);

  Expect.throws(() => f.constructor, (e) => e is NoSuchMethodError);
  Expect.throws(() => f.constructor(), (e) => e is NoSuchMethodError);
  Expect.throws(() => f.constructor = 42, (e) => e is NoSuchMethodError);

  Expect.throws(() => f.__proto__, (e) => e is NoSuchMethodError);

  // These are valid JS properties but not Dart methods.
  Expect.throws(() => f.toLocaleString, (e) => e is NoSuchMethodError);

  Expect.throws(() => f.hasOwnProperty, (e) => e is NoSuchMethodError);
}
