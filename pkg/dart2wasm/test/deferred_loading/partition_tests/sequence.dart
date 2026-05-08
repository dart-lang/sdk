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
  usedByMain();
  usedByMainD1();
  usedByMainD1D2();
  usedByMainD1D2D3();
  usedByMainD1D3();
  usedByMainD2();
  usedByMainD2D3();
  usedByMainD3();
}

Future d1() async {
  print('d1');
  await D2.loadLibrary();
  await D2.d2();
  usedByD1();
  usedByD1D2();
  usedByD1D2D3();
  usedByD1D3();
  usedByMainD1();
  usedByMainD1D2();
  usedByMainD1D2D3();
  usedByMainD1D3();
}

Future d2() async {
  print('d2');
  await D3.loadLibrary();
  D3.d3();
  usedByMainD1D2();
  usedByMainD1D2D3();
  usedByMainD2D3();
  usedByMainD2();
  usedByD1D2();
  usedByD1D2D3();
  usedByD2();
  usedByD2D3();
}

void d3() {
  print('d3');
  usedByD1D2D3();
  usedByD1D3();
  usedByD2D3();
  usedByD3();
  usedByMainD1D2D3();
  usedByMainD1D3();
  usedByMainD2D3();
  usedByMainD3();
}

void usedByMain() => print('usedByMain');
void usedByMainD1() => print('usedByMainD1');
void usedByMainD1D2() => print('usedByMainD1D2');
void usedByMainD1D2D3() => print('usedByMainD1D2D3');
void usedByMainD1D3() => print('usedByMainD1D3');
void usedByMainD2D3() => print('usedByMainD2D3');
void usedByMainD2() => print('usedByMainD2');
void usedByMainD3() => print('usedByMainD3');

void usedByD1() => print('usedByD1');
void usedByD1D2() => print('usedByD1D2');
void usedByD1D2D3() => print('usedByD1D2D3');
void usedByD1D3() => print('usedByD1D3');

void usedByD2() => print('usedByD2');
void usedByD2D3() => print('usedByD2D3');

void usedByD3() => print('usedByD3');
