// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test illustrates the error scenario described in
// https://github.com/dart-lang/sdk/issues/45551

class C {}

extension on C {
  void Function() get call => () {};
}

test(C c) {
  c();
//^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
// ^
// [cfe] Cannot invoke an instance of 'C' because it declares 'call' to be something other than a method.
}

main() {}
