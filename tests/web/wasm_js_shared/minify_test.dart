// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--minify
// dart2wasmOptions=--minify

import 'package:expect/expect.dart';
import 'package:expect/config.dart';

void main() {
  // This test is specific to testing dart2wasm & dart2js.
  if (!isDart2jsConfiguration && !isDart2WasmConfiguration) return;

  final obj = int.parse('1') == 1 ? Foo<Bar>() : Foo<Baz>();
  final runtimeType = obj.runtimeType.toString();
  final match = RegExp(r'^minified:[A-Za-z0-9]+<minified:[A-Za-z0-9]+>$')
      .matchAsPrefix(runtimeType);
  Expect.isNotNull(
      match,
      'Foo<Bar>().runtimeType should have format '
      'minified:XXX<minified:YYY> but was $runtimeType');
  Expect.isTrue(obj.isT(Bar()));
  Expect.isTrue(!obj.isT(Baz()));
}

class Foo<T> {
  bool isT(Object obj) => obj is T;
}

class Bar {}

class Baz {}
