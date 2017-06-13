// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisHighlightsTest);
  });
}

@reflectiveTest
class AnalysisHighlightsTest extends AbstractAnalysisServerIntegrationTest {
  Future startServer(
      {bool checked: true, int diagnosticPort, int servicesPort}) {
    return server.start(
        checked: checked,
        diagnosticPort: diagnosticPort,
        servicesPort: servicesPort,
        useAnalysisHighlight2: true);
  }

  test_highlights() {
    String pathname = sourcePath('test.dart');
    String text = r'''
import 'dart:async' as async;

/**
 * Doc comment
 */
class Class<TypeParameter> {
  Class() {
    field = {1.0: [].toList()};
  }

  Class.constructor() {
    dynamic local = true;
    field = {2: local};
  }

  Map field;
  static int staticField;

  method() {
    // End of line comment
    /* Block comment */
  }

  static staticMethod() {
  }

  get getter {
  }

  set setter(int parameter) {
    print(parameter);
  }
}

class Class2<TypeParameter> extends Class<TypeParameter> {
  @override
  method() {
  }
}

typedef functionType();

function(dynamicType) {
  print('string');
  unresolvedIdentifier = 42;
  return async.Future.wait([]);
}

int topLevelVariable;
''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    sendAnalysisSetSubscriptions({
      AnalysisService.HIGHLIGHTS: [pathname]
    });
    // Map from highlight type to highlighted text
    Map<HighlightRegionType, Set<String>> highlights;
    onAnalysisHighlights.listen((AnalysisHighlightsParams params) {
      expect(params.file, equals(pathname));
      highlights = <HighlightRegionType, Set<String>>{};
      for (HighlightRegion region in params.regions) {
        int startIndex = region.offset;
        int endIndex = startIndex + region.length;
        String highlightedText = text.substring(startIndex, endIndex);
        HighlightRegionType type = region.type;
        if (!highlights.containsKey(type)) {
          highlights[type] = new Set<String>();
        }
        highlights[type].add(highlightedText);
      }
    });
    return analysisFinished.then((_) {
      // There should be 1 error due to the fact that unresolvedIdentifier is
      // unresolved.
      expect(currentAnalysisErrors[pathname], hasLength(1));
      void check(HighlightRegionType type, List<String> expected) {
        expect(highlights[type], equals(expected.toSet()));
        highlights.remove(type);
      }

      check(HighlightRegionType.ANNOTATION, ['@override']);
      check(HighlightRegionType.BUILT_IN,
          ['as', 'get', 'import', 'set', 'static', 'typedef']);
      check(HighlightRegionType.CLASS,
          ['Class', 'Class2', 'Future', 'Map', 'int']);
      check(HighlightRegionType.COMMENT_BLOCK, ['/* Block comment */']);
      check(HighlightRegionType.COMMENT_DOCUMENTATION,
          ['/**\n * Doc comment\n */']);
      check(
          HighlightRegionType.COMMENT_END_OF_LINE, ['// End of line comment']);
      check(HighlightRegionType.CONSTRUCTOR, ['constructor']);
      check(HighlightRegionType.DIRECTIVE, ["import 'dart:async' as async;"]);
      check(HighlightRegionType.DYNAMIC_PARAMETER_DECLARATION, ['dynamicType']);
      check(HighlightRegionType.INSTANCE_FIELD_DECLARATION, ['field']);
      check(HighlightRegionType.INSTANCE_SETTER_REFERENCE, ['field']);
      check(HighlightRegionType.STATIC_FIELD_DECLARATION, ['staticField']);
      check(HighlightRegionType.TOP_LEVEL_FUNCTION_REFERENCE, ['print']);
      check(HighlightRegionType.TOP_LEVEL_FUNCTION_DECLARATION, ['function']);
      check(HighlightRegionType.FUNCTION_TYPE_ALIAS, ['functionType']);
      check(HighlightRegionType.INSTANCE_GETTER_DECLARATION, ['getter']);
      check(HighlightRegionType.IDENTIFIER_DEFAULT, ['unresolvedIdentifier']);
      check(HighlightRegionType.IMPORT_PREFIX, ['async']);
      check(HighlightRegionType.KEYWORD, ['class', 'true', 'return']);
      check(HighlightRegionType.LITERAL_BOOLEAN, ['true']);
      check(HighlightRegionType.LITERAL_DOUBLE, ['1.0']);
      check(HighlightRegionType.LITERAL_INTEGER, ['2', '42']);
      check(HighlightRegionType.LITERAL_LIST, ['[]']);
      check(HighlightRegionType.LITERAL_MAP,
          ['{1.0: [].toList()}', '{2: local}']);
      check(HighlightRegionType.LITERAL_STRING, ["'dart:async'", "'string'"]);
      check(HighlightRegionType.LOCAL_VARIABLE_DECLARATION, ['local']);
      check(HighlightRegionType.LOCAL_VARIABLE_REFERENCE, ['local']);
      check(HighlightRegionType.INSTANCE_METHOD_REFERENCE, ['toList']);
      check(HighlightRegionType.INSTANCE_METHOD_DECLARATION, ['method']);
      check(HighlightRegionType.STATIC_METHOD_DECLARATION, ['staticMethod']);
      check(HighlightRegionType.STATIC_METHOD_REFERENCE, ['wait']);
      check(HighlightRegionType.PARAMETER_DECLARATION, ['parameter']);
      check(HighlightRegionType.PARAMETER_REFERENCE, ['parameter']);
      check(HighlightRegionType.INSTANCE_SETTER_DECLARATION, ['setter']);
      check(HighlightRegionType.TOP_LEVEL_GETTER_REFERENCE, ['override']);
      check(HighlightRegionType.TOP_LEVEL_VARIABLE_DECLARATION,
          ['topLevelVariable']);
      check(HighlightRegionType.TYPE_NAME_DYNAMIC, ['dynamic']);
      check(HighlightRegionType.TYPE_PARAMETER, ['TypeParameter']);
      expect(highlights, isEmpty);
    });
  }
}
