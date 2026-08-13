// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This script is used by tests in `test/dap_handler_test.dart`.

import 'dart:developer';

void main() async {
  final myInstance = MyClass('myFieldValue');
  debugger();
  print(myInstance);
}

class MyClass {
  final String myField;

  MyClass(this.myField);

  @override
  String toString() => 'MyClass';
}
