// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_code_actions_source_tests.dart';
import 'abstract_code_actions.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceCodeActionsTest);
    defineReflectiveTests(OrganizeImportsSourceCodeActionsTest);
    defineReflectiveTests(SortMembersSourceCodeActionsTest);
    defineReflectiveTests(FixAllSourceCodeActionsTest);
    defineReflectiveTests(FlutterFixAllSourceCodeActionsTest);
  });
}

@reflectiveTest
class FixAllSourceCodeActionsTest extends AbstractCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedFixAllSourceCodeActionsTests {}

@reflectiveTest
class FlutterFixAllSourceCodeActionsTest extends AbstractCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedFlutterFixAllSourceCodeActionsTests {}

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
