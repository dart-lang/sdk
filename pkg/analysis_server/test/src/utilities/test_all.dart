// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'extensions/test_all.dart' as extensions;
import 'flutter_test.dart' as flutter_test;
import 'import_analyzer_test.dart' as import_analyzer;
import 'profiling_test.dart' as profiling_test;
import 'selection_test.dart' as selection_test;
import 'strings_test.dart' as strings_test;

void main() {
  defineReflectiveSuite(() {
    extensions.main();
    flutter_test.main();
    import_analyzer.main();
    profiling_test.main();
    selection_test.main();
    strings_test.main();
  });
}
