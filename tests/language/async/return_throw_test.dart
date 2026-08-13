// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

Future<String> f() async {
  throw 'f';
}

Future<String> g() async {
  try {
    // Should obtain the `Future<String>`, await it, then throw.
    return f();
  } catch (e) {
    // Having caught the exception, we return a value.
    return 'g';
  }
}

void main() async {
  Expect.equals('g', await g());
}
