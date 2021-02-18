// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9
final int field = 42;
void set field(int value) {}

class Class {
  final int field = 42;
  void set field(int value) {}
}

main() {
  field = field;
  var c = new Class();
  c.field = field;
}
