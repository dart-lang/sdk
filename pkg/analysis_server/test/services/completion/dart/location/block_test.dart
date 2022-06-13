// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BlockTest1);
    defineReflectiveTests(BlockTest2);
  });
}

@reflectiveTest
class BlockTest1 extends AbstractCompletionDriverTest with BlockTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class BlockTest2 extends AbstractCompletionDriverTest with BlockTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin BlockTestCases on AbstractCompletionDriverTest {
  static final spaces_4 = ' ' * 4;
  static final spaces_6 = ' ' * 6;
  static final spaces_8 = ' ' * 8;

  Future<void> test_flutter_setState_indent6_hasPrefix() async {
    await _check_flutter_setState(
      line: '${spaces_6}setSt^',
      completion: '''
setState(() {
$spaces_8
$spaces_6});''',
      selectionOffset: 22,
    );
  }

  Future<void> test_flutter_setState_indent_hasPrefix() async {
    await _check_flutter_setState(
      line: '${spaces_4}setSt^',
      completion: '''
setState(() {
$spaces_6
$spaces_4});''',
      selectionOffset: 20,
    );
  }

  Future<void> test_flutter_setState_indent_noPrefix() async {
    await _check_flutter_setState(
      line: '$spaces_4^',
      completion: '''
setState(() {
$spaces_6
$spaces_4});''',
      selectionOffset: 20,
    );
  }

  Future<void> _check_flutter_setState({
    required String line,
    required String completion,
    required int selectionOffset,
  }) async {
    writeTestPackageConfig(flutter: true);

    var response = await getTestCodeSuggestions('''
import 'package:flutter/widgets.dart';

class TestWidget extends StatefulWidget {
  @override
  State<TestWidget> createState() {
    return TestWidgetState();
  }
}

class TestWidgetState extends State<TestWidget> {
  @override
  Widget build(BuildContext context) {
$line
  }
}
''');

    check(response).suggestions.includesAll([
      (suggestion) => suggestion
        ..completion.startsWith('setState')
        ..completion.isEqualTo(completion)
        ..hasSelection(offset: selectionOffset)
        // It is an invocation, but we don't need any additional info for it.
        // So, all parameter information is absent.
        ..kind.isInvocation
        ..parameterNames.isNull
        ..parameterTypes.isNull
        ..requiredParameterCount.isNull
        ..hasNamedParameters.isNull,
    ]);
  }
}
