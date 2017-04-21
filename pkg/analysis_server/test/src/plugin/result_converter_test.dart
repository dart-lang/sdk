// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart' as server;
import 'package:analysis_server/src/plugin/result_converter.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart' as server;
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

  void test_convertAnalysisError() {
    plugin.AnalysisError initial = pluginAnalysisError(0, 0);
    server.AnalysisError expected = serverAnalysisError(0, 0);
    expect(converter.convertAnalysisError(initial), expected);
  }

  void test_convertAnalysisErrorFixes() {
    plugin.AnalysisErrorFixes initial = new plugin.AnalysisErrorFixes(
        pluginAnalysisError(0, 0),
        fixes: <plugin.PrioritizedSourceChange>[
          new plugin.PrioritizedSourceChange(100, pluginSourceChange(4, 4))
        ]);
    server.AnalysisErrorFixes expected = new server.AnalysisErrorFixes(
        serverAnalysisError(0, 0),
        fixes: <server.SourceChange>[serverSourceChange(4, 4)]);
    expect(converter.convertAnalysisErrorFixes(initial), expected);
  }

  void test_convertAnalysisNavigationParams() {
    plugin.AnalysisNavigationParams initial =
        new plugin.AnalysisNavigationParams('a.dart', <plugin.NavigationRegion>[
      new plugin.NavigationRegion(1, 2, <int>[3, 4])
    ], <plugin.NavigationTarget>[
      new plugin.NavigationTarget(plugin.ElementKind.FIELD, 5, 6, 7, 8, 9)
    ], <String>[
      'a',
      'b'
    ]);
    server.AnalysisNavigationParams expected =
        new server.AnalysisNavigationParams('a.dart', <server.NavigationRegion>[
      new server.NavigationRegion(1, 2, <int>[3, 4])
    ], <server.NavigationTarget>[
      new server.NavigationTarget(server.ElementKind.FIELD, 5, 6, 7, 8, 9)
    ], <String>[
      'a',
      'b'
    ]);
    expect(converter.convertAnalysisNavigationParams(initial), expected);
  }

  void test_convertCompletionSuggestion() {
    plugin.CompletionSuggestion initial = new plugin.CompletionSuggestion(
        plugin.CompletionSuggestionKind.IMPORT, 1, 'a', 2, 3, true, false,
        docSummary: 'b',
        docComplete: 'c',
        declaringType: 'd',
        element: pluginElement(4, 4),
        returnType: 'i',
        parameterNames: <String>['j', 'k'],
        parameterTypes: <String>[],
        requiredParameterCount: 9,
        hasNamedParameters: true,
        parameterName: 'l',
        parameterType: 'm',
        importUri: 'n');
    server.CompletionSuggestion expected = new server.CompletionSuggestion(
        server.CompletionSuggestionKind.IMPORT, 1, 'a', 2, 3, true, false,
        docSummary: 'b',
        docComplete: 'c',
        declaringType: 'd',
        element: serverElement(4, 4),
        returnType: 'i',
        parameterNames: <String>['j', 'k'],
        parameterTypes: <String>[],
        requiredParameterCount: 9,
        hasNamedParameters: true,
        parameterName: 'l',
        parameterType: 'm',
        importUri: 'n');
    expect(converter.convertCompletionSuggestion(initial), expected);
  }

  void test_convertEditGetRefactoringResult_inlineMethod() {
    plugin.EditGetRefactoringResult initial =
        new plugin.EditGetRefactoringResult(
            <plugin.RefactoringProblem>[pluginRefactoringProblem(0, 0)],
            <plugin.RefactoringProblem>[pluginRefactoringProblem(2, 4)],
            <plugin.RefactoringProblem>[pluginRefactoringProblem(4, 8)],
            feedback:
                new plugin.InlineMethodFeedback('a', true, className: 'b'),
            change: pluginSourceChange(6, 12),
            potentialEdits: <String>['f']);
    server.EditGetRefactoringResult expected =
        new server.EditGetRefactoringResult(
            <server.RefactoringProblem>[serverRefactoringProblem(0, 0)],
            <server.RefactoringProblem>[serverRefactoringProblem(2, 4)],
            <server.RefactoringProblem>[serverRefactoringProblem(4, 8)],
            feedback:
                new server.InlineMethodFeedback('a', true, className: 'b'),
            change: serverSourceChange(6, 12),
            potentialEdits: <String>['f']);
    expect(
        converter.convertEditGetRefactoringResult(
            plugin.RefactoringKind.INLINE_METHOD, initial),
        expected);
  }

  void test_convertEditGetRefactoringResult_moveFile() {
    plugin.EditGetRefactoringResult initial =
        new plugin.EditGetRefactoringResult(
            <plugin.RefactoringProblem>[pluginRefactoringProblem(0, 0)],
            <plugin.RefactoringProblem>[pluginRefactoringProblem(2, 4)],
            <plugin.RefactoringProblem>[pluginRefactoringProblem(4, 8)],
            feedback: new plugin.MoveFileFeedback(),
            change: pluginSourceChange(6, 12),
            potentialEdits: <String>['f']);
    server.EditGetRefactoringResult expected =
        new server.EditGetRefactoringResult(
            <server.RefactoringProblem>[serverRefactoringProblem(0, 0)],
            <server.RefactoringProblem>[serverRefactoringProblem(2, 4)],
            <server.RefactoringProblem>[serverRefactoringProblem(4, 8)],
            change: serverSourceChange(6, 12),
            potentialEdits: <String>['f']);
    expect(
        converter.convertEditGetRefactoringResult(
            plugin.RefactoringKind.MOVE_FILE, initial),
        expected);
  }

  void test_convertFoldingRegion() {
    plugin.FoldingRegion initial = pluginFoldingRegion(1, 2);
    server.FoldingRegion expected = serverFoldingRegion(1, 2);
    expect(converter.convertFoldingRegion(initial), expected);
  }

  void test_convertHighlightRegion() {
    plugin.HighlightRegion initial = pluginHighlightRegion(1, 2);
    server.HighlightRegion expected = serverHighlightRegion(1, 2);
    expect(converter.convertHighlightRegion(initial), expected);
  }

  void test_convertOccurrences() {
    plugin.Occurrences initial = pluginOccurrences(1, 1);
    server.Occurrences expected = serverOccurrences(1, 1);
    expect(converter.convertOccurrences(initial), expected);
  }

  void test_convertOutline() {
    plugin.Outline initial = new plugin.Outline(pluginElement(1, 1), 6, 7,
        children: <plugin.Outline>[
          new plugin.Outline(pluginElement(6, 8), 14, 15)
        ]);
    server.Outline expected = new server.Outline(serverElement(1, 1), 6, 7,
        children: <server.Outline>[
          new server.Outline(serverElement(6, 8), 14, 15)
        ]);
    expect(converter.convertOutline(initial), expected);
  }

  void test_convertPrioritizedSourceChange() {
    plugin.PrioritizedSourceChange initial =
        new plugin.PrioritizedSourceChange(100, pluginSourceChange(0, 0));
    server.SourceChange expected = serverSourceChange(0, 0);
    expect(converter.convertPrioritizedSourceChange(initial), expected);
  }

  void test_convertRefactoringFeedback_convertGetterToMethod() {
    plugin.ConvertGetterToMethodFeedback initial =
        new plugin.ConvertGetterToMethodFeedback();
    expect(
        converter.convertRefactoringFeedback(
            plugin.RefactoringKind.CONVERT_GETTER_TO_METHOD, initial),
        isNull);
  }

  void test_convertRefactoringFeedback_convertMethodToGetter() {
    plugin.ConvertMethodToGetterFeedback initial =
        new plugin.ConvertMethodToGetterFeedback();
    expect(
        converter.convertRefactoringFeedback(
            plugin.RefactoringKind.CONVERT_METHOD_TO_GETTER, initial),
        isNull);
  }

  void test_convertRefactoringFeedback_extractLocalVariable() {
    plugin.ExtractLocalVariableFeedback initial =
        new plugin.ExtractLocalVariableFeedback(
            <String>['a', 'b'], <int>[1, 2], <int>[3],
            coveringExpressionOffsets: <int>[4, 5],
            coveringExpressionLengths: <int>[6]);
    server.ExtractLocalVariableFeedback expected =
        new server.ExtractLocalVariableFeedback(
            <String>['a', 'b'], <int>[1, 2], <int>[3],
            coveringExpressionOffsets: <int>[4, 5],
            coveringExpressionLengths: <int>[6]);
    expect(
        converter.convertRefactoringFeedback(
            plugin.RefactoringKind.EXTRACT_LOCAL_VARIABLE, initial),
        expected);
  }

  void test_convertRefactoringFeedback_extractMethod() {
    plugin.ExtractMethodFeedback initial = new plugin.ExtractMethodFeedback(
        1,
        2,
        'a',
        <String>['b', 'c'],
        true,
        <plugin.RefactoringMethodParameter>[
          new plugin.RefactoringMethodParameter(
              plugin.RefactoringMethodParameterKind.NAMED, 'd', 'e',
              id: 'f', parameters: 'g')
        ],
        <int>[3, 4],
        <int>[5, 6]);
    server.ExtractMethodFeedback expected = new server.ExtractMethodFeedback(
        1,
        2,
        'a',
        <String>['b', 'c'],
        true,
        <server.RefactoringMethodParameter>[
          new server.RefactoringMethodParameter(
              server.RefactoringMethodParameterKind.NAMED, 'd', 'e',
              id: 'f', parameters: 'g')
        ],
        <int>[3, 4],
        <int>[5, 6]);
    expect(
        converter.convertRefactoringFeedback(
            plugin.RefactoringKind.EXTRACT_METHOD, initial),
        expected);
  }

  void test_convertRefactoringFeedback_inlineLocalVariable() {
    plugin.InlineLocalVariableFeedback initial =
        new plugin.InlineLocalVariableFeedback('a', 1);
    server.InlineLocalVariableFeedback expected =
        new server.InlineLocalVariableFeedback('a', 1);
    expect(
        converter.convertRefactoringFeedback(
            plugin.RefactoringKind.INLINE_LOCAL_VARIABLE, initial),
        expected);
  }

  void test_convertRefactoringFeedback_inlineMethod() {
    plugin.InlineMethodFeedback initial =
        new plugin.InlineMethodFeedback('a', true, className: 'b');
    server.InlineMethodFeedback expected =
        new server.InlineMethodFeedback('a', true, className: 'b');
    expect(
        converter.convertRefactoringFeedback(
            plugin.RefactoringKind.INLINE_METHOD, initial),
        expected);
  }

  void test_convertRefactoringFeedback_moveFile() {
    plugin.MoveFileFeedback initial = new plugin.MoveFileFeedback();
    expect(
        converter.convertRefactoringFeedback(
            plugin.RefactoringKind.MOVE_FILE, initial),
        isNull);
  }

  void test_convertRefactoringFeedback_rename() {
    plugin.RenameFeedback initial = new plugin.RenameFeedback(1, 2, 'a', 'b');
    server.RenameFeedback expected = new server.RenameFeedback(1, 2, 'a', 'b');
    expect(
        converter.convertRefactoringFeedback(
            plugin.RefactoringKind.RENAME, initial),
        expected);
  }

  void test_convertRefactoringKind() {
    Map<plugin.RefactoringKind, server.RefactoringKind> kindMap =
        <plugin.RefactoringKind, server.RefactoringKind>{
      plugin.RefactoringKind.CONVERT_GETTER_TO_METHOD:
          server.RefactoringKind.CONVERT_GETTER_TO_METHOD,
      plugin.RefactoringKind.CONVERT_METHOD_TO_GETTER:
          server.RefactoringKind.CONVERT_METHOD_TO_GETTER,
      plugin.RefactoringKind.EXTRACT_LOCAL_VARIABLE:
          server.RefactoringKind.EXTRACT_LOCAL_VARIABLE,
      plugin.RefactoringKind.EXTRACT_METHOD:
          server.RefactoringKind.EXTRACT_METHOD,
      plugin.RefactoringKind.INLINE_LOCAL_VARIABLE:
          server.RefactoringKind.INLINE_LOCAL_VARIABLE,
      plugin.RefactoringKind.INLINE_METHOD:
          server.RefactoringKind.INLINE_METHOD,
      plugin.RefactoringKind.MOVE_FILE: server.RefactoringKind.MOVE_FILE,
      plugin.RefactoringKind.RENAME: server.RefactoringKind.RENAME,
      plugin.RefactoringKind.SORT_MEMBERS: server.RefactoringKind.SORT_MEMBERS,
    };
    kindMap.forEach(
        (plugin.RefactoringKind pluginKind, server.RefactoringKind serverKind) {
      expect(converter.convertRefactoringKind(pluginKind), serverKind);
    });
  }

  void test_convertSourceChange() {
    plugin.SourceChange initial = pluginSourceChange(0, 0);
    server.SourceChange expected = serverSourceChange(0, 0);
    expect(converter.convertSourceChange(initial), expected);
  }
}
