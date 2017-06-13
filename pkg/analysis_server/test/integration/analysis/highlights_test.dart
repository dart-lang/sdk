// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
      check(HighlightRegionType.DYNAMIC_TYPE, ['dynamicType']);
      check(HighlightRegionType.FIELD, ['field']);
      check(HighlightRegionType.FIELD_STATIC, ['staticField']);
      check(HighlightRegionType.FUNCTION, ['print']);
      check(HighlightRegionType.FUNCTION_DECLARATION, ['function']);
      check(HighlightRegionType.FUNCTION_TYPE_ALIAS, ['functionType']);
      check(HighlightRegionType.GETTER_DECLARATION, ['getter']);
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
      check(HighlightRegionType.LOCAL_VARIABLE, ['local']);
      check(HighlightRegionType.LOCAL_VARIABLE_DECLARATION, ['local']);
      check(HighlightRegionType.METHOD, ['toList']);
      check(HighlightRegionType.METHOD_DECLARATION, ['method']);
      check(HighlightRegionType.METHOD_DECLARATION_STATIC, ['staticMethod']);
      check(HighlightRegionType.METHOD_STATIC, ['wait']);
      check(HighlightRegionType.PARAMETER, ['parameter']);
      check(HighlightRegionType.SETTER_DECLARATION, ['setter']);
      check(HighlightRegionType.TOP_LEVEL_VARIABLE,
          ['override', 'topLevelVariable']);
      check(HighlightRegionType.TYPE_NAME_DYNAMIC, ['dynamic']);
      check(HighlightRegionType.TYPE_PARAMETER, ['TypeParameter']);
      expect(highlights, isEmpty);
    });
  }
}
