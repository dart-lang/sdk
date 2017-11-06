// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/incremental/combine.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/testing/mock_sdk_program.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CombineTest);
  });
}

@reflectiveTest
class CombineTest {
  Program sdk;
  CoreTypes coreTypes;

  Supertype get objectSuper => coreTypes.objectClass.asThisSupertype;

  void setUp() {
    sdk = createMockSdkProgram();
    coreTypes = new CoreTypes(sdk);
  }

  void test_class_mergeLibrary_appendClass() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addClass(new Class(name: 'A', supertype: objectSuper));

    var libraryA2 = _newLibrary('a');
    libraryA2.addClass(new Class(name: 'B', supertype: objectSuper));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');

      var classA = _getClass(libraryA, 'A');
      expect(classA.members, isEmpty);

      var classB = _getClass(libraryA, 'B');
      expect(classB.members, isEmpty);
    });
  }

  /// We test two cases of class declarations:
  ///   * When a class to merge is first time declared in the first library;
  ///   * When a class to merge is first time declared in the second library.
  ///
  /// With two cases of constructor declarations:
  ///   * Already defined, so references to it should be rewritten.
  ///   * First defined in this outline, so references to it can be kept as is.
  ///
  /// For each case we validate [DirectMethodInvocation], [MethodInvocation],
  /// and [SuperMethodInvocation].
  void test_class_procedure_constructor() {
    var nodeToName = <NamedNode, String>{};

    var library1 = _newLibrary('test');
    var constructorA11 = _newConstructor('a1');
    var classA1 = new Class(
        name: 'A', supertype: objectSuper, constructors: [constructorA11]);
    library1.addClass(classA1);
    nodeToName[classA1] = 'A1';
    nodeToName[constructorA11] = 'A11';

    var library2 = _newLibrary('test');
    var constructorA12 = _newConstructor('a1');
    var constructorA22 = _newConstructor('a2');
    var constructorB11 = _newConstructor('b1');
    var classA2 = new Class(
        name: 'A',
        supertype: objectSuper,
        constructors: [constructorA12, constructorA22]);
    library2.addClass(classA2);
    var classB1 = new Class(
        name: 'B', supertype: objectSuper, constructors: [constructorB11]);
    library2.addClass(classB1);
    // Use 'A.a1' and 'A.a2' to validate later how they are rewritten.
    library2.addProcedure(_newExpressionsProcedure([
      new ConstructorInvocation(constructorA12, new Arguments.empty()),
      new ConstructorInvocation(constructorA22, new Arguments.empty()),
    ], name: 'main2'));
    library2.addClass(new Class(
        name: 'S1',
        supertype: classA2.asThisSupertype,
        constructors: [
          new Constructor(new FunctionNode(new EmptyStatement()),
              name: new Name('c1'),
              initializers: [
                new SuperInitializer(constructorA12, new Arguments.empty()),
                new SuperInitializer(constructorA22, new Arguments.empty()),
              ]),
          new Constructor(new FunctionNode(new EmptyStatement()),
              name: new Name('c2'),
              initializers: [
                new RedirectingInitializer(
                    constructorA12, new Arguments.empty()),
                new RedirectingInitializer(
                    constructorA22, new Arguments.empty()),
              ]),
        ]));
    nodeToName[classA2] = 'A2';
    nodeToName[constructorA12] = 'A12';
    nodeToName[constructorA22] = 'A22';
    nodeToName[constructorB11] = 'B11';
    nodeToName[classB1] = 'B1';
    nodeToName[constructorB11] = 'B11';

    var library3 = _newLibrary('test');
    var constructorB12 = _newConstructor('b1');
    var constructorB22 = _newConstructor('b2');
    var classB2 = new Class(
        name: 'B',
        supertype: objectSuper,
        constructors: [constructorB12, constructorB22]);
    library3.addClass(classB2);
    library3.addProcedure(_newExpressionsProcedure([
      new ConstructorInvocation(constructorB12, new Arguments.empty()),
      new ConstructorInvocation(constructorB22, new Arguments.empty()),
    ], name: 'main3'));
    library3.addClass(new Class(
        name: 'S2',
        supertype: classB2.asThisSupertype,
        constructors: [
          new Constructor(new FunctionNode(new EmptyStatement()),
              name: new Name('c1'),
              initializers: [
                new SuperInitializer(constructorB12, new Arguments.empty()),
                new SuperInitializer(constructorB22, new Arguments.empty()),
              ]),
          new Constructor(new FunctionNode(new EmptyStatement()),
              name: new Name('c2'),
              initializers: [
                new RedirectingInitializer(
                    constructorB12, new Arguments.empty()),
                new RedirectingInitializer(
                    constructorB22, new Arguments.empty()),
              ]),
        ]));
    nodeToName[classB2] = 'B2';
    nodeToName[constructorB12] = 'B12';
    nodeToName[constructorB22] = 'B22';

    var outline1 = _newOutline([library1]);
    var outline2 = _newOutline([library2]);
    var outline3 = _newOutline([library3]);

    expect(_getLibraryText(library1, nodeToName), r'''
class A[A1] {
  constructor a1[A11]();
}
''');
    expect(_getLibraryText(library2, nodeToName), r'''
class A[A2] {
  constructor a1[A12]();
  constructor a2[A22]();
}
class B[B1] {
  constructor b1[B11]();
}
class S1 extends A[A2] {
  constructor c1() :
      super[A12](),
      super[A22]();
  constructor c2() :
      redirect[A12](),
      redirect[A22]();
}
main2() {
  ConstructorInvocation[A12]();
  ConstructorInvocation[A22]();
}
''');
    expect(_getLibraryText(library3, nodeToName), r'''
class B[B2] {
  constructor b1[B12]();
  constructor b2[B22]();
}
class S2 extends B[B2] {
  constructor c1() :
      super[B12](),
      super[B22]();
  constructor c2() :
      redirect[B12](),
      redirect[B22]();
}
main3() {
  ConstructorInvocation[B12]();
  ConstructorInvocation[B22]();
}
''');

    _runCombineTest([outline1, outline2, outline3], (result) {
      var library = _getLibrary(result.program, 'test');
      expect(_getLibraryText(library, nodeToName), r'''
class A[A1] {
  constructor a1[A11]();
  constructor a2[A22]();
}
class B[B1] {
  constructor b1[B11]();
  constructor b2[B22]();
}
class S1 extends A[A1] {
  constructor c1() :
      super[A11](),
      super[A22]();
  constructor c2() :
      redirect[A11](),
      redirect[A22]();
}
class S2 extends B[B1] {
  constructor c1() :
      super[B11](),
      super[B22]();
  constructor c2() :
      redirect[B11](),
      redirect[B22]();
}
main2() {
  ConstructorInvocation[A11]();
  ConstructorInvocation[A22]();
}
main3() {
  ConstructorInvocation[B11]();
  ConstructorInvocation[B22]();
}
''');
    });
  }

  /// We test two cases of class declarations:
  ///   * When a class to merge is first time declared in the first library;
  ///   * When a class to merge is first time declared in the second library.
  ///
  /// With two cases of field declarations:
  ///   * Already defined, so references to it should be rewritten.
  ///   * First defined in this outline, so references to it can be kept as is.
  ///
  /// For each case we validate [DirectPropertyGet], [DirectPropertySet],
  /// [PropertyGet], [PropertySet], [SuperPropertyGet], and [SuperPropertySet].
  void test_class_procedure_field() {
    var nodeToName = <NamedNode, String>{};

    var library1 = _newLibrary('test');
    var fieldA11 = _newField('a1');
    var classA1 =
        new Class(name: 'A', supertype: objectSuper, fields: [fieldA11]);
    library1.addClass(classA1);
    nodeToName[classA1] = 'A1';
    nodeToName[fieldA11] = 'a11';

    var library2 = _newLibrary('test');
    var fieldA12 = _newField('a1');
    var fieldA22 = _newField('a2');
    var fieldB11 = _newField('b1');
    var classA2 = new Class(
        name: 'A', supertype: objectSuper, fields: [fieldA12, fieldA22]);
    library2.addClass(classA2);
    var classB1 =
        new Class(name: 'B', supertype: objectSuper, fields: [fieldB11]);
    library2.addClass(classB1);
    // Use 'A.a1' and 'A.a2' to validate later how they are rewritten.
    library2.addProcedure(_newExpressionsProcedure([
      new DirectPropertyGet(null, fieldA12),
      new PropertyGet(null, null, fieldA12),
      new DirectPropertySet(null, fieldA12, null),
      new PropertySet(null, null, null, fieldA12),
      new DirectPropertyGet(null, fieldA22),
      new PropertyGet(null, null, fieldA22),
      new DirectPropertySet(null, fieldA22, null),
      new PropertySet(null, null, null, fieldA22),
    ], name: 'main2'));
    library2.addClass(
        new Class(name: 'S1', supertype: classA2.asThisSupertype, procedures: [
      _newExpressionsProcedure([
        new SuperPropertyGet(null, fieldA12),
        new SuperPropertySet(null, null, fieldA12),
        new SuperPropertyGet(null, fieldA22),
        new SuperPropertySet(null, null, fieldA22),
      ], name: 'foo')
    ]));
    nodeToName[classA2] = 'A2';
    nodeToName[classB1] = 'B1';
    nodeToName[fieldA12] = 'a12';
    nodeToName[fieldA22] = 'a22';
    nodeToName[fieldB11] = 'b11';

    var library3 = _newLibrary('test');
    var fieldB12 = _newField('b1');
    var fieldB22 = _newField('b2');
    var classB2 = new Class(
        name: 'B', supertype: objectSuper, fields: [fieldB12, fieldB22]);
    library3.addClass(classB2);
    library3.addProcedure(_newExpressionsProcedure([
      new DirectPropertyGet(null, fieldB12),
      new PropertyGet(null, null, fieldB12),
      new DirectPropertyGet(null, fieldB22),
      new PropertyGet(null, null, fieldB22),
    ], name: 'main3'));
    library3.addClass(
        new Class(name: 'S2', supertype: classB2.asThisSupertype, procedures: [
      _newExpressionsProcedure([
        new SuperPropertyGet(null, fieldB12),
        new SuperPropertySet(null, null, fieldB12),
        new SuperPropertyGet(null, fieldB22),
        new SuperPropertySet(null, null, fieldB22),
      ], name: 'foo')
    ]));
    nodeToName[classB2] = 'B2';
    nodeToName[fieldB12] = 'b12';
    nodeToName[fieldB22] = 'b22';

    var outline1 = _newOutline([library1]);
    var outline2 = _newOutline([library2]);
    var outline3 = _newOutline([library3]);

    expect(_getLibraryText(library1, nodeToName), r'''
class A[A1] {
  var a1[a11];
}
''');
    expect(_getLibraryText(library2, nodeToName), r'''
class A[A2] {
  var a1[a12];
  var a2[a22];
}
class B[B1] {
  var b1[b11];
}
class S1 extends A[A2] {
  foo() {
    SuperPropertyGet[a12]();
    SuperPropertySet[a12]();
    SuperPropertyGet[a22]();
    SuperPropertySet[a22]();
  }
}
main2() {
  DirectPropertyGet[a12]();
  PropertyGet[a12]();
  DirectPropertySet[a12]();
  PropertySet[a12]();
  DirectPropertyGet[a22]();
  PropertyGet[a22]();
  DirectPropertySet[a22]();
  PropertySet[a22]();
}
''');
    expect(_getLibraryText(library3, nodeToName), r'''
class B[B2] {
  var b1[b12];
  var b2[b22];
}
class S2 extends B[B2] {
  foo() {
    SuperPropertyGet[b12]();
    SuperPropertySet[b12]();
    SuperPropertyGet[b22]();
    SuperPropertySet[b22]();
  }
}
main3() {
  DirectPropertyGet[b12]();
  PropertyGet[b12]();
  DirectPropertyGet[b22]();
  PropertyGet[b22]();
}
''');

    _runCombineTest([outline1, outline2, outline3], (result) {
      var library = _getLibrary(result.program, 'test');
      expect(_getLibraryText(library, nodeToName), r'''
class A[A1] {
  var a1[a11];
  var a2[a22];
}
class B[B1] {
  var b1[b11];
  var b2[b22];
}
class S1 extends A[A1] {
  foo() {
    SuperPropertyGet[a11]();
    SuperPropertySet[a11]();
    SuperPropertyGet[a22]();
    SuperPropertySet[a22]();
  }
}
class S2 extends B[B1] {
  foo() {
    SuperPropertyGet[b11]();
    SuperPropertySet[b11]();
    SuperPropertyGet[b22]();
    SuperPropertySet[b22]();
  }
}
main2() {
  DirectPropertyGet[a11]();
  PropertyGet[a11]();
  DirectPropertySet[a11]();
  PropertySet[a11]();
  DirectPropertyGet[a22]();
  PropertyGet[a22]();
  DirectPropertySet[a22]();
  PropertySet[a22]();
}
main3() {
  DirectPropertyGet[b11]();
  PropertyGet[b11]();
  DirectPropertyGet[b22]();
  PropertyGet[b22]();
}
''');
    });
  }

  /// We test two cases of class declarations:
  ///   * When a class to merge is first time declared in the first library;
  ///   * When a class to merge is first time declared in the second library.
  ///
  /// With two cases of setter declarations:
  ///   * Already defined, so references to it should be rewritten.
  ///   * First defined in this outline, so references to it can be kept as is.
  ///
  /// For each case we validate [DirectPropertyGet], [PropertyGet],
  /// and [SuperPropertyGet].
  void test_class_procedure_getter() {
    var nodeToName = <NamedNode, String>{};

    var library1 = _newLibrary('test');
    var procedureA11 = _newGetter('a1');
    var classA1 = new Class(
        name: 'A', supertype: objectSuper, procedures: [procedureA11]);
    library1.addClass(classA1);
    nodeToName[classA1] = 'A1';
    nodeToName[procedureA11] = 'a11';

    var library2 = _newLibrary('test');
    var procedureA12 = _newGetter('a1');
    var procedureA22 = _newGetter('a2');
    var procedureB11 = _newGetter('b1');
    var classA2 = new Class(
        name: 'A',
        supertype: objectSuper,
        procedures: [procedureA12, procedureA22]);
    library2.addClass(classA2);
    var classB1 = new Class(
        name: 'B', supertype: objectSuper, procedures: [procedureB11]);
    library2.addClass(classB1);
    // Use 'A.a1' and 'A.a2' to validate later how they are rewritten.
    library2.addProcedure(_newExpressionsProcedure([
      new DirectPropertyGet(null, procedureA12),
      new PropertyGet(null, null, procedureA12),
      new DirectPropertyGet(null, procedureA22),
      new PropertyGet(null, null, procedureA22),
    ], name: 'main2'));
    library2.addClass(
        new Class(name: 'S1', supertype: classA2.asThisSupertype, procedures: [
      _newExpressionsProcedure([
        new SuperPropertyGet(null, procedureA12),
        new SuperPropertyGet(null, procedureA22),
      ], name: 'foo')
    ]));
    nodeToName[classA2] = 'A2';
    nodeToName[classB1] = 'B1';
    nodeToName[procedureA12] = 'a12';
    nodeToName[procedureA22] = 'a22';
    nodeToName[procedureB11] = 'b11';

    var library3 = _newLibrary('test');
    var procedureB12 = _newGetter('b1');
    var procedureB22 = _newGetter('b2');
    var classB2 = new Class(
        name: 'B',
        supertype: objectSuper,
        procedures: [procedureB12, procedureB22]);
    library3.addClass(classB2);
    library3.addProcedure(_newExpressionsProcedure([
      new DirectPropertyGet(null, procedureB12),
      new PropertyGet(null, null, procedureB12),
    ], name: 'main3'));
    library3.addClass(
        new Class(name: 'S2', supertype: classB2.asThisSupertype, procedures: [
      _newExpressionsProcedure([
        new SuperPropertyGet(null, procedureB12),
        new SuperPropertyGet(null, procedureB22),
      ], name: 'foo')
    ]));
    nodeToName[classB2] = 'B2';
    nodeToName[procedureB12] = 'b12';
    nodeToName[procedureB22] = 'b22';

    var outline1 = _newOutline([library1]);
    var outline2 = _newOutline([library2]);
    var outline3 = _newOutline([library3]);

    expect(_getLibraryText(library1, nodeToName), r'''
class A[A1] {
  get a1[a11] => 0;
}
''');
    expect(_getLibraryText(library2, nodeToName), r'''
class A[A2] {
  get a1[a12] => 0;
  get a2[a22] => 0;
}
class B[B1] {
  get b1[b11] => 0;
}
class S1 extends A[A2] {
  foo() {
    SuperPropertyGet[a12]();
    SuperPropertyGet[a22]();
  }
}
main2() {
  DirectPropertyGet[a12]();
  PropertyGet[a12]();
  DirectPropertyGet[a22]();
  PropertyGet[a22]();
}
''');
    expect(_getLibraryText(library3, nodeToName), r'''
class B[B2] {
  get b1[b12] => 0;
  get b2[b22] => 0;
}
class S2 extends B[B2] {
  foo() {
    SuperPropertyGet[b12]();
    SuperPropertyGet[b22]();
  }
}
main3() {
  DirectPropertyGet[b12]();
  PropertyGet[b12]();
}
''');

    _runCombineTest([outline1, outline2, outline3], (result) {
      var library = _getLibrary(result.program, 'test');
      expect(_getLibraryText(library, nodeToName), r'''
class A[A1] {
  get a1[a11] => 0;
  get a2[a22] => 0;
}
class B[B1] {
  get b1[b11] => 0;
  get b2[b22] => 0;
}
class S1 extends A[A1] {
  foo() {
    SuperPropertyGet[a11]();
    SuperPropertyGet[a22]();
  }
}
class S2 extends B[B1] {
  foo() {
    SuperPropertyGet[b11]();
    SuperPropertyGet[b22]();
  }
}
main2() {
  DirectPropertyGet[a11]();
  PropertyGet[a11]();
  DirectPropertyGet[a22]();
  PropertyGet[a22]();
}
main3() {
  DirectPropertyGet[b11]();
  PropertyGet[b11]();
}
''');
    });
  }

  /// We test two cases of class declarations:
  ///   * When a class to merge is first time declared in the first library;
  ///   * When a class to merge is first time declared in the second library.
  ///
  /// With two cases of method declarations:
  ///   * Already defined, so references to it should be rewritten.
  ///   * First defined in this outline, so references to it can be kept as is.
  ///
  /// For each case we validate [DirectMethodInvocation], [MethodInvocation],
  /// and [SuperMethodInvocation].
  void test_class_procedure_method() {
    var nodeToName = <NamedNode, String>{};

    var library1 = _newLibrary('test');
    var procedureA11 = _newMethod('a1');
    var classA1 = new Class(
        name: 'A', supertype: objectSuper, procedures: [procedureA11]);
    library1.addClass(classA1);
    nodeToName[classA1] = 'A1';
    nodeToName[procedureA11] = 'a11';

    var library2 = _newLibrary('test');
    var procedureA12 = _newMethod('a1');
    var procedureA22 = _newMethod('a2');
    var procedureB11 = _newMethod('b1');
    var classA2 = new Class(
        name: 'A',
        supertype: objectSuper,
        procedures: [procedureA12, procedureA22]);
    library2.addClass(classA2);
    var classB1 = new Class(
        name: 'B', supertype: objectSuper, procedures: [procedureB11]);
    library2.addClass(classB1);
    // Use 'A.a1' and 'A.a2' to validate later how they are rewritten.
    library2.addProcedure(_newExpressionsProcedure([
      new DirectMethodInvocation(null, procedureA12, new Arguments.empty()),
      new MethodInvocation(null, null, new Arguments.empty(), procedureA12),
      new DirectMethodInvocation(null, procedureA22, new Arguments.empty()),
      new MethodInvocation(null, null, new Arguments.empty(), procedureA22),
    ], name: 'main2'));
    library2.addClass(
        new Class(name: 'S1', supertype: classA2.asThisSupertype, procedures: [
      _newExpressionsProcedure([
        new SuperMethodInvocation(null, null, procedureA12),
        new SuperMethodInvocation(null, null, procedureA22),
      ], name: 'foo')
    ]));
    nodeToName[classA2] = 'A2';
    nodeToName[classB1] = 'B1';
    nodeToName[procedureA12] = 'a12';
    nodeToName[procedureA22] = 'a22';
    nodeToName[procedureB11] = 'b11';

    var library3 = _newLibrary('test');
    var procedureB12 = _newMethod('b1');
    var procedureB22 = _newMethod('b2');
    var classB2 = new Class(
        name: 'B',
        supertype: objectSuper,
        procedures: [procedureB12, procedureB22]);
    library3.addClass(classB2);
    library3.addProcedure(_newExpressionsProcedure([
      new DirectMethodInvocation(null, procedureB12, new Arguments.empty()),
      new MethodInvocation(null, null, new Arguments.empty(), procedureB12),
    ], name: 'main3'));
    library3.addClass(
        new Class(name: 'S2', supertype: classB2.asThisSupertype, procedures: [
      _newExpressionsProcedure([
        new SuperMethodInvocation(null, null, procedureB12),
        new SuperMethodInvocation(null, null, procedureB22),
      ], name: 'foo')
    ]));
    nodeToName[classB2] = 'B2';
    nodeToName[procedureB12] = 'b12';
    nodeToName[procedureB22] = 'b22';

    var outline1 = _newOutline([library1]);
    var outline2 = _newOutline([library2]);
    var outline3 = _newOutline([library3]);

    expect(_getLibraryText(library1, nodeToName), r'''
class A[A1] {
  a1[a11]();
}
''');
    expect(_getLibraryText(library2, nodeToName), r'''
class A[A2] {
  a1[a12]();
  a2[a22]();
}
class B[B1] {
  b1[b11]();
}
class S1 extends A[A2] {
  foo() {
    SuperMethodInvocation[a12]();
    SuperMethodInvocation[a22]();
  }
}
main2() {
  DirectMethodInvocation[a12]();
  MethodInvocation[a12]();
  DirectMethodInvocation[a22]();
  MethodInvocation[a22]();
}
''');
    expect(_getLibraryText(library3, nodeToName), r'''
class B[B2] {
  b1[b12]();
  b2[b22]();
}
class S2 extends B[B2] {
  foo() {
    SuperMethodInvocation[b12]();
    SuperMethodInvocation[b22]();
  }
}
main3() {
  DirectMethodInvocation[b12]();
  MethodInvocation[b12]();
}
''');

    _runCombineTest([outline1, outline2, outline3], (result) {
      var library = _getLibrary(result.program, 'test');
      expect(_getLibraryText(library, nodeToName), r'''
class A[A1] {
  a1[a11]();
  a2[a22]();
}
class B[B1] {
  b1[b11]();
  b2[b22]();
}
class S1 extends A[A1] {
  foo() {
    SuperMethodInvocation[a11]();
    SuperMethodInvocation[a22]();
  }
}
class S2 extends B[B1] {
  foo() {
    SuperMethodInvocation[b11]();
    SuperMethodInvocation[b22]();
  }
}
main2() {
  DirectMethodInvocation[a11]();
  MethodInvocation[a11]();
  DirectMethodInvocation[a22]();
  MethodInvocation[a22]();
}
main3() {
  DirectMethodInvocation[b11]();
  MethodInvocation[b11]();
}
''');
    });
  }

  /// We test two cases of class declarations:
  ///   * When a class to merge is first time declared in the first library;
  ///   * When a class to merge is first time declared in the second library.
  ///
  /// With two cases of setter declarations:
  ///   * Already defined, so references to it should be rewritten.
  ///   * First defined in this outline, so references to it can be kept as is.
  ///
  /// For each case we validate [DirectPropertySet], [PropertySet],
  /// and [SuperPropertySet].
  void test_class_procedure_setter() {
    var nodeToName = <NamedNode, String>{};

    var library1 = _newLibrary('test');
    var procedureA11 = _newSetter('a1');
    var classA1 = new Class(
        name: 'A', supertype: objectSuper, procedures: [procedureA11]);
    library1.addClass(classA1);
    nodeToName[classA1] = 'A1';
    nodeToName[procedureA11] = 'a11';

    var library2 = _newLibrary('test');
    var procedureA12 = _newSetter('a1');
    var procedureA22 = _newSetter('a2');
    var procedureB11 = _newSetter('b1');
    var classA2 = new Class(
        name: 'A',
        supertype: objectSuper,
        procedures: [procedureA12, procedureA22]);
    library2.addClass(classA2);
    var classB1 = new Class(
        name: 'B', supertype: objectSuper, procedures: [procedureB11]);
    library2.addClass(classB1);
    // Use 'A.a1' and 'A.a2' to validate later how they are rewritten.
    library2.addProcedure(_newExpressionsProcedure([
      new DirectPropertySet(null, procedureA12, new IntLiteral(0)),
      new PropertySet(null, null, new IntLiteral(0), procedureA12),
      new DirectPropertySet(null, procedureA22, new IntLiteral(0)),
      new PropertySet(null, null, new IntLiteral(0), procedureA22),
    ], name: 'main2'));
    library2.addClass(
        new Class(name: 'S1', supertype: classA2.asThisSupertype, procedures: [
      _newExpressionsProcedure([
        new SuperPropertySet(null, new IntLiteral(0), procedureA12),
        new SuperPropertySet(null, new IntLiteral(0), procedureA22),
      ], name: 'foo')
    ]));
    nodeToName[classA2] = 'A2';
    nodeToName[classB1] = 'B1';
    nodeToName[procedureA12] = 'a12';
    nodeToName[procedureA22] = 'a22';
    nodeToName[procedureB11] = 'b11';

    var library3 = _newLibrary('test');
    var procedureB12 = _newSetter('b1');
    var procedureB22 = _newSetter('b2');
    var classB2 = new Class(
        name: 'B',
        supertype: objectSuper,
        procedures: [procedureB12, procedureB22]);
    library3.addClass(classB2);
    library3.addProcedure(_newExpressionsProcedure([
      new DirectPropertySet(null, procedureB12, new IntLiteral(0)),
      new PropertySet(null, null, new IntLiteral(0), procedureB12),
    ], name: 'main3'));
    library3.addClass(
        new Class(name: 'S2', supertype: classB2.asThisSupertype, procedures: [
      _newExpressionsProcedure([
        new SuperPropertySet(null, new IntLiteral(0), procedureB12),
        new SuperPropertySet(null, new IntLiteral(0), procedureB22),
      ], name: 'foo')
    ]));
    nodeToName[classB2] = 'B2';
    nodeToName[procedureB12] = 'b12';
    nodeToName[procedureB22] = 'b22';

    var outline1 = _newOutline([library1]);
    var outline2 = _newOutline([library2]);
    var outline3 = _newOutline([library3]);

    expect(_getLibraryText(library1, nodeToName), r'''
class A[A1] {
  set a1[a11]();
}
''');
    expect(_getLibraryText(library2, nodeToName), r'''
class A[A2] {
  set a1[a12]();
  set a2[a22]();
}
class B[B1] {
  set b1[b11]();
}
class S1 extends A[A2] {
  foo() {
    SuperPropertySet[a12]();
    SuperPropertySet[a22]();
  }
}
main2() {
  DirectPropertySet[a12]();
  PropertySet[a12]();
  DirectPropertySet[a22]();
  PropertySet[a22]();
}
''');
    expect(_getLibraryText(library3, nodeToName), r'''
class B[B2] {
  set b1[b12]();
  set b2[b22]();
}
class S2 extends B[B2] {
  foo() {
    SuperPropertySet[b12]();
    SuperPropertySet[b22]();
  }
}
main3() {
  DirectPropertySet[b12]();
  PropertySet[b12]();
}
''');

    _runCombineTest([outline1, outline2, outline3], (result) {
      var library = _getLibrary(result.program, 'test');
      expect(_getLibraryText(library, nodeToName), r'''
class A[A1] {
  set a1[a11]();
  set a2[a22]();
}
class B[B1] {
  set b1[b11]();
  set b2[b22]();
}
class S1 extends A[A1] {
  foo() {
    SuperPropertySet[a11]();
    SuperPropertySet[a22]();
  }
}
class S2 extends B[B1] {
  foo() {
    SuperPropertySet[b11]();
    SuperPropertySet[b22]();
  }
}
main2() {
  DirectPropertySet[a11]();
  PropertySet[a11]();
  DirectPropertySet[a22]();
  PropertySet[a22]();
}
main3() {
  DirectPropertySet[b11]();
  PropertySet[b11]();
}
''');
    });
  }

  void test_class_typeParameter_updateReference() {
    var nodeToName = <TreeNode, String>{};

    var library1 = _newLibrary('test');
    var typeParameterT1 = _newTypeParameter('T');
    var fieldA11 =
        _newField('a1', type: new TypeParameterType(typeParameterT1));
    var classA1 = new Class(
        name: 'A',
        typeParameters: [typeParameterT1],
        supertype: objectSuper,
        fields: [fieldA11]);
    library1.addClass(classA1);
    nodeToName[typeParameterT1] = 'T1';
    nodeToName[classA1] = 'A1';
    nodeToName[fieldA11] = 'a11';

    var library2 = _newLibrary('test');
    var typeParameterT2 = _newTypeParameter('T');
    var fieldA12 =
        _newField('a1', type: new TypeParameterType(typeParameterT2));
    var fieldA22 =
        _newField('a2', type: new TypeParameterType(typeParameterT2));
    var classA2 = new Class(
        name: 'A',
        typeParameters: [typeParameterT2],
        supertype: objectSuper,
        fields: [fieldA12, fieldA22]);
    nodeToName[typeParameterT2] = 'T2';
    library2.addClass(classA2);
    nodeToName[classA2] = 'A2';
    nodeToName[fieldA12] = 'a12';
    nodeToName[fieldA22] = 'a22';

    var outline1 = _newOutline([library1]);
    var outline2 = _newOutline([library2]);

    expect(_getLibraryText(library1, nodeToName), r'''
class A[A1]<T[T1]> {
  T[T1] a1[a11];
}
''');
    expect(_getLibraryText(library2, nodeToName), r'''
class A[A2]<T[T2]> {
  T[T2] a1[a12];
  T[T2] a2[a22];
}
''');

    _runCombineTest([outline1, outline2], (result) {
      var library = _getLibrary(result.program, 'test');
      expect(_getLibraryText(library, nodeToName), r'''
class A[A1]<T[T1]> {
  T[T1] a1[a11];
  T[T1] a2[a22];
}
''');
    });
  }

  void test_class_updateReferences() {
    var nodeToName = <TreeNode, String>{};

    var library1 = _newLibrary('test');
    var classA1 = new Class(name: 'A', supertype: objectSuper);
    library1.addClass(classA1);
    nodeToName[classA1] = 'A1';

    var library2 = _newLibrary('test');
    var classA2 = new Class(name: 'A', supertype: objectSuper);
    var classB1 = new Class(name: 'B1', supertype: new Supertype(classA2, []));
    var classB2 = new Class(
        name: 'B2',
        supertype: objectSuper,
        implementedTypes: [new Supertype(classA2, [])]);
    var classB3 = new Class(
        name: 'B3',
        supertype: objectSuper,
        mixedInType: new Supertype(classA2, []));
    var typeParameterT1 = new TypeParameter('T', new InterfaceType(classA2));
    var classB4 = new Class(
        name: 'B4', supertype: objectSuper, typeParameters: [typeParameterT1]);
    library2.addClass(classA2);
    library2.addClass(classB1);
    library2.addClass(classB2);
    library2.addClass(classB3);
    library2.addClass(classB4);
    nodeToName[classA2] = 'A2';
    nodeToName[classB1] = 'B1';
    nodeToName[classB2] = 'B2';
    nodeToName[classB3] = 'B3';
    nodeToName[classB4] = 'B4';
    nodeToName[typeParameterT1] = 'T';

    var outline1 = _newOutline([library1]);
    var outline2 = _newOutline([library2]);

    expect(_getLibraryText(library1, nodeToName), r'''
class A[A1] {}
''');
    expect(_getLibraryText(library2, nodeToName), r'''
class A[A2] {}
class B1[B1] extends A[A2] {}
class B2[B2] implements A[A2] {}
class B3[B3] with A[A2] {}
class B4[B4]<T[T] extends A[A2]> {}
''');

    _runCombineTest([outline1, outline2], (result) {
      var library = _getLibrary(result.program, 'test');
      expect(_getLibraryText(library, nodeToName), r'''
class A[A1] {}
class B1[B1] extends A[A1] {}
class B2[B2] implements A[A1] {}
class B3[B3] with A[A1] {}
class B4[B4]<T[T] extends A[A1]> {}
''');
    });
  }

  void test_field() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addField(_newField('A'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addField(_newField('B'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getField(libraryA, 'A');
      _getField(libraryA, 'B');
    });
  }

  void test_field_skipDuplicate() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addField(_newField('A'));
    libraryA1.addField(_newField('B'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addField(_newField('A'));
    libraryA2.addField(_newField('C'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getField(libraryA, 'A');
      _getField(libraryA, 'B');
      _getField(libraryA, 'C');
    });
  }

  void test_field_updateReferences() {
    var libraryA1 = _newLibrary('a');
    var fieldA1A = _newField('A');
    libraryA1.addField(fieldA1A);

    var libraryA2 = _newLibrary('a');
    var fieldA2A = _newField('A');
    libraryA2.addField(fieldA2A);

    var libraryB = _newLibrary('b');
    libraryB.addProcedure(_newExpressionsProcedure([
      new StaticGet(fieldA2A),
      new StaticSet(fieldA2A, new IntLiteral(0)),
    ]));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2, libraryB]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getField(libraryA, 'A');

      var libraryB = _getLibrary(result.program, 'b');
      var main = _getProcedure(libraryB, 'main', '@methods');
      expect((_getProcedureExpression(main, 0) as StaticGet).targetReference,
          same(fieldA1A.reference));
      expect((_getProcedureExpression(main, 1) as StaticSet).targetReference,
          same(fieldA1A.reference));
    });
  }

  void test_library_replaceReference() {
    var libraryA1 = _newLibrary('a');

    var libraryA2 = _newLibrary('a');

    var libraryB = _newLibrary('b');
    libraryB.dependencies.add(new LibraryDependency.import(libraryA2));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2, libraryB]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');

      var libraryB = _getLibrary(result.program, 'b');
      expect(libraryB.dependencies, hasLength(1));
      expect(libraryB.dependencies[0].targetLibrary, libraryA);
    });
  }

  void test_procedure_getter() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addProcedure(_newGetter('A'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addProcedure(_newGetter('B'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@getters');
      _getProcedure(libraryA, 'B', '@getters');
    });
  }

  void test_procedure_getter_skipDuplicate() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addProcedure(_newGetter('A'));
    libraryA1.addProcedure(_newGetter('B'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addProcedure(_newGetter('A'));
    libraryA2.addProcedure(_newGetter('C'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@getters');
      _getProcedure(libraryA, 'B', '@getters');
      _getProcedure(libraryA, 'C', '@getters');
    });
  }

  void test_procedure_getter_updateReferences() {
    var libraryA1 = _newLibrary('a');
    var procedureA1A = _newGetter('A');
    libraryA1.addProcedure(procedureA1A);

    var libraryA2 = _newLibrary('a');
    var procedureA2A = _newGetter('A');
    libraryA2.addProcedure(procedureA2A);

    var libraryB = _newLibrary('b');
    libraryB.addProcedure(_newExpressionsProcedure([
      new StaticGet(procedureA2A),
    ]));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2, libraryB]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@getters');

      var libraryB = _getLibrary(result.program, 'b');
      var main = _getProcedure(libraryB, 'main', '@methods');
      expect((_getProcedureExpression(main, 0) as StaticGet).targetReference,
          same(procedureA1A.reference));
    });
  }

  void test_procedure_method() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addProcedure(_newMethod('A'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addProcedure(_newMethod('B'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@methods');
      _getProcedure(libraryA, 'B', '@methods');
    });
  }

  void test_procedure_method_private_updateReferences() {
    var libraryA1 = _newLibrary('a');
    var procedureA1A = _newMethod('_A', libraryForPrivate: libraryA1);
    libraryA1.addProcedure(procedureA1A);

    var libraryA2 = _newLibrary('a');
    var procedureA2A = _newMethod('_A', libraryForPrivate: libraryA2);
    libraryA2.addProcedure(procedureA2A);

    var libraryB = _newLibrary('b');
    libraryB.addProcedure(_newExpressionsProcedure([
      new StaticInvocation(procedureA2A, new Arguments.empty()),
    ]));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2, libraryB]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, '_A', '@methods');

      var libraryB = _getLibrary(result.program, 'b');
      var main = _getProcedure(libraryB, 'main', '@methods');
      expect(
          (_getProcedureExpression(main, 0) as StaticInvocation)
              .targetReference,
          same(procedureA1A.reference));
    });
  }

  void test_procedure_method_skipDuplicate() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addProcedure(_newMethod('A'));
    libraryA1.addProcedure(_newMethod('B'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addProcedure(_newMethod('A'));
    libraryA2.addProcedure(_newMethod('C'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@methods');
      _getProcedure(libraryA, 'B', '@methods');
      _getProcedure(libraryA, 'C', '@methods');
    });
  }

  void test_procedure_method_updateReferences() {
    var libraryA1 = _newLibrary('a');
    var procedureA1A = _newMethod('A');
    libraryA1.addProcedure(procedureA1A);

    var libraryA2 = _newLibrary('a');
    var procedureA2A = _newMethod('A');
    libraryA2.addProcedure(procedureA2A);

    var libraryB = _newLibrary('b');
    libraryB.addProcedure(_newExpressionsProcedure([
      new StaticInvocation(procedureA2A, new Arguments.empty()),
    ]));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2, libraryB]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@methods');

      var libraryB = _getLibrary(result.program, 'b');
      var main = _getProcedure(libraryB, 'main', '@methods');
      expect(
          (_getProcedureExpression(main, 0) as StaticInvocation)
              .targetReference,
          same(procedureA1A.reference));
    });
  }

  void test_procedure_setter() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addProcedure(_newSetter('A'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addProcedure(_newSetter('B'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@setters');
      _getProcedure(libraryA, 'B', '@setters');
    });
  }

  void test_procedure_setter_skipDuplicate() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addProcedure(_newSetter('A'));
    libraryA1.addProcedure(_newSetter('B'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addProcedure(_newSetter('A'));
    libraryA2.addProcedure(_newSetter('C'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@setters');
      _getProcedure(libraryA, 'B', '@setters');
      _getProcedure(libraryA, 'C', '@setters');
    });
  }

  void test_procedure_setter_updateReferences() {
    var libraryA1 = _newLibrary('a');
    var procedureA1A = _newSetter('A');
    libraryA1.addProcedure(procedureA1A);

    var libraryA2 = _newLibrary('a');
    var procedureA2A = _newSetter('A');
    libraryA2.addProcedure(procedureA2A);

    var libraryB = _newLibrary('b');
    libraryB.addProcedure(_newExpressionsProcedure([
      new StaticSet(procedureA2A, new IntLiteral(0)),
    ]));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2, libraryB]);

    _runCombineTest([outline1, outline2], (result) {
      var libraryA = _getLibrary(result.program, 'a');
      _getProcedure(libraryA, 'A', '@setters');

      var libraryB = _getLibrary(result.program, 'b');
      var main = _getProcedure(libraryB, 'main', '@methods');
      expect((_getProcedureExpression(main, 0) as StaticSet).targetReference,
          same(procedureA1A.reference));
    });
  }

  void test_undo_twice() {
    var libraryA1 = _newLibrary('a');
    libraryA1.addField(_newField('A'));

    var libraryA2 = _newLibrary('a');
    libraryA2.addField(_newField('B'));

    var outline1 = _newOutline([libraryA1]);
    var outline2 = _newOutline([libraryA2]);

    var result = combine([outline1, outline2]);
    result.undo();
    expect(() => result.undo(), throwsStateError);
  }

  /// Get a single [Class] with the given [name].
  /// Throw if there is not exactly one.
  Class _getClass(Library library, String name) {
    var results = library.classes.where((class_) => class_.name == name);
    expect(results, hasLength(1), reason: 'Expected only one: $name');
    Class result = results.first;
    expect(result.parent, library);
    expect(result.canonicalName.parent, library.canonicalName);
    return result;
  }

  /// Get a single [Field] with the given [name].
  /// Throw if there is not exactly one.
  Field _getField(NamedNode parent, String name) {
    List<Field> fields;
    if (parent is Library) {
      fields = parent.fields;
    } else if (parent is Class) {
      fields = parent.fields;
    } else {
      throw new ArgumentError('Only Library or Class expected');
    }

    var results = fields.where((field) => field.name.name == name);
    expect(results, hasLength(1), reason: 'Expected only one: $name');
    Field result = results.first;
    expect(result.parent, parent);
    var parentName = parent.canonicalName.getChild('@fields');
    expect(result.canonicalName.parent, parentName);
    return result;
  }

  /// Get a single [Library] with the given [name].
  /// Throw if there is not exactly one.
  Library _getLibrary(Program program, String name) {
    var results = program.libraries.where((library) => library.name == name);
    expect(results, hasLength(1), reason: 'Expected only one: $name');
    var result = results.first;
    expect(result.parent, program);
    expect(result.canonicalName.parent, program.root);
    return result;
  }

  /// Get a single [Procedure] with the given [name].
  /// Throw if there is not exactly one.
  Procedure _getProcedure(NamedNode parent, String name, String prefixName) {
    Library enclosingLibrary;
    List<Procedure> procedures;
    if (parent is Library) {
      enclosingLibrary = parent;
      procedures = parent.procedures;
    } else if (parent is Class) {
      enclosingLibrary = parent.enclosingLibrary;
      procedures = parent.procedures;
    } else {
      throw new ArgumentError('Only Library or Class expected');
    }

    Iterable<Procedure> results =
        procedures.where((procedure) => procedure.name.name == name);
    expect(results, hasLength(1), reason: 'Expected only one: $name');
    Procedure result = results.first;
    expect(result.parent, parent);

    var parentName = parent.canonicalName.getChild(prefixName);
    if (name.startsWith('_')) {
      parentName = parentName.getChildFromUri(enclosingLibrary.importUri);
    }
    expect(result.canonicalName.parent, parentName);

    return result;
  }

  /// Return the [Expression] in the [index]th statement of the [procedure]'s
  /// block body.
  Expression _getProcedureExpression(Procedure procedure, int index) {
    Block mainBlock = procedure.function.body;
    ExpressionStatement statement = mainBlock.statements[index];
    return statement.expression;
  }

  Constructor _newConstructor(String name, {Statement body}) {
    body ??= new EmptyStatement();
    return new Constructor(new FunctionNode(body), name: new Name(name));
  }

  Procedure _newExpressionsProcedure(List<Expression> expressions,
      {String name: 'main'}) {
    var statements =
        expressions.map((e) => new ExpressionStatement(e)).toList();
    return new Procedure(new Name(name), ProcedureKind.Method,
        new FunctionNode(new Block(statements)));
  }

  Field _newField(String name, {DartType type}) {
    type ??= const DynamicType();
    return new Field(new Name(name), type: type);
  }

  Procedure _newGetter(String name) {
    return new Procedure(new Name(name), ProcedureKind.Getter,
        new FunctionNode(new ExpressionStatement(new IntLiteral((0)))));
  }

  Library _newLibrary(String name) {
    var uri = Uri.parse('org-dartlang:///$name.dart');
    return new Library(uri, name: name);
  }

  Procedure _newMethod(String name,
      {Statement body, Library libraryForPrivate}) {
    body ??= new EmptyStatement();
    return new Procedure(new Name(name, libraryForPrivate),
        ProcedureKind.Method, new FunctionNode(body));
  }

  Program _newOutline(List<Library> libraries) {
    var outline = new Program(libraries: libraries);
    outline.computeCanonicalNames();
    return outline;
  }

  Procedure _newSetter(String name) {
    return new Procedure(
        new Name(name),
        ProcedureKind.Setter,
        new FunctionNode(new EmptyStatement(),
            positionalParameters: [new VariableDeclaration('_')]));
  }

  TypeParameter _newTypeParameter(String name) {
    var bound = new InterfaceType(coreTypes.objectClass);
    return new TypeParameter(name, bound);
  }

  void _runCombineTest(
      List<Program> outlines, void checkResult(CombineResult result)) {
    // Store the original state.
    var states = <Program, _OutlineState>{};
    for (var outline in outlines) {
      states[outline] = new _OutlineState(outline);
    }

    // Combine the outlines and check the result.
    var result = combine(outlines);
    checkResult(result);

    // Undo and verify that the state is the same as the original.
    result.undo();
    states.forEach((outline, state) {
      state.verifySame();
    });
  }

  /// Return the text presentation of the [library] that is not a normal Kernel
  /// AST text, but includes portions that we want to test - declarations
  /// and references.  The map [nodeToName] must have entries for all
  /// referenced nodes, other declarations are optional.
  static String _getLibraryText(
      Library library, Map<TreeNode, String> nodeToName) {
    var buffer = new StringBuffer();

    String getNodeName(TreeNode node, {bool required: false}) {
      String name = nodeToName[node];
      if (name != null) {
        return '[$name]';
      } else {
        if (required) {
          fail('The name is required for (${node.runtimeType}) $node');
        }
        return '';
      }
    }

    void writeType(DartType type) {
      if (type is InterfaceType) {
        String name = getNodeName(type.classNode);
        buffer.write('${type.classNode.name}$name');
      } else if (type is TypeParameterType) {
        String name = getNodeName(type.parameter);
        buffer.write('${type.parameter.name}$name');
      } else {
        throw new UnimplementedError('(${type.runtimeType}) $type');
      }
    }

    void writeStatement(Statement node, String indent) {
      if (node is ExpressionStatement) {
        Expression expression = node.expression;
        String prefix = expression.runtimeType.toString();
        Member target;
        if (expression is ConstructorInvocation) {
          target = expression.target;
        } else if (expression is DirectMethodInvocation) {
          target = expression.target;
        } else if (expression is DirectPropertyGet) {
          target = expression.target;
        } else if (expression is DirectPropertySet) {
          target = expression.target;
        } else if (expression is MethodInvocation) {
          target = expression.interfaceTarget;
        } else if (expression is PropertyGet) {
          target = expression.interfaceTarget;
        } else if (expression is PropertySet) {
          target = expression.interfaceTarget;
        } else if (expression is SuperMethodInvocation) {
          target = expression.interfaceTarget;
        } else if (expression is SuperPropertyGet) {
          target = expression.interfaceTarget;
        } else if (expression is SuperPropertySet) {
          target = expression.interfaceTarget;
        } else {
          var type = expression.runtimeType;
          fail('Unsupported expression: $type');
        }
        String name = getNodeName(target, required: true);
        buffer.writeln('$indent$prefix$name();');
      } else {
        fail('Unsupported statement: (${node.runtimeType}) $node');
      }
    }

    void writeBody(Statement body, String indent) {
      if (body is EmptyStatement) {
        buffer.writeln(';');
      } else if (body is Block) {
        buffer.write(' {');
        if (body.statements.isNotEmpty) {
          buffer.writeln();
          for (var statement in body.statements) {
            writeStatement(statement, '$indent  ');
          }
          buffer.writeln('$indent}');
        } else {
          buffer.writeln('}');
        }
      } else if (body is ExpressionStatement) {
        buffer.write(' => ');
        Expression expression = body.expression;
        if (expression is IntLiteral) {
          buffer.write(expression);
        } else {
          fail('Not implemented ${expression.runtimeType}');
        }
        buffer.writeln(';');
      } else {
        fail('Not implemented ${body.runtimeType}');
      }
    }

    void writeField(Field node, String indent) {
      buffer.write(indent);
      String name = getNodeName(node, required: true);
      if (node.type is DynamicType) {
        buffer.write('var');
      } else {
        writeType(node.type);
      }
      buffer.writeln(' ${node.name}$name;');
    }

    void writeInitializer(Initializer node, String indent) {
      String kind;
      Constructor target;
      if (node is RedirectingInitializer) {
        kind = 'redirect';
        target = node.target;
      } else if (node is SuperInitializer) {
        kind = 'super';
        target = node.target;
      } else {
        fail('Not implemented ${node.runtimeType}');
      }
      String name = getNodeName(target, required: true);
      buffer.write('${indent}${kind}$name()');
    }

    void writeConstructor(Constructor node, String indent) {
      String name = getNodeName(node);
      buffer.write('${indent}constructor ${node.name}$name()');
      List<Initializer> initializers = node.initializers;
      if (initializers.isNotEmpty) {
        buffer.writeln(' :');
        for (int i = 0; i < initializers.length; i++) {
          Initializer initializer = initializers[i];
          writeInitializer(initializer, '      ');
          if (i != initializers.length - 1) {
            buffer.writeln(',');
          }
        }
      }
      writeBody(node.function.body, indent);
    }

    void writeProcedure(NamedNode parent, Procedure node, String indent) {
      String prefixName;
      String kindStr;
      ProcedureKind kind = node.kind;
      if (kind == ProcedureKind.Method) {
        prefixName = '@methods';
        kindStr = '';
      } else if (kind == ProcedureKind.Getter) {
        prefixName = '@getters';
        kindStr = 'get ';
      } else if (kind == ProcedureKind.Setter) {
        prefixName = '@setters';
        kindStr = 'set ';
      } else {
        fail('Unsupported kind: $kind');
      }

      // Verify canonical names linkage.
      var parentName = parent.canonicalName.getChild(prefixName);
      expect(node.canonicalName.parent, parentName);

      String nodeName = getNodeName(node);
      buffer.write('$indent$kindStr${node.name}$nodeName');
      if (kind != ProcedureKind.Getter) {
        buffer.write('()');
      }
      writeBody(node.function.body, indent);
    }

    void writeSupertype(Supertype supertype) {
      expect(supertype.typeArguments, isEmpty);
      var clazz = supertype.classNode;
      String name = getNodeName(clazz, required: true);
      buffer.write('${clazz.name}$name');
    }

    void writeClass(Class node) {
      String nodeName = getNodeName(node);
      buffer.write('class ${node.name}$nodeName');

      if (node.typeParameters.isNotEmpty) {
        buffer.write('<');
        for (var i = 0; i < node.typeParameters.length; i++) {
          if (i != 0) {
            buffer.write(', ');
          }
          TypeParameter typeParameter = node.typeParameters[i];
          String name = getNodeName(typeParameter, required: true);
          buffer.write('${typeParameter.name}$name');
          if (typeParameter.bound != null) {
            var bound = typeParameter.bound as InterfaceType;
            if (bound.classNode.name != 'Object') {
              buffer.write(' extends ');
              writeType(typeParameter.bound);
            }
          }
        }
        buffer.write('>');
      }

      {
        var superType = node.supertype;
        var superClassName = superType.classNode.name;
        if (superClassName != 'Object') {
          buffer.write(' extends ');
          writeSupertype(superType);
        }

        if (node.implementedTypes.isNotEmpty) {
          buffer.write(' implements ');
          for (var i = 0; i < node.implementedTypes.length; i++) {
            if (i != 0) {
              buffer.write(', ');
            }
            writeSupertype(node.implementedTypes[i]);
          }
        }

        Supertype mixedInType = node.mixedInType;
        if (mixedInType != null) {
          buffer.write(' with ');
          writeSupertype(mixedInType);
        }
      }

      buffer.write(' {');

      if (!node.members.isEmpty) {
        buffer.writeln();
        for (var field in node.fields) {
          writeField(field, '  ');
        }
        for (var constructor in node.constructors) {
          writeConstructor(constructor, '  ');
        }
        for (var procedure in node.procedures) {
          writeProcedure(node, procedure, '  ');
        }
      }
      buffer.writeln('}');
    }

    for (var node in library.fields) {
      writeField(node, '');
    }

    for (var node in library.classes) {
      writeClass(node);
    }

    for (var node in library.procedures) {
      writeProcedure(library, node, '');
    }

    return buffer.toString();
  }
}

