// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "library10.dart";

main() {
  // Library prefixes in the imported libraries should not be visible here.
  new lib11.Library11(1); //# 01: compile-time error
  lib11.Library11.static_func(); //# 02: compile-time error
  lib11.Library11.static_fld; //# 03: compile-time error
}
