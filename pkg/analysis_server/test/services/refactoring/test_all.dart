// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring;

import 'package:unittest/unittest.dart';

import 'convert_method_to_getter_test.dart' as convert_method_to_getter_test;
import 'extract_local_test.dart' as extract_local_test;
import 'extract_method_test.dart' as extract_method_test;
import 'inline_local_test.dart' as inline_local_test;
import 'inline_method_test.dart' as inline_method_test;
import 'move_file_test.dart' as move_file_test;
import 'naming_conventions_test.dart' as naming_conventions_test;
import 'rename_class_member_test.dart' as rename_class_member_test;
import 'rename_constructor_test.dart' as rename_constructor_test;
import 'rename_import_test.dart' as rename_import_test;
import 'rename_label_test.dart' as rename_label_test;
import 'rename_library_test.dart' as rename_library_test;
import 'rename_local_test.dart' as rename_local_test;
import 'rename_unit_member_test.dart' as rename_unit_member_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('refactoring', () {
    convert_method_to_getter_test.main();
    extract_local_test.main();
    extract_method_test.main();
    inline_local_test.main();
    inline_method_test.main();
    move_file_test.main();
    naming_conventions_test.main();
    rename_class_member_test.main();
    rename_constructor_test.main();
    rename_import_test.main();
    rename_label_test.main();
    rename_library_test.main();
    rename_local_test.main();
    rename_unit_member_test.main();
  });
}