/// The original state of an outline, and code that validates that after some
/// manipulations (e.g. combine and undo) the state stays the same.
class _OutlineState {
  final Program outline;
  final initialCollector = new _StateCollector();

  _OutlineState(this.outline) {
    outline.accept(initialCollector);
  }

  void verifySame() {
    var collector = new _StateCollector();
    outline.accept(collector);
    expect(collector.nodes, initialCollector.nodes);
    expect(collector.references, initialCollector.references);
    expect(collector.typeParameters, initialCollector.typeParameters);
    initialCollector.libraryParents.forEach((library, outline) {
      expect(library.canonicalName.parent, outline.root);
      expect(library.parent, outline);
    });
    initialCollector.nodeParents.forEach((child, parent) {
      expect(child.parent, parent);
      if (child is Member) {
        var qualifier = CanonicalName.getMemberQualifier(child);
        var parentName = parent.canonicalName.getChild(qualifier);
        if (child.name.isPrivate) {
          var libraryUri = child.enclosingLibrary.importUri;
          parentName = parentName.getChildFromUri(libraryUri);
        }
        expect(child.canonicalName.parent, parentName);
      } else {
        expect(child.canonicalName.parent, parent.canonicalName);
      }
    });
  }
}

class _StateCollector extends RecursiveVisitor {
  final List<Node> nodes = [];
  final Map<NamedNode, NamedNode> nodeParents = {};
  final Map<Library, Program> libraryParents = {};
  final List<Reference> references = [];
  final List<TypeParameter> typeParameters = [];

  @override
  void defaultMemberReference(Member node) {
    references.add(node.reference);
  }

  @override
  void defaultNode(Node node) {
    nodes.add(node);
    if (node is Library) {
      libraryParents[node] = node.parent as Program;
    } else if (node is NamedNode) {
      nodeParents[node] = node.parent as NamedNode;
    }
    super.defaultNode(node);
  }

  @override
  void visitClassReference(Class node) {
    references.add(node.reference);
  }

  @override
  visitLibraryDependency(LibraryDependency node) {
    references.add(node.importedLibraryReference);
    super.visitLibraryDependency(node);
  }

  @override
  void visitTypedefReference(Typedef node) {
    references.add(node.reference);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    typeParameters.add(node.parameter);
  }
}
