// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis/base.dart';
import '../resolution/find_element.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InheritanceManager2Test);
  });
}

@reflectiveTest
class InheritanceManager2Test extends BaseAnalysisDriverTest {
  AnalysisResult result;
  FindElement findElement;
  InheritanceManager2 manager;

  TypeProvider get typeProvider =>
      result.unit.declaredElement.context.typeProvider;

  Future resolveTestFile() async {
    result = await driver.getResult(testFile);
    findElement = new FindElement(result.unit);
    manager =
        new InheritanceManager2(result.unit.declaredElement.context.typeSystem);
  }

  void test_computeNode_ClassDeclaration() async {
    addTestFile('''
abstract class I1 {
  void f(int i);
}
abstract class I2 {
  void f(Object o);
}
abstract class C implements I1, I2 {}
''');
    await resolveTestFile();
    ClassElement c = findElement.class_('C');
    FunctionType memberType =
        manager.getMember(c.type, new Name(c.library.source.uri, 'f'));
    expect(memberType, isNotNull);
    expect(memberType.parameters, hasLength(1));
    DartType parameterType = memberType.parameters[0].type;
    expect(parameterType.name, 'Object');
  }
}
