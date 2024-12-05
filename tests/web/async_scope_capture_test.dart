// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  bool disposed = false;

  void dispose() {
    if (disposed) throw 'Used disposed foo';
    disposed = true;
  }
}

Future<void> main() async {
  List<Function> callbacks = [];
  for (final x in [1, 2]) {
    final Foo foo = Foo();
    callbacks.add(() {
      // This closure should capture the foo from this loop iteration and only
      // dispose each one once.
      foo.dispose();
    });
  }
  for (final callback in callbacks) {
    callback();
  }
}
