// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../shared/shared_code_actions_source_tests.dart';
import 'code_actions_mixin.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceCodeActionsTest);
    defineReflectiveTests(SortMembersSourceCodeActionsTest);
    defineReflectiveTests(OrganizeImportsSourceCodeActionsTest);
    defineReflectiveTests(FixAllSourceCodeActionsTest);
    defineReflectiveTests(FlutterFixAllSourceCodeActionsTest);
  });
}

abstract class AbstractSourceCodeActionsTest
    extends AbstractLspAnalysisServerTest
    with
        LspSharedTestMixin,
        SharedSourceCodeActionsTestMixin,
        CodeActionsTestMixin {}

@reflectiveTest
class FixAllSourceCodeActionsTest extends AbstractSourceCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedFixAllSourceCodeActionsTests {}

@reflectiveTest
class FlutterFixAllSourceCodeActionsTest extends AbstractSourceCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedFlutterFixAllSourceCodeActionsTests {}

@reflectiveTest
class OrganizeImportsSourceCodeActionsTest extends AbstractSourceCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedOrganizeImportsSourceCodeActionsTests {}

@reflectiveTest
class SortMembersSourceCodeActionsTest extends AbstractSourceCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedSortMembersSourceCodeActionsTests {}

@reflectiveTest
class SourceCodeActionsTest extends AbstractSourceCodeActionsTest
    with
        SharedSourceCodeActionsTestMixin,
        // Tests are defined in a shared mixin.
        SharedSourceCodeActionsTests {}
