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
    defineReflectiveTests(AnalysisNavigationTest);
  });
}

@reflectiveTest
class AnalysisNavigationTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_navigation() async {
    var pathname1 = sourcePath('test1.dart');
    var text1 = r'''
library foo;

import 'dart:async';
part 'test2.dart';

class Class<TypeParameter> {
  Class.constructor(); /* constructor declaration */

  TypeParameter field = (throw 0);

  method() {}
}

typedef FunctionTypeAlias();

function(FunctionTypeAlias parameter) {
  print(parameter());
}

int topLevelVariable = 0;

main() {
  Class<int> localVariable = new Class<int>.constructor(); // usage
  function(() => localVariable.field);
  localVariable.method();
  localVariable.field = 1;
}
''';
    writeFile(pathname1, text1);
    var pathname2 = sourcePath('test2.dart');
    var text2 = r'''
part of foo;
''';
    writeFile(pathname2, text2);
    standardAnalysisSetup();
    sendAnalysisSetSubscriptions({
      AnalysisService.NAVIGATION: [pathname1]
    });
    List<NavigationRegion> regions;
    List<NavigationTarget> targets;
    List<String> targetFiles;
    onAnalysisNavigation.listen((AnalysisNavigationParams params) {
      expect(params.file, equals(pathname1));
      regions = params.regions;
      targets = params.targets;
      targetFiles = params.files;
    });

    await analysisFinished;

    // There should be a single error, due to the fact that 'dart:async' is not
    // used.
    expect(currentAnalysisErrors[pathname1], hasLength(1));
    expect(currentAnalysisErrors[pathname2], isEmpty);
    NavigationTarget findTargetElement(int index) {
      for (var region in regions) {
        if (region.offset <= index && index < region.offset + region.length) {
          expect(region.targets, hasLength(1));
          var targetIndex = region.targets[0];
          return targets[targetIndex];
        }
      }
      fail('No element found for index $index');
    }

    void checkLocal(
        String source, String expectedTarget, ElementKind expectedKind) {
      var sourceIndex = text1.indexOf(source);
      var targetIndex = text1.indexOf(expectedTarget);
      var element = findTargetElement(sourceIndex);
      expect(targetFiles[element.fileIndex], equals(pathname1));
      expect(element.offset, equals(targetIndex));
      expect(element.kind, equals(expectedKind));
    }

    void checkRemote(
        String source, String expectedTargetRegexp, ElementKind expectedKind) {
      var sourceIndex = text1.indexOf(source);
      var element = findTargetElement(sourceIndex);
      expect(targetFiles[element.fileIndex], matches(expectedTargetRegexp));
      expect(element.kind, equals(expectedKind));
    }

    // TODO(paulberry): will the element type 'CLASS_TYPE_ALIAS' ever appear as
    // a navigation target?
    checkLocal('Class<int>', 'Class<TypeParameter>', ElementKind.CLASS);
    checkRemote("'test2.dart';", r'test2.dart$', ElementKind.COMPILATION_UNIT);
    checkLocal(
        'Class<int>.constructor',
        'constructor(); /* constructor declaration */',
        ElementKind.CONSTRUCTOR);
    checkLocal(
        'constructor(); // usage',
        'constructor(); /* constructor declaration */',
        ElementKind.CONSTRUCTOR);
    checkLocal('field = (', 'field = (', ElementKind.FIELD);
    checkLocal('function(() => localVariable.field)',
        'function(FunctionTypeAlias parameter)', ElementKind.FUNCTION);
    checkLocal('FunctionTypeAlias parameter', 'FunctionTypeAlias();',
        ElementKind.FUNCTION_TYPE_ALIAS);
    checkLocal('field)', 'field = (', ElementKind.GETTER);
    checkRemote("'dart:async'", r'async\.dart$', ElementKind.LIBRARY);
    checkLocal(
        'localVariable.field', 'localVariable =', ElementKind.LOCAL_VARIABLE);
    checkLocal('method();', 'method() {', ElementKind.METHOD);
    checkLocal('parameter());', 'parameter) {', ElementKind.PARAMETER);
    checkLocal('field = 1', 'field = (', ElementKind.SETTER);
    checkLocal('topLevelVariable = 0;', 'topLevelVariable = 0;',
        ElementKind.TOP_LEVEL_VARIABLE);
    checkLocal('TypeParameter field = (', 'TypeParameter>',
        ElementKind.TYPE_PARAMETER);
  }
}
