// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: library_private_types_in_public_api

import 'dart:typed_data';
import '../common/test_helper.dart';

const MB = 1 << 20;

class _TestClass {
  _TestClass(this.x, this.y);
  // Make sure these fields are not removed by the tree shaker.
  @pragma('vm:entry-point')
  dynamic x;
  @pragma('vm:entry-point')
  dynamic y;
}

@pragma('vm:entry-point')
late _TestClass myVar;

@pragma('vm:entry-point')
_TestClass invoke1() => myVar = _TestClass(null, null);

@pragma('vm:entry-point')
_TestClass invoke2() => myVar = _TestClass(_TestClass(null, null), null);

@pragma('vm:entry-point')
_TestClass invoke3() => myVar = _TestClass(WeakReference(Uint8List(MB)), null);

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest();
}
