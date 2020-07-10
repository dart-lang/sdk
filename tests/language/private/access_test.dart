// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'access_lib.dart';
import 'access_lib.dart' as private;

main() {
  _function();
//^^^^^^^^^
// [analyzer] STATIC_TYPE_WARNING.UNDEFINED_FUNCTION
// [cfe] Method not found: '_function'.
  private._function();
//^
// [cfe] Method not found: '_function'.
//        ^^^^^^^^^
// [analyzer] STATIC_TYPE_WARNING.UNDEFINED_FUNCTION
  new _Class();
  //  ^^^^^^
  // [analyzer] STATIC_WARNING.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: '_Class'.
  private._Class();
//^
// [cfe] Method not found: '_Class'.
//        ^^^^^^
// [analyzer] STATIC_TYPE_WARNING.UNDEFINED_FUNCTION
  new Class._constructor();
  //        ^^^^^^^^^^^^
  // [analyzer] STATIC_WARNING.NEW_WITH_UNDEFINED_CONSTRUCTOR
  // [cfe] Method not found: 'Class._constructor'.
  new private.Class._constructor();
  //                ^^^^^^^^^^^^
  // [analyzer] STATIC_WARNING.NEW_WITH_UNDEFINED_CONSTRUCTOR
  // [cfe] Method not found: 'Class._constructor'.
}
