// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that generic constants can be constructed from a named factory.

import "package:expect/expect.dart";

class Optional<T> {
  final T? value;
  const Optional.absent() : value = null;
}

class Foo {
  Optional<int> value;
  Foo._(this.value);
  factory Foo.named() {
    return Foo._(const Optional.absent());
  }
}

void main() {
  var foo = Foo.named();
  Expect.equals(foo.value, const Optional<int>.absent());
  Expect.equals(foo.value.value, null);
}
