// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:kernel/ast.dart';

/// TODO(scheglov) document
class FunctionReferenceDartType implements DartType {
  final FunctionDeclaration function;
  final DartType type;

  FunctionReferenceDartType(this.function, this.type);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '(${function.variable}, $type)';
  }
}

/// Type inference listener that records inferred types and file offsets for
/// later use by [ValidatingResolutionApplier].
class InstrumentedResolutionStorer extends ResolutionStorer {
  /// Indicates whether debug messages should be printed.
  static const bool _debug = false;

  final List<int> _declarationOffsets;
  final List<int> _referenceOffsets;
  final List<int> _typeOffsets;

  final List<int> _deferredReferenceOffsets = [];
  final List<int> _deferredTypeOffsets = [];

  InstrumentedResolutionStorer(
      List<Statement> declarations,
      List<Node> references,
      List<DartType> types,
      this._declarationOffsets,
      this._referenceOffsets,
      this._typeOffsets)
      : super(declarations, references, types);

  @override
  void _deferReference(int offset) {
    super._deferReference(offset);
    if (_debug) {
      _deferredReferenceOffsets.add(offset);
    }
  }

  @override
  void _deferType(int offset) {
    super._deferType(offset);
    if (_debug) {
      _deferredTypeOffsets.add(offset);
    }
  }

  @override
  void _recordDeclaration(Statement declaration, int offset) {
    if (_debug) {
      print('Recording declaration of $declaration for offset $offset');
    }
    _declarationOffsets.add(offset);
    super._recordDeclaration(declaration, offset);
  }

  @override
  int _recordReference(Node target, int offset) {
    if (_debug) {
      print('Recording reference to $target for offset $offset');
    }
    _referenceOffsets.add(offset);
    return super._recordReference(target, offset);
  }

  @override
  int _recordType(DartType type, int offset) {
    if (_debug) {
      print('Recording type $type for offset $offset');
    }
    assert(_types.length == _typeOffsets.length);
    _typeOffsets.add(offset);
    return super._recordType(type, offset);
  }

  @override
  void _replaceReference(Node reference) {
    if (_debug) {
      int offset = _deferredReferenceOffsets.removeLast();
      print('Replacing reference $reference for offset $offset');
    }
    super._replaceReference(reference);
  }

  @override
  void _replaceType(DartType type) {
    if (_debug) {
      int offset = _deferredTypeOffsets.removeLast();
      print('Replacing type $type for offset $offset');
    }
    super._replaceType(type);
  }
}

/// A reference to the getter represented by the [member].
/// The [member] might be either a getter itself, or a field.
class MemberGetterNode implements TreeNode {
  final Member member;

  MemberGetterNode(this.member);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '$member.getter';
  }
}

/// TODO(scheglov) document
class MemberReferenceDartType implements DartType {
  final Member member;
  final List<DartType> typeArguments;

  MemberReferenceDartType(this.member, this.typeArguments);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '<${typeArguments.join(', ')}>$member';
  }
}

/// A reference to the setter represented by the [member].
/// The [member] might be either a setter itself, or a field.
class MemberSetterNode implements TreeNode {
  final Member member;

  MemberSetterNode(this.member);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '$member.setter';
  }
}

/// Type inference listener that records inferred types for later use by
/// [ResolutionApplier].
class ResolutionStorer extends TypeInferenceListener {
  final List<Statement> _declarations;
  final List<Node> _references;
  final List<DartType> _types;

  /// Indices into [_references] which need to be filled in later.
  final _deferredReferenceSlots = <int>[];

  /// Indices into [_types] which need to be filled in later.
  final _deferredTypeSlots = <int>[];

  ResolutionStorer(this._declarations, this._references, this._types);

  @override
  bool constructorInvocationEnter(
      InvocationExpression expression, DartType typeContext) {
    return super.constructorInvocationEnter(expression, typeContext);
  }

  @override
  void constructorInvocationExit(
      InvocationExpression expression, DartType inferredType) {
    if (expression is ConstructorInvocation) {
      _recordReference(expression.target, expression.fileOffset);
    } else if (expression is StaticInvocation) {
      _recordReference(expression.target, expression.fileOffset);
    } else {
      throw new UnimplementedError('${expression.runtimeType}');
    }
    super.constructorInvocationExit(expression, inferredType);
  }

  /// Verifies that all deferred work has been completed.
  void finished() {
    assert(_deferredTypeSlots.isEmpty);
  }

  @override
  void functionDeclarationExit(FunctionDeclaration statement) {
    _recordDeclaration(statement.variable, statement.fileOffset);
    _recordType(statement.function.returnType, statement.fileOffset);
    super.functionDeclarationExit(statement);
  }

  @override
  bool genericExpressionEnter(
      String expressionType, Expression expression, DartType typeContext) {
    super.genericExpressionEnter(expressionType, expression, typeContext);
    return true;
  }

  @override
  void genericExpressionExit(
      String expressionType, Expression expression, DartType inferredType) {
    _recordType(inferredType, expression.fileOffset);
    super.genericExpressionExit(expressionType, expression, inferredType);
  }

  @override
  void methodInvocationBeforeArgs(Expression expression, bool isImplicitCall) {
    if (!isImplicitCall) {
      // When the invocation target is `VariableGet`, we record the target
      // before arguments. To ensure this order for method invocations, we
      // first record `null`, and then replace it on exit.
      _deferReference(expression.fileOffset);
      // We are visiting a method invocation like: a.f(args).  We have visited a
      // but we haven't visited the args yet.
      //
      // The analyzer AST will expect a type for f at this point.  (It can't
      // wait until later, because for all it knows, a.f might be a property
      // access, in which case the appropriate time for the type is now).  But
      // the type isn't known yet (because it may depend on type inference based
      // on arguments).
      //
      // So we add a `null` to our list of types; we'll update it with the
      // actual type later.
      _deferType(expression.fileOffset);
    }
    super.methodInvocationBeforeArgs(expression, isImplicitCall);
  }

