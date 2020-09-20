// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library f;

import 'g.dart' deferred as g;
import 'i.dart' deferred as i;

f() async {
  print("F");
  await g.loadLibrary();
  return g.g();
  await i.loadLibrary();
  return i.i();
}
