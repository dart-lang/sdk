// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Foo {}

inline class FooBar implements Foo {
  final int i;

  const FooBar(this.i);
}

inline class FooBaz implements Foo {
  final int i;

  const FooBaz(this.i);
}

void main() {
  final a = FooBar(0);
  switch (a) {
    case FooBar(i: final a):
      print("FooBar $a");
  }
}
