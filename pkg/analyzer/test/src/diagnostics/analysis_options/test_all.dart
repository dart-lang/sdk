// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'include_file_not_found_test.dart' as include_file_not_found;
import 'include_file_warning_test.dart' as include_file_warning;
import 'recursive_include_file_test.dart' as recursive_include_file;

main() {
  defineReflectiveSuite(() {
    include_file_not_found.main();
    include_file_warning.main();
    recursive_include_file.main();
  });
}
