// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js where [List.addAll] was not typed
// correctly.

import "package:expect/expect.dart";

import 'dart:collection';

class MyIterable extends IterableBase {
  get iterator => [].iterator;
}

main() {
  Expect.isTrue(([]..addAll(new MyIterable())).isEmpty);
}
