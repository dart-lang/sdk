// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--enable-deferred-loading

import 'default_nullable_param_helper.dart' deferred as helper;
import 'package:async_helper/async_helper.dart';

helper.Base getBase(int i, String s) => i < 10 ? helper.A() : helper.B(s);

Future<void> main() async {
  asyncStart();
  await helper.loadLibrary();
  getBase(9, 'world').format('hello');
  getBase(11, 'foo').format('hey', 'world');
  getBase(11, 'foo').format('hey');
  asyncEnd();
}
