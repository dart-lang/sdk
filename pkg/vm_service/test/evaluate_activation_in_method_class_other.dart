// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: overridden_fields

import 'dart:developer';

var topLevel = 'OtherLibrary';

class Superclass2 {
  final _instVar = 'Superclass2';
  var instVar = 'Superclass2';
  String method() => 'Superclass2';
  static String staticMethod() => 'Superclass2';
  String suppressWarning() => _instVar;
}

class Superclass1 extends Superclass2 {
  @override
  final _instVar = 'Superclass1';
  @override
  var instVar = 'Superclass1';
  @override
  String method() => 'Superclass1';
  static String staticMethod() => 'Superclass1';

  void test() {
    // ignore: no_leading_underscores_for_local_identifiers
    final _local = 'Superclass1';
    debugger();
    // Suppress unused variable warning.
    print(_local);
  }
}
