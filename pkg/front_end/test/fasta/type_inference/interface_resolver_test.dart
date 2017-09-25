// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/interface_resolver.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/incremental_class_hierarchy.dart';
import 'package:kernel/testing/mock_sdk_program.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InterfaceResolverTest);
  });
}

@reflectiveTest
class InterfaceResolverTest {
  final testLib =
      new Library(Uri.parse('org-dartlang:///test.dart'), name: 'lib');

  Program program;

  CoreTypes coreTypes;

  InterfaceResolverTest() {
    program = createMockSdkProgram();
    program.libraries.add(testLib..parent = program);
    coreTypes = new CoreTypes(program);
  }

  Class get objectClass => coreTypes.objectClass;

  void checkCandidate(Procedure procedure, bool setter) {
    var class_ = makeClass(procedures: [procedure]);
    var candidate = getCandidate(class_, setter);
    expect(candidate, same(procedure));
  }

  Procedure getCandidate(Class class_, bool setter) {
    var candidates = getCandidates(class_, setter);
    expect(candidates, hasLength(1));
    return candidates[0];
  }

  List<Procedure> getCandidates(Class class_, bool setters) {
    var forwardingNodes = getForwardingNodes(class_, setters);
    expect(forwardingNodes, hasLength(1));
    return ForwardingNode.getCandidates(forwardingNodes[0]);
  }

  List<ForwardingNode> getForwardingNodes(Class class_, bool setters) {
    testLib.addClass(class_);
    var interfaceResolver =
        new InterfaceResolver(new IncrementalClassHierarchy());
    var forwardingNodes = <ForwardingNode>[];
    interfaceResolver.createForwardingNodes(class_, forwardingNodes, setters);
    return forwardingNodes;
  }

  Class makeClass(
      {String name,
      Supertype supertype,
      Supertype mixedInType,
      List<Supertype> implementedTypes,
      List<Procedure> procedures,
      List<Field> fields}) {
    return new Class(
        name: name ?? 'C',
        supertype: supertype ?? objectClass.asThisSupertype,
        mixedInType: mixedInType,
        implementedTypes: implementedTypes,
        procedures: procedures,
        fields: fields);
  }

  Procedure makeEmptyMethod({String name: 'foo'}) {
    var function = new FunctionNode(null);
    return new Procedure(new Name(name), ProcedureKind.Method, function);
  }

  void test_candidate_for_field_getter() {
    var field = new Field(new Name('foo'));
    var class_ = makeClass(fields: [field]);
    var candidate = getCandidate(class_, false);
    expect(candidate, new isInstanceOf<SyntheticAccessor>());
    expect(candidate.parent, same(class_));
    expect(candidate.name, field.name);
    expect(candidate.kind, ProcedureKind.Getter);
    expect(candidate.function.positionalParameters, isEmpty);
    expect(candidate.function.namedParameters, isEmpty);
    expect(candidate.function.typeParameters, isEmpty);
  }

  void test_candidate_for_field_setter() {
    var field = new Field(new Name('foo'));
    var class_ = makeClass(fields: [field]);
    var candidate = getCandidate(class_, true);
    expect(candidate, new isInstanceOf<SyntheticAccessor>());
    expect(candidate.parent, same(class_));
    expect(candidate.name, field.name);
    expect(candidate.kind, ProcedureKind.Setter);
    expect(candidate.function.positionalParameters, hasLength(1));
    expect(candidate.function.positionalParameters[0].name, '_');
    expect(candidate.function.namedParameters, isEmpty);
    expect(candidate.function.typeParameters, isEmpty);
    expect(candidate.function.returnType, const VoidType());
  }

  void test_candidate_for_getter() {
    var function = new FunctionNode(null);
    var getter = new Procedure(new Name('foo'), ProcedureKind.Getter, function);
    checkCandidate(getter, false);
  }

  void test_candidate_for_method() {
    checkCandidate(makeEmptyMethod(), false);
  }

  void test_candidate_for_setter() {
    var parameter = new VariableDeclaration('value');
    var function = new FunctionNode(null,
        positionalParameters: [parameter], returnType: const VoidType());
    var setter = new Procedure(new Name('foo'), ProcedureKind.Setter, function);
    checkCandidate(setter, true);
  }

