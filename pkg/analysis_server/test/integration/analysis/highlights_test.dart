// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.highlights;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

@ReflectiveTestCase()
class AnalysisHighlightsTest extends AbstractAnalysisServerIntegrationTest {
  test_highlights() {
    String pathname = sourcePath('test.dart');
    String text =
        r'''
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
    sendAnalysisSetSubscriptions({AnalysisService.HIGHLIGHTS: [pathname]});
    // Map from highlight type to highlighted text
    Map<String, Set<String>> highlights;
    onAnalysisHighlights.listen((params) {
      expect(params['file'], equals(pathname));
      highlights = <String, Set<String>>{};
      for (var region in params['regions']) {
        int startIndex = region['offset'];
        int endIndex = startIndex + region['length'];
        String highlightedText = text.substring(startIndex, endIndex);
        String type = region['type'];
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
      void check(String type, List<String> expected) {
        expect(highlights[type], equals(expected.toSet()));
        highlights.remove(type);
      }
      check('ANNOTATION', ['@override']);
      check('BUILT_IN', ['as', 'get', 'import', 'set', 'static', 'typedef']);
      check('CLASS', ['Class', 'Class2', 'Future', 'Map', 'int']);
      check('COMMENT_BLOCK', ['/* Block comment */']);
      check('COMMENT_DOCUMENTATION', ['/**\n * Doc comment\n */']);
      check('COMMENT_END_OF_LINE', ['// End of line comment']);
      check('CONSTRUCTOR', ['constructor']);
      check('DIRECTIVE', ["import 'dart:async' as async;"]);
      check('DYNAMIC_TYPE', ['dynamicType']);
      check('FIELD', ['field']);
      check('FIELD_STATIC', ['staticField']);
      check('FUNCTION', ['print']);
      check('FUNCTION_DECLARATION', ['function']);
      check('FUNCTION_TYPE_ALIAS', ['functionType']);
      check('GETTER_DECLARATION', ['getter']);
      check('IDENTIFIER_DEFAULT', ['unresolvedIdentifier']);
      check('IMPORT_PREFIX', ['async']);
      check('KEYWORD', ['class', 'true', 'return']);
      check('LITERAL_BOOLEAN', ['true']);
      check('LITERAL_DOUBLE', ['1.0']);
      check('LITERAL_INTEGER', ['2', '42']);
      check('LITERAL_LIST', ['[]']);
      check('LITERAL_MAP', ['{1.0: [].toList()}', '{2: local}']);
      check('LITERAL_STRING', ["'dart:async'", "'string'"]);
      check('LOCAL_VARIABLE', ['local']);
      check('LOCAL_VARIABLE_DECLARATION', ['local']);
      check('METHOD', ['toList']);
      check('METHOD_DECLARATION', ['method']);
      check('METHOD_DECLARATION_STATIC', ['staticMethod']);
      check('METHOD_STATIC', ['wait']);
      check('PARAMETER', ['parameter']);
      check('SETTER_DECLARATION', ['setter']);
      check('TOP_LEVEL_VARIABLE', ['override', 'topLevelVariable']);
      check('TYPE_NAME_DYNAMIC', ['dynamic']);
      check('TYPE_PARAMETER', ['TypeParameter']);
      expect(highlights, isEmpty);
    });
  }
}

main() {
  runReflectiveTests(AnalysisHighlightsTest);
}
