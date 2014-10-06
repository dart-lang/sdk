// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.navigation;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

@ReflectiveTestCase()
class AnalysisNavigationTest extends AbstractAnalysisServerIntegrationTest {
  test_navigation() {
    String pathname1 = sourcePath('test1.dart');
    String text1 = r'''
library foo;

import 'dart:async';
part 'test2.dart';

class Class<TypeParameter> {
  Class.constructor(); /* constructor declaration */

  TypeParameter field;

  method() {}
}

typedef FunctionTypeAlias();

function(FunctionTypeAlias parameter) {
  print(parameter());
}

int topLevelVariable;

main() {
  Class<int> localVariable = new Class<int>.constructor();
  function(() => localVariable.field);
  localVariable.method();
  localVariable.field = 1;
}
''';
    writeFile(pathname1, text1);
    String pathname2 = sourcePath('test2.dart');
    String text2 = r'''
part of foo;
''';
    writeFile(pathname2, text2);
    standardAnalysisSetup();
    sendAnalysisSetSubscriptions({
      AnalysisService.NAVIGATION: [pathname1]
    });
    List<NavigationRegion> regions;
    onAnalysisNavigation.listen((AnalysisNavigationParams params) {
      expect(params.file, equals(pathname1));
      regions = params.regions;
    });
    return analysisFinished.then((_) {
      // There should be a single error, due to the fact that 'dart:async' is
      // not used.
      expect(currentAnalysisErrors[pathname1], hasLength(1));
      expect(currentAnalysisErrors[pathname2], isEmpty);
      Element findTargetElement(int index) {
        for (NavigationRegion region in regions) {
          if (region.offset <= index && index < region.offset + region.length) {
            expect(region.targets, hasLength(1));
            return region.targets[0];
          }
        }
        fail('No element found for index $index');
        return null;
      }
      void checkLocal(String source, String expectedTarget,
          ElementKind expectedKind) {
        int sourceIndex = text1.indexOf(source);
        int targetIndex = text1.indexOf(expectedTarget);
        Element element = findTargetElement(sourceIndex);
        expect(element.location.file, equals(pathname1));
        expect(element.location.offset, equals(targetIndex));
        expect(element.kind, equals(expectedKind));
      }
      void checkRemote(String source, String expectedTargetRegexp,
          ElementKind expectedKind) {
        int sourceIndex = text1.indexOf(source);
        Element element = findTargetElement(sourceIndex);
        expect(element.location.file, matches(expectedTargetRegexp));
        expect(element.kind, equals(expectedKind));
      }
      // TODO(paulberry): will the element type 'CLASS_TYPE_ALIAS' ever appear
      // as a navigation target?
      checkLocal('Class<int>', 'Class<TypeParameter>', ElementKind.CLASS);
      checkRemote(
          "part 'test2.dart';",
          r'test2.dart$',
          ElementKind.COMPILATION_UNIT);
      checkLocal(
          'new Class<int>.constructor',
          'constructor(); /* constructor declaration */',
          ElementKind.CONSTRUCTOR);
      checkLocal('field;', 'field;', ElementKind.FIELD);
      checkLocal(
          'function(() => localVariable.field)',
          'function(FunctionTypeAlias parameter)',
          ElementKind.FUNCTION);
      checkLocal(
          'FunctionTypeAlias parameter',
          'FunctionTypeAlias();',
          ElementKind.FUNCTION_TYPE_ALIAS);
      checkLocal('field)', 'field;', ElementKind.GETTER);
      checkRemote("import 'dart:async'", r'async\.dart$', ElementKind.LIBRARY);
      checkLocal(
          'localVariable.field',
          'localVariable =',
          ElementKind.LOCAL_VARIABLE);
      checkLocal('method();', 'method() {', ElementKind.METHOD);
      checkLocal('parameter());', 'parameter) {', ElementKind.PARAMETER);
      checkLocal('field = 1', 'field;', ElementKind.SETTER);
      checkLocal(
          'topLevelVariable;',
          'topLevelVariable;',
          ElementKind.TOP_LEVEL_VARIABLE);
      checkLocal(
          'TypeParameter field;',
          'TypeParameter>',
          ElementKind.TYPE_PARAMETER);
    });
  }
}

main() {
  runReflectiveTests(AnalysisNavigationTest);
}
