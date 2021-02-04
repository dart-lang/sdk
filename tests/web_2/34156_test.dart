// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

@pragma('dart2js:tryInline')
// This function should not be inlined. Multiple returns and try-catch cannot
// currently be inlined correctly.
method() {
  try {
    thrower();
    return 'x';
  } catch (e) {
    print(e);
    return 'y';
  }
  return 'z';
}

thrower() {
  if (g) throw 123;
}

var g;
main() {
  g = false;
  var x1 = method();
  Expect.equals('x', x1);

  g = true;
  var x2 = method();
  Expect.equals('y', x2);
}