  void test_candidate_from_interface() {
    var method = makeEmptyMethod();
    var a = makeClass(name: 'A', procedures: [method]);
    var b = makeClass(name: 'B', implementedTypes: [a.asThisSupertype]);
    var candidate = getCandidate(b, false);
    expect(candidate, same(method));
  }

  void test_candidate_from_mixin() {
    var method = makeEmptyMethod();
    var a = makeClass(name: 'A', procedures: [method]);
    var b = makeClass(name: 'B', mixedInType: a.asThisSupertype);
    var candidate = getCandidate(b, false);
    expect(candidate, same(method));
  }

  void test_candidate_from_superclass() {
    var method = makeEmptyMethod();
    var a = makeClass(name: 'A', procedures: [method]);
    var b = makeClass(name: 'B', supertype: a.asThisSupertype);
    var candidate = getCandidate(b, false);
    expect(candidate, same(method));
  }

  void test_forwardingNodes_multiple() {
    var methodAf = makeEmptyMethod(name: 'f');
    var methodBf = makeEmptyMethod(name: 'f');
    var methodAg = makeEmptyMethod(name: 'g');
    var methodBg = makeEmptyMethod(name: 'g');
    var a = makeClass(name: 'A', procedures: [methodAf, methodAg]);
    var b = makeClass(
        name: 'B',
        supertype: a.asThisSupertype,
        procedures: [methodBf, methodBg]);
    var forwardingNodes = getForwardingNodes(b, false);
    expect(forwardingNodes, hasLength(2));
    var nodef = ClassHierarchy.findMemberByName(forwardingNodes, methodAf.name);
    var nodeg = ClassHierarchy.findMemberByName(forwardingNodes, methodAg.name);
    expect(nodef, isNot(same(nodeg)));
    expect(nodef.parent, b);
    expect(nodeg.parent, b);
    {
      var candidates = ForwardingNode.getCandidates(nodef);
      expect(candidates, hasLength(2));
      expect(candidates[0], same(methodBf));
      expect(candidates[1], same(methodAf));
    }
    {
      var candidates = ForwardingNode.getCandidates(nodeg);
      expect(candidates, hasLength(2));
      expect(candidates[0], same(methodBg));
      expect(candidates[1], same(methodAg));
    }
  }

  void test_forwardingNodes_single() {
    var methodA = makeEmptyMethod();
    var methodB = makeEmptyMethod();
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(
        name: 'B', supertype: a.asThisSupertype, procedures: [methodB]);
    var forwardingNodes = getForwardingNodes(b, false);
    expect(forwardingNodes, hasLength(1));
    expect(forwardingNodes[0].parent, b);
    expect(forwardingNodes[0].name, methodA.name);
    var candidates = ForwardingNode.getCandidates(forwardingNodes[0]);
    expect(candidates, hasLength(2));
    expect(candidates[0], same(methodB));
    expect(candidates[1], same(methodA));
  }

  void test_merge_candidates_including_mixin() {
    var methodA = makeEmptyMethod();
    var methodB = makeEmptyMethod();
    var methodC = makeEmptyMethod();
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(name: 'B', procedures: [methodB]);
    var c = makeClass(name: 'C', procedures: [methodC]);
    var d = makeClass(
        name: 'D',
        supertype: a.asThisSupertype,
        mixedInType: b.asThisSupertype,
        implementedTypes: [c.asThisSupertype]);
    var candidates = getCandidates(d, false);
    expect(candidates, hasLength(3));
    expect(candidates[0], same(methodB));
    expect(candidates[1], same(methodA));
    expect(candidates[2], same(methodC));
  }

  void test_merge_candidates_not_including_mixin() {
    var methodA = makeEmptyMethod();
    var methodB = makeEmptyMethod();
    var methodC = makeEmptyMethod();
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(name: 'B', procedures: [methodB]);
    var c = makeClass(
        name: 'C',
        supertype: a.asThisSupertype,
        implementedTypes: [b.asThisSupertype],
        procedures: [methodC]);
    var candidates = getCandidates(c, false);
    expect(candidates, hasLength(3));
    expect(candidates[0], same(methodC));
    expect(candidates[1], same(methodA));
    expect(candidates[2], same(methodB));
  }
}