  @override
  void methodInvocationExit(Expression expression, Arguments arguments,
      bool isImplicitCall, Object interfaceMember, DartType inferredType) {
    if (!isImplicitCall) {
      _replaceReference(interfaceMember);
      _replaceType(new MemberReferenceDartType(
          interfaceMember as Member, arguments.types));
    }
    int resultOffset = arguments.fileOffset != -1
        ? arguments.fileOffset
        : expression.fileOffset;
    _recordType(inferredType, resultOffset);
    super.genericExpressionExit("methodInvocation", expression, inferredType);
  }

  @override
  bool propertyAssignEnter(Expression expression, DartType typeContext) {
    _deferReference(expression.fileOffset);
    _deferType(expression.fileOffset);
    return super.propertyAssignEnter(expression, typeContext);
  }

  @override
  void propertyAssignExit(Expression expression, Member writeMember,
      DartType writeContext, DartType inferredType) {
    _replaceReference(new MemberSetterNode(writeMember));
    _replaceType(writeContext);
    // No call for super().
    // The type of the assignment is the type of the RHS.
  }

  @override
  void propertyGetExit(
      Expression expression, Object member, DartType inferredType) {
    _recordReference(new MemberGetterNode(member), expression.fileOffset);
    super.propertyGetExit(expression, member, inferredType);
  }

  @override
  void staticGetExit(StaticGet expression, DartType inferredType) {
    _recordReference(expression.target, expression.fileOffset);
    super.staticGetExit(expression, inferredType);
  }

  @override
  bool staticInvocationEnter(
      StaticInvocation expression, DartType typeContext) {
    // When the invocation target is `VariableGet`, we record the target
    // before arguments. To ensure this order for method invocations, we
    // first record `null`, and then replace it on exit.
    _deferReference(expression.fileOffset);
    // We are visiting a static invocation like: f(args), and we haven't visited
    // args yet.
    //
    // The analyzer AST will expect a type for f at this point.  (It can't wait
    // until later, because for all it knows, f is a method on `this`, and
    // methods need a type for f at this point--see comments in
    // [methodInvocationBeforeArgs]).  But the type isn't known yet (because it
    // may depend on type inference based on arguments).
    //
    // So we add a `null` to our list of types; we'll update it with the actual
    // type later.
    _deferType(expression.fileOffset);
    return super.staticInvocationEnter(expression, typeContext);
  }

  @override
  void staticInvocationExit(
      StaticInvocation expression, DartType inferredType) {
    _replaceReference(expression.target);
    // TODO(paulberry): get the actual callee function type from the inference
    // engine
    var calleeType = const DynamicType();
    _replaceType(calleeType);
    _recordType(inferredType, expression.arguments.fileOffset);
    super.genericExpressionExit("staticInvocation", expression, inferredType);
  }

  void typeLiteralExit(TypeLiteral expression, DartType inferredType) {
    _recordReference(expression.type, expression.fileOffset);
    super.typeLiteralExit(expression, inferredType);
  }

  @override
  bool variableAssignEnter(Expression expression, DartType typeContext) {
    _deferReference(expression.fileOffset);
    _deferType(expression.fileOffset);
    return super.variableAssignEnter(expression, typeContext);
  }

  @override
  void variableAssignExit(
      Expression expression, DartType writeContext, DartType inferredType) {
    VariableSet variableSet = expression;
    _replaceReference(variableSet.variable);
    _replaceType(writeContext);
    // No call for super().
    // The type of the assignment is the type of the RHS.
  }

  @override
  void variableDeclarationEnter(VariableDeclaration statement) {
    _deferType(statement.fileOffset);
    super.variableDeclarationEnter(statement);
  }

  @override
  void variableDeclarationExit(
      VariableDeclaration statement, DartType inferredType) {
    _recordDeclaration(statement, statement.fileOffset);
    _replaceType(statement.type);
    super.variableDeclarationExit(statement, inferredType);
  }

  @override
  void variableGetExit(VariableGet expression, DartType inferredType) {
    VariableDeclaration variable = expression.variable;
    _recordReference(variable, expression.fileOffset);

    TreeNode function = variable.parent;
    if (function is FunctionDeclaration) {
      _recordType(new FunctionReferenceDartType(function, inferredType),
          expression.fileOffset);
    } else {
      _recordType(inferredType, expression.fileOffset);
    }
  }

  /// Record `null` as the reference at the given [offset], and put the current
  /// slot into the [_deferredReferenceSlots] stack.
  void _deferReference(int offset) {
    int slot = _recordReference(null, offset);
    _deferredReferenceSlots.add(slot);
  }

  /// Record `null` as the type at the given [offset], and put the current
  /// slot into the [_deferredTypeSlots] stack.
  void _deferType(int offset) {
    int slot = _recordType(null, offset);
    _deferredTypeSlots.add(slot);
  }

  void _recordDeclaration(Statement declaration, int offset) {
    _declarations.add(declaration);
  }

  int _recordReference(Node target, int offset) {
    int slot = _references.length;
    _references.add(target);
    return slot;
  }

  int _recordType(DartType type, int offset) {
    int slot = _types.length;
    _types.add(type);
    return slot;
  }

  void _replaceReference(Node reference) {
    int slot = _deferredReferenceSlots.removeLast();
    _references[slot] = reference;
  }

  void _replaceType(DartType type) {
    int slot = _deferredTypeSlots.removeLast();
    _types[slot] = type;
  }
}
