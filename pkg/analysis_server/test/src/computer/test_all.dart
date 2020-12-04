// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'closing_labels_computer_test.dart' as closing_labels_computer;
import 'folding_computer_test.dart' as folding_computer;
import 'highlights_computer_test.dart' as highlights_computer;
import 'import_elements_computer_test.dart' as import_elements_computer;
import 'imported_elements_computer_test.dart' as imported_elements_computer;
import 'outline_computer_test.dart' as outline_computer;

void main() {
  defineReflectiveSuite(() {
    closing_labels_computer.main();
    folding_computer.main();
    highlights_computer.main();
    import_elements_computer.main();
    imported_elements_computer.main();
    outline_computer.main();
  });
}
