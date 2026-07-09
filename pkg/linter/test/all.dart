// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ascii_utils_test.dart' as ascii_utils;
import 'doc_test.dart' as doc;
import 'formatter_test.dart' as formatter;
import 'integration_test.dart' as integration;
import 'lint_code_test.dart' as lint_code;
import 'pubspec_test.dart' as pubspec;
import 'rules/all.dart' as rules;
import 'scope_util_test.dart' as scope_util;
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
  ascii_utils.main();
  doc.main();
  formatter.main();
  integration.main();
  lint_code.main();
  pubspec.main();
  rules.main();
  scope_util.main();
  utils.main();
  validate_incompatible_rules.main();
  validate_no_rule_description_references.main();
  validate_rule_description_format.main();
  verify_checks.main();
  verify_generated_files.main();
  verify_reflective_test_suites.main();
}
