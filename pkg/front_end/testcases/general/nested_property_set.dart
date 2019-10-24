// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class NumField {
  num field;
}

class IntField {
  int field;
}

class DoubleField {
  double field;
}

main() {
  IntField intField1 = new IntField();
  IntField intField2 = new IntField();
  NumField numField = new NumField();
  DoubleField doubleField = new DoubleField();

  intField1.field = intField2.field = numField.field;
  intField1.field = numField.field = intField2.field;
  try {
    numField.field = 0.5;
    intField1.field = doubleField.field = numField.field;
    throw 'Should fail';
  } catch (_) {}
}
