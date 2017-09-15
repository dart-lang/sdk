// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that dart: imports are implicitly hidden and cause warning on use.

library hidden_import;

import 'hidden_import_lib.dart';
import 'hidden_import_lib.dart' as prefix;
import 'dart:async';
import 'dart:async' as prefix;

main() {
  new Future(); //# 01: static type warning
  new prefix.Future(); //# 02: static type warning
}
