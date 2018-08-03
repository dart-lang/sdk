// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dart/test_all.dart' as dart_all;
import 'postfix/test_all.dart' as postfix_all;
import 'statement/test_all.dart' as statement_all;

main() {
  defineReflectiveSuite(() {
    dart_all.main();
    postfix_all.main();
    statement_all.main();
  }, name: 'completion');
}
