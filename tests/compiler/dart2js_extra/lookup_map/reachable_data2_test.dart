// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:lookup_map/lookup_map.dart';
import 'package:expect/expect.dart';

class Key { final x; const Key(this.x); }
const A = const Key(1);
const B = const Key(2);
const C = const Key(3);
const D = const Key(4);
const E = const Key(5);
const map = const LookupMap(const [
    A, const ["the-text-for-A", B],
    B, const ["the-text-for-B", C],
    C, const ["the-text-for-C"],
    D, const ["the-text-for-D", E],
    E, const ["the-text-for-E"],
]);
main() {
  Expect.equals(map[map[A][1]][0], 'the-text-for-B');
}
