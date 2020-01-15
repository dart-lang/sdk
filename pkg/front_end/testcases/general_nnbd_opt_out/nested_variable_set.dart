// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

main() {
  int intLocal1;
  int intLocal2;
  num numLocal;
  double doubleLocal;

  intLocal1 = intLocal2 = numLocal;
  intLocal1 = numLocal = intLocal2;
  numLocal = 0.5;
  try {
    intLocal1 = doubleLocal = numLocal;
    throw 'Should fail';
  } catch (_) {}
}
