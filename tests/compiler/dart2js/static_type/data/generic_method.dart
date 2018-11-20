// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  T method<T>(T t) => t;
}

main() {
  genericMethod1(null);
  genericMethod2(null);
}

genericMethod1(c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c. /*invoke: String*/ method('').length;
  }
}

genericMethod2(c) {
  if (/*dynamic*/ c is! Class) return;
  /*dynamic*/ c. /*invoke: dynamic*/ method('').length;
}
