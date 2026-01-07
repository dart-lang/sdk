// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsMapTest);
  });
}

@reflectiveTest
class AnalysisOptionsMapTest with ResourceProviderMixin {
  var map = AnalysisOptionsMap();

  test_nestedOptions() {
    var rootOptions = AnalysisOptionsImpl();
    var rootFolder = newFolder('/home/test');
    map[rootFolder] = rootOptions;

    var nestedOptions = AnalysisOptionsImpl();
    var nestedFolder = newFolder('/home/test/example');
    map[nestedFolder] = nestedOptions;

    var rootFile = newFile('/home/test/a.dart', '');
    var nestedFile = newFile('/home/test/example/a.dart', '');
    expect(map[rootFile], rootOptions);
    expect(map[nestedFile], nestedOptions);
  }

  test_noOptions() {
    var file = newFile('/home/test/a.dart', '');
    expect(map[file].file, isNull);
  }

  /// https://github.com/dart-lang/sdk/issues/55252
  test_optionsMapLookup() {
    AnalysisOptions addOptions(String folder) {
      var options = AnalysisOptionsImpl();
      map[newFolder(folder)] = options;
      return options;
    }

    var fOptions = addOptions('/home/test/f');
    addOptions('/home/test/g');
    var fghOptions = addOptions('/home/test/f/g/h');
    var fghiOptions = addOptions('/home/test/f/g/h/i');
    addOptions('/home/test/h');
    var fgOptions = addOptions('/home/test/f/g');

    // Ensure lookup retrieves the most specific options files.
    expect(map[newFile('/home/test/f/c.dart', '')], fOptions);
    expect(map[newFile('/home/test/f/g/c.dart', '')], fgOptions);
    expect(map[newFile('/home/test/f/g/h/c.dart', '')], fghOptions);
    expect(map[newFile('/home/test/f/g/h/i/c.dart', '')], fghiOptions);
  }

  test_singleOptions() {
    var rootOptions = AnalysisOptionsImpl();
    var rootFolder = newFolder('/home/test');
    map[rootFolder] = rootOptions;

    var rootFile = newFile('/home/test/a.dart', '');
    var nestedFile = newFile('/home/test/example/lib/src/a.dart', '');
    expect(map[rootFile], rootOptions);
    expect(map[nestedFile], rootOptions);
  }
}
