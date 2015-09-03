// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:lookup_map/lookup_map.dart';
import 'package:expect/expect.dart';

class A{}
class M<T>{ get type => T; }
const map = const LookupMap(const [
    A, 'the-text-for-A',
]);

main() {
  Expect.equals(map[new M<A>().type], 'the-text-for-A');
}
