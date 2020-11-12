// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisHighlightsTest);
  });
}

@reflectiveTest
class AnalysisHighlightsTest extends AbstractAnalysisServerIntegrationTest {
  Map<HighlightRegionType, Set<String>> highlights;

  void check(HighlightRegionType type, List<String> expected) {
    expect(highlights[type], equals(expected.toSet()));
    highlights.remove(type);
  }

  Future<void> computeHighlights(String pathname, String text) async {
    writeFile(pathname, text);
    standardAnalysisSetup();
    sendAnalysisSetSubscriptions({
      AnalysisService.HIGHLIGHTS: [pathname]
    });
    // Map from highlight type to highlighted text
    onAnalysisHighlights.listen((AnalysisHighlightsParams params) {
      expect(params.file, equals(pathname));
      highlights = <HighlightRegionType, Set<String>>{};
      for (var region in params.regions) {
        var startIndex = region.offset;
        var endIndex = startIndex + region.length;
        var highlightedText = text.substring(startIndex, endIndex);
        var type = region.type;
        if (!highlights.containsKey(type)) {
          highlights[type] = <String>{};
        }
        highlights[type].add(highlightedText);
      }
    });
    await analysisFinished;
  }

  @override
  Future startServer({
    int diagnosticPort,
    int servicesPort,
  }) {
    return server.start(
        diagnosticPort: diagnosticPort,
        servicesPort: servicesPort,
        useAnalysisHighlight2: true);
  }

  Future<void> test_highlights() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
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

  Map field = {3: 4};
  static int staticField = 0;

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

int topLevelVariable = 0;
''';
    await computeHighlights(pathname, text);
    // There should be 1 error due to the fact that unresolvedIdentifier is
    // unresolved.
    expect(currentAnalysisErrors[pathname], hasLength(1));

    check(HighlightRegionType.ANNOTATION, ['@override']);
    check(HighlightRegionType.BUILT_IN,
        ['as', 'get', 'import', 'set', 'static', 'typedef']);
    check(
        HighlightRegionType.CLASS, ['Class', 'Class2', 'Future', 'Map', 'int']);
    check(HighlightRegionType.COMMENT_BLOCK, ['/* Block comment */']);
    check(HighlightRegionType.COMMENT_DOCUMENTATION,
        ['/**\n * Doc comment\n */']);
    check(HighlightRegionType.COMMENT_END_OF_LINE, ['// End of line comment']);
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
    check(HighlightRegionType.KEYWORD, ['class', 'extends', 'true', 'return']);
    check(HighlightRegionType.LITERAL_BOOLEAN, ['true']);
    check(HighlightRegionType.LITERAL_DOUBLE, ['1.0']);
    check(HighlightRegionType.LITERAL_INTEGER, ['2', '3', '4', '0', '42']);
    check(HighlightRegionType.LITERAL_LIST, ['[]']);
    check(HighlightRegionType.LITERAL_MAP,
        ['{1.0: [].toList()}', '{2: local}', '{3: 4}']);
    check(HighlightRegionType.LITERAL_STRING, ["'dart:async'", "'string'"]);
    check(HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_DECLARATION, ['local']);
    check(HighlightRegionType.DYNAMIC_LOCAL_VARIABLE_REFERENCE, ['local']);
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
  }

  Future<void> test_highlights_mixin() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
mixin M on A implements B {}
class A {}
class B {}
''';
    await computeHighlights(pathname, text);
    expect(currentAnalysisErrors[pathname], hasLength(0));

    check(HighlightRegionType.BUILT_IN, ['implements', 'mixin', 'on']);
    check(HighlightRegionType.KEYWORD, ['class']);
  }
}
