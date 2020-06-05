// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

void main() {
  print(3);
  print(4);
  if (true) {
    print('hest');
  }
  if (false) {
    print('hest');
  } else {
    print('fisk');
  }
  int foo() {}
  int i = 0;

  for (int j = 0; j < 10; j += 1) {
    print('kat');
  }

  if (false) throw;

  if (false) throw 'dwarf';
}
