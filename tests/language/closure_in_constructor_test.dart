// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
}
