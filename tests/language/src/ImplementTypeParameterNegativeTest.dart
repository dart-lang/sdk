// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Implementing a type parameter is not allowed.

class A<T> implements T { }

main() {
  A a = new A();
}
