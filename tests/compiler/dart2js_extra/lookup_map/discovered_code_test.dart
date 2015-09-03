// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:lookup_map/lookup_map.dart';
import 'package:expect/expect.dart';

class A{ A(B x);}
class B{}
class C{}
class D{}
class E{}
createA() => new A(map[B][1]());
createB() => new B();
const map = const LookupMap(const [
    A, const ["the-text-for-A", createA],
    B, const ["the-text-for-B", createB],
    C, const ["the-text-for-C"],
]);

main() {
  Expect.isTrue(map[A][1]() is A);
}
