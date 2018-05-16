// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'closingLabels_computer_test.dart' as closingLabels_computer_test;
import 'folding_computer_test.dart' as folding_computer_test;
import 'import_elements_computer_test.dart' as import_elements_computer_test;
import 'imported_elements_computer_test.dart'
    as imported_elements_computer_test;
import 'outline_computer_test.dart' as outline_computer_test;

main() {
  defineReflectiveSuite(() {
    closingLabels_computer_test.main();
    folding_computer_test.main();
    import_elements_computer_test.main();
    imported_elements_computer_test.main();
    outline_computer_test.main();
  });
}
