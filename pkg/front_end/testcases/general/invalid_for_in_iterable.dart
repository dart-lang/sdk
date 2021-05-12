// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

Iterable takesNoArg() => null;
void returnVoid() {}
int returnInt() => 42;
dynamic returnDynamic() => [];
Object returnObject() => 0;

test() {
  for (var v in takesNoArg(0)) {}
  for (var v in returnVoid()) {}
  for (var v in returnInt()) {}
  for (var v in returnDynamic()) {}
  for (var v in returnObject()) {}
  for (var v in throw '') {}
}

main() {}
