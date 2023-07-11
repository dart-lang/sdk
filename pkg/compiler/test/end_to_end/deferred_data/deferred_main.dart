// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'deferred_lib1.dart' deferred as lib1;
import 'deferred_lib2.dart' deferred as lib2;

main() async {
  await lib1.loadLibrary();
  await lib2.loadLibrary();
  print(new lib1.Class1().method());
  print(new lib2.Class2().method());
}
