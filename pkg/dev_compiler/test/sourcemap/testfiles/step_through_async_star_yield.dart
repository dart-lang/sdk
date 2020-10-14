// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() async {
  await for (var i in foobar()) {
    print(i);
  }
  print('Done!');
}

dynamic foobar() async* {
  /*bc:4*/ yield /*bc:1*/ foo() /*bc:3*/ + /*bc:2*/ bar();
  /*bc:8*/ yield /*bc:5*/ bar() /*bc:7*/ * /*bc:6*/ foo();
}

dynamic foo() {
  return 42;
}

dynamic bar() {
  return 3;
}
