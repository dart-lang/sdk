// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that ensure that we correctly handle this reference from within the
// try/catch even if it is captured.

import 'package:expect/expect.dart';

var f;

class X {
  final String field;

  X(this.field);

  // We use toString as a selector here to make sure that it is not eligible
  // for any potential transformations which remove named parameters.
  @pragma('vm:never-inline')
  String toString({String prefix}) {
    f = () => this.field;
    try {
      return int.parse(prefix + this.field).toString();
    } catch (e) {
      return '${prefix}${this.field.length}';
    }
  }
}

void main() {
  final tests = [
    ['1', '11'],
    ['2', '22'],
    ['three', 'three5']
  ];
  for (var test in tests) {
    final input = test[0];
    final output = test[1];
    Expect.equals(output, X(input).toString(prefix: input));
    Expect.equals(input, f());
  }

  try {
    f().toString(); // to have an invocation of toString from dynamic context.
  } catch (e) {}
}
