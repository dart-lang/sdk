// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analysis_server/src/plugin/result_converter.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'protocol_test_utilities.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResultConverterTest);
  });
}

@reflectiveTest
class ResultConverterTest extends ProtocolTestUtilities {
  static const List<String> strings = <String>[
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n'
  ];

  ResultConverter converter = ResultConverter();

  void test_convertAnalysisErrorFixes() {
    var error = analysisError(0, 0);
    var change = sourceChange(4, 4);
    var initial = plugin.AnalysisErrorFixes(error,
        fixes: <plugin.PrioritizedSourceChange>[
          plugin.PrioritizedSourceChange(100, change)
        ]);
    var expected =
        server.AnalysisErrorFixes(error, fixes: <SourceChange>[change]);
    expect(converter.convertAnalysisErrorFixes(initial), expected);
  }

  void test_convertAnalysisNavigationParams() {
    var initial = plugin.AnalysisNavigationParams('a.dart', <NavigationRegion>[
      NavigationRegion(1, 2, <int>[3, 4])
    ], <NavigationTarget>[
      NavigationTarget(ElementKind.FIELD, 5, 6, 7, 8, 9)
    ], <String>[
      'a',
      'b'
    ]);
    var expected = server.AnalysisNavigationParams('a.dart', <NavigationRegion>[
      NavigationRegion(1, 2, <int>[3, 4])
    ], <NavigationTarget>[
      NavigationTarget(ElementKind.FIELD, 5, 6, 7, 8, 9)
    ], <String>[
      'a',
      'b'
    ]);
    expect(converter.convertAnalysisNavigationParams(initial), expected);
  }

  void test_convertEditGetRefactoringResult_inlineMethod() {
    var problem1 = refactoringProblem(0, 0);
    var problem2 = refactoringProblem(2, 4);
    var problem3 = refactoringProblem(4, 8);
    var change = sourceChange(6, 12);
    var initial = plugin.EditGetRefactoringResult(
        <RefactoringProblem>[problem1],
        <RefactoringProblem>[problem2],
        <RefactoringProblem>[problem3],
        feedback: plugin.InlineMethodFeedback('a', true, className: 'b'),
        change: change,
        potentialEdits: <String>['f']);
    var expected = server.EditGetRefactoringResult(
        <RefactoringProblem>[problem1],
        <RefactoringProblem>[problem2],
        <RefactoringProblem>[problem3],
        feedback: server.InlineMethodFeedback('a', true, className: 'b'),
        change: change,
        potentialEdits: <String>['f']);
    expect(
        converter.convertEditGetRefactoringResult(
            RefactoringKind.INLINE_METHOD, initial),
        expected);
  }

  void test_convertEditGetRefactoringResult_moveFile() {
    var problem1 = refactoringProblem(0, 0);
    var problem2 = refactoringProblem(2, 4);
    var problem3 = refactoringProblem(4, 8);
    var change = sourceChange(6, 12);
    var initial = plugin.EditGetRefactoringResult(
        <RefactoringProblem>[problem1],
        <RefactoringProblem>[problem2],
        <RefactoringProblem>[problem3],
        feedback: plugin.MoveFileFeedback(),
        change: change,
        potentialEdits: <String>['f']);
    var expected = server.EditGetRefactoringResult(
        <RefactoringProblem>[problem1],
        <RefactoringProblem>[problem2],
        <RefactoringProblem>[problem3],
        change: change,
        potentialEdits: <String>['f']);
    expect(
        converter.convertEditGetRefactoringResult(
            RefactoringKind.MOVE_FILE, initial),
        expected);
  }

  void test_convertPrioritizedSourceChange() {
    var change = sourceChange(0, 0);
    var initial = plugin.PrioritizedSourceChange(100, change);
    expect(converter.convertPrioritizedSourceChange(initial), change);
  }
}
