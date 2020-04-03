// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library used by conditional_property_assignment_test.dart,
// conditional_property_access_test.dart, and
// conditional_method_invocation_test.dart, all of which import it using the
// prefix "h.".

library lib;

var topLevelVar;

void topLevelFunction() {}

class C {
  static int staticInt;
  static staticF(callback()) => callback();
  static int staticG(int callback()) => callback();
}

C nullC() => null;

class D {
  static E staticE;
}

class E {
  G operator +(int i) => new I();
  G operator -(int i) => new I();
}

class F {}

class G extends E implements F {}

class H {}

class I extends G implements H {}
