// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'all_the_rest_test.dart' as all_the_rest;
import 'checked_mode_compile_time_error_code_test.dart'
    as checked_mode_compile_time_error_code;
import 'compile_time_error_code_test.dart' as compile_time_error_code;
// ignore: deprecated_member_use_from_same_package
import 'constant_test.dart' as constant_test;
import 'element_resolver_test.dart' as element_resolver_test;
import 'error_suppression_test.dart' as error_suppression;
import 'invalid_code_test.dart' as invalid_code;
import 'issues_test.dart' as issues;
import 'java_core_test.dart' as java_core_test;
import 'java_io_test.dart' as java_io_test;
import 'non_error_resolver_test.dart' as non_error_resolver;
import 'non_hint_code_test.dart' as non_hint_code;
import 'parser_fasta_test.dart' as parser_fasta_test;
import 'parser_test.dart' as parser_test;
import 'resolver_test.dart' as resolver_test;
import 'scanner_test.dart' as scanner_test;
import 'sdk_test.dart' as sdk_test;
import 'simple_resolver_test.dart' as simple_resolver_test;
import 'source_factory_test.dart' as source_factory_test;
import 'static_type_analyzer_test.dart' as static_type_analyzer_test;
import 'static_type_warning_code_test.dart' as static_type_warning_code;
import 'static_warning_code_test.dart' as static_warning_code;
import 'strong_mode_test.dart' as strong_mode;
import 'type_system_test.dart' as type_system_test;
import 'utilities_dart_test.dart' as utilities_dart_test;
import 'utilities_test.dart' as utilities_test;

main() {
  defineReflectiveSuite(() {
    all_the_rest.main();
    checked_mode_compile_time_error_code.main();
    compile_time_error_code.main();
    constant_test.main();
    element_resolver_test.main();
    error_suppression.main();
    invalid_code.main();
    issues.main();
    java_core_test.main();
    java_io_test.main();
    non_error_resolver.main();
    non_hint_code.main();
    parser_fasta_test.main();
    parser_test.main();
    resolver_test.main();
    scanner_test.main();
    sdk_test.main();
    simple_resolver_test.main();
    source_factory_test.main();
    static_type_analyzer_test.main();
    static_type_warning_code.main();
    static_warning_code.main();
    strong_mode.main();
    type_system_test.main();
    utilities_dart_test.main();
    utilities_test.main();
  }, name: 'generated');
}
