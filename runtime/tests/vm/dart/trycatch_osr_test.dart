// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that OSR gets into nested try-block correctly.
//
// VMOptions=--optimization-counter-threshold=100

import 'package:expect/expect.dart';

String s = '';

foo() {
  var x = 1;
  try {
    try {
      while (true) {
        try {
          try {
            if (x < -1) {
              print('x is negative? impossible');
            }
            while (true) {
              x += 1;
              if (x > 200) {
                throw '$x';
              }
            }
          } on String catch (e) {
            s += 'got string $e;';
          }
        } on List catch (e) {
          s += 'on List: $e;';
        }
        if (x > 200) {
          throw x / 2;
        }
      }
    } on double catch (e) {
      s += 'on double: $e;';
    }
  } on int catch (e) {
    s += 'x: $x e: $e;';
  } finally {
    s += 'and finally;';
  }
}

main() {
  foo();
  Expect.equals('got string 201;on double: 100.5;and finally;', s);
}
