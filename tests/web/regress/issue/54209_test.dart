// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Implicit uses of `foo.T` were not being registered in the local closure's
// scope. The `await for` was then trying to lookup the `Foo.T` to register it
// as the type argument to Stream. But the lookup failed because it `Foo.T`
// wasn't registered.

class A {
  Future<void> foo<T>(Stream<T> Function() f) async {
    await (() async {
      await for (var v in f()) {
        print(v);
      }
    }());
  }
}

void main() {
  A().foo<int>(() => Stream<int>.value(3));
}
