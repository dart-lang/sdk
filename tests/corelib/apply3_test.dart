// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test [Function.apply] on user-defined classes that implement [noSuchMethod].

import "package:expect/expect.dart";

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
  Expect.throwsNoSuchMethodError(() => Function.apply(new F(), [1, 2]));
  Expect.throwsNoSuchMethodError(() => Function.apply(new F(), [1, 2, 3]));

  Expect.throwsNoSuchMethodError(() => Function.apply(new G(), [1], {#a: 42}));

  // Test that [i] can be used to hit an existing method.
  Expect.equals(43, new H().call(1, a: 42));
  Expect.equals(43, Function.apply(new H(), [1], {#a: 42}));
}
