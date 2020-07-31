// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

// This class is inlined away.
class Class<T> {
  const Class();

  Type get type => T;
}

class A {}

@pragma('dart2js:noInline')
test(o) => Expect.notEquals('dynamic', '$o');

main() {
  test(const Class<A>().type);
}
