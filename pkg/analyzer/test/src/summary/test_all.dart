// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.serialization.test_all;

import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'api_signature_test.dart' as api_signature_test;
import 'flat_buffers_test.dart' as flat_buffers_test;
import 'in_summary_source_test.dart' as in_summary_source_test;
import 'incremental_cache_test.dart' as incremental_cache_test;
import 'index_unit_test.dart' as index_unit_test;
import 'linker_test.dart' as linker_test;
import 'name_filter_test.dart' as name_filter_test;
import 'package_bundle_reader_test.dart' as package_bundle_reader_test;
import 'prelinker_test.dart' as prelinker_test;
import 'pub_summary_test.dart' as pub_summary_test;
import 'resynthesize_ast_test.dart' as resynthesize_ast_test;
import 'resynthesize_strong_test.dart' as resynthesize_strong_test;
import 'resynthesize_test.dart' as resynthesize_test;
import 'summarize_ast_strong_test.dart' as summarize_ast_strong_test;
import 'summarize_ast_test.dart' as summarize_ast_test;
import 'summarize_elements_strong_test.dart' as summarize_elements_strong_test;
import 'summarize_elements_test.dart' as summarize_elements_test;

/// Utility for manually running all tests.
main() {
  initializeTestEnvironment();
  group('summary tests', () {
    api_signature_test.main();
    flat_buffers_test.main();
    in_summary_source_test.main();
    incremental_cache_test.main();
    index_unit_test.main();
    linker_test.main();
    name_filter_test.main();
    package_bundle_reader_test.main();
    prelinker_test.main();
    pub_summary_test.main();
    resynthesize_ast_test.main();
    resynthesize_strong_test.main();
    resynthesize_test.main();
    summarize_ast_strong_test.main();
    summarize_ast_test.main();
    summarize_elements_strong_test.main();
    summarize_elements_test.main();
  });
}
