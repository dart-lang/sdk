// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

methodDirect<T>(T value) {
  T local1;
  late T local2;
  int local3;
  late int local4;
  FutureOr<int> local5;
  late FutureOr<int> local6;
  late T local7 = value;

  local1; // error
  local2; // error
  local3; // error
  local4; // error
  local5; // error
  local6; // error
  local7; // ok
}

var fieldDirect = <T>(T value) {
  T local1;
  late T local2;
  int local3;
  late int local4;
  FutureOr<int> local5;
  late FutureOr<int> local6;
  late T local7 = value;

  local1; // error
  local2; // error
  local3; // error
  local4; // error
  local5; // error
  local6; // error
  local7; // ok
};

methodConditional<T>(bool b, T value) {
  T local1;
  late T local2;
  int local3;
  late int local4;
  FutureOr<int> local5;
  late FutureOr<int> local6;
  late T local7 = value;

  if (b) {
    local1 = value;
    local2 = value;
    local3 = 0;
    local4 = 0;
    local5 = 0;
    local6 = 0;
    local7 = value;
  }

  local1; // error
  local2; // ok
  local3; // error
  local4; // ok
  local5; // error
  local6; // ok
  local7; // ok
}

var fieldConditional = <T>(bool b, T value) {
  T local1;
  late T local2;
  int local3;
  late int local4;
  FutureOr<int> local5;
  late FutureOr<int> local6;
  late T local7 = value;

  if (b) {
    local1 = value;
    local2 = value;
    local3 = 0;
    local4 = 0;
    local5 = 0;
    local6 = 0;
    local7; // ok
  }

  local1; // error
  local2; // ok
  local3; // error
  local4; // ok
  local5; // error
  local6; // ok
  local7; // ok
};

methodCompound() {
  int local3;
  late int local4;

  local3 += 0; // error
  local4 += 0; // error
}

var fieldCompound = () {
  int local3;
  late int local4;

  local3 += 0; // error
  local4 += 0; // error
};

main() {}
