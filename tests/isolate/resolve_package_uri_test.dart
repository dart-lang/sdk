// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for faulty encoding of `Isolate.resolvePackageUri` by
// dart2js.

import 'dart:async';
import 'dart:isolate';

main() {
  Future<Uri> uri = Isolate.resolvePackageUri(Uri.parse('memory:main.dart'));
  print(uri);
}
