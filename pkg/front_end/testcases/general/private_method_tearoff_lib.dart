// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Companion library for private_method_tearoff.dart.

class Bar {
  void _f() {}
}

void baz(Bar bar) {
  print("${bar._f.runtimeType}");
}
