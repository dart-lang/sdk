// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that setters cannot have defined, non-void return types.
// Note: The language specification specifies the absence of a type means
// it is dynamic, however you cannot specify dynamic.

class A {
  set foo(x) {}
  void set bar(x) {}
  dynamic set baz(x) {}
//^^^^^^^
// [analyzer] STATIC_WARNING.NON_VOID_RETURN_FOR_SETTER
  bool set bob(x) {}
//^^^^
// [analyzer] STATIC_WARNING.NON_VOID_RETURN_FOR_SETTER
//         ^^^
// [analyzer] COMPILE_TIME_ERROR.BODY_MIGHT_COMPLETE_NORMALLY
// [cfe] A non-null value must be returned since the return type 'bool' doesn't allow null.
}

main() {
  new A();
}
