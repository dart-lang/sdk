// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/plugin/result_merger.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResultMergerTest);
  });
}

@reflectiveTest
class ResultMergerTest {
  //
  // The tests in this class should always perform the merge operation twice
  // using the same input values in order to ensure that the input values are
  // not modified by the merge operation.
  //

  ResultMerger merger = ResultMerger();

  void test_mergeAnalysisErrorFixes() {
    AnalysisError createError(int offset) {
      var severity = AnalysisErrorSeverity.ERROR;
      var type = AnalysisErrorType.HINT;
      var location = Location('test.dart', offset, 2, 3, 4);
      return AnalysisError(severity, type, location, '', '');
    }

    var error1 = createError(10);
    var error2 = createError(20);
    var error3 = createError(30);
    var error4 = createError(40);
    var change1 = plugin.PrioritizedSourceChange(1, SourceChange('a'));
    var change2 = plugin.PrioritizedSourceChange(2, SourceChange('b'));
    var change3 = plugin.PrioritizedSourceChange(3, SourceChange('c'));
    var change4 = plugin.PrioritizedSourceChange(4, SourceChange('d'));
    var change5 = plugin.PrioritizedSourceChange(5, SourceChange('e'));
    var fix1 = plugin.AnalysisErrorFixes(error1, fixes: [change1]);
    var fix2 = plugin.AnalysisErrorFixes(error2, fixes: [change2]);
    var fix3 = plugin.AnalysisErrorFixes(error2, fixes: [change3]);
    var fix4 = plugin.AnalysisErrorFixes(error3, fixes: [change4]);
    var fix5 = plugin.AnalysisErrorFixes(error4, fixes: [change5]);
    var fix2and3 = plugin.AnalysisErrorFixes(error2, fixes: [change2, change3]);

    void runTest() {
      expect(
          merger.mergeAnalysisErrorFixes([
            [fix1, fix2],
            [fix3, fix4],
            [fix5],
            []
          ]),
          unorderedEquals([fix1, fix2and3, fix4, fix5]));
    }

    runTest();
    runTest();
  }

  void test_mergeAnalysisErrors() {
    AnalysisError createError(int offset) {
      var severity = AnalysisErrorSeverity.ERROR;
      var type = AnalysisErrorType.HINT;
      var location = Location('test.dart', offset, 2, 3, 4);
      return AnalysisError(severity, type, location, '', '');
    }

    var error1 = createError(10);
    var error2 = createError(20);
    var error3 = createError(30);
    var error4 = createError(40);

    void runTest() {
      expect(
          merger.mergeAnalysisErrors([
            [error1, error2],
            [error3],
            [],
            [error4]
          ]),
          unorderedEquals([error1, error2, error3, error4]));
    }

    runTest();
    runTest();
  }

  void test_mergeCompletionSuggestions() {
    CompletionSuggestion createSuggestion(String completion) =>
        CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER, 50,
            completion, 0, 3, false, false);

    var suggestion1 = createSuggestion('a');
    var suggestion2 = createSuggestion('b');
    var suggestion3 = createSuggestion('c');
    var suggestion4 = createSuggestion('d');

    void runTest() {
      expect(
          merger.mergeCompletionSuggestions([
            [suggestion1],
            [suggestion2, suggestion3, suggestion4],
            []
          ]),
          unorderedEquals(
              [suggestion1, suggestion2, suggestion3, suggestion4]));
    }

