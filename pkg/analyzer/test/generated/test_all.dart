// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'all_the_rest_test.dart' as all_the_rest;
import 'bazel_test.dart' as bazel_test;
import 'checked_mode_compile_time_error_code_driver_test.dart'
    as checked_mode_compile_time_error_code_driver_test;
import 'checked_mode_compile_time_error_code_test.dart'
    as checked_mode_compile_time_error_code_test;
import 'compile_time_error_code_driver_test.dart'
    as compile_time_error_code_driver_test;
import 'compile_time_error_code_test.dart' as compile_time_error_code_test;
import 'constant_test.dart' as constant_test;
import 'declaration_resolver_test.dart' as declaration_resolver_test;
import 'element_resolver_test.dart' as element_resolver_test;
import 'engine_test.dart' as engine_test;
import 'error_suppression_driver_test.dart' as error_suppression_driver_test;
import 'error_suppression_test.dart' as error_suppression_test;
import 'gn_test.dart' as gn_test;
import 'hint_code_driver_test.dart' as hint_code_driver_test;
import 'hint_code_test.dart' as hint_code_test;
import 'inheritance_manager_test.dart' as inheritance_manager_test;
import 'java_core_test.dart' as java_core_test;
import 'java_io_test.dart' as java_io_test;
import 'non_error_resolver_driver_test.dart' as non_error_resolver_driver_test;
import 'non_error_resolver_kernel_test.dart' as non_error_resolver_kernel_test;
import 'non_error_resolver_test.dart' as non_error_resolver_test;
import 'non_hint_code_driver_test.dart' as non_hint_code_driver_test;
import 'non_hint_code_test.dart' as non_hint_code_test;
import 'package_test.dart' as package_test;
import 'parser_fasta_test.dart' as parser_fasta_test;
import 'parser_test.dart' as parser_test;
import 'resolver_driver_test.dart' as resolver_driver_test;
import 'resolver_test.dart' as resolver_test;
import 'scanner_test.dart' as scanner_test;
import 'sdk_test.dart' as sdk_test;
import 'simple_resolver_test.dart' as simple_resolver_test;
import 'source_factory_test.dart' as source_factory_test;
import 'static_type_analyzer_driver_test.dart'
    as static_type_analyzer_driver_test;
import 'static_type_analyzer_test.dart' as static_type_analyzer_test;
import 'static_type_warning_code_driver_test.dart'
    as static_type_warning_code_driver_test;
import 'static_type_warning_code_test.dart' as static_type_warning_code_test;
import 'static_warning_code_driver_test.dart'
    as static_warning_code_driver_test;
import 'static_warning_code_test.dart' as static_warning_code_test;
import 'strong_mode_driver_test.dart' as strong_mode_driver_test;
import 'strong_mode_test.dart' as strong_mode_test;
import 'type_system_test.dart' as type_system_test;
import 'utilities_dart_test.dart' as utilities_dart_test;
import 'utilities_test.dart' as utilities_test;

main() {
  defineReflectiveSuite(() {
    all_the_rest.main();
    bazel_test.main();
    checked_mode_compile_time_error_code_driver_test.main();
    checked_mode_compile_time_error_code_test.main();
    compile_time_error_code_driver_test.main();
    compile_time_error_code_test.main();
    constant_test.main();
    declaration_resolver_test.main();
    element_resolver_test.main();
    engine_test.main();
    error_suppression_driver_test.main();
    error_suppression_test.main();
    gn_test.main();
    hint_code_driver_test.main();
    hint_code_test.main();
    inheritance_manager_test.main();
    java_core_test.main();
    java_io_test.main();
    non_error_resolver_driver_test.main();
    non_error_resolver_kernel_test.main();
    non_error_resolver_test.main();
    non_hint_code_driver_test.main();
    non_hint_code_test.main();
    package_test.main();
    parser_fasta_test.main();
    parser_test.main();
    resolver_driver_test.main();
    resolver_test.main();
    scanner_test.main();
    sdk_test.main();
    simple_resolver_test.main();
    source_factory_test.main();
    static_type_analyzer_driver_test.main();
    static_type_analyzer_test.main();
    static_type_warning_code_driver_test.main();
    static_type_warning_code_test.main();
    static_warning_code_driver_test.main();
    static_warning_code_test.main();
    strong_mode_driver_test.main();
    strong_mode_test.main();
    type_system_test.main();
    utilities_dart_test.main();
    utilities_test.main();
  }, name: 'generated');
}
