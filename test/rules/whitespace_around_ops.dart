// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test/util/solo_test.dart whitespace_around_ops`


// Define our own int so we don't need `int` in our mock SDK.
class MyInt {
  MyInt operator -() => this;
  MyInt operator ~() => this;
  MyInt operator ~/(MyInt other) => this;
  MyInt operator /(MyInt other) => this;
}

void main() {
  MyInt f, g;
  print(f ~/ g);
  print(f~/ g); //LINT
  print(f ~/g); //LINT
  print(f~/g); //LINT
  print(f/ ~g); //LINT
  print(f /~g); //LINT
  print(f / ~g); //OK
  f =- g; //LINT
  f = -g; //OK
}
