// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

var topLevel = "OtherLibrary";

class Superclass {
  var _instVar = 'Superclass';
  var instVar = 'Superclass';
  method() => 'Superclass';
  static staticMethod() => 'Superclass';
  suppress_warning() => _instVar;
}

class Klass extends Superclass {
  var _instVar = 'Klass';
  var instVar = 'Klass';
  method() => 'Klass';
  static staticMethod() => 'Klass';

  test() {
    var _local = 'Klass';
    debugger();
    // Suppress unused variable warning.
    print(_local);
  }
}
