// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Regression test for http://dartbug.com/51179
//
// The derived class constructor tear-off should inherit default values of
// optional arguments. The generated code does not default optional arguments
// correctly, providing `null` instead of `'default value'`.

class Base {
  String? s0;
  String? s1;

  Base({this.s0, this.s1});
}

class Derived extends Base {
  Derived({super.s0, super.s1 = 'default value'});
}

void main(List<String> arguments) {
  Function f = Derived.new;
  Derived a = Function.apply(f, [], {Symbol('s0'): 's0 from args'});

  print('a.s0 = ${a.s0}');
  print('a.s1 = ${a.s1}');

  Expect.equals('s0 from args', a.s0);
  Expect.equals('default value', a.s1); // In #51179 this is incorrect: `null`.
}
