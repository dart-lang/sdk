// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_code_actions_source_tests.dart';
import 'abstract_code_actions.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceCodeActionsTest);
    defineReflectiveTests(OrganizeImportsSourceCodeActionsTest);
    defineReflectiveTests(SortMembersSourceCodeActionsTest);
    defineReflectiveTests(FixAllSourceCodeActionsTest);
  });
}

@reflectiveTest
class FixAllSourceCodeActionsTest extends AbstractCodeActionsTest
    with SharedSourceCodeActionsTestMixin {
  /// The fix all command is currently LSP-only, so we shouldn't return code
  /// actions for it.
  Future<void> test_unavailable() async {
    await expectNoAction('// content', command: Commands.fixAll);

    expect(
      serverSupportsFixAll,
      isFalse,
      reason:
          'Fix All is not currently available for the legacy server. '
          'If/when that changes, this test must be updated by extracting the '
          'Fix All tests from LSP into a shared mixin like the others',
    );
  }
}

@reflectiveTest
class OrganizeImportsSourceCodeActionsTest extends AbstractCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedOrganizeImportsSourceCodeActionsTests {}

@reflectiveTest
class SortMembersSourceCodeActionsTest extends AbstractCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedSortMembersSourceCodeActionsTests {}

@reflectiveTest
class SourceCodeActionsTest extends AbstractCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedSourceCodeActionsTests {}
