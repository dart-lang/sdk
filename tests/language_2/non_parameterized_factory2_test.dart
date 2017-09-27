// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface<T> {
  factory Interface() = Factory<T>;
  factory Interface.withArg(T value) = Factory<T>.withArg;
}

class Factory<T> implements Interface<T> {
  factory Factory() {
    return null;
  }

  factory Factory.withArg(T value) {
    return null;
  }
}

main() {
  new Interface<int>();
  new Interface<int>.withArg(4);
}
