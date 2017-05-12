// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'change_builder/test_all.dart' as change_builder;
import 'string_utilities_test.dart' as string_utilities;

main() {
  defineReflectiveSuite(() {
    change_builder.main();
    string_utilities.main();
  }, name: 'utilities');
}
