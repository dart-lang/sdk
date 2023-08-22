// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {}

extension type FooBar(Foo i) implements Foo {}

extension type FooBaz(Foo i) implements Foo {}

void main() {
  final a = FooBar(Foo());
  switch (a) {
    case FooBar(i: final a):
      print("FooBar $a");
  }
}
