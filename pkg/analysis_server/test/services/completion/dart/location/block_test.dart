// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

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
    await _check_flutter_setState(line: '${spaces_6}setSt^', expected: '''
replacement
  left: 5
suggestions
  setState(() {
$spaces_8
$spaces_6});
    kind: invocation
    selection: 22
''');
  }

  Future<void> test_flutter_setState_indent_hasPrefix() async {
    await _check_flutter_setState(line: '${spaces_4}setSt^', expected: '''
replacement
  left: 5
suggestions
  setState(() {
$spaces_6
$spaces_4});
    kind: invocation
    selection: 20
''');
  }

  Future<void> test_flutter_setState_indent_noPrefix() async {
    await _check_flutter_setState(line: '$spaces_4^', expected: '''
suggestions
  setState(() {
$spaces_6
$spaces_4});
    kind: invocation
    selection: 20
''');
  }

  Future<void> _check_flutter_setState({
    required String line,
    required String expected,
  }) async {
    writeTestPackageConfig(flutter: true);

    await computeSuggestions('''
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

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        return suggestion.completion.contains('setState(');
      },
    );

    assertResponse(expected);
  }
}
