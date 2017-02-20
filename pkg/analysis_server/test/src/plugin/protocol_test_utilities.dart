// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart' as server;
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

class ProtocolTestUtilities {
  static const List<String> strings = const <String>[
    'aa',
    'ab',
    'ac',
    'ad',
    'ae',
    'af',
    'ag',
    'ah',
    'ai',
    'aj',
    'ak',
    'al',
    'am',
    'an',
    'ao',
    'ap',
    'aq',
    'ar',
    'as',
    'at',
    'au',
    'av',
    'aw',
    'ax',
    'ay',
    'az',
    'ba',
    'bb',
    'bc',
    'bd',
    'be',
    'bf',
    'bg',
    'bh',
    'bi',
    'bj',
    'bk',
    'bl',
    'bm',
    'bn',
    'bo',
    'bp',
    'bq',
    'br',
    'bs',
    'bt',
    'bu',
    'bv',
    'bw',
    'bx',
    'by',
    'bz',
  ];

  String fileName(int stringIndex) => '${strings[stringIndex]}.dart';

  /**
   * On return, increment [stringIndex] by 3 (or 4 if no [file] name is
   * provided) and [intIndex] by 4.
   */
  plugin.AnalysisError pluginAnalysisError(int stringIndex, int intIndex,
      {String file}) {
    return new plugin.AnalysisError(
        plugin.AnalysisErrorSeverity.ERROR,
        plugin.AnalysisErrorType.COMPILE_TIME_ERROR,
        pluginLocation(stringIndex, intIndex, file: file),
        strings[stringIndex++],
        strings[stringIndex++],
        correction: strings[stringIndex++],
        hasFix: true);
  }

  /**
   * On return, increment [stringIndex] by 5 and [intIndex] by 5.
   */
  plugin.Element pluginElement(int stringIndex, int intIndex,
          {plugin.ElementKind kind}) =>
      new plugin.Element(
          kind ?? plugin.ElementKind.CLASS, strings[stringIndex++], intIndex++,
          location: new plugin.Location(fileName(stringIndex++), intIndex++,
              intIndex++, intIndex++, intIndex++),
          parameters: strings[stringIndex++],
          returnType: strings[stringIndex++],
          typeParameters: strings[stringIndex++]);

  plugin.FoldingRegion pluginFoldingRegion(int offset, int length) =>
      new plugin.FoldingRegion(plugin.FoldingKind.COMMENT, offset, length);

  plugin.HighlightRegion pluginHighlightRegion(int offset, int length) =>
      new plugin.HighlightRegion(
          plugin.HighlightRegionType.FIELD, offset, length);

  /**
   * On return, increment [stringIndex] by 1 and [intIndex] by 4.
   */
  plugin.Location pluginLocation(int stringIndex, int intIndex,
          {String file}) =>
      new plugin.Location(file ?? fileName(stringIndex), intIndex++, intIndex++,
          intIndex++, intIndex++);

  /**
   * On return, increment [stringIndex] by 2 (or 3 if no [file] name is
   * provided) and [intIndex] by 4.
   */
  plugin.AnalysisNavigationParams pluginNavigationParams(
          int stringIndex, int intIndex, {String file}) =>
      new plugin.AnalysisNavigationParams(
          file ?? fileName(stringIndex++), <plugin.NavigationRegion>[
        new plugin.NavigationRegion(intIndex++, 2, <int>[0])
      ], <plugin.NavigationTarget>[
        new plugin.NavigationTarget(
            plugin.ElementKind.FIELD, 0, intIndex++, 2, intIndex++, intIndex++)
      ], <String>[
        strings[stringIndex++],
        strings[stringIndex++]
      ]);

  /**
   * On return, increment [stringIndex] by 5 and [intIndex] by 7.
   */
  plugin.Occurrences pluginOccurrences(int stringIndex, int intIndex) {
    plugin.Element element = pluginElement(stringIndex, intIndex);
    return new plugin.Occurrences(
        element, <int>[intIndex + 5, intIndex + 6], element.name.length);
  }

  /**
   * On return, increment [stringIndex] by 10 and [intIndex] by 14.
   */
  plugin.Outline pluginOutline(int stringIndex, int intIndex) =>
      new plugin.Outline(
          pluginElement(stringIndex, intIndex), intIndex + 5, intIndex + 6,
          children: <plugin.Outline>[
            new plugin.Outline(
                pluginElement(stringIndex + 5, intIndex + 7,
                    kind: plugin.ElementKind.METHOD),
                intIndex + 12,
                intIndex + 13)
          ]);

  /**
   * On return, increment [stringIndex] by 2 and [intIndex] by 4.
   */
  plugin.RefactoringProblem pluginRefactoringProblem(
      int stringIndex, int intIndex) {
    return new plugin.RefactoringProblem(
        plugin.RefactoringProblemSeverity.FATAL, strings[stringIndex++],
        location: pluginLocation(stringIndex, intIndex));
  }

