// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test a private field name doesn't match the equivalent private name from
// another library.

library lib;

@MirrorsUsed(targets: "lib")
import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'private_class_field_other.dart';

void main() {
  var classMirror = reflectClass(C);
  // The symbol is private w/r/t the wrong library.
  Expect.throws(() => classMirror.getField(#_privateField),
      (e) => e is NoSuchMethodError);

  Expect.equals(42, classMirror.getField(privateFieldSymbolInOther).reflectee);
}
