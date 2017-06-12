// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extending a type parameter is not allowed.

class A<T> extends T {}

main() {
  A a = new A();
}
