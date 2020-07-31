// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library c;

import 'b.dart' as b;
import 'f.dart' deferred as f;

c() async {
  print("C");
  await f.loadLibrary();
  return f.f();
}
