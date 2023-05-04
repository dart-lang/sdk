// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'extensions/test_all.dart' as extensions;
import 'flutter_test.dart' as flutter;
import 'import_analyzer_test.dart' as import_analyzer;
import 'profiling_test.dart' as profiling;
import 'selection_coverage_test.dart' as selection_coverage;
import 'selection_test.dart' as selection;
import 'strings_test.dart' as strings;

void main() {
  defineReflectiveSuite(() {
    extensions.main();
    flutter.main();
    import_analyzer.main();
    profiling.main();
    selection_coverage.main();
    selection.main();
    strings.main();
  });
}
