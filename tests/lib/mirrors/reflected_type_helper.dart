// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.reflected_type_helper;

import 'dart:mirrors';
import 'package:expect/expect.dart';

expectReflectedType(TypeMirror typeMirror, Type expectedType) {
  if (expectedType == null) {
    Expect.isFalse(typeMirror.hasReflectedType);
    Expect.throwsUnsupportedError(() => typeMirror.reflectedType,
        "Should not have a reflected type");
  } else {
    Expect.isTrue(typeMirror.hasReflectedType);
    Expect.equals(expectedType, typeMirror.reflectedType);
  }
}
