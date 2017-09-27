// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/type_inference/interface_resolver.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/incremental_class_hierarchy.dart';
import 'package:kernel/testing/mock_sdk_program.dart';
import 'package:kernel/type_algebra.dart';
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

  ClassHierarchy classHierarchy = new IncrementalClassHierarchy();

  TypeSchemaEnvironment typeEnvironment;

  InterfaceResolver interfaceResolver;

  InterfaceResolverTest() {
    program = createMockSdkProgram();
    program.libraries.add(testLib..parent = program);
    coreTypes = new CoreTypes(program);
    typeEnvironment =
        new TypeSchemaEnvironment(coreTypes, classHierarchy, true);
    interfaceResolver = new InterfaceResolver(typeEnvironment);
  }

  InterfaceType get intType => coreTypes.intClass.rawType;

  InterfaceType get numType => coreTypes.numClass.rawType;

  Class get objectClass => coreTypes.objectClass;

  InterfaceType get objectType => objectClass.rawType;

  void checkCandidate(Procedure procedure, bool setter) {
    var class_ = makeClass(procedures: [procedure]);
    var candidate = getCandidate(class_, setter);
    expect(candidate, same(procedure));
  }

  void checkCandidateOrder(Class class_, Member member) {
    // Check that InterfaceResolver prioritizes [member]
    var candidates = getCandidates(class_, false);
    expect(candidates[0], same(member));

    // Check that both implementations of [ClassHierarchy] prioritize [member]
    // ahead of [other]
    void check(ClassHierarchy classHierarchy) {
      var interfaceMember =
          classHierarchy.getInterfaceMember(class_, member.name);
      expect(interfaceMember, same(member));
    }

    check(new ClosedWorldClassHierarchy(program));
    check(new IncrementalClassHierarchy());
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

  ForwardingNode getForwardingNode(Class class_, bool setter) {
    var forwardingNodes = getForwardingNodes(class_, setter);
    expect(forwardingNodes, hasLength(1));
    return forwardingNodes[0];
  }

  List<ForwardingNode> getForwardingNodes(Class class_, bool setters) {
    var forwardingNodes = <ForwardingNode>[];
    interfaceResolver.createForwardingNodes(class_, forwardingNodes, setters);
    return forwardingNodes;
  }

  Member getStubTarget(ForwardingStub stub) {
    var body = stub.function.body;
    if (body is ReturnStatement) {
      var expression = body.expression;
      if (expression is SuperMethodInvocation) {
        return expression.interfaceTarget;
      } else {
        throw fail('Unexpected expression type: ${expression.runtimeType}');
      }
    } else {
      throw fail('Unexpected body type: ${body.runtimeType}');
    }
  }

  Class makeClass(
      {String name,
      Supertype supertype,
      Supertype mixedInType,
      List<TypeParameter> typeParameters,
      List<Supertype> implementedTypes,
      List<Procedure> procedures,
      List<Field> fields}) {
    var class_ = new ShadowClass(
        name: name ?? 'C',
        supertype: supertype ?? objectClass.asThisSupertype,
        mixedInType: mixedInType,
        typeParameters: typeParameters,
        implementedTypes: implementedTypes,
        procedures: procedures,
        fields: fields);
    testLib.addClass(class_);
    return class_;
  }

  Procedure makeEmptyMethod(
      {String name: 'foo',
      List<TypeParameter> typeParameters,
      List<VariableDeclaration> positionalParameters,
      List<VariableDeclaration> namedParameters,
      int requiredParameterCount,
      DartType returnType: const VoidType()}) {
    var function = new FunctionNode(null,
        typeParameters: typeParameters,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount,
        returnType: returnType);
    return new Procedure(new Name(name), ProcedureKind.Method, function);
  }

  Field makeField({String name: 'foo'}) {
    return new Field(new Name(name));
  }

  ForwardingStub makeForwardingStub(Procedure method) {
    var class_ = makeClass(procedures: [method]);
    var node = getForwardingNode(class_, false);
    return ForwardingNode.createForwardingStubForTesting(
        node, Substitution.empty, method);
  }

  Procedure makeSetter(
      {String name: 'foo', DartType setterType: const DynamicType()}) {
    var parameter = new VariableDeclaration('value', type: setterType);
    var function = new FunctionNode(null,
        positionalParameters: [parameter], returnType: const VoidType());
    return new Procedure(new Name(name), ProcedureKind.Setter, function);
  }

  void test_candidate_for_field_getter() {
    var field = makeField();
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
    var field = makeField();
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

  void test_candidate_order_interfaces() {
    var methodA = makeEmptyMethod();
    var methodB = makeEmptyMethod();
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(name: 'B', procedures: [methodB]);
    var c = makeClass(
        name: 'C', implementedTypes: [a.asThisSupertype, b.asThisSupertype]);
    checkCandidateOrder(c, methodA);
  }

  void test_candidate_order_mixin_before_superclass() {
    var methodA = makeEmptyMethod();
    var methodB = makeEmptyMethod();
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(name: 'B', procedures: [methodB]);
    var c = makeClass(
        name: 'C',
        supertype: a.asThisSupertype,
        mixedInType: b.asThisSupertype);
    checkCandidateOrder(c, methodB);
  }

  void test_candidate_order_superclass_before_interface() {
    var methodA = makeEmptyMethod();
    var methodB = makeEmptyMethod();
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(name: 'B', procedures: [methodB]);
    var c = makeClass(
        name: 'C',
        supertype: a.asThisSupertype,
        implementedTypes: [b.asThisSupertype]);
    checkCandidateOrder(c, methodA);
  }

  void test_createForwardingStub_optionalNamedParameter() {
    var parameter = new VariableDeclaration('x', type: intType);
    var method = makeEmptyMethod(namedParameters: [parameter]);
    var stub = makeForwardingStub(method);
    expect(stub.function.namedParameters, hasLength(1));
    expect(stub.function.namedParameters[0].name, 'x');
    expect(stub.function.namedParameters[0].type, intType);
    expect(stub.function.requiredParameterCount, 0);
    var arguments = ((stub.function.body as ReturnStatement).expression
            as SuperMethodInvocation)
        .arguments;
    expect(arguments.named, hasLength(1));
    expect(arguments.named[0].name, 'x');
    expect((arguments.named[0].value as VariableGet).variable,
        same(stub.function.namedParameters[0]));
  }

  void test_createForwardingStub_optionalPositionalParameter() {
    var parameter = new VariableDeclaration('x', type: intType);
    var method = makeEmptyMethod(
        positionalParameters: [parameter], requiredParameterCount: 0);
    var stub = makeForwardingStub(method);
    expect(stub.function.positionalParameters, hasLength(1));
    expect(stub.function.positionalParameters[0].name, 'x');
    expect(stub.function.positionalParameters[0].type, intType);
    expect(stub.function.requiredParameterCount, 0);
    var arguments = ((stub.function.body as ReturnStatement).expression
            as SuperMethodInvocation)
        .arguments;
    expect(arguments.positional, hasLength(1));
    expect((arguments.positional[0] as VariableGet).variable,
        same(stub.function.positionalParameters[0]));
  }

  void test_createForwardingStub_requiredParameter() {
    var parameter = new VariableDeclaration('x', type: intType);
    var method = makeEmptyMethod(positionalParameters: [parameter]);
    var stub = makeForwardingStub(method);
    expect(stub.function.positionalParameters, hasLength(1));
    expect(stub.function.positionalParameters[0].name, 'x');
    expect(stub.function.positionalParameters[0].type, intType);
    expect(stub.function.requiredParameterCount, 1);
    var arguments = ((stub.function.body as ReturnStatement).expression
            as SuperMethodInvocation)
        .arguments;
    expect(arguments.positional, hasLength(1));
    expect((arguments.positional[0] as VariableGet).variable,
        same(stub.function.positionalParameters[0]));
  }

  void test_createForwardingStub_simple() {
    var method = makeEmptyMethod();
    var stub = makeForwardingStub(method);
    expect(stub.name, method.name);
    expect(stub.kind, ProcedureKind.Method);
    expect(stub.function.positionalParameters, isEmpty);
    expect(stub.function.namedParameters, isEmpty);
    expect(stub.function.typeParameters, isEmpty);
    expect(stub.function.requiredParameterCount, 0);
    expect(stub.function.returnType, const VoidType());
    var body = stub.function.body as ReturnStatement;
    var expression = body.expression as SuperMethodInvocation;
    expect(expression.name, method.name);
    expect(expression.interfaceTarget, same(method));
    expect(expression.arguments.positional, isEmpty);
    expect(expression.arguments.named, isEmpty);
    expect(expression.arguments.types, isEmpty);
  }

  void test_createForwardingStub_typeParameter() {
    var typeParameter = new TypeParameter('T', numType);
    var method = makeEmptyMethod(typeParameters: [typeParameter]);
    var stub = makeForwardingStub(method);
    expect(stub.function.typeParameters, hasLength(1));
    expect(stub.function.typeParameters[0].name, 'T');
    expect(stub.function.typeParameters[0].bound, numType);
    var arguments = ((stub.function.body as ReturnStatement).expression
            as SuperMethodInvocation)
        .arguments;
    expect(arguments.types, hasLength(1));
    var typeArgument = arguments.types[0] as TypeParameterType;
    expect(typeArgument.parameter, same(stub.function.typeParameters[0]));
    expect(typeArgument.promotedBound, isNull);
  }

  void test_direct_isGenericCovariant() {
    var typeParameter = new TypeParameter('T', objectType);
    var u = new TypeParameter('U', new TypeParameterType(typeParameter));
    var x = new VariableDeclaration('x',
        type: new TypeParameterType(typeParameter));
    var y = new VariableDeclaration('y',
        type: new TypeParameterType(typeParameter));
    var method = makeEmptyMethod(
        typeParameters: [u], positionalParameters: [x], namedParameters: [y]);
    var class_ =
        makeClass(typeParameters: [typeParameter], procedures: [method]);
    var node = getForwardingNode(class_, false);
    var resolvedMethod = node.resolve();
    expect(resolvedMethod, same(method));
    expect(u.isGenericCovariantImpl, isTrue);
    expect(u.isGenericCovariantInterface, isTrue);
    expect(x.isGenericCovariantImpl, isTrue);
    expect(x.isGenericCovariantInterface, isTrue);
    expect(x.isCovariant, isFalse);
    expect(y.isGenericCovariantImpl, isTrue);
    expect(y.isGenericCovariantInterface, isTrue);
    expect(y.isCovariant, isFalse);
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

  void test_forwardingStub_isCovariant_inherited() {
    var methodA = makeEmptyMethod(
        positionalParameters: [new VariableDeclaration('x', type: numType)],
        namedParameters: [new VariableDeclaration('y', type: numType)]);
    var methodB = makeEmptyMethod(positionalParameters: [
      new VariableDeclaration('x', type: intType)..isCovariant = true
    ], namedParameters: [
      new VariableDeclaration('y', type: intType)..isCovariant = true
    ]);
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(name: 'B', procedures: [methodB]);
    var c = makeClass(
        name: 'C',
        supertype: a.asThisSupertype,
        implementedTypes: [b.asThisSupertype]);
    var node = getForwardingNode(c, false);
    var stub = node.resolve() as ForwardingStub;
    var x = stub.function.positionalParameters[0];
    expect(x.isGenericCovariantImpl, isFalse);
    expect(x.isGenericCovariantInterface, isFalse);
    expect(x.isCovariant, isTrue);
    var y = stub.function.namedParameters[0];
    expect(y.isGenericCovariantImpl, isFalse);
    expect(y.isGenericCovariantInterface, isFalse);
    expect(y.isCovariant, isTrue);
  }

  void test_forwardingStub_isGenericCovariantImpl_inherited() {
    var methodA = makeEmptyMethod(
        typeParameters: [new TypeParameter('U', numType)],
        positionalParameters: [new VariableDeclaration('x', type: numType)],
        namedParameters: [new VariableDeclaration('y', type: numType)]);
    var typeParameterB = new TypeParameter('T', objectType);
    var methodB = makeEmptyMethod(typeParameters: [
      new TypeParameter('U', new TypeParameterType(typeParameterB))
        ..isGenericCovariantImpl = true
        ..isGenericCovariantInterface = true
    ], positionalParameters: [
      new VariableDeclaration('x', type: new TypeParameterType(typeParameterB))
        ..isGenericCovariantImpl = true
        ..isGenericCovariantInterface = true
    ], namedParameters: [
      new VariableDeclaration('y', type: new TypeParameterType(typeParameterB))
        ..isGenericCovariantImpl = true
        ..isGenericCovariantInterface = true
    ]);
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(
        name: 'B', typeParameters: [typeParameterB], procedures: [methodB]);
    var c = makeClass(
        name: 'C',
        supertype: a.asThisSupertype,
        implementedTypes: [b.asThisSupertype]);
    var node = getForwardingNode(c, false);
    var stub = node.resolve() as ForwardingStub;
    var u = stub.function.typeParameters[0];
    expect(u.isGenericCovariantImpl, isTrue);
    expect(u.isGenericCovariantInterface, isFalse);
    var x = stub.function.positionalParameters[0];
    expect(x.isGenericCovariantImpl, isTrue);
    expect(x.isGenericCovariantInterface, isFalse);
    expect(x.isCovariant, isFalse);
    var y = stub.function.namedParameters[0];
    expect(y.isGenericCovariantImpl, isTrue);
    expect(y.isGenericCovariantInterface, isFalse);
    expect(y.isCovariant, isFalse);
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

  void test_resolve_directly_declared() {
    var parameterA =
        new VariableDeclaration('x', type: objectType, isCovariant: true);
    var methodA = makeEmptyMethod(positionalParameters: [parameterA]);
    var parameterB =
        new VariableDeclaration('x', type: intType, isCovariant: true);
    var methodB = makeEmptyMethod(positionalParameters: [parameterB]);
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(
        name: 'B', supertype: a.asThisSupertype, procedures: [methodB]);
    var node = getForwardingNode(b, false);
    expect(node.resolve(), same(methodB));
  }

  void test_resolve_field() {
    var field = makeField();
    var a = makeClass(name: 'A', fields: [field]);
    var b = makeClass(name: 'B', supertype: a.asThisSupertype);
    var node = getForwardingNode(b, false);
    expect(node.resolve(), same(field));
  }

  void test_resolve_first() {
    var methodA = makeEmptyMethod(returnType: intType);
    var methodB = makeEmptyMethod(returnType: numType);
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(name: 'B', procedures: [methodB]);
    var c = makeClass(
        name: 'C', implementedTypes: [a.asThisSupertype, b.asThisSupertype]);
    var node = getForwardingNode(c, false);
    expect(node.resolve(), same(methodA));
  }

  void test_resolve_second() {
    var methodA = makeEmptyMethod(returnType: numType);
    var methodB = makeEmptyMethod(returnType: intType);
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(name: 'B', procedures: [methodB]);
    var c = makeClass(
        name: 'C', implementedTypes: [a.asThisSupertype, b.asThisSupertype]);
    var node = getForwardingNode(c, false);
    expect(getStubTarget(node.resolve()), same(methodB));
  }

  void test_resolve_setters() {
    var setterA = makeSetter(setterType: intType);
    var setterB = makeSetter(setterType: objectType);
    var setterC = makeSetter(setterType: numType);
    var a = makeClass(name: 'A', procedures: [setterA]);
    var b = makeClass(name: 'B', procedures: [setterB]);
    var c = makeClass(name: 'C', procedures: [setterC]);
    var d = makeClass(name: 'D', implementedTypes: [
      a.asThisSupertype,
      b.asThisSupertype,
      c.asThisSupertype
    ]);
    var node = getForwardingNode(d, true);
    expect(getStubTarget(node.resolve()), same(setterB));
  }

  void test_resolve_with_subsitutions() {
    var typeParamA = new TypeParameter('T', objectType);
    var typeParamB = new TypeParameter('T', objectType);
    var typeParamC = new TypeParameter('T', objectType);
    var methodA =
        makeEmptyMethod(returnType: new TypeParameterType(typeParamA));
    var methodB =
        makeEmptyMethod(returnType: new TypeParameterType(typeParamB));
    var methodC =
        makeEmptyMethod(returnType: new TypeParameterType(typeParamC));
    var a = makeClass(
        name: 'A', typeParameters: [typeParamA], procedures: [methodA]);
    var b = makeClass(
        name: 'B', typeParameters: [typeParamB], procedures: [methodB]);
    var c = makeClass(
        name: 'C', typeParameters: [typeParamC], procedures: [methodC]);
    var d = makeClass(name: 'D', implementedTypes: [
      new Supertype(a, [objectType]),
      new Supertype(b, [intType]),
      new Supertype(c, [numType])
    ]);
    var node = getForwardingNode(d, false);
    expect(getStubTarget(node.resolve()), same(methodB));
  }
}
