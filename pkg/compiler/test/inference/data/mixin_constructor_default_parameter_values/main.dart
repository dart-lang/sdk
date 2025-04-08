// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that the inferrer looks at default values for parameters in
// synthetic constructors using the correct context. If the constructor call
// to D without optional parameters is inferred using D's context, the default
// value `_SECRET` will not be visible and compilation will fail.

import 'lib.dart';

mixin Mixin {
  /*member: Mixin.foo:[exact=JSString|powerset=0]*/
  String get foo => "Mixin:$this";
}

// ignore: MIXIN_HAS_NO_CONSTRUCTORS
class D = C with Mixin;

/*member: main:[null|powerset=1]*/
main() {
  // ignore: NEW_WITH_UNDEFINED_CONSTRUCTOR
  print(new D.a(42). /*[exact=D|powerset=0]*/ foo);
  // ignore: NEW_WITH_UNDEFINED_CONSTRUCTOR
  print(new D.b(42). /*[exact=D|powerset=0]*/ foo);
  // ignore: NEW_WITH_UNDEFINED_CONSTRUCTOR
  print(new D.a(42, "overt"). /*[exact=D|powerset=0]*/ foo);
  // ignore: NEW_WITH_UNDEFINED_CONSTRUCTOR
  print(new D.b(42, b: "odvert"). /*[exact=D|powerset=0]*/ foo);
}
