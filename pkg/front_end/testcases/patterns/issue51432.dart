// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method() {
  int v1 = 42;
  (v1) = ("The string!") as dynamic;
  print(v1); // The string!
  print(v1.runtimeType); // String
}

main() {
  throws(() => method());
}

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Missing exception';
}
