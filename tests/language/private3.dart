// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for testing access to private fields.

part of PrivateOther;

class LibOther3 {
  static accessFieldA3(var a) => a.fieldA;
  static accessFieldB3(var b) => b._fieldB;
  static int c_field1b(c) => c._field1;
  static int c_field2b(c) => c._field2;
}

class AImported extends AExposed {
  AImported() : super();
  getFieldA() => fieldA;
}

class C2 extends C1 {
  int _field1;
  C2()
      : super(),
        _field1 = 99;

  field1b() => _field1;
}

class C4 extends C3 {
  int _field2;
  C4()
      : super(),
        _field2 = 1024;

  field2b() => _field2;
  field1d() => _field1;
}
