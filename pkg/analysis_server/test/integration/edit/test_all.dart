// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'format_test.dart' as format_test;
import 'organize_directives_test.dart' as organize_directives_test;
import 'sort_members_test.dart' as sort_members_test;

main() {
  defineReflectiveSuite(() {
    format_test.main();
    organize_directives_test.main();
    sort_members_test.main();
  }, name: 'edit');
}
