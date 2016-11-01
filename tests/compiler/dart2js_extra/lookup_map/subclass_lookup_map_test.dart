// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:lookup_map/lookup_map.dart';
import 'package:expect/expect.dart';

class A {}

class B {}

class S extends LookupMap {
  const S(list) : super(list);
}

const map = const S(const [
  A,
  "the-text-for-A",
  B,
  "the-text-for-B",
]);

main() {
  Expect.equals(map[A], "the-text-for-A");
}
