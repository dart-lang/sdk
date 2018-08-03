// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/spec/check_all_test.dart' as check_spec;
import 'plugin/test_all.dart' as plugin;
import 'src/test_all.dart' as src;
import 'utilities/test_all.dart' as utilities;

main() {
  defineReflectiveSuite(() {
    plugin.main();
    src.main();
    utilities.main();
    defineReflectiveSuite(() {
      defineReflectiveTests(SpecTest);
    }, name: 'spec');
  }, name: 'analyzer_plugin');
}

@reflectiveTest
class SpecTest {
  test_specHasBeenGenerated() {
    check_spec.main();
  }
}
