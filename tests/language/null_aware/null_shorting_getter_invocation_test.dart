// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that when method invocation syntax is used in a
// null-shorting context, but the thing being invoked is actually a
// function-typed getter rather than a method, the static type of the invocation
// is still properly made nullable.

import '../static_type_helper.dart';

class A {
  final String Function() f;
  A(this.f);
}

class B {
  final A a;
  B(this.a);
}

test(B? b) {
  var x = b?.a.f();
  x.expectStaticType<Exactly<String?>>();
}

main() {
  test(null);
  test(B(A(() => '')));
}
