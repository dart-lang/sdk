// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_mixin_test.dart' as assist_mixin_test;
import 'completion_mixin_test.dart' as completion_mixin_test;
import 'fix_mixin_test.dart' as fix_mixin_test;
import 'folding_mixin_test.dart' as folding_mixin_test;
import 'highlights_mixin_test.dart' as highlights_mixin_test;
import 'kythe_mixin_test.dart' as kythe_mixin_test;
import 'navigation_mixin_test.dart' as navigation_mixin_test;
import 'occurrences_mixin_test.dart' as occurrences_mixin_test;
import 'outline_mixin_test.dart' as outline_mixin_test;
import 'plugin_test.dart' as plugin_test;

main() {
  defineReflectiveSuite(() {
    assist_mixin_test.main();
    completion_mixin_test.main();
    fix_mixin_test.main();
    folding_mixin_test.main();
    highlights_mixin_test.main();
    kythe_mixin_test.main();
    navigation_mixin_test.main();
    occurrences_mixin_test.main();
    outline_mixin_test.main();
    plugin_test.main();
  }, name: 'plugin');
}
