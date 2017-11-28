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
  Expect.equals('foo', x.finalField = "foo", 'should call noSuchMethod');
  Expect.equals('final!', x.finalField, 'field was not set');

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

  dynamic b = new BaseClass();
  Expect.equals('final!', b.finalField);
  Expect.throwsNoSuchMethodError(() => b.finalField = "foo");
  Expect.equals('final!', b.finalField, 'field was not set');

  // Verify that noSuchMethod errors are triggered even when the JS object
  // happens to have a matching member name.
  dynamic f = new Foo();
  Expect.throwsNoSuchMethodError(() => f.prototype);
  Expect.throwsNoSuchMethodError(() => f.prototype());
  Expect.throwsNoSuchMethodError(() => f.prototype = 42);

  Expect.throwsNoSuchMethodError(() => f.constructor);
  Expect.throwsNoSuchMethodError(() => f.constructor());
  Expect.throwsNoSuchMethodError(() => f.constructor = 42);

  Expect.throwsNoSuchMethodError(() => f.__proto__);

  // These are valid JS properties but not Dart methods.
  Expect.throwsNoSuchMethodError(() => f.toLocaleString);

  Expect.throwsNoSuchMethodError(() => f.hasOwnProperty);
}
