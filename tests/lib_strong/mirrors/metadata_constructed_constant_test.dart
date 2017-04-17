// compile options: --emit-metadata
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.metadata_constructed_constant_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class ConstructedConstant {
  final value;
  const ConstructedConstant(this.value);
  toString() => 'ConstructedConstant($value)';
}

class Foo {
  @ConstructedConstant(StateError)
  m() {}
}

main() {
  var value = reflectClass(Foo).declarations[#m].metadata.single.reflectee;
  Expect.stringEquals('ConstructedConstant($StateError)', '$value');
}
