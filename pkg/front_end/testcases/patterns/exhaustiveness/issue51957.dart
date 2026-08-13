// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class Sealed {}

class C1 extends Sealed {}

class C2 extends Sealed {}

void main() {
  Sealed s = C1();
  switch (s) {
    case C1():
    case C2():
  }
  print(s);
  print(switch (s) {
    C1() => 'C1',
    C2() => 'C2',
  });
}
