// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  var closure;

  factory A.factory() => new A(() => new List<T>());

  A([this.closure]) {
    if (closure == null) {
      closure = () => new List<T>();
    }
  }
}

main() {
  Expect.isTrue((new A.factory()).closure() is List);
  Expect.isTrue((new A()).closure() is List);
  Expect.isTrue((new A<int>.factory()).closure() is List<int>);
  Expect.isTrue((new A<int>()).closure() is List<int>);
  Expect.isFalse((new A<int>.factory()).closure() is List<String>);
  Expect.isFalse((new A<int>()).closure() is List<String>);
}
