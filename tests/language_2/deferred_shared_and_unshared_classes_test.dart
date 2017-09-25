// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "deferred_shared_and_unshared_classes_lib1.dart" deferred as lib1;
import "deferred_shared_and_unshared_classes_lib2.dart" deferred as lib2;
import "dart:async";

void main() {
  asyncTest(() {
    return Future.wait([
      lib1.loadLibrary().then((_) {
        lib1.foo();
      }),
      lib2.loadLibrary().then((_) {
        lib2.foo();
      })
    ]);
  });
}
