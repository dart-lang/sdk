// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test [Function.apply] on user-defined classes that implement [noSuchMethod].

import "package:expect/expect.dart";
import 'dart:mirrors';

class F {
  call([p1]) => "call";
  noSuchMethod(Invocation invocation) => "NSM";
}

class G {
  call() => '42';
  noSuchMethod(Invocation invocation) => invocation;
}

class H {
  call(required, {a}) => required + a;
}

main() {
  Expect.equals('call', Function.apply(new F(), []));
  Expect.equals('call', Function.apply(new F(), [1]));
  Expect.equals('NSM', Function.apply(new F(), [1, 2]));
  Expect.equals('NSM', Function.apply(new F(), [1, 2, 3]));

  var symbol = const Symbol('a');
  var requiredParameters = [1];
  var optionalParameters = new Map()..[symbol] = 42;
  Invocation i =
      Function.apply(new G(), requiredParameters, optionalParameters);

  Expect.equals(const Symbol('call'), i.memberName);
  Expect.listEquals(requiredParameters, i.positionalArguments);
  Expect.mapEquals(optionalParameters, i.namedArguments);
  Expect.isTrue(i.isMethod);
  Expect.isFalse(i.isGetter);
  Expect.isFalse(i.isSetter);
  Expect.isFalse(i.isAccessor);

  // Check that changing the passed list and map for parameters does
  // not affect [i].
  requiredParameters[0] = 42;
  optionalParameters[symbol] = 12;
  Expect.listEquals([1], i.positionalArguments);
  Expect.mapEquals(new Map()..[symbol] = 42, i.namedArguments);

  // Check that using [i] for invocation yields the same [Invocation]
  // object.
  var mirror = reflect(new G());
  Invocation other = mirror.delegate(i);
  Expect.equals(i.memberName, other.memberName);
  Expect.listEquals(i.positionalArguments, other.positionalArguments);
  Expect.mapEquals(i.namedArguments, other.namedArguments);
  Expect.equals(i.isMethod, other.isMethod);
  Expect.equals(i.isGetter, other.isGetter);
  Expect.equals(i.isSetter, other.isSetter);
  Expect.equals(i.isAccessor, other.isAccessor);

  // Test that [i] can be used to hit an existing method.
  Expect.equals(43, new H().call(1, a: 42));
  Expect.equals(43, Function.apply(new H(), [1], new Map()..[symbol] = 42));
  mirror = reflect(new H());
  Expect.equals(43, mirror.delegate(i));
  Expect.equals(43, mirror.delegate(other));
}
