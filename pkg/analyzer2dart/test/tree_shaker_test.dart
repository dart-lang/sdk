// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:unittest/unittest.dart';

import '../lib/src/closed_world.dart';
import '../lib/src/driver.dart';

main() {
  test('Toplevel function', () {
    var helper = new TreeShakerTestHelper('''
main() {
  foo();
}
foo() {
}
''');
    expect(helper.functions['main'], isNotNull);
    expect(helper.functions['foo'], isNotNull);
  });

  test('Class instantiation', () {
    var helper = new TreeShakerTestHelper('''
main() {
  var x = new A();
}
class A {}
class B {}
''');
    expect(helper.instantiatedClasses['A'], isNotNull);
    expect(helper.instantiatedClasses['B'], isNull);
  });
}

class TreeShakerTestHelper {
  /**
   * ClosedWorld that resulted from tree shaking.
   */
  ClosedWorld world;

  /**
   * Functions contained in [world], indexed by name.
   */
  Map<String, FunctionDeclaration> functions = <String, FunctionDeclaration>{};

  /**
   * Classes instantiated in [world], indexed by name.
   */
  Map<String, ClassDeclaration> instantiatedClasses = <String,
      ClassDeclaration>{};

  /**
   * Create a TreeShakerTestHelper based on the given file contents.
   */
  TreeShakerTestHelper(String contents) {
    Driver driver = new Driver();
    world =
        driver.computeWorld(driver.resolveEntryPoint(driver.setFakeRoot(contents)));
    world.elements.forEach((Element element, AstNode node) {
      if (element is FunctionElement) {
        FunctionDeclaration declaration = node as FunctionDeclaration;
        expect(declaration, isNotNull);
        expect(declaration.element, equals(element));
        functions[element.name] = declaration;
      } else if (element is ClassElement) {
        ClassDeclaration declaration = node as ClassDeclaration;
        expect(declaration, isNotNull);
        expect(declaration.element, equals(element));
        instantiatedClasses[element.name] = declaration;
      }
    });
  }
}
