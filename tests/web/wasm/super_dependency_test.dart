// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--enable-deferred-loading

import 'super_dependency_helper2.dart' deferred as def;
import 'super_dependency_helper1.dart' as eager;

Future<void> main() async {
  eager.Eager().invoke('hello');
  eager.Eager().setter = 'world';
  await def.loadLibrary();
  def.useEager();
  def.Deferred();
}
