// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:developer';

// Regression test: https://github.com/dart-lang/sdk/issues/45544

var b = true;
void main() {
  // Ensure multiple debugger calls of different varieties map to different
  // unique locations.
  print('1');
  /*s:1*/ debugger();
  print('2');
  /*s:2*/ debugger(when: b);
  print('3');
  foo(/*s:3*/ debugger());
  print('4');
  /*s:4*/ debugger(when: b);
  print('5');
  foo(/*s:5*/ debugger(when: b));
  print('6');
  /*s:6*/ debugger();
  print('7');
  foo(/*s:7*/ debugger(when: b));
  print('8');
  foo(/*s:8*/ debugger());
}

void foo(bool _) {}
