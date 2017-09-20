// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js uses the right interceptor when call a method on
// something that has type number.

import 'package:expect/expect.dart';

var array = <dynamic>[];

main() {
  array.add(false);
  dynamic x = array[0] ? 1.5 : 2;
  Expect.isTrue(x.isEven);
}
