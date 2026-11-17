// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Conventions for tests written using `package:test_reflective_loader` aren't
// compatible with the `non_constant_identifier_names` lint.
// ignore_for_file: non_constant_identifier_names

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:analyzer_testing/correction/assist_processor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssistProcessorTestTest);
  });
}

@reflectiveTest
class AssistProcessorTestTest extends AssistProcessorTest {
  @override
  AssistKind get kind => _RemoveAwait._removeAwaitKind;

  @override
  void setUp() {
    super.setUp();
    registerAssist(_RemoveAwait.new);
  }

  Future<void> test_hasAssist() async {
    await resolveTestCode('''
void f(Future<int> p) async {
  ^await p;
}
''');
    await assertHasAssist('''
void f(Future<int> p) async {
  p;
}
''');
  }

  Future<void> test_noAssist() async {
    await resolveTestCode('''
void f(Future<int> p) async {
  ^p;
}
''');
    await assertNoAssist();
  }
}

class _RemoveAwait extends ResolvedCorrectionProducer {
  static const _removeAwaitKind = AssistKind(
    'dart.assist.removeAwait',
    30,
    "Remove the 'await' keyword",
  );

  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _removeAwaitKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var awaitExpression = node;
    if (awaitExpression is AwaitExpression) {
      var awaitToken = awaitExpression.awaitKeyword;
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.startStart(awaitToken, awaitToken.next!));
      });
    }
  }
}
