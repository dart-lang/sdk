// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.superclass;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Foo<T> {
  List<T> makeList() {
    if (new DateTime.now().millisecondsSinceEpoch == 42) return [];
    return new List<T>();
  }
}

main() {
  List<String> list = new Foo<String>().makeList();
  var cls = reflectClass(list.runtimeType);
  Expect.isNotNull(cls, 'Failed to reflect on MyClass.');
}
