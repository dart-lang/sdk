// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Super<T extends num> {}
class Malbounded1 implements Super<String> {}  /// static type warning
class Malbounded2 extends Super<String> {}  /// static type warning

main() {
  bool inCheckedMode = false;
  try {
    String a = 42; /// static type warning
  } catch (e) {
    inCheckedMode = true;
  }

  var expectedError;
  if (inCheckedMode) {
  	expectedError = (e) => e is TypeError;
  } else {
  	expectedError = (e) => e is CastError;
  }

  var s = new Super<int>();
  Expect.throws(() => s as Malbounded1, expectedError);
  Expect.throws(() => s as Malbounded2, expectedError);
  Expect.throws(() => s as Super<String>, expectedError); /// static type warning
}
