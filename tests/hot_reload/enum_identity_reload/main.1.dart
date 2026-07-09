// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2207

enum Fruit { Apple, Banana, Cantaloupe }

var x, y, z, w;

Future<void> main() async {
  x = {
    Fruit.Apple: Fruit.Apple.index,
    Fruit.Banana: Fruit.Banana.index,
    Fruit.Cantaloupe: Fruit.Cantaloupe.index,
  };
  y = Fruit.Apple;
  z = Fruit.Banana;
  w = Fruit.Cantaloupe;
  await hotReload();

  x.forEach((fruit, index) {
    Expect.identical(Fruit.values[index], fruit);
  });
  Expect.equals(x[Fruit.Apple], Fruit.Apple.index);
  Expect.equals(x[Fruit.Banana], Fruit.Banana.index);
  Expect.equals(x[Fruit.Cantaloupe], Fruit.Cantaloupe.index);
  Expect.equals(y, Fruit.values[x[Fruit.Apple]]);
  Expect.equals(z, Fruit.values[x[Fruit.Banana]]);
  Expect.equals(w, Fruit.values[x[Fruit.Cantaloupe]]);
}

/** DIFF **/
/*
*/
