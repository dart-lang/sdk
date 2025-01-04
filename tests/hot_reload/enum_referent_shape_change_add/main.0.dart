// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2402

class Box {
  final x;
  const Box(this.x);
}

enum Fruit {
  Apple('Apple', const Box('A')),
  Banana('Banana', const Box('B')),
  Cherry('Cherry', const Box('C')),
  Durian('Durian', const Box('D')),
  Elderberry('Elderberry', const Box('E')),
  Fig('Fig', const Box('F')),
  Grape('Grape', const Box('G')),
  Huckleberry('Huckleberry', const Box('H')),
  Jackfruit('Jackfruit', const Box('J'));

  const Fruit(this.name, this.initial);
  final String name;
  final Box initial;
}

var retained;

Future<void> main() async {
  retained = Fruit.Apple;
  Expect.equals('Fruit.Apple', retained.toString());
  await hotReload();
  Expect.equals('Fruit.Apple', retained.toString());
}
