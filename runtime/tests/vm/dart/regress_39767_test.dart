// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.7

// VMOptions=--optimization_counter_threshold=1 --deterministic

// Regression test for https://github.com/dart-lang/sdk/issues/39767.
//
// Verifies that pushing now-dead definitions as call arguments where the
// PushArgumentInstrs end up outliving the original call in the IL due to
// environmental uses do not remain after dead code elimination removes their
// definitions.

List<double> var25 = List<double>.filled(8, 0);

double foo0(){
    do {
      throw {}; //# 01: runtime error
    } while (false);
}

main() {
      do {
        switch (1){
          case 1: {
                var25[7] = foo0();
          }
        }
      } while (false);
}
