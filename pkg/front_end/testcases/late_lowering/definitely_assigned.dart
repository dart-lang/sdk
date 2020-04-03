// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

methodDirect<T>(T value) {
  late final T local2;
  late final int local4;
  late final FutureOr<int> local6;

  local2 = value; // ok
  local4 = 0; // ok
  local6 = 0; // ok

  local2 = value; // error
  local4 = 0; // error
  local6 = 0; // error
}

var fieldDirect = <T>(T value) {
  late final T local2;
  late final int local4;
  late final FutureOr<int> local6;

  local2 = value; // ok
  local4 = 0; // ok
  local6 = 0; // ok

  local2 = value; // error
  local4 = 0; // error
  local6 = 0; // error
};

methodConditional<T>(bool b, T value) {
  late final T local2;
  late final int local4;
  late final FutureOr<int> local6;

  if (b) {
    local2 = value; // ok
    local4 = 0; // ok
    local6 = 0; // ok
  }

  local2 = value; // ok
  local4 = 0; // ok
  local6 = 0; // ok

  local2 = value; // error
  local4 = 0; // error
  local6 = 0; // error
}

var fieldConditional = <T>(bool b, T value) {
  late final T local2;
  late final int local4;
  late final FutureOr<int> local6;

  if (b) {
    local2 = value; // ok
    local4 = 0; // ok
    local6 = 0; // ok
  }

  local2 = value; // ok
  local4 = 0; // ok
  local6 = 0; // ok

  local2 = value; // error
  local4 = 0; // error
  local6 = 0; // error
};

methodCompound() {
  late final int local4;

  local4 = 0; // ok

  local4 += 0; // error
}

var fieldCompound = () {
  late final int local4;

  local4 = 0; // ok

  local4 += 0; // error
};

main() {}
