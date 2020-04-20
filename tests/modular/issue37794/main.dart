// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

import 'module2.dart';
import 'module1.dart';

main() {
  const x = B();
  const y = A();
  Expect.equals('foo', x.foo);
  Expect.listEquals(['l', 'i', 's', 't'], x.list);
  Expect.equals('foo', y.foo);
  Expect.listEquals(['l', 'i', 's', 't'], y.list);
}
