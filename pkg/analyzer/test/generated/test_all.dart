// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generated;

import 'package:unittest/unittest.dart';

import 'all_the_rest.dart' as all_the_rest;
import 'ast_test.dart' as ast_test;
import 'compile_time_error_code_test.dart' as compile_time_error_code_test;
import 'element_test.dart' as element_test;
import 'engine_test.dart' as engine_test;
import 'incremental_resolver_test.dart' as incremental_resolver_test;
import 'java_core_test.dart' as java_core_test;
import 'java_io_test.dart' as java_io_test;
import 'non_error_resolver_test.dart' as non_error_resolver_test;
import 'parser_test.dart' as parser_test;
import 'resolver_test.dart' as resolver_test;
import 'scanner_test.dart' as scanner_test;
import 'static_type_warning_code_test.dart' as static_type_warning_code_test;
import 'static_warning_code_test.dart' as static_warning_code_test;
import 'utilities_test.dart' as utilities_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('generated tests', () {
    all_the_rest.main();
    ast_test.main();
    compile_time_error_code_test.main();
    element_test.main();
    engine_test.main();
    incremental_resolver_test.main();
    java_core_test.main();
    java_io_test.main();
    non_error_resolver_test.main();
    parser_test.main();
    resolver_test.main();
    scanner_test.main();
    static_type_warning_code_test.main();
    static_warning_code_test.main();
    utilities_test.main();
  });
}
