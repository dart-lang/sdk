// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N noop_primitive_operations`

onStringInterpolations() {
  var s = '${1.toString()}'; // LINT
}

onPrint() {
  print(''); // OK
  print(1.toString()); // LINT
  print(null.toString()); // LINT

  print(toString()); // OK
}

String toString() => '';

class Ok {
  f() {
    // Can't use 'super' as an expression
    var s = '${super.toString()}'; // OK
    print(super.toString()); // OK
  }
}

onString() {
  String? nullable;
  String v = 'hello';

  v.toString(); // LINT
  nullable.toString(); // OK

  v = 'hello\n'
      'world\n'
      ''; // LINT
}

onInt() {
  int v = 1;
  v.toInt(); // LINT
  v.round(); // LINT
  v.ceil(); // LINT
  v.floor(); // LINT
  v.truncate(); // LINT
}

onDouble() {
  double v = 1.23;
  v.toDouble(); // LINT
}
