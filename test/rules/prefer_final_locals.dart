// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test/util/solo_test.dart prefer_final_locals`

void badMethod() {
  var label = 'hola mundo! badMethod'; // LINT
  print(label);
}

void goodMethod() {
  final label = 'hola mundo! goodMethod';
  print(label);
}

void mutableCase() {
  var label = 'hola mundo! mutableCase';
  print(label);
  label = 'hello world';
  print(label);
}
