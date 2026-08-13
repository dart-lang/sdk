// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/test_helper.dart';

class Foo {}

// Prevent TFA from removing this static field to ensure the objects are kept
// alive, so the allocation stats will report them via the service api.
@pragma('vm:entry-point')
List<Foo>? foos;

void script() {
  foos = [
    Foo(),
    Foo(),
    Foo(),
  ];
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: script);
}
