// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '' deferred as D1;
import '' deferred as D2;
import '' deferred as D3;

void main() async {
  print('main');
  await D1.loadLibrary();
  await D1.d1();
}

Future d1() async {
  await D2.loadLibrary();
  print(D2.barConst);
}

const barConst = bar;

Future bar() async {
  await D3.loadLibrary();
  D3.baz();
}

void baz() => print('baz');
