// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for failure caused by refactoring of handling of scope info
// locals map in the ssa locals handler.

class Class {
  static const list = [];
  var field = {for (final key in list) key: null};

  Class(parameter) {
    parameter;
  }
}

main() {
  new Class(null);
}
