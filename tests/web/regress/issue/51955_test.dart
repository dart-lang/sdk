// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test uses Records with different shapes, but only in deferred libraries.

import '51955_lib1.dart' deferred as lib1;
import '51955_lib2.dart' deferred as lib2;

void main() async {
  await lib1.loadLibrary();
  print(lib1.work());
  await lib2.loadLibrary();
  print(lib2.work());
}
