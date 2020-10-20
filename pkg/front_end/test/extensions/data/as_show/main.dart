// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[lib.dart.Extension1,origin.dart.Extension2]*/

import 'lib.dart' as lib1;
import 'lib.dart' show Extension1;

// ignore: uri_does_not_exist
import 'dart:test' as lib2;
// ignore: uri_does_not_exist
import 'dart:test' show Extension2;

main() {
  0.method1();
  Extension1(0).method1();
  "".method2();
  Extension2("").method2();
}
