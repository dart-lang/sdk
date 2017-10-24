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
  /// With two cases of setter declarations:
  ///   * Already defined, so references to it should be rewritten.
  ///   * First defined in this outline, so references to it can be kept as is.
  ///
  /// For each case we validate [DirectPropertyGet], [PropertyGet],
  /// and [SuperPropertyGet].
  void test_class_procedure_getter() {
    var library1 = _newLibrary('test');
    var procedureA11 = _newGetter('a1');
    var classA1 = new Class(
        name: 'A', supertype: objectSuper, procedures: [procedureA11]);
    library1.addClass(classA1);

    var library2 = _newLibrary('test');
    var procedureA12 = _newGetter('a1');
    var procedureA22 = _newGetter('a2');
    var procedureB11 = _newGetter('b1');
    var classA2 = new Class(
        name: 'A',
        supertype: objectSuper,
        procedures: [procedureA12, procedureA22]);
    library2.addClass(classA2);
    library2.addClass(new Class(
        name: 'B', supertype: objectSuper, procedures: [procedureB11]));
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

    var library3 = _newLibrary('test');
    var procedureB12 = _newGetter('b1');
    var procedureB22 = _newGetter('b2');
    library3.addClass(new Class(
        name: 'B',
        supertype: objectSuper,
        procedures: [procedureB12, procedureB22]));
    library3.addProcedure(_newExpressionsProcedure([
      new DirectPropertyGet(null, procedureB12),
      new PropertyGet(null, null, procedureB12),
    ], name: 'main3'));
    library3.addClass(
        new Class(name: 'S2', supertype: classA2.asThisSupertype, procedures: [
      _newExpressionsProcedure([
        new SuperPropertyGet(null, procedureB12),
        new SuperPropertyGet(null, procedureB22),
      ], name: 'foo')
    ]));

    var outline1 = _newOutline([library1]);
    var outline2 = _newOutline([library2]);
    var outline3 = _newOutline([library3]);

    _runCombineTest([outline1, outline2, outline3], (result) {
      var library = _getLibrary(result.program, 'test');

      var classA = _getClass(library, 'A');
      expect(_getProcedure(classA, 'a1', '@getters'), same(procedureA11));
      expect(_getProcedure(classA, 'a2', '@getters'), same(procedureA22));

      // main2() is updated to point to "A.a1" from library1.
      // But "A.a2" is still from library2.
      var main2 = _getProcedure(library, 'main2', '@methods');
      expect((_getProcedureExpression(main2, 0) as DirectPropertyGet).target,
          same(procedureA11));
      expect((_getProcedureExpression(main2, 1) as PropertyGet).interfaceTarget,
          same(procedureA11));
      expect((_getProcedureExpression(main2, 2) as DirectPropertyGet).target,
          same(procedureA22));
      expect((_getProcedureExpression(main2, 3) as PropertyGet).interfaceTarget,
          same(procedureA22));

      // Super invocations are updated.
      var classS1 = _getClass(library, 'S1');
      var fooS1 = _getProcedure(classS1, 'foo', '@methods');
      expect(
          (_getProcedureExpression(fooS1, 0) as SuperPropertyGet)
              .interfaceTarget,
          same(procedureA11));
      expect(
          (_getProcedureExpression(fooS1, 1) as SuperPropertyGet)
              .interfaceTarget,
          same(procedureA22));

      var classB = _getClass(library, 'B');
      expect(_getProcedure(classB, 'b1', '@getters'), same(procedureB11));
      expect(_getProcedure(classB, 'b2', '@getters'), same(procedureB22));

      // main3() is updated to point to "B.b1" from library2.
      var main3 = _getProcedure(library, 'main3', '@methods');
      expect((_getProcedureExpression(main3, 0) as DirectPropertyGet).target,
          same(procedureB11));
      expect((_getProcedureExpression(main3, 1) as PropertyGet).interfaceTarget,
          same(procedureB11));

      // Super invocations are updated.
      var classS2 = _getClass(library, 'S2');
      var fooS2 = _getProcedure(classS2, 'foo', '@methods');
      expect(
          (_getProcedureExpression(fooS2, 0) as SuperPropertyGet)
              .interfaceTarget,
          same(procedureB11));
      expect(
          (_getProcedureExpression(fooS2, 1) as SuperPropertyGet)
              .interfaceTarget,
          same(procedureB22));
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
    var library1 = _newLibrary('test');
    var procedureA11 = _newMethod('a1');
    var classA1 = new Class(
        name: 'A', supertype: objectSuper, procedures: [procedureA11]);
    library1.addClass(classA1);

    var library2 = _newLibrary('test');
    var procedureA12 = _newMethod('a1');
    var procedureA22 = _newMethod('a2');
    var procedureB11 = _newMethod('b1');
    var classA2 = new Class(
        name: 'A',
        supertype: objectSuper,
        procedures: [procedureA12, procedureA22]);
    library2.addClass(classA2);
    library2.addClass(new Class(
        name: 'B', supertype: objectSuper, procedures: [procedureB11]));
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

    var library3 = _newLibrary('test');
    var procedureB12 = _newMethod('b1');
    var procedureB22 = _newMethod('b2');
    library3.addClass(new Class(
        name: 'B',
        supertype: objectSuper,
        procedures: [procedureB12, procedureB22]));
    library3.addProcedure(_newExpressionsProcedure([
      new DirectMethodInvocation(null, procedureB12, new Arguments.empty()),
      new MethodInvocation(null, null, new Arguments.empty(), procedureB12),
    ], name: 'main3'));
    library3.addClass(
        new Class(name: 'S2', supertype: classA2.asThisSupertype, procedures: [
      _newExpressionsProcedure([
        new SuperMethodInvocation(null, null, procedureB12),
        new SuperMethodInvocation(null, null, procedureB22),
      ], name: 'foo')
    ]));

    var outline1 = _newOutline([library1]);
    var outline2 = _newOutline([library2]);
    var outline3 = _newOutline([library3]);

    _runCombineTest([outline1, outline2, outline3], (result) {
      var library = _getLibrary(result.program, 'test');

      var classA = _getClass(library, 'A');
      expect(_getProcedure(classA, 'a1', '@methods'), same(procedureA11));
      expect(_getProcedure(classA, 'a2', '@methods'), same(procedureA22));

      // main2() is updated to point to "A.a1" from library1.
      // But "A.a2" is still from library2.
      var main2 = _getProcedure(library, 'main2', '@methods');
      expect(
          (_getProcedureExpression(main2, 0) as DirectMethodInvocation).target,
          same(procedureA11));
      expect(
          (_getProcedureExpression(main2, 1) as MethodInvocation)
              .interfaceTarget,
          same(procedureA11));
      expect(
          (_getProcedureExpression(main2, 2) as DirectMethodInvocation).target,
          same(procedureA22));
      expect(
          (_getProcedureExpression(main2, 3) as MethodInvocation)
              .interfaceTarget,
          same(procedureA22));

      // Super invocations are updated.
      var classS1 = _getClass(library, 'S1');
      var fooS1 = _getProcedure(classS1, 'foo', '@methods');
      expect(
          (_getProcedureExpression(fooS1, 0) as SuperMethodInvocation)
              .interfaceTarget,
          same(procedureA11));
      expect(
          (_getProcedureExpression(fooS1, 1) as SuperMethodInvocation)
              .interfaceTarget,
          same(procedureA22));

      var classB = _getClass(library, 'B');
      expect(_getProcedure(classB, 'b1', '@methods'), same(procedureB11));
      expect(_getProcedure(classB, 'b2', '@methods'), same(procedureB22));

      // main3() is updated to point to "B.b1" from library2.
      var main3 = _getProcedure(library, 'main3', '@methods');
      expect(
          (_getProcedureExpression(main3, 0) as DirectMethodInvocation).target,
          same(procedureB11));
      expect(
          (_getProcedureExpression(main3, 1) as MethodInvocation)
              .interfaceTarget,
          same(procedureB11));

      // Super invocations are updated.
      var classS2 = _getClass(library, 'S2');
      var fooS2 = _getProcedure(classS2, 'foo', '@methods');
      expect(
          (_getProcedureExpression(fooS2, 0) as SuperMethodInvocation)
              .interfaceTarget,
          same(procedureB11));
      expect(
          (_getProcedureExpression(fooS2, 1) as SuperMethodInvocation)
              .interfaceTarget,
          same(procedureB22));
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
    var library1 = _newLibrary('test');
    var procedureA11 = _newSetter('a1');
    var classA1 = new Class(
        name: 'A', supertype: objectSuper, procedures: [procedureA11]);
    library1.addClass(classA1);

    var library2 = _newLibrary('test');
    var procedureA12 = _newSetter('a1');
    var procedureA22 = _newSetter('a2');
    var procedureB11 = _newSetter('b1');
    var classA2 = new Class(
        name: 'A',
        supertype: objectSuper,
        procedures: [procedureA12, procedureA22]);
    library2.addClass(classA2);
    library2.addClass(new Class(
        name: 'B', supertype: objectSuper, procedures: [procedureB11]));
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

    var library3 = _newLibrary('test');
    var procedureB12 = _newSetter('b1');
    var procedureB22 = _newSetter('b2');
    library3.addClass(new Class(
        name: 'B',
        supertype: objectSuper,
        procedures: [procedureB12, procedureB22]));
    library3.addProcedure(_newExpressionsProcedure([
      new DirectPropertySet(null, procedureB12, new IntLiteral(0)),
      new PropertySet(null, null, new IntLiteral(0), procedureB12),
    ], name: 'main3'));
    library3.addClass(
        new Class(name: 'S2', supertype: classA2.asThisSupertype, procedures: [
      _newExpressionsProcedure([
        new SuperPropertySet(null, new IntLiteral(0), procedureB12),
        new SuperPropertySet(null, new IntLiteral(0), procedureB22),
      ], name: 'foo')
    ]));

    var outline1 = _newOutline([library1]);
    var outline2 = _newOutline([library2]);
    var outline3 = _newOutline([library3]);

    _runCombineTest([outline1, outline2, outline3], (result) {
      var library = _getLibrary(result.program, 'test');

      var classA = _getClass(library, 'A');
      expect(_getProcedure(classA, 'a1', '@setters'), same(procedureA11));
      expect(_getProcedure(classA, 'a2', '@setters'), same(procedureA22));

      // main2() is updated to point to "A.a1" from library1.
      // But "A.a2" is still from library2.
      var main2 = _getProcedure(library, 'main2', '@methods');
      expect((_getProcedureExpression(main2, 0) as DirectPropertySet).target,
          same(procedureA11));
      expect((_getProcedureExpression(main2, 1) as PropertySet).interfaceTarget,
          same(procedureA11));
      expect((_getProcedureExpression(main2, 2) as DirectPropertySet).target,
          same(procedureA22));
      expect((_getProcedureExpression(main2, 3) as PropertySet).interfaceTarget,
          same(procedureA22));

      // Super invocations are updated.
      var classS1 = _getClass(library, 'S1');
      var fooS1 = _getProcedure(classS1, 'foo', '@methods');
      expect(
          (_getProcedureExpression(fooS1, 0) as SuperPropertySet)
              .interfaceTarget,
          same(procedureA11));
      expect(
          (_getProcedureExpression(fooS1, 1) as SuperPropertySet)
              .interfaceTarget,
          same(procedureA22));

      var classB = _getClass(library, 'B');
      expect(_getProcedure(classB, 'b1', '@setters'), same(procedureB11));
      expect(_getProcedure(classB, 'b2', '@setters'), same(procedureB22));

      // main3() is updated to point to "B.b1" from library2.
      var main3 = _getProcedure(library, 'main3', '@methods');
      expect((_getProcedureExpression(main3, 0) as DirectPropertySet).target,
          same(procedureB11));
      expect((_getProcedureExpression(main3, 1) as PropertySet).interfaceTarget,
          same(procedureB11));

      // Super invocations are updated.
      var classS2 = _getClass(library, 'S2');
      var fooS2 = _getProcedure(classS2, 'foo', '@methods');
      expect(
          (_getProcedureExpression(fooS2, 0) as SuperPropertySet)
              .interfaceTarget,
          same(procedureB11));
      expect(
          (_getProcedureExpression(fooS2, 1) as SuperPropertySet)
              .interfaceTarget,
          same(procedureB22));
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
  Field _getField(Library library, String name) {
    var results = library.fields.where((field) => field.name.name == name);
    expect(results, hasLength(1), reason: 'Expected only one: $name');
    Field result = results.first;
    expect(result.parent, library);
    var parentName = library.canonicalName.getChild('@fields');
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
    List<Procedure> procedures;
    if (parent is Library) {
      procedures = parent.procedures;
    } else if (parent is Class) {
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

  Procedure _newExpressionsProcedure(List<Expression> expressions,
      {String name: 'main'}) {
    var statements =
        expressions.map((e) => new ExpressionStatement(e)).toList();
    return new Procedure(new Name(name), ProcedureKind.Method,
        new FunctionNode(new Block(statements)));
  }

  Field _newField(String name) {
    return new Field(new Name(name));
  }

  Procedure _newGetter(String name) {
    return new Procedure(new Name(name), ProcedureKind.Getter,
        new FunctionNode(new ExpressionStatement(new IntLiteral((0)))));
  }

  Library _newLibrary(String name) {
    var uri = Uri.parse('org-dartlang:///$name.dart');
    return new Library(uri, name: name);
  }

  Procedure _newMethod(String name, {Statement body}) {
    body ??= new EmptyStatement();
    return new Procedure(
        new Name(name), ProcedureKind.Method, new FunctionNode(body));
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
    initialCollector.libraryParents.forEach((library, outline) {
      expect(library.canonicalName.parent, outline.root);
      expect(library.parent, outline);
    });
    initialCollector.nodeParents.forEach((child, parent) {
      expect(child.parent, parent);
      if (child is Member) {
        var qualifier = CanonicalName.getMemberQualifier(child);
        var parentName = parent.canonicalName.getChild(qualifier);
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
}