  /**
   * On return, increment [stringIndex] by 6 and [intIndex] by 6.
   */
  plugin.SourceChange pluginSourceChange(int stringIndex, int intIndex) =>
      new plugin.SourceChange(strings[stringIndex++],
          edits: <plugin.SourceFileEdit>[
            new plugin.SourceFileEdit(fileName(stringIndex), intIndex++,
                edits: <plugin.SourceEdit>[
                  new plugin.SourceEdit(
                      intIndex++, intIndex++, strings[stringIndex++])
                ])
          ],
          linkedEditGroups: <plugin.LinkedEditGroup>[
            new plugin.LinkedEditGroup(
                <plugin.Position>[
                  new plugin.Position(fileName(stringIndex), intIndex++)
                ],
                intIndex++,
                <plugin.LinkedEditSuggestion>[
                  new plugin.LinkedEditSuggestion(strings[stringIndex++],
                      plugin.LinkedEditSuggestionKind.METHOD)
                ])
          ],
          selection: new plugin.Position(fileName(stringIndex), intIndex++));

  /**
   * On return, increment [stringIndex] by 3 (or 4 if no [file] name is
   * provided) and [intIndex] by 4.
   */
  server.AnalysisError serverAnalysisError(int stringIndex, int intIndex,
      {String file}) {
    return new server.AnalysisError(
        server.AnalysisErrorSeverity.ERROR,
        server.AnalysisErrorType.COMPILE_TIME_ERROR,
        serverLocation(stringIndex, intIndex, file: file),
        strings[stringIndex++],
        strings[stringIndex++],
        correction: strings[stringIndex++],
        hasFix: true);
  }

  /**
   * On return, increment [stringIndex] by 5 and [intIndex] by 5.
   */
  server.Element serverElement(int stringIndex, int intIndex,
          {server.ElementKind kind}) =>
      new server.Element(
          kind ?? server.ElementKind.CLASS, strings[stringIndex++], intIndex++,
          location: new server.Location(fileName(stringIndex++), intIndex++,
              intIndex++, intIndex++, intIndex++),
          parameters: strings[stringIndex++],
          returnType: strings[stringIndex++],
          typeParameters: strings[stringIndex++]);

  server.FoldingRegion serverFoldingRegion(int offset, int length) =>
      new server.FoldingRegion(server.FoldingKind.COMMENT, offset, length);

  server.HighlightRegion serverHighlightRegion(int offset, int length) =>
      new server.HighlightRegion(
          server.HighlightRegionType.FIELD, offset, length);

  /**
   * On return, increment [stringIndex] by 1 and [intIndex] by 4.
   */
  server.Location serverLocation(int stringIndex, int intIndex,
          {String file}) =>
      new server.Location(file ?? fileName(stringIndex), intIndex++, intIndex++,
          intIndex++, intIndex++);

  /**
   * On return, increment [stringIndex] by 2 (or 3 if no [file] name is
   * provided) and [intIndex] by 4.
   */
  server.AnalysisNavigationParams serverNavigationParams(
          int stringIndex, int intIndex, {String file}) =>
      new server.AnalysisNavigationParams(
          file ?? fileName(stringIndex++), <server.NavigationRegion>[
        new server.NavigationRegion(intIndex++, 2, <int>[0])
      ], <server.NavigationTarget>[
        new server.NavigationTarget(
            server.ElementKind.FIELD, 0, intIndex++, 2, intIndex++, intIndex++)
      ], <String>[
        strings[stringIndex++],
        strings[stringIndex++]
      ]);

  /**
   * On return, increment [stringIndex] by 5 and [intIndex] by 7.
   */
  server.Occurrences serverOccurrences(int stringIndex, int intIndex) {
    server.Element element = serverElement(stringIndex, intIndex);
    return new server.Occurrences(
        element, <int>[intIndex + 5, intIndex + 6], element.name.length);
  }

  /**
   * On return, increment [stringIndex] by 10 and [intIndex] by 14.
   */
  server.Outline serverOutline(int stringIndex, int intIndex) =>
      new server.Outline(
          serverElement(stringIndex, intIndex), intIndex + 5, intIndex + 6,
          children: <server.Outline>[
            new server.Outline(
                serverElement(stringIndex + 5, intIndex + 7,
                    kind: server.ElementKind.METHOD),
                intIndex + 12,
                intIndex + 13)
          ]);

  /**
   * On return, increment [stringIndex] by 2 and [intIndex] by 4.
   */
  server.RefactoringProblem serverRefactoringProblem(
          int stringIndex, int intIndex) =>
      new server.RefactoringProblem(
          server.RefactoringProblemSeverity.FATAL, strings[stringIndex++],
          location: serverLocation(stringIndex, intIndex));

  /**
   * On return, increment [stringIndex] by 6 and [intIndex] by 6.
   */
  server.SourceChange serverSourceChange(int stringIndex, int intIndex) =>
      new server.SourceChange(strings[stringIndex++],
          edits: <server.SourceFileEdit>[
            new server.SourceFileEdit(fileName(stringIndex), intIndex++,
                edits: <server.SourceEdit>[
                  new server.SourceEdit(
                      intIndex++, intIndex++, strings[stringIndex++])
                ])
          ],
          linkedEditGroups: <server.LinkedEditGroup>[
            new server.LinkedEditGroup(
                <server.Position>[
                  new server.Position(fileName(stringIndex), intIndex++)
                ],
                intIndex++,
                <server.LinkedEditSuggestion>[
                  new server.LinkedEditSuggestion(strings[stringIndex++],
                      server.LinkedEditSuggestionKind.METHOD)
                ])
          ],
          selection: new server.Position(fileName(stringIndex), intIndex++));
}
