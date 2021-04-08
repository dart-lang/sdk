// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:developer';

void main() {
  print('1');
  /*sl:1*/ debugger();
  print('2');
  /*sl:2*/ debugger();
  print('3');
  foo(/*s:3*/ debugger());
  print('4');
  /*sl:4*/ debugger();
  print('5');
  foo(/*s:5*/ debugger());
  print('6');
  foo(/*s:6*/ debugger());
}

void foo(bool _) => null;
