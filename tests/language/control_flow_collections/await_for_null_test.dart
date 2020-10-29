// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a null stream expression produces a compile error.
void main() async {
  // Null stream.
  Stream<int>? nullStream;
  var a = <int>[await for (var i in nullStream) 1];
  //                                ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] The type 'Stream<int>?' used in the 'for' loop must implement 'Stream<dynamic>' because 'Stream<int>?' is nullable and 'Stream<dynamic>' isn't.
  var b = <int, int>{await for (var i in nullStream) 1: 1};
  //                                     ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] The type 'Stream<int>?' used in the 'for' loop must implement 'Stream<dynamic>' because 'Stream<int>?' is nullable and 'Stream<dynamic>' isn't.
  var c = <int>{await for (var i in nullStream) 1};
  //                                ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] The type 'Stream<int>?' used in the 'for' loop must implement 'Stream<dynamic>' because 'Stream<int>?' is nullable and 'Stream<dynamic>' isn't.
}
