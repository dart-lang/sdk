// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

foo() {
  try {
    try {
      return 1;
    } catch (e1) {} finally {
      return 3;
    }
  } catch (e2) {} finally {
    return 5;
  }
}

main() {
  Expect.equals(5, foo());
}
