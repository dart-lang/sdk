// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'import_library_element_test.dart' as import_library_element;
import 'syntactic_scope_test.dart' as syntactic_scope;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    import_library_element.main();
    syntactic_scope.main();
  });
}
