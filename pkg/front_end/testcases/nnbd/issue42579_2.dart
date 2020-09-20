// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  T get property => throw "A.property";
}

S foo<S>() => throw "foo";

wrap<R>(R Function() f) {}

wrap2<R>(A<R> Function() f) {}

bar() {
  A().property.unknown();
  foo().unknown();
  wrap(() => foo()..unknown());
  wrap2(() => foo()..property?.unknown());
}

main() {}
