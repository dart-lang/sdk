// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/160137.
// Verifies that TFA correctly retains library if it only has an extension
// type declaration.

import 'regress_flutter160137.lib.dart';

class Class {
  void procedure() {
    Helper helper = new Helper();
    if (helper.instance != null) {
      print("hello");
    }
  }
}

class Helper {
  Helper();
  MyExtensionType? get instance {
    return null;
  }
}

void main() {
  Class c = new Class();
  c.procedure();
}
