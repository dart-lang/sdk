// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  Expect.equals(test(5), 'a');
  Expect.equals(test(10), 'a through b');
  Expect.equals(test(7), 'b');
}

String test(int i) {
  switch (i) {
    a:
    case 5:
      {
        if (i == 10) {
          return 'a through b';
        }
        if (i == 0) {
          return 'a';
        }
        i -= 1;
        continue a; // backward jump to non-default self
      }

    b:
    default:
      {
        if (i == 10) {
          continue a; // backward jump to non-default
        }
        if (i == 0) {
          return 'b';
        }
        i -= 1;
        continue b; // backward jump to default
      }
  }
}
