// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_final_locals`

void badMethod() {
  var label = 'hola mundo! badMethod'; // LINT
  print(label);
}

void goodMethod() {
  final label = 'hola mundo! goodMethod'; // OK
  print(label);
}

void mutableCase() {
  var label = 'hola mundo! mutableCase'; // OK
  print(label);
  label = 'hello world';
  print(label);
}

void fn() {
  for (var i in [1, 2, 3]) { // LINT
    print(i);
  }

  for (final i in [1, 2, 3]) { // OK
    print(i);
  }

  for (var i in [1, 2, 3]) { // OK
    i += 1;
    print(i);
  }

  int j;
  for (j in [1, 2, 3]) { // OK
    print(j);
  }
}
