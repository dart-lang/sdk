// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/io.dart';

import 'annotation_test.dart' as annotation;
import 'ascii_utils_test.dart' as ascii_utils;
import 'canonicalization_test.dart' as canonicalization;
import 'doc_test.dart' as doc;
import 'engine_test.dart' as engine;
import 'formatter_test.dart' as formatter;
import 'integration_test.dart' as integration;
import 'lint_code_test.dart' as lint_code;
import 'mocks.dart';
import 'pubspec_test.dart' as pubspec;
import 'rule_test.dart' as rule;
import 'rules/all.dart' as rules;
import 'unmocked_sdk_rule_test.dart' as unmocked_sdk_rule;
import 'utils_test.dart' as utils;
import 'validate_incompatible_rules_test.dart' as validate_incompatible_rules;
import 'validate_no_rule_description_references_test.dart'
    as validate_no_rule_description_references;
import 'validate_rule_description_format_test.dart'
    as validate_rule_description_format;
import 'verify_checks_test.dart' as verify_checks;
import 'verify_generated_files_test.dart' as verify_generated_files;
import 'verify_reflective_test_suites_test.dart'
    as verify_reflective_test_suites;

void main() {
  // Redirect output.
  outSink = MockIOSink();

  annotation.main();
  ascii_utils.main();
  canonicalization.main();
  doc.main();
  engine.main();
  formatter.main();
  integration.main();
  lint_code.main();
  pubspec.main();
  rule.main();
  rules.main();
  unmocked_sdk_rule.main();
  utils.main();
  validate_incompatible_rules.main();
  validate_no_rule_description_references.main();
  validate_rule_description_format.main();
  verify_checks.main();
  verify_generated_files.main();
  verify_reflective_test_suites.main();
}
