// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'summarize_ast_test.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(LinkerUnitTest);
}

@reflectiveTest
class LinkerUnitTest extends SummaryLinkerTest {
  Linker linker;

  LinkerInputs linkerInputs;
  LibraryElementInBuildUnit _testLibrary;
  @override
  bool get allowMissingFiles => false;

  LibraryElementInBuildUnit get testLibrary => _testLibrary ??=
      linker.getLibrary(linkerInputs.testDartUri) as LibraryElementInBuildUnit;

  void createLinker(String text, {String path: '/test.dart'}) {
    linkerInputs = createLinkerInputs(text, path: path);
    Map<String, LinkedLibraryBuilder> linkedLibraries =
        setupForLink(linkerInputs.linkedLibraries, linkerInputs.getUnit);
    linker = new Linker(linkedLibraries, linkerInputs.getDependency,
        linkerInputs.getUnit, true);
  }

  LibraryElementForLink getLibrary(String uri) {
    return linker.getLibrary(Uri.parse(uri));
  }

  void test_baseClass_genericWithAccessor() {
    createLinker('''
class B<T> {
  int get i => null;
}
class C<U> extends B<U> {
  var j;
}
    ''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    // No assertions--just make sure it doesn't crash.
  }

  void test_baseClass_genericWithField() {
    createLinker('''
class B<T> {
  int i = 0;
}
class C<T> extends B<T> {
  void f() {}
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    // No assertions--just make sure it doesn't crash.
  }

  void test_baseClass_genericWithFunctionTypedParameter() {
    createLinker('''
class B<T> {
  void f(void g(T t));
}
class C<U> extends B<U> {
  void f(g) {}
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    // No assertions--just make sure it doesn't crash.
  }

  void test_baseClass_genericWithGenericMethod() {
    createLinker('''
class B<T> {
  List<U> f<U>(U u) => null;
}
class C<V> extends B<V> {
  var j;
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    // No assertions--just make sure it doesn't crash.
  }

  void test_baseClass_genericWithGenericMethod_returnsGenericFuture() {
    createLinker('''
import 'dart:async';
class B<T> {
  Future<T> f() => null;
}
class C<T> extends B<T> {
  Future<T> f() => null;
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    // No assertions--just make sure it doesn't crash.
  }

  void test_baseClass_genericWithStaticFinal() {
    createLinker('''
class B<T> {
  static final int i = 0;
}
class C<T> extends B<T> {
  void f() {}
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
  }

  void test_baseClass_withPrivateField() {
    createLinker('''
class B {
  var _b;
}
class C extends B {
  var c;
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    // No assertions--just make sure it doesn't crash.
  }

  void test_constCycle_viaLength() {
    createLinker('''
class C {
  final y;
  const C() : y = x.length;
}
const x = [const C()];
''');
    testLibrary.libraryCycleForLink.ensureLinked();
    ClassElementForLink classC = testLibrary.getContainedName('C');
    expect(classC.unnamedConstructor.isCycleFree, false);
  }

  void test_inferredType_instanceField_dynamic() {
    createLinker('''
var x;
class C {
  var f = x; // Inferred type: dynamic
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    ClassElementForLink_Class cls = library.getContainedName('C');
    expect(cls.fields, hasLength(1));
    var field = cls.fields[0];
    expect(field.type.toString(), 'dynamic');
  }

  void test_inferredType_methodParamType_dynamic() {
    createLinker('''
clas B {
  void f(dynamic x) {}
}
class C extends B {
  f(x) {} // Inferred param type: dynamic
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    ClassElementForLink_Class cls = library.getContainedName('C');
    expect(cls.methods, hasLength(1));
    var method = cls.methods[0];
    expect(method.parameters, hasLength(1));
    expect(method.parameters[0].type.toString(), 'dynamic');
  }

  void test_inferredType_methodReturnType_dynamic() {
    createLinker('''
class B {
  dynamic f() {}
}
class C extends B {
  f() {} // Inferred return type: dynamic
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    ClassElementForLink_Class cls = library.getContainedName('C');
    expect(cls.methods, hasLength(1));
    expect(cls.methods[0].returnType.toString(), 'dynamic');
  }

  void test_inferredType_methodReturnType_void() {
    createLinker('''
class B {
  void f() {}
}
class C extends B {
  f() {}
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    ClassElementForLink_Class cls = library.getContainedName('C');
    expect(cls.methods, hasLength(1));
    expect(cls.methods[0].returnType.toString(), 'void');
  }

  void test_inferredType_staticField_dynamic() {
    createLinker('''
dynamic x = null;
class C {
  static var y = x;
}
''');
    expect(
        linker
            .getLibrary(linkerInputs.testDartUri)
            .getContainedName('C')
            .getContainedName('y')
            .asTypeInferenceNode
            .variableElement
            .inferredType
            .toString(),
        'dynamic');
  }

  void test_inferredType_topLevelVariable_dynamic() {
    createLinker('''
dynamic x = null;
var y = x;
''');
    expect(
        linker
            .getLibrary(linkerInputs.testDartUri)
            .getContainedName('y')
            .asTypeInferenceNode
            .variableElement
            .inferredType
            .toString(),
        'dynamic');
  }

  void test_inferredTypeFromOutsideBuildUnit_dynamic() {
    var bundle = createPackageBundle(
        '''
var x;
var y = x; // Inferred type: dynamic
''',
        path: '/a.dart');
    addBundle(bundle);
    createLinker('''
import 'a.dart';
var z = y; // Inferred type: dynamic
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    expect(
        library
            .getContainedName('z')
            .asTypeInferenceNode
            .variableElement
            .inferredType
            .toString(),
        'dynamic');
  }

  void test_inferredTypeFromOutsideBuildUnit_instanceField() {
    var bundle = createPackageBundle(
        '''
class C {
  var f = 0; // Inferred type: int
}
''',
        path: '/a.dart');
    addBundle(bundle);
    createLinker('''
import 'a.dart';
var x = new C().f; // Inferred type: int
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    expect(
        library
            .getContainedName('x')
            .asTypeInferenceNode
            .variableElement
            .inferredType
            .toString(),
        'int');
  }

  void test_inferredTypeFromOutsideBuildUnit_instanceField_toInstanceField() {
    var bundle = createPackageBundle(
        '''
class C {
  var f = 0; // Inferred type: int
}
''',
        path: '/a.dart');
    addBundle(bundle);
    createLinker('''
import 'a.dart';
class D {
  var g = new C().f; // Inferred type: int
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    ClassElementForLink_Class classD = library.getContainedName('D');
    expect(classD.fields[0].inferredType.toString(), 'int');
  }

  void test_inferredTypeFromOutsideBuildUnit_methodParamType_viaGeneric() {
    var bundle = createPackageBundle(
        '''
class B {
  T f<T>(T t) => t;
}
class C extends B {
  f<T>(t) => t; // Inferred param type: T
}
''',
        path: '/a.dart');
    addBundle(bundle);
    createLinker('''
import 'a.dart';
var x = new C().f(0); // Inferred type: int
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    expect(
        library
            .getContainedName('x')
            .asTypeInferenceNode
            .variableElement
            .inferredType
            .toString(),
        'int');
  }

  void test_inferredTypeFromOutsideBuildUnit_methodParamType_viaInheritance() {
    var bundle = createPackageBundle(
        '''
class B {
  void f(int i) {}
}
class C extends B {
  f(i) {} // Inferred param type: int
}
''',
        path: '/a.dart');
    addBundle(bundle);
    createLinker('''
import 'a.dart';
class D extends C {
  f(i) {} // Inferred param type: int
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    ClassElementForLink_Class cls = library.getContainedName('D');
    expect(cls.methods, hasLength(1));
    var method = cls.methods[0];
    expect(method.parameters, hasLength(1));
    expect(method.parameters[0].type.toString(), 'int');
  }

  void test_inferredTypeFromOutsideBuildUnit_methodReturnType_viaCall() {
    var bundle = createPackageBundle(
        '''
class B {
  int f() => 0;
}
class C extends B {
  f() => 1; // Inferred return type: int
}
''',
        path: '/a.dart');
    addBundle(bundle);
    createLinker('''
import 'a.dart';
var x = new C().f(); // Inferred type: int
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    expect(
        library
            .getContainedName('x')
            .asTypeInferenceNode
            .variableElement
            .inferredType
            .toString(),
        'int');
  }

  void test_inferredTypeFromOutsideBuildUnit_methodReturnType_viaInheritance() {
    var bundle = createPackageBundle(
        '''
class B {
  int f() => 0;
}
class C extends B {
  f() => 1; // Inferred return type: int
}
''',
        path: '/a.dart');
    addBundle(bundle);
    createLinker('''
import 'a.dart';
class D extends C {
  f() => 2; //Inferred return type: int
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    ClassElementForLink_Class cls = library.getContainedName('D');
    expect(cls.methods, hasLength(1));
    expect(cls.methods[0].returnType.toString(), 'int');
  }

  void test_inferredTypeFromOutsideBuildUnit_staticField() {
    var bundle =
        createPackageBundle('class C { static var f = 0; }', path: '/a.dart');
    addBundle(bundle);
    createLinker('import "a.dart"; var x = C.f;', path: '/b.dart');
    expect(
        linker
            .getLibrary(linkerInputs.testDartUri)
            .getContainedName('x')
            .asTypeInferenceNode
            .variableElement
            .inferredType
            .toString(),
        'int');
  }

  void test_inferredTypeFromOutsideBuildUnit_topLevelVariable() {
    var bundle = createPackageBundle('var a = 0;', path: '/a.dart');
    addBundle(bundle);
    createLinker('import "a.dart"; var b = a;', path: '/b.dart');
    expect(
        linker
            .getLibrary(linkerInputs.testDartUri)
            .getContainedName('b')
            .asTypeInferenceNode
            .variableElement
            .inferredType
            .toString(),
        'int');
  }

  void test_leastUpperBound_functionAndClass() {
    createLinker('''
class C {}
void f() {}
var x = {
  'C': C,
  'f': f
};
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    // No assertions--just make sure it doesn't crash.
  }

  void test_libraryCycle_ignoresDependenciesOutsideBuildUnit() {
    createLinker('import "dart:async";');
    LibraryCycleForLink libraryCycle = testLibrary.libraryCycleForLink;
    expect(libraryCycle.dependencies, isEmpty);
    expect(libraryCycle.libraries, [testLibrary]);
  }

  void test_libraryCycle_linkEnsuresDependenciesLinked() {
    addNamedSource('/a.dart', 'import "b.dart";');
    addNamedSource('/b.dart', '');
    addNamedSource('/c.dart', '');
    createLinker('import "a.dart"; import "c.dart";');
    LibraryElementForLink libA = getLibrary('file:///a.dart');
    LibraryElementForLink libB = getLibrary('file:///b.dart');
    LibraryElementForLink libC = getLibrary('file:///c.dart');
    expect(libA.libraryCycleForLink.node.isEvaluated, isFalse);
    expect(libB.libraryCycleForLink.node.isEvaluated, isFalse);
    expect(libC.libraryCycleForLink.node.isEvaluated, isFalse);
    libA.libraryCycleForLink.ensureLinked();
    expect(libA.libraryCycleForLink.node.isEvaluated, isTrue);
    expect(libB.libraryCycleForLink.node.isEvaluated, isTrue);
    expect(libC.libraryCycleForLink.node.isEvaluated, isFalse);
  }

  void test_libraryCycle_nontrivial() {
    addNamedSource('/a.dart', 'import "b.dart";');
    addNamedSource('/b.dart', 'import "a.dart";');
    createLinker('');
    LibraryElementForLink libA = getLibrary('file:///a.dart');
    LibraryElementForLink libB = getLibrary('file:///b.dart');
    LibraryCycleForLink libraryCycle = libA.libraryCycleForLink;
    expect(libB.libraryCycleForLink, same(libraryCycle));
    expect(libraryCycle.dependencies, isEmpty);
    expect(libraryCycle.libraries, unorderedEquals([libA, libB]));
  }

  void test_libraryCycle_nontrivial_dependencies() {
    addNamedSource('/a.dart', '');
    addNamedSource('/b.dart', '');
    addNamedSource('/c.dart', 'import "a.dart"; import "d.dart";');
    addNamedSource('/d.dart', 'import "b.dart"; import "c.dart";');
    createLinker('');
    LibraryElementForLink libA = getLibrary('file:///a.dart');
    LibraryElementForLink libB = getLibrary('file:///b.dart');
    LibraryElementForLink libC = getLibrary('file:///c.dart');
    LibraryElementForLink libD = getLibrary('file:///d.dart');
    LibraryCycleForLink libraryCycle = libC.libraryCycleForLink;
    expect(libD.libraryCycleForLink, same(libraryCycle));
    expect(libraryCycle.dependencies,
        unorderedEquals([libA.libraryCycleForLink, libB.libraryCycleForLink]));
    expect(libraryCycle.libraries, unorderedEquals([libC, libD]));
  }

  void test_libraryCycle_nontrivial_via_export() {
    addNamedSource('/a.dart', 'export "b.dart";');
    addNamedSource('/b.dart', 'export "a.dart";');
    createLinker('');
    LibraryElementForLink libA = getLibrary('file:///a.dart');
    LibraryElementForLink libB = getLibrary('file:///b.dart');
    LibraryCycleForLink libraryCycle = libA.libraryCycleForLink;
    expect(libB.libraryCycleForLink, same(libraryCycle));
    expect(libraryCycle.dependencies, isEmpty);
    expect(libraryCycle.libraries, unorderedEquals([libA, libB]));
  }

  void test_libraryCycle_trivial() {
    createLinker('');
    LibraryCycleForLink libraryCycle = testLibrary.libraryCycleForLink;
    expect(libraryCycle.dependencies, isEmpty);
    expect(libraryCycle.libraries, [testLibrary]);
  }

  void test_libraryCycle_trivial_dependencies() {
    addNamedSource('/a.dart', '');
    addNamedSource('/b.dart', '');
    createLinker('import "a.dart"; import "b.dart";');
    LibraryElementForLink libA = getLibrary('file:///a.dart');
    LibraryElementForLink libB = getLibrary('file:///b.dart');
    LibraryCycleForLink libraryCycle = testLibrary.libraryCycleForLink;
    expect(libraryCycle.dependencies,
        unorderedEquals([libA.libraryCycleForLink, libB.libraryCycleForLink]));
    expect(libraryCycle.libraries, [testLibrary]);
  }

  void test_multiplyInheritedExecutable_differentSignatures() {
    createLinker('''
class B {
  void f() {}
}
abstract class I {
   f();
}
class C extends B with I {}
class D extends C {
  void f() {}
}
''');
    LibraryElementForLink library = linker.getLibrary(linkerInputs.testDartUri);
    library.libraryCycleForLink.ensureLinked();
    // No assertions--just make sure it doesn't crash.
  }

  void test_parameterParentElementForLink_implicitFunctionTypeIndices() {
    createLinker('void f(a, void g(b, c, d, void h())) {}');
    TopLevelFunctionElementForLink f = testLibrary.getContainedName('f');
    expect(f.implicitFunctionTypeIndices, []);
    ParameterElementForLink g = f.parameters[1];
    FunctionType gType = g.type;
    FunctionElementForLink_FunctionTypedParam gTypeElement = gType.element;
    expect(gTypeElement.implicitFunctionTypeIndices, [1]);
    ParameterElementForLink h = gTypeElement.parameters[3];
    FunctionType hType = h.type;
    FunctionElementForLink_FunctionTypedParam hTypeElement = hType.element;
    expect(hTypeElement.implicitFunctionTypeIndices, [1, 3]);
  }

  void test_parameterParentElementForLink_innermostExecutable() {
    createLinker('void f(void g(void h())) {}');
    TopLevelFunctionElementForLink f = testLibrary.getContainedName('f');
    expect(f.typeParameterContext, same(f));
    ParameterElementForLink g = f.parameters[0];
    FunctionType gType = g.type;
    FunctionElementForLink_FunctionTypedParam gTypeElement = gType.element;
    expect(gTypeElement.typeParameterContext, same(f));
    ParameterElementForLink h = gTypeElement.parameters[0];
    FunctionType hType = h.type;
    FunctionElementForLink_FunctionTypedParam hTypeElement = hType.element;
    expect(hTypeElement.typeParameterContext, same(f));
  }

  void test_typeParameter_isTypeParameterInScope_direct() {
    createLinker('class C<T, U> {}');
    ClassElementForLink_Class c = testLibrary.getContainedName('C');
    TypeParameterElementForLink t = c.typeParameters[0];
    TypeParameterElementForLink u = c.typeParameters[1];
    expect(c.isTypeParameterInScope(t), true);
    expect(c.isTypeParameterInScope(u), true);
  }

  void test_typeParameter_isTypeParameterInScope_indirect() {
    createLinker('class C<T, U> { f<V, W>() {} }');
    ClassElementForLink_Class c = testLibrary.getContainedName('C');
    MethodElementForLink f = c.methods[0];
    TypeParameterElementForLink t = c.typeParameters[0];
    TypeParameterElementForLink u = c.typeParameters[1];
    expect(f.isTypeParameterInScope(t), true);
    expect(f.isTypeParameterInScope(u), true);
  }

  void test_typeParameter_isTypeParameterInScope_reversed() {
    createLinker('class C<T, U> { f<V, W>() {} }');
    ClassElementForLink_Class c = testLibrary.getContainedName('C');
    MethodElementForLink f = c.methods[0];
    TypeParameterElementForLink v = f.typeParameters[0];
    TypeParameterElementForLink w = f.typeParameters[1];
    expect(c.isTypeParameterInScope(v), false);
    expect(c.isTypeParameterInScope(w), false);
  }

  void test_typeParameter_isTypeParameterInScope_unrelated() {
    createLinker('class C<T, U> {} class D<V, W> {}');
    ClassElementForLink_Class c = testLibrary.getContainedName('C');
    ClassElementForLink_Class d = testLibrary.getContainedName('D');
    TypeParameterElementForLink t = c.typeParameters[0];
    TypeParameterElementForLink u = c.typeParameters[1];
    TypeParameterElementForLink v = d.typeParameters[0];
    TypeParameterElementForLink w = d.typeParameters[1];
    expect(c.isTypeParameterInScope(v), false);
    expect(c.isTypeParameterInScope(w), false);
    expect(d.isTypeParameterInScope(t), false);
    expect(d.isTypeParameterInScope(u), false);
  }
}
