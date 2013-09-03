// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is a helper for run.sh. We try to run all of the Dart code in one
 * instance of the Dart VM to reduce warm-up time.
 */
library run_impl;

import 'dart:io';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'package:polymer/testing/content_shell_test.dart';

import 'css_test.dart' as css_test;
import 'compiler_test.dart' as compiler_test;
import 'utils_test.dart' as utils_test;
import 'transform/all_phases_test.dart' as all_phases_test;
import 'transform/code_extractor_test.dart' as code_extractor_test;
import 'transform/import_inliner_test.dart' as import_inliner_test;
import 'transform/polyfill_injector_test.dart' as polyfill_injector_test;
import 'transform/script_compactor_test.dart' as script_compactor_test;

main() {
  var args = new Options().arguments;
  var pattern = new RegExp(args.length > 0 ? args[0] : '.');

  useCompactVMConfiguration();

  void addGroup(testFile, testMain) {
    if (pattern.hasMatch(testFile)) {
      group(testFile.replaceAll('_test.dart', ':'), testMain);
    }
  }

  addGroup('compiler_test.dart', compiler_test.main);
  addGroup('css_test.dart', css_test.main);
  addGroup('utils_test.dart', utils_test.main);
  addGroup('transform/code_extractor_test.dart', code_extractor_test.main);
  addGroup('transform/import_inliner_test.dart', import_inliner_test.main);
  addGroup('transform/script_compactor_test.dart', script_compactor_test.main);
  addGroup('transform/polyfill_injector_test.dart',
      polyfill_injector_test.main);
  addGroup('transform/all_phases_test.dart', all_phases_test.main);

  endToEndTests('data/unit/', 'data/out');

  // Note: if you're adding more render test suites, make sure to update run.sh
  // as well for convenient baseline diff/updating.

  // TODO(jmesserly): figure out why this fails in content_shell but works in
  // Dartium and Firefox when using the ShadowDOM polyfill.
  exampleTest('../example/component/news', ['--no-shadowdom']..addAll(args));
}

void exampleTest(String path, [List args]) {
  // TODO(sigmund): renderTests currently contatenates [path] with the out
  // folder. This can be a problem with relative paths that go up (like todomvc
  // above, which has '../../../'). If we continue running tests with
  // test/run.sh, we should fix this. For now we work around this problem by
  // using a long path 'data/out/example/test'. That way we avoid dumping output
  // in the source-tree.
  renderTests(path, '$path/test', '$path/test/expected',
      'data/out/example/test', arguments: args);
}
