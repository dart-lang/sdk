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
  call(_, {a});
  noSuchMethod(Invocation invocation) => invocation;
}

class H {
  call(required, {a}) => required + a;
}

void main() {
  Expect.equals('call', Function.apply(F().call, []));
  Expect.equals('call', Function.apply(F().call, [1]));
  Expect.throwsNoSuchMethodError(() => Function.apply(F().call, [1, 2]));
  Expect.throwsNoSuchMethodError(() => Function.apply(F().call, [1, 2, 3]));

  const symbol = #a;
  var positionalArguments = <Object?>[1];
  var namedArguments = <Symbol, int>{symbol: 42};
  Invocation i = Function.apply(G().call, positionalArguments, namedArguments);

  Expect.equals(#call, i.memberName);
  Expect.listEquals(positionalArguments, i.positionalArguments);
  Expect.mapEquals(namedArguments, i.namedArguments);
  Expect.isTrue(i.isMethod);
  Expect.isFalse(i.isGetter);
  Expect.isFalse(i.isSetter);
  Expect.isFalse(i.isAccessor);

  // Check that changing the passed list and map for parameters does
  // not affect [i].
  positionalArguments[0] = 42;
  namedArguments[symbol] = 12;
  Expect.listEquals([1], i.positionalArguments);
  Expect.mapEquals({symbol: 42}, i.namedArguments);

  // Check that delegating [i] to [G] yields equivalent [Invocation]
  // object.
  var mirror = reflect(G());
  Invocation other = mirror.delegate(i);
  Expect.equals(i.memberName, other.memberName);
  Expect.listEquals(i.positionalArguments, other.positionalArguments);
  Expect.mapEquals(i.namedArguments, other.namedArguments);
  Expect.equals(i.isMethod, other.isMethod);
  Expect.equals(i.isGetter, other.isGetter);
  Expect.equals(i.isSetter, other.isSetter);
  Expect.equals(i.isAccessor, other.isAccessor);

  // Test that [i] can be used to hit an existing method.
  Expect.equals(43, H().call(1, a: 42));
  Expect.equals(43, Function.apply(H().call, [1], {symbol: 42}));
  mirror = reflect(H());
  Expect.equals(43, mirror.delegate(i));
  Expect.equals(43, mirror.delegate(other));
}
