// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' as server;
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
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
  AnalysisError pluginAnalysisError(int stringIndex, int intIndex,
      {String file}) {
    // TODO(brianwilkerson) Unify the "plugin" and "server" methods when the return type is common.
    return new AnalysisError(
        AnalysisErrorSeverity.ERROR,
        AnalysisErrorType.COMPILE_TIME_ERROR,
        pluginLocation(stringIndex, intIndex, file: file),
        strings[stringIndex++],
        strings[stringIndex++],
        correction: strings[stringIndex++],
        hasFix: true);
  }

  /**
   * On return, increment [stringIndex] by 5 and [intIndex] by 5.
   */
  Element pluginElement(int stringIndex, int intIndex, {ElementKind kind}) =>
      new Element(kind ?? ElementKind.CLASS, strings[stringIndex++], intIndex++,
          location: new Location(fileName(stringIndex++), intIndex++,
              intIndex++, intIndex++, intIndex++),
          parameters: strings[stringIndex++],
          returnType: strings[stringIndex++],
          typeParameters: strings[stringIndex++]);

  FoldingRegion pluginFoldingRegion(int offset, int length) =>
      new FoldingRegion(FoldingKind.COMMENT, offset, length);

  HighlightRegion pluginHighlightRegion(int offset, int length) =>
      new HighlightRegion(HighlightRegionType.FIELD, offset, length);

  /**
   * On return, increment [stringIndex] by 1 and [intIndex] by 4.
   */
  Location pluginLocation(int stringIndex, int intIndex, {String file}) =>
      new Location(file ?? fileName(stringIndex), intIndex++, intIndex++,
          intIndex++, intIndex++);

  /**
   * On return, increment [stringIndex] by 2 (or 3 if no [file] name is
   * provided) and [intIndex] by 4.
   */
  plugin.AnalysisNavigationParams pluginNavigationParams(
          int stringIndex, int intIndex, {String file}) =>
      new plugin.AnalysisNavigationParams(
          file ?? fileName(stringIndex++), <NavigationRegion>[
        new NavigationRegion(intIndex++, 2, <int>[0])
      ], <NavigationTarget>[
        new NavigationTarget(
            ElementKind.FIELD, 0, intIndex++, 2, intIndex++, intIndex++)
      ], <String>[
        strings[stringIndex++],
        strings[stringIndex++]
      ]);

  /**
   * On return, increment [stringIndex] by 5 and [intIndex] by 7.
   */
  Occurrences pluginOccurrences(int stringIndex, int intIndex) {
    Element element = pluginElement(stringIndex, intIndex);
    return new Occurrences(
        element, <int>[intIndex + 5, intIndex + 6], element.name.length);
  }

  /**
   * On return, increment [stringIndex] by 10 and [intIndex] by 14.
   */
  Outline pluginOutline(int stringIndex, int intIndex) => new Outline(
          pluginElement(stringIndex, intIndex), intIndex + 5, intIndex + 6,
          children: <Outline>[
            new Outline(
                pluginElement(stringIndex + 5, intIndex + 7,
                    kind: ElementKind.METHOD),
                intIndex + 12,
                intIndex + 13)
          ]);

  /**
   * On return, increment [stringIndex] by 2 and [intIndex] by 4.
   */
  RefactoringProblem pluginRefactoringProblem(int stringIndex, int intIndex) {
    return new RefactoringProblem(
        RefactoringProblemSeverity.FATAL, strings[stringIndex++],
        location: pluginLocation(stringIndex, intIndex));
  }

  /**
   * On return, increment [stringIndex] by 6 and [intIndex] by 6.
   */
  SourceChange pluginSourceChange(int stringIndex, int intIndex) =>
      new SourceChange(strings[stringIndex++],
          edits: <SourceFileEdit>[
            new SourceFileEdit(fileName(stringIndex), intIndex++,
                edits: <SourceEdit>[
                  new SourceEdit(intIndex++, intIndex++, strings[stringIndex++])
                ])
          ],
          linkedEditGroups: <LinkedEditGroup>[
            new LinkedEditGroup(
                <Position>[new Position(fileName(stringIndex), intIndex++)],
                intIndex++,
                <LinkedEditSuggestion>[
                  new LinkedEditSuggestion(
                      strings[stringIndex++], LinkedEditSuggestionKind.METHOD)
                ])
          ],
          selection: new Position(fileName(stringIndex), intIndex++));

  /**
   * On return, increment [stringIndex] by 3 (or 4 if no [file] name is
   * provided) and [intIndex] by 4.
   */
  AnalysisError serverAnalysisError(int stringIndex, int intIndex,
      {String file}) {
    return new AnalysisError(
        AnalysisErrorSeverity.ERROR,
        AnalysisErrorType.COMPILE_TIME_ERROR,
        serverLocation(stringIndex, intIndex, file: file),
        strings[stringIndex++],
        strings[stringIndex++],
        correction: strings[stringIndex++],
        hasFix: true);
  }

  /**
   * On return, increment [stringIndex] by 5 and [intIndex] by 5.
   */
  Element serverElement(int stringIndex, int intIndex, {ElementKind kind}) =>
      new Element(kind ?? ElementKind.CLASS, strings[stringIndex++], intIndex++,
          location: new Location(fileName(stringIndex++), intIndex++,
              intIndex++, intIndex++, intIndex++),
          parameters: strings[stringIndex++],
          returnType: strings[stringIndex++],
          typeParameters: strings[stringIndex++]);

  FoldingRegion serverFoldingRegion(int offset, int length) =>
      new FoldingRegion(FoldingKind.COMMENT, offset, length);

  HighlightRegion serverHighlightRegion(int offset, int length) =>
      new HighlightRegion(HighlightRegionType.FIELD, offset, length);

  /**
   * On return, increment [stringIndex] by 1 and [intIndex] by 4.
   */
  Location serverLocation(int stringIndex, int intIndex, {String file}) =>
      new Location(file ?? fileName(stringIndex), intIndex++, intIndex++,
          intIndex++, intIndex++);

  /**
   * On return, increment [stringIndex] by 2 (or 3 if no [file] name is
   * provided) and [intIndex] by 4.
   */
  server.AnalysisNavigationParams serverNavigationParams(
          int stringIndex, int intIndex, {String file}) =>
      new server.AnalysisNavigationParams(
          file ?? fileName(stringIndex++), <NavigationRegion>[
        new NavigationRegion(intIndex++, 2, <int>[0])
      ], <NavigationTarget>[
        new NavigationTarget(
            ElementKind.FIELD, 0, intIndex++, 2, intIndex++, intIndex++)
      ], <String>[
        strings[stringIndex++],
        strings[stringIndex++]
      ]);

  /**
   * On return, increment [stringIndex] by 5 and [intIndex] by 7.
   */
  Occurrences serverOccurrences(int stringIndex, int intIndex) {
    Element element = serverElement(stringIndex, intIndex);
    return new Occurrences(
        element, <int>[intIndex + 5, intIndex + 6], element.name.length);
  }

  /**
   * On return, increment [stringIndex] by 10 and [intIndex] by 14.
   */
  Outline serverOutline(int stringIndex, int intIndex) => new Outline(
          serverElement(stringIndex, intIndex), intIndex + 5, intIndex + 6,
          children: <Outline>[
            new Outline(
                serverElement(stringIndex + 5, intIndex + 7,
                    kind: ElementKind.METHOD),
                intIndex + 12,
                intIndex + 13)
          ]);

  /**
   * On return, increment [stringIndex] by 2 and [intIndex] by 4.
   */
  RefactoringProblem serverRefactoringProblem(int stringIndex, int intIndex) =>
      new RefactoringProblem(
          RefactoringProblemSeverity.FATAL, strings[stringIndex++],
          location: serverLocation(stringIndex, intIndex));

  /**
   * On return, increment [stringIndex] by 6 and [intIndex] by 6.
   */
  SourceChange serverSourceChange(int stringIndex, int intIndex) =>
      new SourceChange(strings[stringIndex++],
          edits: <SourceFileEdit>[
            new SourceFileEdit(fileName(stringIndex), intIndex++,
                edits: <SourceEdit>[
                  new SourceEdit(intIndex++, intIndex++, strings[stringIndex++])
                ])
          ],
          linkedEditGroups: <LinkedEditGroup>[
            new LinkedEditGroup(
                <Position>[new Position(fileName(stringIndex), intIndex++)],
                intIndex++,
                <LinkedEditSuggestion>[
                  new LinkedEditSuggestion(
                      strings[stringIndex++], LinkedEditSuggestionKind.METHOD)
                ])
          ],
          selection: new Position(fileName(stringIndex), intIndex++));
}
