// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion/test_all.dart' as completion_all;
import 'correction/test_all.dart' as correction_all;
import 'linter/test_all.dart' as linter_all;
import 'refactoring/test_all.dart' as refactoring_all;
import 'search/test_all.dart' as search_all;

main() {
  defineReflectiveSuite(() {
    completion_all.main();
    correction_all.main();
    linter_all.main();
    refactoring_all.main();
    search_all.main();
  });
}
