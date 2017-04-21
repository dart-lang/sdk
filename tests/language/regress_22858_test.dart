// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  var good = "good";

  f1() {
    {
      var bad = "bad";
      f2() {
        bad;
      }
    }

    Expect.equals("good", good);
    do {
      Expect.equals("good", good);
      int ugly = 0;
      f3() {
        ugly;
      }
    } while (false);
  }

  f1();
}
