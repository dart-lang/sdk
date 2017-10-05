// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'private_access_lib.dart';
import 'private_access_lib.dart' as private;

main() {
  _function(); //# 01: compile-time error
  private._function(); //# 02: compile-time error
  new _Class(); //# 03: compile-time error
  private._Class(); //# 04: compile-time error
  new Class._constructor(); //# 05: compile-time error
  new private.Class._constructor(); //# 06: compile-time error
}
