// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analysis_server/src/plugin/result_converter.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart' as server;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'protocol_test_utilities.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResultConverterTest);
  });
}

@reflectiveTest
class ResultConverterTest extends ProtocolTestUtilities {
  static const List<String> strings = const <String>[
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

  ResultConverter converter = new ResultConverter();

  void test_convertAnalysisErrorFixes() {
    AnalysisError error = analysisError(0, 0);
    SourceChange change = sourceChange(4, 4);
    plugin.AnalysisErrorFixes initial = new plugin.AnalysisErrorFixes(error,
        fixes: <plugin.PrioritizedSourceChange>[
          new plugin.PrioritizedSourceChange(100, change)
        ]);
    server.AnalysisErrorFixes expected =
        new server.AnalysisErrorFixes(error, fixes: <SourceChange>[change]);
    expect(converter.convertAnalysisErrorFixes(initial), expected);
  }

  void test_convertAnalysisNavigationParams() {
    plugin.AnalysisNavigationParams initial =
        new plugin.AnalysisNavigationParams('a.dart', <NavigationRegion>[
      new NavigationRegion(1, 2, <int>[3, 4])
    ], <NavigationTarget>[
      new NavigationTarget(ElementKind.FIELD, 5, 6, 7, 8, 9)
    ], <String>[
      'a',
      'b'
    ]);
    server.AnalysisNavigationParams expected =
        new server.AnalysisNavigationParams('a.dart', <NavigationRegion>[
      new NavigationRegion(1, 2, <int>[3, 4])
    ], <NavigationTarget>[
      new NavigationTarget(ElementKind.FIELD, 5, 6, 7, 8, 9)
    ], <String>[
      'a',
      'b'
    ]);
    expect(converter.convertAnalysisNavigationParams(initial), expected);
  }

  void test_convertEditGetRefactoringResult_inlineMethod() {
    RefactoringProblem problem1 = refactoringProblem(0, 0);
    RefactoringProblem problem2 = refactoringProblem(2, 4);
    RefactoringProblem problem3 = refactoringProblem(4, 8);
    SourceChange change = sourceChange(6, 12);
    plugin.EditGetRefactoringResult initial =
        new plugin.EditGetRefactoringResult(<RefactoringProblem>[problem1],
            <RefactoringProblem>[problem2], <RefactoringProblem>[problem3],
            feedback:
                new plugin.InlineMethodFeedback('a', true, className: 'b'),
            change: change,
            potentialEdits: <String>['f']);
    server.EditGetRefactoringResult expected =
        new server.EditGetRefactoringResult(<RefactoringProblem>[problem1],
            <RefactoringProblem>[problem2], <RefactoringProblem>[problem3],
            feedback:
                new server.InlineMethodFeedback('a', true, className: 'b'),
            change: change,
            potentialEdits: <String>['f']);
    expect(
        converter.convertEditGetRefactoringResult(
            RefactoringKind.INLINE_METHOD, initial),
        expected);
  }

  void test_convertEditGetRefactoringResult_moveFile() {
    RefactoringProblem problem1 = refactoringProblem(0, 0);
    RefactoringProblem problem2 = refactoringProblem(2, 4);
    RefactoringProblem problem3 = refactoringProblem(4, 8);
    SourceChange change = sourceChange(6, 12);
    plugin.EditGetRefactoringResult initial =
        new plugin.EditGetRefactoringResult(<RefactoringProblem>[problem1],
            <RefactoringProblem>[problem2], <RefactoringProblem>[problem3],
            feedback: new plugin.MoveFileFeedback(),
            change: change,
            potentialEdits: <String>['f']);
    server.EditGetRefactoringResult expected =
        new server.EditGetRefactoringResult(<RefactoringProblem>[problem1],
            <RefactoringProblem>[problem2], <RefactoringProblem>[problem3],
            change: change, potentialEdits: <String>['f']);
    expect(
        converter.convertEditGetRefactoringResult(
            RefactoringKind.MOVE_FILE, initial),
        expected);
  }

  void test_convertPrioritizedSourceChange() {
    SourceChange change = sourceChange(0, 0);
    plugin.PrioritizedSourceChange initial =
        new plugin.PrioritizedSourceChange(100, change);
    expect(converter.convertPrioritizedSourceChange(initial), change);
  }
}
