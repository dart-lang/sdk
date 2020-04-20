// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@metadata
library regress_19731;

import 'dart:mirrors';
import 'package:expect/expect.dart';

@metadata
const metadata = const Object();

class OneField {
  @metadata
  var onlyClassField;

  @metadata
  method() {}
}

@metadata
method() {}

main() {
  dynamic classMirror = reflectType(OneField);
  var classFieldNames = classMirror.declarations.values
      .where((v) => v is VariableMirror)
      .map((v) => v.simpleName)
      .toList();
  Expect.setEquals([#onlyClassField], classFieldNames);

  dynamic libraryMirror = classMirror.owner;
  var libraryFieldNames = libraryMirror.declarations.values
      .where((v) => v is VariableMirror)
      .map((v) => v.simpleName)
      .toList();
  Expect.setEquals([#metadata], libraryFieldNames);
}
