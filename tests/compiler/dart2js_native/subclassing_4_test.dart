// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:_js_helper' show Native, Creates, setNativeSubclassDispatchRecord;
import 'dart:_interceptors' show Interceptor, findInterceptorForType;

// Test calling convention on subclasses of native classes.

class M {
  miz() => 'M';
}

@Native("N")
class N {}

class A extends N {}

class B extends A with M {
  // The call to [miz] has a know type [B].  The call is in an intercepted
  // method and to an intercepted method, so the ambient interceptor can be
  // used.  For correct optimization of the interceptor, the compiler needs to
  // (1) correctly determine that B is an intercepted type (because it extends a
  // native class) and (2) realize that the intersection of [B] and subclasses
  // of mixin applications of [M] is non-empty.
  callMiz() => this.miz();
}

B makeB() native;

@Creates('=Object')
getBPrototype() native;

void setup() native r"""
function B() {}
makeB = function(){return new B;};
getBPrototype = function(){return B.prototype;};
""";

main() {
  setup();

  setNativeSubclassDispatchRecord(getBPrototype(), findInterceptorForType(B));

  B b = makeB();
  Expect.equals('M', b.callMiz());
}
