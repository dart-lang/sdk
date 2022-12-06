// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/io.dart';

import 'ascii_utils_test.dart' as ascii_utils;
import 'doc_test.dart' as doc_test;
import 'engine_test.dart' as engine_test;
import 'formatter_test.dart' as formatter_test;
import 'integration_test.dart' as integration_test;
import 'mocks.dart';
import 'rule_test.dart' as rule_test;
import 'rules/all.dart' as reflective_rule_tests;
import 'unmocked_sdk_rule_test.dart' as unmocked_sdk_rule_test;
import 'utils_test.dart' as utils_test;
import 'validate_format_test.dart' as validate_format;
import 'validate_headers_test.dart' as validate_headers;
import 'validate_incompatible_rules.dart' as validate_incompatible_rules;
import 'validate_no_rule_description_references.dart'
    as validate_no_rule_description_references;
import 'validate_rule_description_format_test.dart'
    as validate_rule_description_format;
import 'verify_reflective_test_suites.dart' as verify_reflective_test_suites;
import 'version_test.dart' as version_test;

void main() {
  // Redirect output.
  outSink = MockIOSink();

  ascii_utils.main();
  doc_test.main();
  engine_test.main();
  formatter_test.main();
  integration_test.main();
  rule_test.main();
  reflective_rule_tests.main();
  unmocked_sdk_rule_test.main();
  utils_test.main();
  validate_format.main();
  validate_headers.main();
  validate_incompatible_rules.main();
  validate_no_rule_description_references.main();
  validate_rule_description_format.main();
  verify_reflective_test_suites.main();
  version_test.main();
}