    runTest();
    runTest();
  }

  void test_mergeFoldingRegion() {
    var kind = FoldingKind.FILE_HEADER;
    var region1 = FoldingRegion(kind, 30, 5);
    var region2 = FoldingRegion(kind, 0, 4);
    var region3 = FoldingRegion(kind, 20, 6);
    var region4 = FoldingRegion(kind, 10, 3);
    var region5 = FoldingRegion(kind, 2, 6); // overlaps

    void runTest() {
      expect(
          merger.mergeFoldingRegions([
            [region1, region2],
            [],
            [region3],
            [region4, region5]
          ]),
          unorderedEquals([region1, region2, region3, region4]));
    }

    runTest();
    runTest();
  }

  void test_mergeHighlightRegions() {
    var type = HighlightRegionType.COMMENT_BLOCK;
    var region1 = HighlightRegion(type, 30, 5);
    var region2 = HighlightRegion(type, 0, 4);
    var region3 = HighlightRegion(type, 20, 6);
    var region4 = HighlightRegion(type, 10, 3);

    void runTest() {
      expect(
          merger.mergeHighlightRegions([
            [region1, region2],
            [],
            [region3],
            [region4]
          ]),
          unorderedEquals([region1, region2, region3, region4]));
    }

    runTest();
    runTest();
  }

  void test_mergeNavigation() {
    NavigationTarget target(int fileIndex, int offset) {
      return NavigationTarget(ElementKind.CLASS, fileIndex, offset, 1, 0, 0,
          codeOffset: offset, codeLength: 1);
    }

    //
    // Create the parameters from the server.
    //
    var target1_1 = target(0, 1);
    var target1_2 = target(0, 2);
    var target2_1 = target(1, 3);
    var target2_2 = target(1, 4);
    var region1_1 = NavigationRegion(10, 4, [0]);
    var region1_2 = NavigationRegion(20, 4, [1]);
    var region2_1 = NavigationRegion(30, 4, [2]);
    var region2_2 = NavigationRegion(40, 4, [3]);
    var params1 = AnalysisNavigationParams(
        'a.dart',
        [region1_1, region1_2, region2_1, region2_2],
        [target1_1, target1_2, target2_1, target2_2],
        ['one.dart', 'two.dart']);
    //
    // Create the parameters from the second plugin.
    //
    // same file and offset as target 2_2
    var target2_3 = target(0, 4);
    var target2_4 = target(0, 5);
    var target3_1 = target(1, 6);
    var target3_2 = target(1, 7);
    // same region and target as region2_2
    var region2_3 = NavigationRegion(40, 4, [0]);
    // same region as region2_2, but a different target
    var region2_4 = NavigationRegion(40, 4, [2]);
    var region2_5 = NavigationRegion(50, 4, [1]);
    var region3_1 = NavigationRegion(60, 4, [2]);
    var region3_2 = NavigationRegion(70, 4, [3]);
    var params2 = AnalysisNavigationParams(
        'a.dart',
        [region2_3, region2_4, region2_5, region3_1, region3_2],
        [target2_3, target2_4, target3_1, target3_2],
        ['two.dart', 'three.dart']);
    var expected = AnalysisNavigationParams('a.dart', [
      region1_1,
      region1_2,
      region2_1,
      NavigationRegion(40, 4, [3, 5]), // union of region2_2 and region2_4
      NavigationRegion(50, 4, [4]), // region2_5
      NavigationRegion(60, 4, [5]), // region3_1
      NavigationRegion(70, 4, [6]), // region3_2
    ], [
      target1_1,
      target1_2,
      target2_1,
      target2_2,
      target(1, 5), // target2_4
      target(2, 6), // target3_1
      target(2, 7), // target3_2
    ], [
      'one.dart',
      'two.dart',
      'three.dart'
    ]);

    void runTest() {
      expect(merger.mergeNavigation([params1, params2]), expected);
    }

    runTest();
    runTest();
  }

  void test_mergeOccurrences() {
    var element1 = Element(ElementKind.CLASS, 'e1', 0);
    var element2 = Element(ElementKind.CLASS, 'e2', 0);
    var element3 = Element(ElementKind.CLASS, 'e3', 0);
    var occurrence1 = Occurrences(element1, [1, 2, 4], 2);
    var occurrence2 = Occurrences(element2, [5], 2);
    var occurrence3 = Occurrences(element1, [2, 3], 2);
    var occurrence4 = Occurrences(element3, [8], 2);
    var occurrence5 = Occurrences(element2, [6], 2);
    var occurrence6 = Occurrences(element3, [7, 9], 2);
    var result1 = Occurrences(element1, [1, 2, 3, 4], 2);
    var result2 = Occurrences(element2, [5, 6], 2);
    var result3 = Occurrences(element3, [7, 8, 9], 2);

    void runTest() {
      expect(
          merger.mergeOccurrences([
            [occurrence1, occurrence2],
            [],
            [occurrence3, occurrence4],
            [occurrence5, occurrence6]
          ]),
          unorderedEquals([result1, result2, result3]));
    }

    runTest();
    runTest();
  }

  void test_mergeOutline() {
    Element element(ElementKind kind, int offset) {
      var location = Location('', offset, 0, 0, 0);
      return Element(kind, '', 0, location: location);
    }

    var element1 = element(ElementKind.CLASS, 100);
    var element1_1 = element(ElementKind.METHOD, 110);
    var element1_2 = element(ElementKind.METHOD, 120);
    var element2 = element(ElementKind.CLASS, 200);
    var element2_1 = element(ElementKind.METHOD, 210);
    var element2_2 = element(ElementKind.METHOD, 220);
    var element3_1 = element(ElementKind.METHOD, 220); // same as 2_2
    var element3_2 = element(ElementKind.METHOD, 230);
    var element4 = element(ElementKind.CLASS, 300);
    var element4_1 = element(ElementKind.METHOD, 310);
    //
    // Unique, contributed from first plugin.
    //
    // element1
    // - element1_1
    // - element1_2
    //
    var outline1_1 = Outline(element1_1, 0, 0, 0, 0, children: []);
    var outline1_2 = Outline(element1_2, 0, 0, 0, 0, children: []);
    var outline1 =
        Outline(element1, 0, 0, 0, 0, children: [outline1_1, outline1_2]);
    //
    // Same top level element, common child.
    //
    // element2
    // - element2_1
    // - element2_2
    // element2
    // - element3_1
    // - element3_2
    //
    var outline2_1 = Outline(element2_1, 0, 0, 0, 0, children: []);
    var outline2_2 = Outline(element2_2, 0, 0, 0, 0, children: []);
    var outline3_1 = Outline(element3_1, 0, 0, 0, 0, children: []);
    var outline3_2 = Outline(element3_2, 0, 0, 0, 0, children: []);
    var outline2 =
        Outline(element2, 0, 0, 0, 0, children: [outline2_1, outline2_2]);
    var outline3 =
        Outline(element2, 0, 0, 0, 0, children: [outline3_1, outline3_2]);
    var outline2and3 = Outline(element2, 0, 0, 0, 0,
        children: [outline2_1, outline2_2, outline3_2]);
    //
    // Unique, contributed from second plugin.
    //
    // element4
    // - element4_1
    //
    var outline4_1 = Outline(element4_1, 0, 0, 0, 0, children: []);
    var outline4 = Outline(element4, 0, 0, 0, 0, children: [outline4_1]);

    void runTest() {
      expect(
          merger.mergeOutline([
            [outline1, outline2],
            [],
            [outline3, outline4]
          ]),
          unorderedEquals([outline1, outline2and3, outline4]));
    }

    runTest();
    runTest();
  }

  void test_mergePrioritizedSourceChanges() {
    var kind1 = plugin.PrioritizedSourceChange(1, SourceChange(''));
    var kind2 = plugin.PrioritizedSourceChange(1, SourceChange(''));
    var kind3 = plugin.PrioritizedSourceChange(1, SourceChange(''));
    var kind4 = plugin.PrioritizedSourceChange(1, SourceChange(''));

    void runTest() {
      expect(
          merger.mergePrioritizedSourceChanges([
            [kind3, kind2],
            [],
            [kind4],
            [kind1]
          ]),
          unorderedEquals([kind1, kind2, kind3, kind4]));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_convertGetterToMethodFeedback() {
    RefactoringFeedback feedback1 = ConvertGetterToMethodFeedback();
    RefactoringFeedback feedback2 = ConvertGetterToMethodFeedback();

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(feedback1));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_convertMethodToGetterFeedback() {
    RefactoringFeedback feedback1 = ConvertMethodToGetterFeedback();
    RefactoringFeedback feedback2 = ConvertMethodToGetterFeedback();

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(feedback1));
    }

    runTest();
    runTest();
  }

  void
      test_mergeRefactoringFeedbacks_extractLocalVariableFeedback_addEverything() {
    var names1 = <String>['a', 'b', 'c'];
    var offsets1 = <int>[10, 20];
    var lengths1 = <int>[4, 5];
    var coveringOffsets1 = <int>[100, 150, 200];
    var coveringLengths1 = <int>[200, 100, 20];
    RefactoringFeedback feedback1 = ExtractLocalVariableFeedback(
        names1, offsets1, lengths1,
        coveringExpressionOffsets: coveringOffsets1,
        coveringExpressionLengths: coveringLengths1);
    var names2 = <String>['c', 'd'];
    var offsets2 = <int>[30];
    var lengths2 = <int>[6];
    var coveringOffsets2 = <int>[210];
    var coveringLengths2 = <int>[5];
    RefactoringFeedback feedback2 = ExtractLocalVariableFeedback(
        names2, offsets2, lengths2,
        coveringExpressionOffsets: coveringOffsets2,
        coveringExpressionLengths: coveringLengths2);
    var resultNames = <String>['a', 'b', 'c', 'd'];
    var resultOffsets = List<int>.from(offsets1)..addAll(offsets2);
    var resultLengths = List<int>.from(lengths1)..addAll(lengths2);
    var resultCoveringOffsets = List<int>.from(coveringOffsets1)
      ..addAll(coveringOffsets2);
    var resultCoveringLengths = List<int>.from(coveringLengths1)
      ..addAll(coveringLengths2);
    RefactoringFeedback result = ExtractLocalVariableFeedback(
        resultNames, resultOffsets, resultLengths,
        coveringExpressionOffsets: resultCoveringOffsets,
        coveringExpressionLengths: resultCoveringLengths);

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(result));
    }

    runTest();
    runTest();
  }

  void
      test_mergeRefactoringFeedbacks_extractLocalVariableFeedback_addOffsetsAndLengths() {
    var names1 = <String>['a', 'b', 'c'];
    var offsets1 = <int>[10, 20];
    var lengths1 = <int>[4, 5];
    var coveringOffsets1 = <int>[100, 150, 200];
    var coveringLengths1 = <int>[200, 100, 20];
    RefactoringFeedback feedback1 = ExtractLocalVariableFeedback(
        names1, offsets1, lengths1,
        coveringExpressionOffsets: coveringOffsets1,
        coveringExpressionLengths: coveringLengths1);
    var names2 = <String>[];
    var offsets2 = <int>[30];
    var lengths2 = <int>[6];
    RefactoringFeedback feedback2 =
        ExtractLocalVariableFeedback(names2, offsets2, lengths2);
    var resultOffsets = List<int>.from(offsets1)..addAll(offsets2);
    var resultLengths = List<int>.from(lengths1)..addAll(lengths2);
    RefactoringFeedback result = ExtractLocalVariableFeedback(
        names1, resultOffsets, resultLengths,
        coveringExpressionOffsets: coveringOffsets1,
        coveringExpressionLengths: coveringLengths1);

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(result));
    }

    runTest();
    runTest();
  }

  void
      test_mergeRefactoringFeedbacks_extractLocalVariableFeedback_noCoverings() {
    var names1 = <String>['a', 'b', 'c'];
    var offsets1 = <int>[10, 20];
    var lengths1 = <int>[4, 5];
    RefactoringFeedback feedback1 =
        ExtractLocalVariableFeedback(names1, offsets1, lengths1);
    var names2 = <String>[];
    var offsets2 = <int>[30];
    var lengths2 = <int>[6];
    RefactoringFeedback feedback2 =
        ExtractLocalVariableFeedback(names2, offsets2, lengths2);
    var resultOffsets = List<int>.from(offsets1)..addAll(offsets2);
    var resultLengths = List<int>.from(lengths1)..addAll(lengths2);
    RefactoringFeedback result =
        ExtractLocalVariableFeedback(names1, resultOffsets, resultLengths);

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(result));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_extractMethodFeedback() {
    var offset1 = 20;
    var length1 = 5;
    var returnType1 = 'int';
    var names1 = <String>['a', 'b', 'c'];
    var canCreateGetter1 = false;
    var parameters1 = <RefactoringMethodParameter>[];
    var offsets1 = <int>[10, 20];
    var lengths1 = <int>[4, 5];
    RefactoringFeedback feedback1 = ExtractMethodFeedback(offset1, length1,
        returnType1, names1, canCreateGetter1, parameters1, offsets1, lengths1);
    var names2 = <String>['c', 'd'];
    var canCreateGetter2 = true;
    var parameters2 = <RefactoringMethodParameter>[];
    var offsets2 = <int>[30];
    var lengths2 = <int>[6];
    RefactoringFeedback feedback2 = ExtractMethodFeedback(
        0, 0, '', names2, canCreateGetter2, parameters2, offsets2, lengths2);
    var resultNames = <String>['a', 'b', 'c', 'd'];
    var resultOffsets = List<int>.from(offsets1)..addAll(offsets2);
    var resultLengths = List<int>.from(lengths1)..addAll(lengths2);
    RefactoringFeedback result = ExtractMethodFeedback(
        offset1,
        length1,
        returnType1,
        resultNames,
        false,
        parameters1,
        resultOffsets,
        resultLengths);

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(result));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_inlineLocalVariableFeedback() {
    RefactoringFeedback feedback1 = InlineLocalVariableFeedback('a', 2);
    RefactoringFeedback feedback2 = InlineLocalVariableFeedback('a', 3);
    RefactoringFeedback result = InlineLocalVariableFeedback('a', 5);

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(result));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_inlineMethodFeedback() {
    RefactoringFeedback feedback1 = InlineMethodFeedback('a', false);
    RefactoringFeedback feedback2 = InlineMethodFeedback('a', false);

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(feedback1));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_moveFileFeedback() {
    RefactoringFeedback feedback1 = MoveFileFeedback();
    RefactoringFeedback feedback2 = MoveFileFeedback();

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(feedback1));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_renameFeedback() {
    RefactoringFeedback feedback1 = RenameFeedback(10, 0, '', '');
    RefactoringFeedback feedback2 = RenameFeedback(20, 0, '', '');

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(feedback1));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringKinds() {
    var kind1 = RefactoringKind.CONVERT_GETTER_TO_METHOD;
    var kind2 = RefactoringKind.EXTRACT_LOCAL_VARIABLE;
    var kind3 = RefactoringKind.INLINE_LOCAL_VARIABLE;
    var kind4 = RefactoringKind.MOVE_FILE;
    var kind5 = RefactoringKind.EXTRACT_LOCAL_VARIABLE;

    void runTest() {
      expect(
          merger.mergeRefactoringKinds([
            [kind1, kind2],
            [kind3],
            [],
            [kind4, kind5]
          ]),
          unorderedEquals([kind1, kind2, kind3, kind4]));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactorings() {
    RefactoringProblem problem(String message) =>
        RefactoringProblem(RefactoringProblemSeverity.ERROR, message);
    var problem1 = problem('1');
    var problem2 = problem('2');
    var problem3 = problem('3');
    var problem4 = problem('4');
    var problem5 = problem('5');
    var problem6 = problem('6');

    var initialProblems1 = <RefactoringProblem>[problem1, problem2];
    var optionsProblems1 = <RefactoringProblem>[problem3];
    var finalProblems1 = <RefactoringProblem>[problem4];
    RefactoringFeedback feedback1 = RenameFeedback(10, 0, '', '');
    var edit1 = SourceFileEdit('file1.dart', 11, edits: <SourceEdit>[
      SourceEdit(12, 2, 'w', id: 'e1'),
      SourceEdit(13, 3, 'x'),
    ]);
    var change1 = SourceChange('c1', edits: <SourceFileEdit>[edit1]);
    var potentialEdits1 = <String>['e1'];
    var result1 = EditGetRefactoringResult(
        initialProblems1, optionsProblems1, finalProblems1,
        feedback: feedback1, change: change1, potentialEdits: potentialEdits1);
    var initialProblems2 = <RefactoringProblem>[problem5];
    var optionsProblems2 = <RefactoringProblem>[];
    var finalProblems2 = <RefactoringProblem>[problem6];
    RefactoringFeedback feedback2 = RenameFeedback(20, 0, '', '');
    var edit2 = SourceFileEdit('file2.dart', 21, edits: <SourceEdit>[
      SourceEdit(12, 2, 'y', id: 'e2'),
      SourceEdit(13, 3, 'z'),
    ]);
    var change2 = SourceChange('c2', edits: <SourceFileEdit>[edit2]);
    var potentialEdits2 = <String>['e2'];
    var result2 = EditGetRefactoringResult(
        initialProblems2, optionsProblems2, finalProblems2,
        feedback: feedback2, change: change2, potentialEdits: potentialEdits2);
    var mergedInitialProblems = <RefactoringProblem>[
      problem1,
      problem2,
      problem5
    ];
    var mergedOptionsProblems = <RefactoringProblem>[problem3];
    var mergedFinalProblems = <RefactoringProblem>[problem4, problem6];
    var mergedChange =
        SourceChange('c1', edits: <SourceFileEdit>[edit1, edit2]);
    var mergedPotentialEdits = <String>['e1', 'e2'];
    var mergedResult = EditGetRefactoringResult(
        mergedInitialProblems, mergedOptionsProblems, mergedFinalProblems,
        feedback: merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
        change: mergedChange,
        potentialEdits: mergedPotentialEdits);

    void runTest() {
      expect(merger.mergeRefactorings([result1, result2]), mergedResult);
    }

    runTest();
    runTest();
  }

  void test_mergeSourceChanges() {
    var kind1 = SourceChange('');
    var kind2 = SourceChange('');
    var kind3 = SourceChange('');
    var kind4 = SourceChange('');

    void runTest() {
      expect(
          merger.mergeSourceChanges([
            [kind1, kind2],
            [],
            [kind3],
            [kind4]
          ]),
          unorderedEquals([kind1, kind2, kind3, kind4]));
    }

    runTest();
    runTest();
  }

  void test_overlaps_false_nested_left() {
    expect(merger.overlaps(3, 5, 1, 7, allowNesting: true), isFalse);
  }

  void test_overlaps_false_nested_right() {
    expect(merger.overlaps(1, 7, 3, 5, allowNesting: true), isFalse);
  }

  void test_overlaps_false_onLeft() {
    expect(merger.overlaps(1, 3, 5, 7), isFalse);
  }

  void test_overlaps_false_onRight() {
    expect(merger.overlaps(5, 7, 1, 3), isFalse);
  }

  void test_overlaps_true_nested_left() {
    expect(merger.overlaps(3, 5, 1, 7), isTrue);
  }

  void test_overlaps_true_nested_right() {
    expect(merger.overlaps(1, 7, 3, 5), isTrue);
  }

  void test_overlaps_true_onLeft() {
    expect(merger.overlaps(1, 5, 3, 7), isTrue);
  }

  void test_overlaps_true_onRight() {
    expect(merger.overlaps(3, 7, 1, 5), isTrue);
  }
}
