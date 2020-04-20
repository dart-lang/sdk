// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

Map<String, num> map = {'a': 1};

main() {
  var exception;
  try {
    print((map['b'] > 82) ? 'x' : 'y');
  } catch (e, s) {
    exception = e;
  }
  Expect.isTrue(exception is NoSuchMethodError);
}
