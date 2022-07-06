// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N prefer_final_locals`

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

void multiUnmutated() {
  var unmutated1 = 'hello', unmutated2 = 'world'; // LINT
  print(unmutated1);
  print(unmutated2);
}

void multiUnmutatedWithType() {
  String unmutated1 = 'hello', unmutated2 = 'world'; // LINT
  print(unmutated1);
  print(unmutated2);
}

void multiWithAMutation() {
  var mutated = 'hello', unmutated = 'unmutated'; // OK
  print(mutated);
  mutated = 'world';
  print(mutated);
  print(unmutated);
}

class Coverage {
  int testedLines = 0; // OK
}
