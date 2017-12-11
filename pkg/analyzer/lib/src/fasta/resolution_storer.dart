// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/type_inference/interface_resolver.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';

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

/// The type of [DartType] node that is used as a marker for using `null`
/// as the [FunctionType] for index assignment.
class IndexAssignNullFunctionType implements DartType {
  const IndexAssignNullFunctionType();

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return 'IndexAssignNullFunctionType';
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
      List<TreeNode> declarations,
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
  void _recordDeclaration(TreeNode declaration, int offset) {
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
  void _replaceType(DartType type, [int newOffset = -1]) {
    if (newOffset != -1) {
      _typeOffsets[_deferredTypeSlots.last] = newOffset;
    }
    if (_debug) {
      if (newOffset != -1) {
        _deferredTypeOffsets.removeLast();
        _deferredTypeOffsets.add(newOffset);
      }
      int offset = _deferredTypeOffsets.removeLast();
      print('Replacing type $type for offset $offset');
    }
    super._replaceType(type, newOffset);
  }
}

/// A reference to the getter represented by the [member].
/// The [member] might be either a getter itself, or a field.
class MemberGetterNode implements TreeNode {
  /// The member representing the getter, or `null` if the getter could not be
  /// resolved.
  final Member member;

  MemberGetterNode(this.member);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '$member.getter';
  }
}

/// Information about invocation of the [member] and its instantiated [type].
class MemberInvocationDartType implements DartType {
  final Member member;
  final FunctionType type;

  MemberInvocationDartType(this.member, this.type);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '($member, $type)';
  }
}

/// A reference to the setter represented by the [member].
/// The [member] might be either a setter itself, or a field.
class MemberSetterNode implements TreeNode {
  /// The member representing the setter, or `null` if the setter could not be
  /// resolved.
  final Member member;

  MemberSetterNode(this.member);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '$member.setter';
  }
}

/// The type of [TreeNode] node that is used as a marker for `null`.
class NullNode implements TreeNode {
  final String kind;

  const NullNode(this.kind);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '(null-$kind)';
  }
}

/// Type inference listener that records inferred types for later use by
/// [ResolutionApplier].
class ResolutionStorer extends TypeInferenceListener {
  final List<TreeNode> _declarations;
  final List<Node> _references;
  final List<DartType> _types;

  /// Indices into [_references] which need to be filled in later.
  final _deferredReferenceSlots = <int>[];

  /// Indices into [_types] which need to be filled in later.
  final _deferredTypeSlots = <int>[];

  ResolutionStorer(this._declarations, this._references, this._types);

  @override
  void asExpressionExit(AsExpression expression, DartType inferredType) {
    _recordType(expression.type, expression.fileOffset);
    _recordType(inferredType, expression.fileOffset);
  }

  @override
  void cascadeExpressionExit(Let expression, DartType inferredType) {
    // Overridden so that the type of the expression will not be recorded. We
    // don't need to record the type because the type is always the same as the
    // type of the target, and we don't have the appropriate offset so we can't
    // correctly apply the type even if we recorded it.
  }

  @override
  void catchStatementEnter(Catch node) {
    _recordType(node.guard, node.fileOffset);

    VariableDeclaration exception = node.exception;
    if (exception != null) {
      _recordDeclaration(exception, exception.fileOffset);
      _recordType(exception.type, exception.fileOffset);
    }

    VariableDeclaration stackTrace = node.stackTrace;
    if (stackTrace != null) {
      _recordDeclaration(stackTrace, stackTrace.fileOffset);
      _recordType(stackTrace.type, stackTrace.fileOffset);
    }
  }

  @override
  bool constructorInvocationEnter(
      InvocationExpression expression, DartType typeContext) {
    _deferReference(expression.fileOffset);
    _deferType(expression.fileOffset);
    return true;
  }

  @override
  void constructorInvocationExit(
      InvocationExpression expression, DartType inferredType) {
    _replaceType(inferredType);
    if (expression is ConstructorInvocation) {
      _replaceReference(expression.target);
    } else if (expression is StaticInvocation) {
      _replaceReference(expression.target);
    } else {
      throw new UnimplementedError('${expression.runtimeType}');
    }
  }

  @override
  void fieldInitializerEnter(FieldInitializer initializer) {
    _recordReference(initializer.field, initializer.fileOffset);
  }

  /// Verifies that all deferred work has been completed.
  void finished() {
    assert(_deferredTypeSlots.isEmpty);
  }

  @override
  void forInStatementEnter(ForInStatement statement,
      VariableDeclaration variable, Expression write) {
    if (variable != null) {
      _deferType(variable.fileOffset);
      _recordDeclaration(variable, variable.fileOffset);
    } else {
      if (write is VariableSet) {
        _recordReference(write.variable, write.fileOffset);
        _recordType(write.variable.type, write.fileOffset);
      } else if (write is PropertySet) {
        Field field = write.interfaceTarget;
        _recordReference(new MemberSetterNode(field), write.fileOffset);
        _recordType(field.type, write.fileOffset);
      } else if (write is StaticSet) {
        Field field = write.target;
        _recordReference(new MemberSetterNode(field), write.fileOffset);
        _recordType(field.type, write.fileOffset);
      } else {
        throw new UnimplementedError('(${write.runtimeType}) $write');
      }
    }
  }

