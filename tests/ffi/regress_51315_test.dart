// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization-counter-threshold=100

import 'dart:ffi';

import "package:ffi/ffi.dart";

main(List<String> arguments) {
  for (int i = 0; i < 1000; i++) {
    testCompoundLoadAndStore();
  }
  print('done');
}

const count = 10;

testCompoundLoadAndStore() {
  final foos = calloc<Foo>(count);
  final reference = foos.ref;
  reference.a = count;

  for (var j = 1; j < count; j++) {
    final foo = foos + j;
    foo.ref = reference;
  }

  calloc.free(foos);
}

final class Foo extends Struct {
  @Int8()
  external int a;
}
