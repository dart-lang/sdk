// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import '61833_helper.dart' deferred as d;

final String localStr = 'hello';

Future<void> main() async {
  asyncStart();
  await d.loadLibrary();

  // Don't use 'Expect' APIs since constants have to be direct
  // inputs to the operators being tested.
  Expect.isTrue(d.str == localStr);
  Expect.isTrue(identical(d.str, localStr));
  Expect.isTrue(d.nullBool ?? true);
  d.foo();
  asyncEnd();
}
