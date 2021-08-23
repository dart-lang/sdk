// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--use_slow_path

// @dart = 2.9

class RawSocketEvent {}

class Stream<T> {}

class _RawSocket extends Stream<RawSocketEvent> {
  int field1 = 512;
  int field2 = -512;

  _RawSocket() {
    blackhole(_onSubscriptionStateChange);
  }

  void _onSubscriptionStateChange<T>() {
    print("blah");
  }
}

@pragma("vm:never-inline")
blackhole(x) {}

main() {
  for (var i = 0; i < 10000000; i++) {
    blackhole(new _RawSocket());
  }
}
