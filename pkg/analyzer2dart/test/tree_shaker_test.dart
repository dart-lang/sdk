// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'mock_sdk.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:compiler/implementation/dart2jslib.dart' show NullSink;
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

  test('Toplevel field read', () {
    var helper = new TreeShakerTestHelper('''
main() {
  return foo;
}
var foo;
var bar;
''');
    helper.assertHasFunction('main');
    helper.assertHasVariable('foo');
    helper.assertNoVariable('bar');
  });

  test('Toplevel field write', () {
    var helper = new TreeShakerTestHelper('''
main() {
  foo = 1;
}
var foo;
var bar;
''');
    helper.assertHasFunction('main');
    helper.assertHasVariable('foo');
    helper.assertNoVariable('bar');
  });

  test('Toplevel field invocation', () {
    var helper = new TreeShakerTestHelper('''
main() {
  return foo();
}
var foo;
var bar;
''');
    helper.assertHasFunction('main');
    helper.assertHasVariable('foo');
    helper.assertNoVariable('bar');
  });

  test('Member field invocation', () {
    var helper = new TreeShakerTestHelper('''
class A {
  void call() {}
  void baz() {}
}
main() {
  new A();
  foo();
}
var foo;
var bar;
''');
    helper.assertHasFunction('main');
    helper.assertHasVariable('foo');
    helper.assertNoVariable('bar');
    helper.assertHasInstantiatedClass('A');
    helper.assertHasMethod('A.call');
    helper.assertNoMethod('A.baz');
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

  test('Getter usage', () {
    var helper = new TreeShakerTestHelper('''
class A {
  get g1 => null;
  get g2 => null;
  set g1(x) {}
  set g2(x) {}
}
class B {
  get g1 => null;
  get g2 => null;
  set g1(x) {}
  set g2(x) {}
}
main() {
  new A().g1;
}
''');
    helper.assertHasGetter('A.g1');
    helper.assertNoGetter('A.g2');
    helper.assertNoGetter('B.g1');
    helper.assertNoGetter('B.g2');
    helper.assertNoSetter('A.g1');
    helper.assertNoSetter('A.g2');
    helper.assertNoSetter('B.g1');
    helper.assertNoSetter('B.g2');
  });

  test('Setter usage', () {
    var helper = new TreeShakerTestHelper('''
class A {
  get g1 => null;
  get g2 => null;
  set g1(x) {}
  set g2(x) {}
}
class B {
  get g1 => null;
  get g2 => null;
  set g1(x) {}
  set g2(x) {}
}
main() {
  new A().g1 = 1;
}
''');
    helper.assertHasSetter('A.g1');
    helper.assertNoSetter('A.g2');
    helper.assertNoSetter('B.g1');
    helper.assertNoSetter('B.g2');
    helper.assertNoGetter('A.g1');
    helper.assertNoGetter('A.g2');
    helper.assertNoGetter('B.g1');
    helper.assertNoGetter('B.g2');
  });

  test('Field read', () {
    var helper = new TreeShakerTestHelper('''
class A {
  var f1;
  var f2;
}
class B {
  var f1;
  var f2;
}
main() {
  new A().f1;
}
''');
    helper.assertHasField('A.f1');
    helper.assertNoField('A.f2');
    helper.assertNoField('B.f1');
    helper.assertNoField('B.f2');
  });

  test('Field write', () {
    var helper = new TreeShakerTestHelper('''
class A {
  var f1;
  var f2;
}
class B {
  var f1;
  var f2;
}
main() {
  new A().f1 = 1;
}
''');
    helper.assertHasField('A.f1');
    helper.assertNoField('A.f2');
    helper.assertNoField('B.f1');
    helper.assertNoField('B.f2');
  });

  test('Ordinary constructor with initializer list', () {
    var helper = new TreeShakerTestHelper('''
class A {
  A() : x = f();
  var x;
  foo() {}
}
f() {}
main() {
  new A().foo();
}
''');
    helper.assertHasMethod('A.foo');
    helper.assertHasFunction('f');
  });

  test('Redirecting constructor', () {
    var helper = new TreeShakerTestHelper('''
class A {
  A.a1() : this.a2();
  A.a2();
  foo() {}
}
main() {
  new A.a1().foo();
}
''');
    helper.assertHasMethod('A.foo');
  });

  test('Factory constructor', () {
    var helper = new TreeShakerTestHelper('''
class A {
  factory A() {
    return new B();
  }
  foo() {}
}
class B {
  B();
  foo() {}
}
main() {
  new A().foo();
}
''');
    helper.assertHasMethod('B.foo');
    helper.assertNoMethod('A.foo');
  });

  test('Redirecting factory constructor', () {
    var helper = new TreeShakerTestHelper('''
class A {
  factory A() = B;
  foo() {}
}
class B {
  B();
  foo() {}
}
main() {
  new A().foo();
}
''');
    helper.assertHasMethod('B.foo');
    helper.assertNoMethod('A.foo');
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
   * Getters contained in [world], indexed by className.propertyName.
   */
  Map<String, MethodDeclaration> getters = <String, MethodDeclaration>{};

  /**
   * Setters contained in [world], indexed by className.propertyName.
   */
  Map<String, MethodDeclaration> setters = <String, MethodDeclaration>{};

  /**
   * Fields contained in [world], indexed by className.fieldName.
   */
  Map<String, VariableDeclaration> fields = <String, VariableDeclaration>{};

  /**
   * Top level variables contained in [world], indexed by name.
   */
  Map<String, VariableDeclaration> variables = <String, VariableDeclaration>{};

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
    Driver driver = new Driver(provider, sdk, NullSink.outputProvider);
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
      } else if (element is PropertyAccessorElement) {
        MethodDeclaration declaration = node as MethodDeclaration;
        expect(declaration, isNotNull);
        expect(declaration.element, equals(element));
        if (declaration.isGetter) {
          getters['${element.enclosingElement.name}.${element.name}'] =
              declaration;
        } else if (declaration.isSetter) {
          setters['${element.enclosingElement.name}.${element.displayName}'] =
              declaration;
        } else {
          fail('Unexpected property accessor (neither getter nor setter)');
        }
      }
    });
    world.instantiatedClasses.forEach(
        (ClassElement element, ClassDeclaration declaration) {
      expect(declaration, isNotNull);
      expect(declaration.element, equals(element));
      instantiatedClasses[element.name] = declaration;
    });
    world.fields.forEach(
        (FieldElement element, VariableDeclaration declaration) {
      expect(declaration, isNotNull);
      expect(declaration.element, equals(element));
      fields['${element.enclosingElement.name}.${element.name}'] = declaration;
    });
    world.variables.forEach(
        (TopLevelVariableElement element, VariableDeclaration declaration) {
      expect(declaration, isNotNull);
      expect(declaration.element, equals(element));
      variables['${element.name}'] = declaration;
    });
  }

  /**
   * Asserts that [world] contains a field with the given qualified name.
   */
  void assertHasField(String qualifiedName) {
    expect(fields, contains(qualifiedName));
  }

  /**
   * Asserts that [world] contains a top level variable with the given name.
   */
  void assertHasVariable(String name) {
    expect(variables, contains(name));
  }

  /**
   * Asserts that [world] contains a top-level function with the given name.
   */
  void assertHasFunction(String name) {
    expect(functions, contains(name));
  }

  /**
   * Asserts that [world] contains a getter with the given qualified name.
   */
  void assertHasGetter(String qualifiedName) {
    expect(getters, contains(qualifiedName));
  }

  /**
   * Asserts that [world] contains a setter with the given qualified name.
   */
  void assertHasSetter(String qualifiedName) {
    expect(setters, contains(qualifiedName));
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

  /**
   * Asserts that [world] doesn't contain a field with the given qualified
   * name.
   */
  void assertNoField(String qualifiedName) {
    expect(fields, isNot(contains(qualifiedName)));
  }

  /**
   * Asserts that [world] doesn't contain a top level variable with the given
   * name.
   */
  void assertNoVariable(String name) {
    expect(variables, isNot(contains(name)));
  }

  /**
   * Asserts that [world] doesn't contain a top-level function with the given
   * name.
   */
  void assertNoFunction(String name) {
    expect(functions, isNot(contains(name)));
  }

  /**
   * Asserts that [world] doesn't contain a getter with the given qualified
   * name.
   */
  void assertNoGetter(String qualifiedName) {
    expect(getters, isNot(contains(qualifiedName)));
  }

  /**
   * Asserts that [world] doesn't contain a setter with the given qualified
   * name.
   */
  void assertNoSetter(String qualifiedName) {
    expect(setters, isNot(contains(qualifiedName)));
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