  @override
  void forInStatementExit(
      ForInStatement statement, VariableDeclaration variable) {
    if (variable != null) {
      _replaceType(variable.type);
    }
  }

  void functionDeclarationEnter(FunctionDeclaration statement) {
    _recordDeclaration(statement.variable, statement.fileOffset);
    super.functionDeclarationEnter(statement);
  }

  @override
  bool functionExpressionEnter(
      FunctionExpression expression, DartType typeContext) {
    _recordDeclaration(expression, expression.fileOffset);
    return super.functionExpressionEnter(expression, typeContext);
  }

  @override
  void functionExpressionExit(
      FunctionExpression expression, DartType inferredType) {
    // We don't need to record the inferred type.
    // It is already set in the function declaration.
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
  void ifNullBeforeRhs(Expression expression) {
    _deferType(expression.fileOffset);
  }

  @override
  void ifNullExit(Expression expression, DartType inferredType) {
    _replaceType(inferredType);
  }

  @override
  void indexAssignAfterReceiver(Expression write, DartType typeContext) {
    _deferReference(write.fileOffset);
    _recordType(const IndexAssignNullFunctionType(), write.fileOffset);
    _deferType(write.fileOffset);
  }

  @override
  void indexAssignExit(Expression expression, Expression write,
      Member writeMember, Procedure combiner, DartType inferredType) {
    _replaceReference(writeMember);
    _replaceType(inferredType);
    _recordReference(
        combiner ?? const NullNode('assign-combiner'), write.fileOffset);
    _recordType(inferredType, write.fileOffset);
  }

  @override
  void isExpressionExit(IsExpression expression, DartType inferredType) {
    _recordType(expression.type, expression.fileOffset);
    _recordType(inferredType, expression.fileOffset);
  }

  void isNotExpressionExit(
      Not expression, DartType type, DartType inferredType) {
    _recordType(type, expression.fileOffset);
    _recordType(inferredType, expression.fileOffset);
  }

  @override
  void logicalExpressionBeforeRhs(LogicalExpression expression) {
    _deferType(expression.fileOffset);
  }

  @override
  void logicalExpressionExit(
      LogicalExpression expression, DartType inferredType) {
    _replaceType(inferredType);
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
    _deferType(expression.fileOffset);
    super.methodInvocationBeforeArgs(expression, isImplicitCall);
  }

  @override
  void methodInvocationExit(
      Expression expression,
      Arguments arguments,
      bool isImplicitCall,
      Member interfaceMember,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    _replaceType(
        inferredType,
        arguments.fileOffset != -1
            ? arguments.fileOffset
            : expression.fileOffset);
    if (!isImplicitCall) {
      if (interfaceMember is ForwardingStub) {
        interfaceMember = ForwardingStub.getInterfaceTarget(interfaceMember);
      }
      _replaceReference(interfaceMember);
      FunctionType invokeType = substitution == null
          ? calleeType
          : substitution.substituteType(calleeType.withoutTypeParameters);
      _replaceType(new MemberInvocationDartType(interfaceMember, invokeType));
    }
    super.genericExpressionExit("methodInvocation", expression, inferredType);
  }

  @override
  void methodInvocationExitCall(Expression expression, Arguments arguments,
      bool isImplicitCall, DartType inferredType) {
    _replaceType(
        inferredType,
        arguments.fileOffset != -1
            ? arguments.fileOffset
            : expression.fileOffset);
    if (!isImplicitCall) {
      throw new UnimplementedError(); // TODO(scheglov): handle this case
    }
    super.genericExpressionExit("methodInvocation", expression, inferredType);
  }

  @override
  bool propertyAssignEnter(
      Expression expression, Expression write, DartType typeContext) {
    _deferReference(write.fileOffset);
    _deferType(write.fileOffset);
    return super.propertyAssignEnter(expression, write, typeContext);
  }

  @override
  void propertyAssignExit(
      Expression expression,
      Expression write,
      Member writeMember,
      DartType writeContext,
      Procedure combiner,
      DartType inferredType) {
    if (writeMember is ForwardingStub) {
      writeMember = ForwardingStub.getInterfaceTarget(writeMember);
    }
    _replaceReference(new MemberSetterNode(writeMember));
    _replaceType(writeContext);
    _recordReference(
        combiner ?? const NullNode('assign-combiner'), write.fileOffset);
    _recordType(inferredType, write.fileOffset);
  }

  @override
  void propertyGetExit(
      Expression expression, Member member, DartType inferredType) {
    _recordReference(new MemberGetterNode(member), expression.fileOffset);
    super.propertyGetExit(expression, member, inferredType);
  }

  @override
  void propertyGetExitCall(Expression expression, DartType inferredType) {
    throw new UnimplementedError(); // TODO(scheglov): handle this case
    // super.propertyGetExitCall(expression, inferredType);
  }

  @override
  bool staticAssignEnter(Expression expression, int targetOffset,
      Class targetClass, Expression write, DartType typeContext) {
    // If the static target is explicit (and is a class), record it.
    if (targetClass != null) {
      _recordReference(targetClass, targetOffset);
      _recordType(targetClass.rawType, targetOffset);
    }

    _deferReference(write.fileOffset);
    _deferType(write.fileOffset);
    return super.staticAssignEnter(
        expression, targetOffset, targetClass, write, typeContext);
  }

  @override
  void staticAssignExit(
      Expression expression,
      Expression write,
      Member writeMember,
      DartType writeContext,
      Procedure combiner,
      DartType inferredType) {
    _replaceReference(new MemberSetterNode(writeMember));
    _replaceType(writeContext);
    _recordReference(
        combiner ?? const NullNode('assign-combiner'), write.fileOffset);
    _recordType(inferredType, write.fileOffset);
  }

  @override
  bool staticGetEnter(StaticGet expression, int targetOffset, Class targetClass,
      DartType typeContext) {
    // If the static target is explicit (and is a class), record it.
    if (targetClass != null) {
      _recordReference(targetClass, targetOffset);
      _recordType(targetClass.rawType, targetOffset);
    }
    return super
        .staticGetEnter(expression, targetOffset, targetClass, typeContext);
  }

  @override
  void staticGetExit(StaticGet expression, DartType inferredType) {
    _recordReference(
        new MemberGetterNode(expression.target), expression.fileOffset);
    super.staticGetExit(expression, inferredType);
  }

  @override
  bool staticInvocationEnter(StaticInvocation expression, int targetOffset,
      Class targetClass, DartType typeContext) {
    // If the static target is explicit (and is a class), record it.
    if (targetClass != null) {
      _recordReference(targetClass, targetOffset);
      _recordType(targetClass.rawType, targetOffset);
    }
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
    _deferType(expression.arguments.fileOffset);
    return super.staticInvocationEnter(
        expression, targetOffset, targetClass, typeContext);
  }

  @override
  void staticInvocationExit(
      StaticInvocation expression,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    _replaceType(inferredType);
    _replaceReference(expression.target);
    FunctionType invokeType = substitution == null
        ? calleeType
        : substitution.substituteType(calleeType.withoutTypeParameters);
    _replaceType(new MemberInvocationDartType(expression.target, invokeType));
    super.genericExpressionExit("staticInvocation", expression, inferredType);
  }

  @override
  void stringConcatenationExit(
      StringConcatenation expression, DartType inferredType) {
    // We don't need the type - we already know that it is String.
    // Moreover, the file offset for StringConcatenation is `-1`.
  }

  @override
  void thisExpressionExit(ThisExpression expression, DartType inferredType) {}

  void typeLiteralExit(TypeLiteral expression, DartType inferredType) {
    _recordReference(expression.type, expression.fileOffset);
    super.typeLiteralExit(expression, inferredType);
  }

  @override
  bool variableAssignEnter(
      Expression expression, DartType typeContext, Expression write) {
    _deferReference(write.fileOffset);
    _deferType(write.fileOffset);
    return super.variableAssignEnter(expression, typeContext, write);
  }

  @override
  void variableAssignExit(Expression expression, DartType writeContext,
      Expression write, Procedure combiner, DartType inferredType) {
    _replaceReference(write is VariableSet
        ? write.variable
        : const NullNode('writable-variable'));
    _replaceType(writeContext);
    _recordReference(
        combiner ?? const NullNode('assign-combiner'), write.fileOffset);
    _recordType(inferredType, write.fileOffset);
  }

  @override
  void variableDeclarationEnter(VariableDeclaration statement) {
    _recordDeclaration(statement, statement.fileOffset);
    _deferType(statement.fileOffset);
    super.variableDeclarationEnter(statement);
  }

  @override
  void variableDeclarationExit(
      VariableDeclaration statement, DartType inferredType) {
    _replaceType(statement.type);
    super.variableDeclarationExit(statement, inferredType);
  }

  @override
  void variableGetExit(VariableGet expression, DartType inferredType) {
    /// Return `true` if the given [variable] declaration occurs in a let
    /// expression that is, or is part of, a cascade expression.
    bool isInCascade(VariableDeclaration variable) {
      TreeNode ancestor = variable.parent;
      while (ancestor is Let) {
        if (ancestor is ShadowCascadeExpression) {
          return true;
        }
        ancestor = ancestor.parent;
      }
      return false;
    }

    VariableDeclaration variable = expression.variable;
    if (isInCascade(variable)) {
      return;
    }
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

  void _recordDeclaration(TreeNode declaration, int offset) {
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

  void _replaceType(DartType type, [int newOffset = -1]) {
    int slot = _deferredTypeSlots.removeLast();
    _types[slot] = type;
  }
}
