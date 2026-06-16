// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '' deferred as D1;
import '' deferred as D2;
import '' deferred as D1_1;
import '' deferred as D2_1;

main() async {
  print('main');

  if (opaqueTrue) {
    await D1.loadLibrary();
    D1.d1();
  } else {
    await D2.loadLibrary();
    D2.d2();
  }
}

Future d1() async {
  await D1_1.loadLibrary();
  // We can put `D1` into deferred D1_1.
  print(Foo1());
  D1_1.d1_1();
}

void d1_1() => print('d1_1');

Future d2() async {
  final future = D2_1.loadLibrary();
  // We *cannot* put `D2` into deferred D2_1.
  print(Foo2());
  await future;
  D2_1.d2_1();
}

void d2_1() => print('d2_1');

class Foo1 {
  String toString() => 'Foo1.toString';
}

class Foo2 {
  String toString() => 'Foo2.toString';
}

bool get opaqueTrue => int.parse('1') == 1;
