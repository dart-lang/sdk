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
    interfaceResolver = new InterfaceResolver(typeEnvironment, null, true);
  }

  InterfaceType get intType => coreTypes.intClass.rawType;

  Class get listClass => coreTypes.listClass;

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

  List<Procedure> getCandidates(Class class_, bool setters) =>
      interfaceResolver.getCandidates(class_, setters);

  ForwardingNode getForwardingNode(Class class_, bool setter) {
    var forwardingNodes = getForwardingNodes(class_, setter);
    expect(forwardingNodes, hasLength(1));
    return forwardingNodes[0];
  }

  List<ForwardingNode> getForwardingNodes(Class class_, bool setters) {
    var forwardingNodes = <ForwardingNode>[];
    var candidates = getCandidates(class_, setters);
    InterfaceResolver.forEachApiMember(candidates,
        (int start, int end, Name name) {
      forwardingNodes.add(new ForwardingNode(interfaceResolver, class_, name,
          candidates[start].kind, candidates, setters, start, end));
    });
    return forwardingNodes;
  }

  Member getStubTarget(Procedure stub) {
    var body = stub.function.body;
    if (body == null) return null;
    if (body is ReturnStatement) {
      var expression = body.expression;
      if (expression is SuperMethodInvocation) {
        return expression.interfaceTarget;
      } else if (expression is SuperPropertySet) {
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
      {ProcedureKind kind: ProcedureKind.Method,
      String name: 'foo',
      List<TypeParameter> typeParameters,
      List<VariableDeclaration> positionalParameters,
      List<VariableDeclaration> namedParameters,
      int requiredParameterCount,
      DartType returnType: const VoidType(),
      bool isAbstract: false}) {
    var body = isAbstract ? null : new ReturnStatement(new NullLiteral());
    var function = new FunctionNode(body,
        typeParameters: typeParameters,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount,
        returnType: returnType);
    return new ShadowProcedure(new Name(name), kind, function, false,
        isAbstract: isAbstract);
  }

  Field makeField({String name: 'foo', DartType type: const DynamicType()}) {
    return new Field(new Name(name), type: type);
  }

  Procedure makeForwardingStub(Procedure method, bool setter,
      {Substitution substitution}) {
    var a = makeClass(name: 'A', procedures: [method]);
    var b = makeClass(name: 'B', supertype: a.asThisSupertype);
    var node = getForwardingNode(b, setter);
    var stub = ForwardingNode.createForwardingStubForTesting(
        node, substitution ?? Substitution.empty, method);
    ForwardingNode.createForwardingImplIfNeededForTesting(node, stub.function);
    return stub;
  }

  Procedure makeGetter(
      {String name: 'foo', DartType getterType: const DynamicType()}) {
    var body = new ReturnStatement(new NullLiteral());
    var function = new FunctionNode(body, returnType: getterType);
    return new ShadowProcedure(
        new Name(name), ProcedureKind.Getter, function, false);
  }

  Procedure makeSetter(
      {String name: 'foo', DartType setterType: const DynamicType()}) {
    var parameter = new ShadowVariableDeclaration('value', 0, type: setterType);
    var body = new Block([]);
    var function = new FunctionNode(body,
        positionalParameters: [parameter], returnType: const VoidType());
    return new ShadowProcedure(
        new Name(name), ProcedureKind.Setter, function, false);
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
    var getter = new ShadowProcedure(
        new Name('foo'), ProcedureKind.Getter, function, false);
    checkCandidate(getter, false);
  }

  void test_candidate_for_method() {
    checkCandidate(makeEmptyMethod(), false);
  }

  void test_candidate_for_setter() {
    var parameter = new ShadowVariableDeclaration('value', 0);
    var function = new FunctionNode(null,
        positionalParameters: [parameter], returnType: const VoidType());
    var setter = new ShadowProcedure(
        new Name('foo'), ProcedureKind.Setter, function, false);
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

  void test_createForwardingStub_abstract() {
    var method = makeEmptyMethod(isAbstract: true);
    var stub = makeForwardingStub(method, false);
    expect(stub.isAbstract, isTrue);
    expect(stub.function.body, isNull);
  }

  void test_createForwardingStub_getter() {
    var getter = makeGetter(getterType: numType);
    var stub = makeForwardingStub(getter, false);
    expect(stub.name, getter.name);
    expect(stub.kind, ProcedureKind.Getter);
    expect(stub.function.positionalParameters, isEmpty);
    expect(stub.function.namedParameters, isEmpty);
    expect(stub.function.typeParameters, isEmpty);
    expect(stub.function.requiredParameterCount, 0);
    expect(stub.function.returnType, numType);
    var body = stub.function.body as ReturnStatement;
    var expression = body.expression as SuperPropertyGet;
    expect(expression.name, getter.name);
    expect(expression.interfaceTarget, same(getter));
  }

  void test_createForwardingStub_getter_for_field() {
    var field = makeField(type: numType);
    var stub = makeForwardingStub(
        InterfaceResolver.makeCandidate(field, false), false);
    expect(stub.name, field.name);
    expect(stub.kind, ProcedureKind.Getter);
    expect(stub.function.positionalParameters, isEmpty);
    expect(stub.function.namedParameters, isEmpty);
    expect(stub.function.typeParameters, isEmpty);
    expect(stub.function.requiredParameterCount, 0);
    expect(stub.function.returnType, numType);
    var body = stub.function.body as ReturnStatement;
    var expression = body.expression as SuperPropertyGet;
    expect(expression.name, field.name);
    expect(expression.interfaceTarget, same(field));
  }

  void test_createForwardingStub_operator() {
    var operator = makeEmptyMethod(
        kind: ProcedureKind.Operator,
        name: '[]=',
        positionalParameters: [
          new ShadowVariableDeclaration('index', 0, type: intType),
          new ShadowVariableDeclaration('value', 0, type: numType)
        ]);
    var stub = makeForwardingStub(operator, false);
    expect(stub.name, operator.name);
    expect(stub.kind, ProcedureKind.Operator);
    expect(stub.function.positionalParameters, hasLength(2));
    expect(stub.function.positionalParameters[0].name,
        operator.function.positionalParameters[0].name);
    expect(stub.function.positionalParameters[0].type, intType);
    expect(stub.function.positionalParameters[1].name,
        operator.function.positionalParameters[1].name);
    expect(stub.function.positionalParameters[1].type, numType);
    expect(stub.function.namedParameters, isEmpty);
    expect(stub.function.typeParameters, isEmpty);
    expect(stub.function.requiredParameterCount, 2);
    expect(stub.function.returnType, const VoidType());
    var body = stub.function.body as ReturnStatement;
    var expression = body.expression as SuperMethodInvocation;
    expect(expression.name, operator.name);
    expect(expression.interfaceTarget, same(operator));
    var arguments = expression.arguments;
    expect(arguments.positional, hasLength(2));
    expect((arguments.positional[0] as VariableGet).variable,
        same(stub.function.positionalParameters[0]));
    expect((arguments.positional[1] as VariableGet).variable,
        same(stub.function.positionalParameters[1]));
  }

  void test_createForwardingStub_optionalNamedParameter() {
    var parameter = new ShadowVariableDeclaration('x', 0, type: intType);
    var method = makeEmptyMethod(namedParameters: [parameter]);
    var stub = makeForwardingStub(method, false);
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
    var parameter = new ShadowVariableDeclaration('x', 0, type: intType);
    var method = makeEmptyMethod(
        positionalParameters: [parameter], requiredParameterCount: 0);
    var stub = makeForwardingStub(method, false);
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
    var parameter = new ShadowVariableDeclaration('x', 0, type: intType);
    var method = makeEmptyMethod(positionalParameters: [parameter]);
    var stub = makeForwardingStub(method, false);
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

  void test_createForwardingStub_setter() {
    var setter = makeSetter(setterType: numType);
    var stub = makeForwardingStub(setter, true);
    expect(stub.name, setter.name);
    expect(stub.kind, ProcedureKind.Setter);
    expect(stub.function.positionalParameters, hasLength(1));
    expect(stub.function.positionalParameters[0].name,
        setter.function.positionalParameters[0].name);
    expect(stub.function.positionalParameters[0].type, numType);
    expect(stub.function.namedParameters, isEmpty);
    expect(stub.function.typeParameters, isEmpty);
    expect(stub.function.requiredParameterCount, 1);
    expect(stub.function.returnType, const VoidType());
    var body = stub.function.body as ReturnStatement;
    var expression = body.expression as SuperPropertySet;
    expect(expression.name, setter.name);
    expect(expression.interfaceTarget, same(setter));
    expect((expression.value as VariableGet).variable,
        same(stub.function.positionalParameters[0]));
  }

  void test_createForwardingStub_setter_for_field() {
    var field = makeField(type: numType);
    var stub =
        makeForwardingStub(InterfaceResolver.makeCandidate(field, true), true);
    expect(stub.name, field.name);
    expect(stub.kind, ProcedureKind.Setter);
    expect(stub.function.positionalParameters, hasLength(1));
    expect(stub.function.positionalParameters[0].name, '_');
    expect(stub.function.positionalParameters[0].type, numType);
    expect(stub.function.namedParameters, isEmpty);
    expect(stub.function.typeParameters, isEmpty);
    expect(stub.function.requiredParameterCount, 1);
    expect(stub.function.returnType, const VoidType());
    var body = stub.function.body as ReturnStatement;
    var expression = body.expression as SuperPropertySet;
    expect(expression.name, field.name);
    expect(expression.interfaceTarget, same(field));
    expect((expression.value as VariableGet).variable,
        same(stub.function.positionalParameters[0]));
  }

  void test_createForwardingStub_simple() {
    var method = makeEmptyMethod();
    var stub = makeForwardingStub(method, false);
    expect(stub.name, method.name);
    expect(stub.kind, ProcedureKind.Method);
    expect(stub.isAbstract, isFalse);
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

  void test_createForwardingStub_substitute() {
    // class C<T> { T foo(T x, {T y}); }
    var T = new TypeParameter('T', objectType);
    var x =
        new ShadowVariableDeclaration('x', 0, type: new TypeParameterType(T));
    var y =
        new ShadowVariableDeclaration('y', 0, type: new TypeParameterType(T));
    var method = makeEmptyMethod(
        positionalParameters: [x],
        namedParameters: [y],
        returnType: new TypeParameterType(T));
    var substitution = Substitution.fromPairs([T], [intType]);
    var stub = makeForwardingStub(method, false, substitution: substitution);
    expect(stub.function.positionalParameters[0].type, intType);
    expect(stub.function.namedParameters[0].type, intType);
    expect(stub.function.returnType, intType);
  }

  void test_createForwardingStub_typeParameter() {
    var typeParameter = new TypeParameter('T', numType);
    var method = makeEmptyMethod(typeParameters: [typeParameter]);
    var stub = makeForwardingStub(method, false);
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

  void test_createForwardingStub_typeParameter_and_substitution() {
    // class C<T> { void foo<U>(T x, U y); }
    var T = new TypeParameter('T', objectType);
    var U = new TypeParameter('U', objectType);
    var x =
        new ShadowVariableDeclaration('x', 0, type: new TypeParameterType(T));
    var y =
        new ShadowVariableDeclaration('y', 0, type: new TypeParameterType(U));
    var method =
        makeEmptyMethod(typeParameters: [U], positionalParameters: [x, y]);
    var substitution = Substitution.fromPairs([T], [intType]);
    var stub = makeForwardingStub(method, false, substitution: substitution);
    expect(stub.function.positionalParameters[0].type, intType);
    var stubYType =
        stub.function.positionalParameters[1].type as TypeParameterType;
    expect(stubYType.parameter, same(stub.function.typeParameters[0]));
  }

  void test_createForwardingStub_typeParameter_substituteUses() {
    // class C { void foo<T>(T x); }
    var typeParameter = new TypeParameter('T', objectType);
    var param = new ShadowVariableDeclaration('x', 0,
        type: new TypeParameterType(typeParameter));
    var method = makeEmptyMethod(
        typeParameters: [typeParameter], positionalParameters: [param]);
    var stub = makeForwardingStub(method, false);
    var stubXType =
        stub.function.positionalParameters[0].type as TypeParameterType;
    expect(stubXType.parameter, same(stub.function.typeParameters[0]));
  }

  void test_createForwardingStub_typeParameter_substituteUses_fBounded() {
    // class C { void foo<T extends List<T>>(T x); }
    var typeParameter = new TypeParameter('T', null);
    typeParameter.bound =
        new InterfaceType(listClass, [new TypeParameterType(typeParameter)]);
    var param = new ShadowVariableDeclaration('x', 0,
        type: new TypeParameterType(typeParameter));
    var method = makeEmptyMethod(
        typeParameters: [typeParameter], positionalParameters: [param]);
    var stub = makeForwardingStub(method, false);
    var stubTypeParameter = stub.function.typeParameters[0];
    var stubTypeParameterBound = stubTypeParameter.bound as InterfaceType;
    var stubTypeParameterBoundArg =
        stubTypeParameterBound.typeArguments[0] as TypeParameterType;
    expect(stubTypeParameterBoundArg.parameter, same(stubTypeParameter));
    var stubXType =
        stub.function.positionalParameters[0].type as TypeParameterType;
    expect(stubXType.parameter, same(stubTypeParameter));
  }

  void test_direct_isGenericCovariant() {
    var typeParameter = new TypeParameter('T', objectType);
    var u = new TypeParameter('U', new TypeParameterType(typeParameter));
    var x = new ShadowVariableDeclaration('x', 0,
        type: new TypeParameterType(typeParameter));
    var y = new ShadowVariableDeclaration('y', 0,
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

  void test_direct_isGenericCovariant_field() {
    var typeParameter = new TypeParameter('T', objectType);
    var field = makeField(type: new TypeParameterType(typeParameter));
    var class_ = makeClass(typeParameters: [typeParameter], fields: [field]);
    var node = getForwardingNode(class_, true);
    var resolvedField = node.resolve();
    expect(resolvedField, same(field));
    expect(field.isGenericCovariantImpl, isTrue);
    expect(field.isGenericCovariantInterface, isTrue);
    expect(field.isCovariant, isFalse);
  }

  void test_field_isCovariant_inherited() {
    var fieldA = makeField(type: numType)..isCovariant = true;
    var fieldB = makeField(type: numType);
    var a = makeClass(name: 'A', fields: [fieldA]);
    var b = makeClass(
        name: 'B', implementedTypes: [a.asThisSupertype], fields: [fieldB]);
    var node = getForwardingNode(b, true);
    var resolvedField = node.resolve();
    expect(resolvedField, same(fieldB));
    expect(fieldB.isGenericCovariantImpl, isFalse);
    expect(fieldB.isGenericCovariantInterface, isFalse);
    expect(fieldB.isCovariant, isTrue);
  }

  void test_field_isGenericCovariantImpl_inherited() {
    var typeParameter = new TypeParameter('T', objectType);
    var fieldA = makeField(type: new TypeParameterType(typeParameter))
      ..isGenericCovariantInterface = true
      ..isGenericCovariantImpl = true;
    var fieldB = makeField(type: numType);
    var a =
        makeClass(name: 'A', typeParameters: [typeParameter], fields: [fieldA]);
    var b = makeClass(name: 'B', implementedTypes: [
      new Supertype(a, [numType])
    ], fields: [
      fieldB
    ]);
    var node = getForwardingNode(b, true);
    var resolvedField = node.resolve();
    expect(resolvedField, same(fieldB));
    expect(fieldB.isGenericCovariantImpl, isTrue);
    expect(fieldB.isGenericCovariantInterface, isFalse);
    expect(fieldB.isCovariant, isFalse);
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
    var methodA = makeEmptyMethod(positionalParameters: [
      new ShadowVariableDeclaration('x', 0, type: numType)
    ], namedParameters: [
      new ShadowVariableDeclaration('y', 0, type: numType)
    ]);
    var methodB = makeEmptyMethod(positionalParameters: [
      new ShadowVariableDeclaration('x', 0, type: intType)..isCovariant = true
    ], namedParameters: [
      new ShadowVariableDeclaration('y', 0, type: intType)..isCovariant = true
    ]);
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(name: 'B', procedures: [methodB]);
    var c = makeClass(
        name: 'C',
        supertype: a.asThisSupertype,
        implementedTypes: [b.asThisSupertype]);
    var node = getForwardingNode(c, false);
    var stub = node.resolve() as Procedure;
    var x = stub.function.positionalParameters[0];
    expect(x.isGenericCovariantImpl, isFalse);
    expect(x.isGenericCovariantInterface, isFalse);
    expect(x.isCovariant, isTrue);
    var y = stub.function.namedParameters[0];
    expect(y.isGenericCovariantImpl, isFalse);
    expect(y.isGenericCovariantInterface, isFalse);
    expect(y.isCovariant, isTrue);
    expect(getStubTarget(stub), same(methodA));
  }

  void test_forwardingStub_isGenericCovariantImpl_inherited() {
    var methodA = makeEmptyMethod(typeParameters: [
      new TypeParameter('U', numType)
    ], positionalParameters: [
      new ShadowVariableDeclaration('x', 0, type: numType)
    ], namedParameters: [
      new ShadowVariableDeclaration('y', 0, type: numType)
    ]);
    var typeParameterB = new TypeParameter('T', objectType);
    var methodB = makeEmptyMethod(typeParameters: [
      new TypeParameter('U', new TypeParameterType(typeParameterB))
        ..isGenericCovariantImpl = true
        ..isGenericCovariantInterface = true
    ], positionalParameters: [
      new ShadowVariableDeclaration('x', 0,
          type: new TypeParameterType(typeParameterB))
        ..isGenericCovariantImpl = true
        ..isGenericCovariantInterface = true
    ], namedParameters: [
      new ShadowVariableDeclaration('y', 0,
          type: new TypeParameterType(typeParameterB))
        ..isGenericCovariantImpl = true
        ..isGenericCovariantInterface = true
    ]);
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(
        name: 'B', typeParameters: [typeParameterB], procedures: [methodB]);
    var c =
        makeClass(name: 'C', supertype: a.asThisSupertype, implementedTypes: [
      new Supertype(b, [numType])
    ]);
    var node = getForwardingNode(c, false);
    var stub = node.resolve() as Procedure;
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
    expect(getStubTarget(stub), same(methodA));
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
    var parameterA = new ShadowVariableDeclaration('x', 0,
        type: objectType, isCovariant: true);
    var methodA = makeEmptyMethod(positionalParameters: [parameterA]);
    var parameterB =
        new ShadowVariableDeclaration('x', 0, type: intType, isCovariant: true);
    var methodB = makeEmptyMethod(positionalParameters: [parameterB]);
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(
        name: 'B', supertype: a.asThisSupertype, procedures: [methodB]);
    var node = getForwardingNode(b, false);
    expect(node.resolve(), same(methodB));
  }

  void test_resolve_favor_first() {
    // When multiple methods have equivalent types, favor the first one.
    var methodA = makeEmptyMethod();
    var methodB = makeEmptyMethod();
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(name: 'B', procedures: [methodB]);
    var c = makeClass(
        name: 'C', implementedTypes: [a.asThisSupertype, b.asThisSupertype]);
    var node = getForwardingNode(c, false);
    expect(node.resolve(), same(methodA));
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
    var stub = node.resolve();
    expect(getStubTarget(stub), isNull);
    expect(stub.function.returnType, intType);
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
    var stub = node.resolve();
    expect(getStubTarget(stub), isNull);
    expect(stub.function.positionalParameters[0].type, objectType);
  }

  void test_resolve_with_added_implementation() {
    var methodA = makeEmptyMethod(positionalParameters: [
      new ShadowVariableDeclaration('x', 0, type: numType)
    ]);
    var typeParamB = new TypeParameter('T', objectType);
    var methodB = makeEmptyMethod(positionalParameters: [
      new ShadowVariableDeclaration('x', 0,
          type: new TypeParameterType(typeParamB))
        ..isGenericCovariantInterface = true
        ..isGenericCovariantImpl = true
    ]);
    var methodC = makeEmptyMethod(positionalParameters: [
      new ShadowVariableDeclaration('x', 0, type: numType)
    ], isAbstract: true);
    var a = makeClass(name: 'A', procedures: [methodA]);
    var b = makeClass(
        name: 'B', typeParameters: [typeParamB], procedures: [methodB]);
    var c =
        makeClass(name: 'C', supertype: a.asThisSupertype, implementedTypes: [
      new Supertype(b, [numType])
    ], procedures: [
      methodC
    ]);
    var node = getForwardingNode(c, false);
    expect(methodC.function.body, isNull);
    var resolvedMethod = node.resolve();
    expect(resolvedMethod, same(methodC));
    expect(methodC.function.body, isNotNull);
    expect(getStubTarget(methodC), same(methodA));
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
    var d = makeClass(
        name: 'D',
        supertype: new Supertype(a, [objectType]),
        implementedTypes: [
          new Supertype(b, [intType]),
          new Supertype(c, [numType])
        ]);
    var node = getForwardingNode(d, false);
    var stub = node.resolve();
    expect(getStubTarget(stub), isNull);
    expect(stub.function.returnType, intType);
  }
}
