// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'a.dart' deferred as a;
import 'b.dart' deferred as b;

Future<void> main() async {
  await a.loadLibrary();
  a.a();
  await b.loadLibrary();
  b.b();
}
