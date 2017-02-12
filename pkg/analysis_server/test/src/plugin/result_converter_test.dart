// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart' as server;
import 'package:analysis_server/src/plugin/result_converter.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart' as server;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResultConverterTest);
  });
}

@reflectiveTest
class ResultConverterTest {
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
    plugin.AnalysisError initial = _pluginAnalysisError();
    server.AnalysisError expected = _serverAnalysisError();
    expect(converter.convertAnalysisError(initial), expected);
  }

  void test_convertAnalysisErrorFixes() {
    plugin.AnalysisErrorFixes initial = new plugin.AnalysisErrorFixes(
        _pluginAnalysisError(),
        fixes: <plugin.PrioritizedSourceChange>[
          new plugin.PrioritizedSourceChange(100, _pluginSourceChange())
        ]);
    server.AnalysisErrorFixes expected = new server.AnalysisErrorFixes(
        _serverAnalysisError(),
        fixes: <server.SourceChange>[_serverSourceChange()]);
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
        element: _pluginElement(4, 4),
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
        element: _serverElement(4, 4),
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
            <plugin.RefactoringProblem>[_pluginRefactoringProblem('a', 1)],
            <plugin.RefactoringProblem>[_pluginRefactoringProblem('b', 5)],
            <plugin.RefactoringProblem>[_pluginRefactoringProblem('c', 9)],
            feedback:
                new plugin.InlineMethodFeedback('a', true, className: 'b'),
            change: _pluginSourceChange(),
            potentialEdits: <String>['f']);
    server.EditGetRefactoringResult expected =
        new server.EditGetRefactoringResult(
            <server.RefactoringProblem>[_serverRefactoringProblem('a', 1)],
            <server.RefactoringProblem>[_serverRefactoringProblem('b', 5)],
            <server.RefactoringProblem>[_serverRefactoringProblem('c', 9)],
            feedback:
                new server.InlineMethodFeedback('a', true, className: 'b'),
            change: _serverSourceChange(),
            potentialEdits: <String>['f']);
    expect(
        converter.convertEditGetRefactoringResult(
            plugin.RefactoringKind.INLINE_METHOD, initial),
        expected);
  }

  void test_convertEditGetRefactoringResult_moveFile() {
    plugin.EditGetRefactoringResult initial =
        new plugin.EditGetRefactoringResult(
            <plugin.RefactoringProblem>[_pluginRefactoringProblem('a', 1)],
            <plugin.RefactoringProblem>[_pluginRefactoringProblem('b', 5)],
            <plugin.RefactoringProblem>[_pluginRefactoringProblem('c', 9)],
            feedback: new plugin.MoveFileFeedback(),
            change: _pluginSourceChange(),
            potentialEdits: <String>['f']);
    server.EditGetRefactoringResult expected =
        new server.EditGetRefactoringResult(
            <server.RefactoringProblem>[_serverRefactoringProblem('a', 1)],
            <server.RefactoringProblem>[_serverRefactoringProblem('b', 5)],
            <server.RefactoringProblem>[_serverRefactoringProblem('c', 9)],
            change: _serverSourceChange(),
            potentialEdits: <String>['f']);
    expect(
        converter.convertEditGetRefactoringResult(
            plugin.RefactoringKind.MOVE_FILE, initial),
        expected);
  }

  void test_convertFoldingRegion() {
    plugin.FoldingRegion initial =
        new plugin.FoldingRegion(plugin.FoldingKind.COMMENT, 1, 2);
    server.FoldingRegion expected =
        new server.FoldingRegion(server.FoldingKind.COMMENT, 1, 2);
    expect(converter.convertFoldingRegion(initial), expected);
  }

  void test_convertHighlightRegion() {
    plugin.HighlightRegion initial =
        new plugin.HighlightRegion(plugin.HighlightRegionType.FIELD, 1, 2);
    server.HighlightRegion expected =
        new server.HighlightRegion(server.HighlightRegionType.FIELD, 1, 2);
    expect(converter.convertHighlightRegion(initial), expected);
  }

  void test_convertOccurrences() {
    plugin.Occurrences initial =
        new plugin.Occurrences(_pluginElement(1, 1), <int>[6, 7], 8);
    server.Occurrences expected =
        new server.Occurrences(_serverElement(1, 1), <int>[6, 7], 8);
    expect(converter.convertOccurrences(initial), expected);
  }

  void test_convertOutline() {
    plugin.Outline initial = new plugin.Outline(_pluginElement(1, 1), 6, 7,
        children: <plugin.Outline>[
          new plugin.Outline(_pluginElement(6, 8), 14, 15)
        ]);
    server.Outline expected = new server.Outline(_serverElement(1, 1), 6, 7,
        children: <server.Outline>[
          new server.Outline(_serverElement(6, 8), 14, 15)
        ]);
    expect(converter.convertOutline(initial), expected);
  }

  void test_convertPrioritizedSourceChange() {
    plugin.PrioritizedSourceChange initial =
        new plugin.PrioritizedSourceChange(100, _pluginSourceChange());
    server.SourceChange expected = _serverSourceChange();
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
      plugin.RefactoringKind.INLINE_LOCAL_VARIABLE:
          server.RefactoringKind.INLINE_LOCAL_VARIABLE,
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
    plugin.SourceChange initial = _pluginSourceChange();
    server.SourceChange expected = _serverSourceChange();
    expect(converter.convertSourceChange(initial), expected);
  }

  String _fileName(int index) => '${strings[index]}.dart';

  plugin.AnalysisError _pluginAnalysisError() => new plugin.AnalysisError(
      plugin.AnalysisErrorSeverity.ERROR,
      plugin.AnalysisErrorType.COMPILE_TIME_ERROR,
      new plugin.Location('a.dart', 1, 2, 3, 4),
      'm',
      'c',
      correction: 'n',
      hasFix: true);

  /**
   * On return, increment [stringIndex] by 5 and [intIndex] by 5.
   */
  plugin.Element _pluginElement(int stringIndex, int intIndex) =>
      new plugin.Element(
          plugin.ElementKind.CLASS, strings[stringIndex++], intIndex++,
          location: new plugin.Location(_fileName(stringIndex++), intIndex++,
              intIndex++, intIndex++, intIndex++),
          parameters: strings[stringIndex++],
          returnType: strings[stringIndex++],
          typeParameters: strings[stringIndex++]);

  plugin.Location _pluginLocation(String baseName, int index) =>
      new plugin.Location(
          '$baseName.dart', index, index + 1, index + 2, index + 3);

  plugin.RefactoringProblem _pluginRefactoringProblem(
          String baseName, int index) =>
      new plugin.RefactoringProblem(
          plugin.RefactoringProblemSeverity.FATAL, baseName,
          location: _pluginLocation(baseName, index));

  plugin.SourceChange _pluginSourceChange() => new plugin.SourceChange('m',
      edits: <plugin.SourceFileEdit>[
        new plugin.SourceFileEdit('a.dart', 1,
            edits: <plugin.SourceEdit>[new plugin.SourceEdit(2, 3, 'r')])
      ],
      linkedEditGroups: <plugin.LinkedEditGroup>[
        new plugin.LinkedEditGroup(
            <plugin.Position>[new plugin.Position('b.dart', 4)],
            5,
            <plugin.LinkedEditSuggestion>[
              new plugin.LinkedEditSuggestion(
                  'v', plugin.LinkedEditSuggestionKind.METHOD)
            ])
      ],
      selection: new plugin.Position('c.dart', 6));

  server.AnalysisError _serverAnalysisError() {
    return new server.AnalysisError(
        server.AnalysisErrorSeverity.ERROR,
        server.AnalysisErrorType.COMPILE_TIME_ERROR,
        new server.Location('a.dart', 1, 2, 3, 4),
        'm',
        'c',
        correction: 'n',
        hasFix: true);
  }

  /**
   * On return, increment [stringIndex] by 5 and [intIndex] by 5.
   */
  server.Element _serverElement(int stringIndex, int intIndex) =>
      new server.Element(
          server.ElementKind.CLASS, strings[stringIndex++], intIndex++,
          location: new server.Location(_fileName(stringIndex++), intIndex++,
              intIndex++, intIndex++, intIndex++),
          parameters: strings[stringIndex++],
          returnType: strings[stringIndex++],
          typeParameters: strings[stringIndex++]);

  server.Location _serverLocation(String baseName, int index) =>
      new server.Location(
          '$baseName.dart', index, index + 1, index + 2, index + 3);

  server.RefactoringProblem _serverRefactoringProblem(
          String baseName, int index) =>
      new server.RefactoringProblem(
          server.RefactoringProblemSeverity.FATAL, baseName,
          location: _serverLocation(baseName, index));

  server.SourceChange _serverSourceChange() => new server.SourceChange('m',
      edits: <server.SourceFileEdit>[
        new server.SourceFileEdit('a.dart', 1,
            edits: <server.SourceEdit>[new server.SourceEdit(2, 3, 'r')])
      ],
      linkedEditGroups: <server.LinkedEditGroup>[
        new server.LinkedEditGroup(
            <server.Position>[new server.Position('b.dart', 4)],
            5,
            <server.LinkedEditSuggestion>[
              new server.LinkedEditSuggestion(
                  'v', server.LinkedEditSuggestionKind.METHOD)
            ])
      ],
      selection: new server.Position('c.dart', 6));
}
