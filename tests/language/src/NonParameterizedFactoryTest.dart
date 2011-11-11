// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Interface<T> factory Factory {
  Interface();
  Interface.withArg(T value);
}

// A factory must be parametrized. Use legacy form.
class Factory {
  factory Interface<T>() {
    return null;
  }

  factory Interface<T>.withArg(value) {
    return null;
  }
}

main() {
  new Interface();
  new Interface.withArg(4);
}
