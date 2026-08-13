// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--disable-type-inference

import 'package:expect/expect.dart';

void main() {
  final foo = Foo();
  Expect.equals('foo', foo.name);
}

final class Foo {
  late final String name = 'foo';
}
