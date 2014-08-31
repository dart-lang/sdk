// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_testing/mock_sdk.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
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
    helper.assertHasFunction('main');
    helper.assertHasFunction('foo');
  });

  test('Class instantiation', () {
    var helper = new TreeShakerTestHelper('''
main() {
  var x = new A();
}
class A {}
class B {}
''');
    helper.assertHasInstantiatedClass('A');
    helper.assertNoInstantiatedClass('B');
  });

  test('Method invocation', () {
    var helper = new TreeShakerTestHelper('''
main() {
  var x = new A().foo();
}
class A {
  foo() {}
  bar() {}
}
class B {
  foo() {}
  bar() {}
}
''');
    helper.assertHasMethod('A.foo');
    helper.assertNoMethod('A.bar');
    helper.assertNoMethod('B.foo');
    helper.assertNoMethod('B.bar');
  });

  test('Method invocation on dynamic', () {
    var helper = new TreeShakerTestHelper('''
class A {
  m1() {}
  m2() {}
}
foo(dynamic x) {
  x.m1();
}
main() {
  foo(new A());
}
''');
    helper.assertHasMethod('A.m1');
    helper.assertNoMethod('A.m2');
  });

  test('Method invocation on dynamic via cascade', () {
    var helper = new TreeShakerTestHelper('''
class A {
  m1() {}
  m2() {}
}
foo(dynamic x) {
  x..m1()..m2();
}
main() {
  foo(new A());
}
''');
    helper.assertHasMethod('A.m1');
    helper.assertHasMethod('A.m2');
  });
}

class TreeShakerTestHelper {
  /**
   * The name of the root file.
   */
  String rootFile = '/root.dart';

  /**
   * ClosedWorld that resulted from tree shaking.
   */
  ClosedWorld world;

  /**
   * Functions contained in [world], indexed by name.
   */
  Map<String, FunctionDeclaration> functions = <String, FunctionDeclaration>{};

  /**
   * Methods contained in [world], indexed by className.methodName.
   */
  Map<String, MethodDeclaration> methods = <String, MethodDeclaration>{};

  /**
   * Classes instantiated in [world], indexed by name.
   */
  Map<String, ClassDeclaration> instantiatedClasses = <String,
      ClassDeclaration>{};

  /**
   * Create a TreeShakerTestHelper based on the given file contents.
   */
  TreeShakerTestHelper(String contents) {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    DartSdk sdk = new MockSdk();
    Driver driver = new Driver(provider, sdk);
    provider.newFile(rootFile, contents);
    Source rootSource = driver.setRoot(rootFile);
    FunctionElement entryPoint = driver.resolveEntryPoint(rootSource);
    world = driver.computeWorld(entryPoint);
    world.executableElements.forEach(
        (ExecutableElement element, Declaration node) {
      if (element is FunctionElement) {
        FunctionDeclaration declaration = node as FunctionDeclaration;
        expect(declaration, isNotNull);
        expect(declaration.element, equals(element));
        functions[element.name] = declaration;
      } else if (element is MethodElement) {
        MethodDeclaration declaration = node as MethodDeclaration;
        expect(declaration, isNotNull);
        expect(declaration.element, equals(element));
        methods['${element.enclosingElement.name}.${element.name}'] =
            declaration;
      }
    });
    world.instantiatedClasses.forEach(
        (ClassElement element, ClassDeclaration declaration) {
      expect(declaration, isNotNull);
      expect(declaration.element, equals(element));
      instantiatedClasses[element.name] = declaration;
    });
  }

  /**
   * Asserts that [world] contains a top-level function with the given name.
   */
  void assertHasFunction(String name) {
    expect(functions, contains(name));
  }

  /**
   * Asserts that [world] instantiates a class with the given name.
   */
  void assertHasInstantiatedClass(String name) {
    expect(instantiatedClasses, contains(name));
  }

  /**
   * Asserts that [world] contains a method with the given qualified name.
   *
   * [qualifiedName] - the qualified name in form 'className.methodName'.
   */
  void assertHasMethod(String qualifiedName) {
    expect(methods, contains(qualifiedName));
  }

  void assertNoFunction(String name) {
    expect(functions[name], isNull);
  }

  /**
   * Asserts that [world] doesn't instantiate a class with the given name.
   */
  void assertNoInstantiatedClass(String name) {
    expect(instantiatedClasses, isNot(contains(name)));
  }

  /**
   * Asserts that [world] doesn't contain a method with the given qualified
   * name.
   *
   * [qualifiedName] - the qualified name in form 'className.methodName'.
   */
  void assertNoMethod(String qualifiedName) {
    expect(methods, isNot(contains(qualifiedName)));
  }
}
