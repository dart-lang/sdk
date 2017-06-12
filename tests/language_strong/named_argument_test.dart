// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var c1 = ({b, a}) => 'a: $a b: $b';
  var c2 = ({a, b}) => 'a: $a b: $b';

  Expect.equals('a: 2 b: 1', c1(b: 1, a: 2));
  Expect.equals('a: 1 b: 2', c1(a: 1, b: 2));

  Expect.equals('a: 2 b: 1', c2(b: 1, a: 2));
  Expect.equals('a: 1 b: 2', c2(a: 1, b: 2));
}
