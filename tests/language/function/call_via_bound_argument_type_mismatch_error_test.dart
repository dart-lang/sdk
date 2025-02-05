// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that if the target of a function expression invocation has
// a static type which is a type parameter, the type parameter is resolved to
// its bound in order to check argument types.

int testSimpleTarget<T extends int Function(int)>(T Function() createT) {
  var tValue = createT();
  return tValue('');
  //            ^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
}

int testComplexTarget<T extends int Function(int)>(T Function() createT) {
  return createT()('');
  //               ^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
}

main() {}
