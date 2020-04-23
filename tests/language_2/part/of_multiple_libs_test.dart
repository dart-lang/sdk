// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ambiguous_lib;

import 'of_multiple_libs_lib.dart';

part "of_multiple_libs_part.dart";

//^
// [cfe] Method not found: 'foo'.
main() {
  foo();
}
