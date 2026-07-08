// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=#init
// tableFilter=NoMatch
// globalFilter=loadIdModuleImportInfo
// typeFilter=NoMatch
// compilerOption=--enable-deferred-loading
// compilerOption=--no-minify

import '' deferred as D0;
import '' deferred as D0_1;
import '' deferred as D0_2;
import '' deferred as D1;
import '' deferred as D1_1;
import '' deferred as D1_2;

final bool opaqueTrue = int.parse('1') == 1;

void main() async {
  if (opaqueTrue) {
    await D0.loadLibrary();
    await D0.d0_1();
  } else {
    await D1.loadLibrary();
    await D1.d0_2();
  }
}

Future<void> d0_1() async {
  print('d0_1');
  if (opaqueTrue) {
    await D0_1.loadLibrary();
    D0_1.d0_1_1();
  } else {
    await D0_2.loadLibrary();
    D0_2.d0_1_2();
  }
}

Future<void> d0_2() async {
  print('d0_2');
  if (opaqueTrue) {
    await D1_1.loadLibrary();
    D1_1.d0_2_1();
  } else {
    await D1_2.loadLibrary();
    D1_2.d0_2_2();
  }
}

@pragma('wasm:never-inline')
void d0_1_1() {
  print('d0_1_1');
}

@pragma('wasm:never-inline')
void d0_1_2() {
  print('d0_1_2');
}

@pragma('wasm:never-inline')
void d0_2_1() {
  print('d0_2_1');
}

@pragma('wasm:never-inline')
void d0_2_2() {
  print('d0_2_2');
}
