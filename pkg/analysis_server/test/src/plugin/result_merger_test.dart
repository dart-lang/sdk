// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/plugin/result_merger.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
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

  ResultMerger merger = new ResultMerger();

  void test_mergeAnalysisErrorFixes() {
    AnalysisError createError(int offset) {
      AnalysisErrorSeverity severity = AnalysisErrorSeverity.ERROR;
      AnalysisErrorType type = AnalysisErrorType.HINT;
      Location location = new Location('test.dart', offset, 2, 3, 4);
      return new AnalysisError(severity, type, location, '', '');
    }

    AnalysisError error1 = createError(10);
    AnalysisError error2 = createError(20);
    AnalysisError error3 = createError(30);
    AnalysisError error4 = createError(40);
    plugin.PrioritizedSourceChange change1 =
        new plugin.PrioritizedSourceChange(1, new SourceChange('a'));
    plugin.PrioritizedSourceChange change2 =
        new plugin.PrioritizedSourceChange(2, new SourceChange('b'));
    plugin.PrioritizedSourceChange change3 =
        new plugin.PrioritizedSourceChange(3, new SourceChange('c'));
    plugin.PrioritizedSourceChange change4 =
        new plugin.PrioritizedSourceChange(4, new SourceChange('d'));
    plugin.PrioritizedSourceChange change5 =
        new plugin.PrioritizedSourceChange(5, new SourceChange('e'));
    plugin.AnalysisErrorFixes fix1 =
        new plugin.AnalysisErrorFixes(error1, fixes: [change1]);
    plugin.AnalysisErrorFixes fix2 =
        new plugin.AnalysisErrorFixes(error2, fixes: [change2]);
    plugin.AnalysisErrorFixes fix3 =
        new plugin.AnalysisErrorFixes(error2, fixes: [change3]);
    plugin.AnalysisErrorFixes fix4 =
        new plugin.AnalysisErrorFixes(error3, fixes: [change4]);
    plugin.AnalysisErrorFixes fix5 =
        new plugin.AnalysisErrorFixes(error4, fixes: [change5]);
    plugin.AnalysisErrorFixes fix2and3 =
        new plugin.AnalysisErrorFixes(error2, fixes: [change2, change3]);

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
      AnalysisErrorSeverity severity = AnalysisErrorSeverity.ERROR;
      AnalysisErrorType type = AnalysisErrorType.HINT;
      Location location = new Location('test.dart', offset, 2, 3, 4);
      return new AnalysisError(severity, type, location, '', '');
    }

    AnalysisError error1 = createError(10);
    AnalysisError error2 = createError(20);
    AnalysisError error3 = createError(30);
    AnalysisError error4 = createError(40);

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
        new CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER, 50,
            completion, 0, 3, false, false);

    CompletionSuggestion suggestion1 = createSuggestion('a');
    CompletionSuggestion suggestion2 = createSuggestion('b');
    CompletionSuggestion suggestion3 = createSuggestion('c');
    CompletionSuggestion suggestion4 = createSuggestion('d');

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
    FoldingKind kind = FoldingKind.COMMENT;
    FoldingRegion region1 = new FoldingRegion(kind, 30, 5);
    FoldingRegion region2 = new FoldingRegion(kind, 0, 4);
    FoldingRegion region3 = new FoldingRegion(kind, 20, 6);
    FoldingRegion region4 = new FoldingRegion(kind, 10, 3);
    FoldingRegion region5 = new FoldingRegion(kind, 2, 6); // overlaps

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
    HighlightRegionType type = HighlightRegionType.COMMENT_BLOCK;
    HighlightRegion region1 = new HighlightRegion(type, 30, 5);
    HighlightRegion region2 = new HighlightRegion(type, 0, 4);
    HighlightRegion region3 = new HighlightRegion(type, 20, 6);
    HighlightRegion region4 = new HighlightRegion(type, 10, 3);

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
      return new NavigationTarget(
          ElementKind.CLASS, fileIndex, offset, 1, 0, 0);
    }

    //
    // Create the parameters from the server.
    //
    NavigationTarget target1_1 = target(0, 1);
    NavigationTarget target1_2 = target(0, 2);
    NavigationTarget target2_1 = target(1, 3);
    NavigationTarget target2_2 = target(1, 4);
    NavigationRegion region1_1 = new NavigationRegion(10, 4, [0]);
    NavigationRegion region1_2 = new NavigationRegion(20, 4, [1]);
    NavigationRegion region2_1 = new NavigationRegion(30, 4, [2]);
    NavigationRegion region2_2 = new NavigationRegion(40, 4, [3]);
    AnalysisNavigationParams params1 = new AnalysisNavigationParams(
        'a.dart',
        [region1_1, region1_2, region2_1, region2_2],
        [target1_1, target1_2, target2_1, target2_2],
        ['one.dart', 'two.dart']);
    //
    // Create the parameters from the second plugin.
    //
    // same file and offset as target 2_2
    NavigationTarget target2_3 = target(0, 4);
    NavigationTarget target2_4 = target(0, 5);
    NavigationTarget target3_1 = target(1, 6);
    NavigationTarget target3_2 = target(1, 7);
    // same region and target as region2_2
    NavigationRegion region2_3 = new NavigationRegion(40, 4, [0]);
    // same region as region2_2, but a different target
    NavigationRegion region2_4 = new NavigationRegion(40, 4, [2]);
    NavigationRegion region2_5 = new NavigationRegion(50, 4, [1]);
    NavigationRegion region3_1 = new NavigationRegion(60, 4, [2]);
    NavigationRegion region3_2 = new NavigationRegion(70, 4, [3]);
    AnalysisNavigationParams params2 = new AnalysisNavigationParams(
        'a.dart',
        [region2_3, region2_4, region2_5, region3_1, region3_2],
        [target2_3, target2_4, target3_1, target3_2],
        ['two.dart', 'three.dart']);
    AnalysisNavigationParams expected = new AnalysisNavigationParams('a.dart', [
      region1_1,
      region1_2,
      region2_1,
      new NavigationRegion(40, 4, [3, 5]), // union of region2_2 and region2_4
      new NavigationRegion(50, 4, [4]), // region2_5
      new NavigationRegion(60, 4, [5]), // region3_1
      new NavigationRegion(70, 4, [6]), // region3_2
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
    Element element1 = new Element(ElementKind.CLASS, 'e1', 0);
    Element element2 = new Element(ElementKind.CLASS, 'e2', 0);
    Element element3 = new Element(ElementKind.CLASS, 'e3', 0);
    Occurrences occurrence1 = new Occurrences(element1, [1, 2, 4], 2);
    Occurrences occurrence2 = new Occurrences(element2, [5], 2);
    Occurrences occurrence3 = new Occurrences(element1, [2, 3], 2);
    Occurrences occurrence4 = new Occurrences(element3, [8], 2);
    Occurrences occurrence5 = new Occurrences(element2, [6], 2);
    Occurrences occurrence6 = new Occurrences(element3, [7, 9], 2);
    Occurrences result1 = new Occurrences(element1, [1, 2, 3, 4], 2);
    Occurrences result2 = new Occurrences(element2, [5, 6], 2);
    Occurrences result3 = new Occurrences(element3, [7, 8, 9], 2);

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
      Location location = new Location('', offset, 0, 0, 0);
      return new Element(kind, '', 0, location: location);
    }

    Element element1 = element(ElementKind.CLASS, 100);
    Element element1_1 = element(ElementKind.METHOD, 110);
    Element element1_2 = element(ElementKind.METHOD, 120);
    Element element2 = element(ElementKind.CLASS, 200);
    Element element2_1 = element(ElementKind.METHOD, 210);
    Element element2_2 = element(ElementKind.METHOD, 220);
    Element element3_1 = element(ElementKind.METHOD, 220); // same as 2_2
    Element element3_2 = element(ElementKind.METHOD, 230);
    Element element4 = element(ElementKind.CLASS, 300);
    Element element4_1 = element(ElementKind.METHOD, 310);
    //
    // Unique, contributed from first plugin.
    //
    // element1
    // - element1_1
    // - element1_2
    //
    Outline outline1_1 = new Outline(element1_1, 0, 0, children: []);
    Outline outline1_2 = new Outline(element1_2, 0, 0, children: []);
    Outline outline1 =
        new Outline(element1, 0, 0, children: [outline1_1, outline1_2]);
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
    Outline outline2_1 = new Outline(element2_1, 0, 0, children: []);
    Outline outline2_2 = new Outline(element2_2, 0, 0, children: []);
    Outline outline3_1 = new Outline(element3_1, 0, 0, children: []);
    Outline outline3_2 = new Outline(element3_2, 0, 0, children: []);
    Outline outline2 =
        new Outline(element2, 0, 0, children: [outline2_1, outline2_2]);
    Outline outline3 =
        new Outline(element2, 0, 0, children: [outline3_1, outline3_2]);
    Outline outline2and3 = new Outline(element2, 0, 0,
        children: [outline2_1, outline2_2, outline3_2]);
    //
    // Unique, contributed from second plugin.
    //
    // element4
    // - element4_1
    //
    Outline outline4_1 = new Outline(element4_1, 0, 0, children: []);
    Outline outline4 = new Outline(element4, 0, 0, children: [outline4_1]);

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
    plugin.PrioritizedSourceChange kind1 =
        new plugin.PrioritizedSourceChange(1, new SourceChange(''));
    plugin.PrioritizedSourceChange kind2 =
        new plugin.PrioritizedSourceChange(1, new SourceChange(''));
    plugin.PrioritizedSourceChange kind3 =
        new plugin.PrioritizedSourceChange(1, new SourceChange(''));
    plugin.PrioritizedSourceChange kind4 =
        new plugin.PrioritizedSourceChange(1, new SourceChange(''));

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
    RefactoringFeedback feedback1 = new ConvertGetterToMethodFeedback();
    RefactoringFeedback feedback2 = new ConvertGetterToMethodFeedback();

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(feedback1));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_convertMethodToGetterFeedback() {
    RefactoringFeedback feedback1 = new ConvertMethodToGetterFeedback();
    RefactoringFeedback feedback2 = new ConvertMethodToGetterFeedback();

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(feedback1));
    }

    runTest();
    runTest();
  }

  void
      test_mergeRefactoringFeedbacks_extractLocalVariableFeedback_addEverything() {
    List<String> names1 = <String>['a', 'b', 'c'];
    List<int> offsets1 = <int>[10, 20];
    List<int> lengths1 = <int>[4, 5];
    List<int> coveringOffsets1 = <int>[100, 150, 200];
    List<int> coveringLengths1 = <int>[200, 100, 20];
    RefactoringFeedback feedback1 = new ExtractLocalVariableFeedback(
        names1, offsets1, lengths1,
        coveringExpressionOffsets: coveringOffsets1,
        coveringExpressionLengths: coveringLengths1);
    List<String> names2 = <String>['c', 'd'];
    List<int> offsets2 = <int>[30];
    List<int> lengths2 = <int>[6];
    List<int> coveringOffsets2 = <int>[210];
    List<int> coveringLengths2 = <int>[5];
    RefactoringFeedback feedback2 = new ExtractLocalVariableFeedback(
        names2, offsets2, lengths2,
        coveringExpressionOffsets: coveringOffsets2,
        coveringExpressionLengths: coveringLengths2);
    List<String> resultNames = <String>['a', 'b', 'c', 'd'];
    List<int> resultOffsets = new List<int>.from(offsets1)..addAll(offsets2);
    List<int> resultLengths = new List<int>.from(lengths1)..addAll(lengths2);
    List<int> resultCoveringOffsets = new List<int>.from(coveringOffsets1)
      ..addAll(coveringOffsets2);
    List<int> resultCoveringLengths = new List<int>.from(coveringLengths1)
      ..addAll(coveringLengths2);
    RefactoringFeedback result = new ExtractLocalVariableFeedback(
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
    List<String> names1 = <String>['a', 'b', 'c'];
    List<int> offsets1 = <int>[10, 20];
    List<int> lengths1 = <int>[4, 5];
    List<int> coveringOffsets1 = <int>[100, 150, 200];
    List<int> coveringLengths1 = <int>[200, 100, 20];
    RefactoringFeedback feedback1 = new ExtractLocalVariableFeedback(
        names1, offsets1, lengths1,
        coveringExpressionOffsets: coveringOffsets1,
        coveringExpressionLengths: coveringLengths1);
    List<String> names2 = <String>[];
    List<int> offsets2 = <int>[30];
    List<int> lengths2 = <int>[6];
    RefactoringFeedback feedback2 =
        new ExtractLocalVariableFeedback(names2, offsets2, lengths2);
    List<int> resultOffsets = new List<int>.from(offsets1)..addAll(offsets2);
    List<int> resultLengths = new List<int>.from(lengths1)..addAll(lengths2);
    RefactoringFeedback result = new ExtractLocalVariableFeedback(
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
    List<String> names1 = <String>['a', 'b', 'c'];
    List<int> offsets1 = <int>[10, 20];
    List<int> lengths1 = <int>[4, 5];
    RefactoringFeedback feedback1 =
        new ExtractLocalVariableFeedback(names1, offsets1, lengths1);
    List<String> names2 = <String>[];
    List<int> offsets2 = <int>[30];
    List<int> lengths2 = <int>[6];
    RefactoringFeedback feedback2 =
        new ExtractLocalVariableFeedback(names2, offsets2, lengths2);
    List<int> resultOffsets = new List<int>.from(offsets1)..addAll(offsets2);
    List<int> resultLengths = new List<int>.from(lengths1)..addAll(lengths2);
    RefactoringFeedback result =
        new ExtractLocalVariableFeedback(names1, resultOffsets, resultLengths);

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(result));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_extractMethodFeedback() {
    int offset1 = 20;
    int length1 = 5;
    String returnType1 = 'int';
    List<String> names1 = <String>['a', 'b', 'c'];
    bool canCreateGetter1 = false;
    List<RefactoringMethodParameter> parameters1 =
        <RefactoringMethodParameter>[];
    List<int> offsets1 = <int>[10, 20];
    List<int> lengths1 = <int>[4, 5];
    RefactoringFeedback feedback1 = new ExtractMethodFeedback(offset1, length1,
        returnType1, names1, canCreateGetter1, parameters1, offsets1, lengths1);
    List<String> names2 = <String>['c', 'd'];
    bool canCreateGetter2 = true;
    List<RefactoringMethodParameter> parameters2 =
        <RefactoringMethodParameter>[];
    List<int> offsets2 = <int>[30];
    List<int> lengths2 = <int>[6];
    RefactoringFeedback feedback2 = new ExtractMethodFeedback(
        0, 0, '', names2, canCreateGetter2, parameters2, offsets2, lengths2);
    List<String> resultNames = <String>['a', 'b', 'c', 'd'];
    List<int> resultOffsets = new List<int>.from(offsets1)..addAll(offsets2);
    List<int> resultLengths = new List<int>.from(lengths1)..addAll(lengths2);
    RefactoringFeedback result = new ExtractMethodFeedback(
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
    RefactoringFeedback feedback1 = new InlineLocalVariableFeedback('a', 2);
    RefactoringFeedback feedback2 = new InlineLocalVariableFeedback('a', 3);
    RefactoringFeedback result = new InlineLocalVariableFeedback('a', 5);

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(result));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_inlineMethodFeedback() {
    RefactoringFeedback feedback1 = new InlineMethodFeedback('a', false);
    RefactoringFeedback feedback2 = new InlineMethodFeedback('a', false);

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(feedback1));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_moveFileFeedback() {
    RefactoringFeedback feedback1 = new MoveFileFeedback();
    RefactoringFeedback feedback2 = new MoveFileFeedback();

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(feedback1));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringFeedbacks_renameFeedback() {
    RefactoringFeedback feedback1 = new RenameFeedback(10, 0, '', '');
    RefactoringFeedback feedback2 = new RenameFeedback(20, 0, '', '');

    void runTest() {
      expect(merger.mergeRefactoringFeedbacks([feedback1, feedback2]),
          equals(feedback1));
    }

    runTest();
    runTest();
  }

  void test_mergeRefactoringKinds() {
    RefactoringKind kind1 = RefactoringKind.CONVERT_GETTER_TO_METHOD;
    RefactoringKind kind2 = RefactoringKind.EXTRACT_LOCAL_VARIABLE;
    RefactoringKind kind3 = RefactoringKind.INLINE_LOCAL_VARIABLE;
    RefactoringKind kind4 = RefactoringKind.MOVE_FILE;
    RefactoringKind kind5 = RefactoringKind.EXTRACT_LOCAL_VARIABLE;

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
        new RefactoringProblem(RefactoringProblemSeverity.ERROR, message);
    RefactoringProblem problem1 = problem('1');
    RefactoringProblem problem2 = problem('2');
    RefactoringProblem problem3 = problem('3');
    RefactoringProblem problem4 = problem('4');
    RefactoringProblem problem5 = problem('5');
    RefactoringProblem problem6 = problem('6');

    List<RefactoringProblem> initialProblems1 = <RefactoringProblem>[
      problem1,
      problem2
    ];
    List<RefactoringProblem> optionsProblems1 = <RefactoringProblem>[problem3];
    List<RefactoringProblem> finalProblems1 = <RefactoringProblem>[problem4];
    RefactoringFeedback feedback1 = new RenameFeedback(10, 0, '', '');
    SourceFileEdit edit1 =
        new SourceFileEdit('file1.dart', 11, edits: <SourceEdit>[
      new SourceEdit(12, 2, 'w', id: 'e1'),
      new SourceEdit(13, 3, 'x'),
    ]);
    SourceChange change1 =
        new SourceChange('c1', edits: <SourceFileEdit>[edit1]);
    List<String> potentialEdits1 = <String>['e1'];
    EditGetRefactoringResult result1 = new EditGetRefactoringResult(
        initialProblems1, optionsProblems1, finalProblems1,
        feedback: feedback1, change: change1, potentialEdits: potentialEdits1);
    List<RefactoringProblem> initialProblems2 = <RefactoringProblem>[problem5];
    List<RefactoringProblem> optionsProblems2 = <RefactoringProblem>[];
    List<RefactoringProblem> finalProblems2 = <RefactoringProblem>[problem6];
    RefactoringFeedback feedback2 = new RenameFeedback(20, 0, '', '');
    SourceFileEdit edit2 =
        new SourceFileEdit('file2.dart', 21, edits: <SourceEdit>[
      new SourceEdit(12, 2, 'y', id: 'e2'),
      new SourceEdit(13, 3, 'z'),
    ]);
    SourceChange change2 =
        new SourceChange('c2', edits: <SourceFileEdit>[edit2]);
    List<String> potentialEdits2 = <String>['e2'];
    EditGetRefactoringResult result2 = new EditGetRefactoringResult(
        initialProblems2, optionsProblems2, finalProblems2,
        feedback: feedback2, change: change2, potentialEdits: potentialEdits2);
    List<RefactoringProblem> mergedInitialProblems = <RefactoringProblem>[
      problem1,
      problem2,
      problem5
    ];
    List<RefactoringProblem> mergedOptionsProblems = <RefactoringProblem>[
      problem3
    ];
    List<RefactoringProblem> mergedFinalProblems = <RefactoringProblem>[
      problem4,
      problem6
    ];
    SourceChange mergedChange =
        new SourceChange('c1', edits: <SourceFileEdit>[edit1, edit2]);
    List<String> mergedPotentialEdits = <String>['e1', 'e2'];
    EditGetRefactoringResult mergedResult = new EditGetRefactoringResult(
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
    SourceChange kind1 = new SourceChange('');
    SourceChange kind2 = new SourceChange('');
    SourceChange kind3 = new SourceChange('');
    SourceChange kind4 = new SourceChange('');

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
