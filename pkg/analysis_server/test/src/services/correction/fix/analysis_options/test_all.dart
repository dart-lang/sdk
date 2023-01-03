// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'remove_lint_test.dart' as remove_lint;
import 'remove_setting_test.dart' as remove_setting;
import 'replace_with_strict_casts_test.dart' as replace_with_strict_casts;
import 'replace_with_strict_raw_types_test.dart'
    as replace_with_strict_raw_types;

void main() {
  defineReflectiveSuite(() {
    remove_lint.main();
    remove_setting.main();
    replace_with_strict_casts.main();
    replace_with_strict_raw_types.main();
  });
}
