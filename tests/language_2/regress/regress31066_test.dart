// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

typedef Bar = int Function(int);

int defaultBar(int value) => value + 1;

class Foo {
  final Bar bar;

  const Foo._(Bar bar) : bar = bar ?? defaultBar;

  const Foo.baz({Bar bar}) : this._(bar);
}

void main() {
  final foo = const Foo.baz();
  Expect.equals(2, foo.bar(1));
}
