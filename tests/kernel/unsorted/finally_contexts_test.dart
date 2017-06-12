// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Test that the context depth is correct in the presence of control flow,
// specifically branching and joining in the presence of break.  The
// implementation uses the context depth after the else block of an if/then/else
// as the context depth at the join point.  This test has an extra context
// allocated in the (untaken) else branch so it tests that compiling the
// (untaken) break properly tracks the context depth.

test(list) {
  // The loops force creation of a new context, otherwise context allocated
  // variables might be hoisted to an outer context.
  do {
    if (list.length > 1) {
      do {
        var sum = 0;
        addem() {
          for (var x in list) sum += x;
        }

        addem();
        Expect.isTrue(sum == 15);
        L:
        if (sum != 15) {
          // Unreachable.
          do {
            var product = 1;
            multiplyem() {
              for (var x in list) product *= x;
            }

            multiplyem();
            Expect.isTrue(false);
            break L;
          } while (false);
        }
      } while (false);
    }
  } while (false);
  Expect.isTrue(list.length == 5);
}

main() {
  test([1, 2, 3, 4, 5]);
}
