// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/22776

import "package:expect/expect.dart";

class A {}

main() {
  try {
    print(id(new Duration(milliseconds: 10)));
    print(id(3) ~/ new A());
  } catch (e) {
    print("Error '$e' ${e.runtimeType}");
  }
}

@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
id(x) => x;
