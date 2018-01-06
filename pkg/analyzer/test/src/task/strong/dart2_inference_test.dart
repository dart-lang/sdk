// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/resolver_test_case.dart';
import '../../../generated/test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Dart2InferenceTest);
  });
}

/// Tests for Dart2 inference rules back-ported from FrontEnd.
///
/// https://github.com/dart-lang/sdk/issues/31638
@reflectiveTest
class Dart2InferenceTest extends ResolverTestCase {
  @override
  AnalysisOptions get defaultAnalysisOptions =>
      new AnalysisOptionsImpl()..strongMode = true;

  @override
  bool get enableNewAnalysisDriver => true;

  test_inferObject_whenDownwardNull() async {
    var code = r'''
int f(void Function(Null) f2) {}
void main() {
  f((x) {});
}
''';
    var source = addSource(code);
    var analysisResult = await computeAnalysisResult(source);
    var unit = analysisResult.unit;
    var xNode = EngineTestCase.findSimpleIdentifier(unit, code, 'x) {}');
    VariableElement xElement = xNode.staticElement;
    expect(xNode.staticType, typeProvider.objectType);
    expect(xElement.type, typeProvider.objectType);
  }
}
