// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var global;

class Super {
  var superField;
}

class Class extends Super {
  var instanceField;
  static var staticField;

  method(o, parameter) {
    var local;
    (local, // Ok
        parameter, // Ok
        global, // Error
        superField, // Error
        instanceField, // Error
        staticField // Error
    ) = o;
  }
}