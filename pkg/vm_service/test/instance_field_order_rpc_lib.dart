// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

class Super {
  // Make sure these fields are not removed by the tree shaker.
  @pragma('vm:entry-point')
  final z = 1;
  @pragma('vm:entry-point')
  final y = 2;
}

class Sub extends Super {
  @override
  @pragma('vm:entry-point')
  // ignore: overridden_fields
  final y = 3;
  @pragma('vm:entry-point')
  final x = 4;
}

@pragma('vm:entry-point')
Sub getSub() => Sub();

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest();
}
