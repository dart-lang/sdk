// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/strong_mode.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetFieldTypeTest);
    defineReflectiveTests(VariableGathererTest);
  });
}

@reflectiveTest
class SetFieldTypeTest extends ResolverTestCase {
  test_setter_withoutParameter() async {
    Source source = addSource('''
var x = 0;
set x() {}
''');
    var analysisResult = await computeAnalysisResult(source);
    CompilationUnitElement unit = analysisResult.unit.declaredElement;
    TopLevelVariableElement variable = unit.topLevelVariables.single;
    setFieldType(variable, unit.context.typeProvider.intType);
  }
}

@reflectiveTest
class VariableGathererTest extends ResolverTestCase {
  test_creation_withFilter() async {
    VariableFilter filter = (variable) => true;
    VariableGatherer gatherer = new VariableGatherer(filter);
    expect(gatherer, isNotNull);
    expect(gatherer.filter, same(filter));
  }

  test_creation_withoutFilter() async {
    VariableGatherer gatherer = new VariableGatherer();
    expect(gatherer, isNotNull);
    expect(gatherer.filter, isNull);
  }

  test_visit_noReferences() async {
    Source source = addNamedSource('/test.dart', '''
library lib;
import 'dart:math';
int zero = 0;
class C {
  void m() => null;
}
typedef void F();
''');
    var analysisResult = await computeAnalysisResult(source);
    VariableGatherer gatherer = new VariableGatherer();
    analysisResult.unit.accept(gatherer);
    expect(gatherer.results, hasLength(0));
  }

  test_visit_withFilter() async {
    VariableFilter filter = (VariableElement variable) => variable.isStatic;
    Set<VariableElement> variables = await _gather(filter);
    expect(variables, hasLength(1));
  }

  test_visit_withoutFilter() async {
    Set<VariableElement> variables = await _gather();
    expect(variables, hasLength(4));
  }

  Future<Set<VariableElement>> _gather([VariableFilter filter = null]) async {
    Source source = addNamedSource('/test.dart', '''
const int zero = 0;
class Counter {
  int value = zero;
  void inc() {
    value++;
  }
  void dec() {
    value = value - 1;
  }
  void fromZero(f(int index)) {
    for (int i = zero; i < value; i++) {
      f(i);
    }
  }
}
''');
    var analysisResult = await computeAnalysisResult(source);
    VariableGatherer gatherer = new VariableGatherer(filter);
    analysisResult.unit.accept(gatherer);
    return gatherer.results;
  }
}
