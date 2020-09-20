// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--lazy-dispatchers
// VMOptions=--no-lazy-dispatchers

import "package:expect/expect.dart";

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
    var name = invocation.memberName.toString();
    var match = new RegExp(r'Symbol\("([^"]+)"\)').matchAsPrefix(name);
    return match != null ? match.group(1) : name;
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

  f = (int x) {};
  // Calls with the wrong number of arguments should be NoSuchMethodErrors.
  Expect.throwsNoSuchMethodError(() => f());
  Expect.throwsNoSuchMethodError(() => f('hi', '!'));
  Expect.throwsNoSuchMethodError(() => f(x: 42));
}
