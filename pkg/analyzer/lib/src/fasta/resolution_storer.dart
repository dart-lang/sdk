// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';

/// The reference to the import prefix with the [name].
class ImportPrefixNode implements TreeNode {
  final String name;

  ImportPrefixNode(this.name);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '(prefix-$name)';
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

/// The type of [DartType] node that is used as a marker for `null`.
///
/// It is used for import prefix identifiers, which are resolved to elements,
/// but don't have any types.
class NullType implements DartType {
  const NullType();

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '(null-type)';
  }
}

/// Type inference listener that records inferred types for later use by
/// [ResolutionApplier].
class ResolutionStorer {
  /// The offset that is used when the actual offset is not know.
  /// The consumer of information should not validate this offset.
  static const UNKNOWN_OFFSET = -2;

  final List<TreeNode> _declarations;
  final List<Node> _references;
  final List<DartType> _types;

  /// Indices into [_references] which need to be filled in later.
  final _deferredReferenceSlots = <int>[];

  /// Indices into [_types] which need to be filled in later.
  final _deferredTypeSlots = <int>[];

  ResolutionStorer(this._declarations, this._references, this._types);

  void asExpressionExit(AsExpression expression, DartType inferredType) {
    _recordType(expression.type, expression.fileOffset);
    _recordType(inferredType, expression.fileOffset);
  }

  void cascadeExpressionExit(Let expression, DartType inferredType) {
    // Overridden so that the type of the expression will not be recorded. We
    // don't need to record the type because the type is always the same as the
    // type of the target, and we don't have the appropriate offset so we can't
    // correctly apply the type even if we recorded it.
  }

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

  void constructorInvocationEnter(InvocationExpression expression,
      String prefixName, DartType typeContext) {
    _recordImportPrefix(prefixName);
    _deferReference(expression.fileOffset);
    _deferType(expression.fileOffset);
  }

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

  void fieldInitializerEnter(FieldInitializer initializer) {
    _recordReference(initializer.field, initializer.fileOffset);
  }

  /// Verifies that all deferred work has been completed.
  void finished() {
    assert(_deferredTypeSlots.isEmpty);
  }

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

  void forInStatementExit(
      ForInStatement statement, VariableDeclaration variable) {
    if (variable != null) {
      _replaceType(variable.type);
    }
  }

  void functionDeclarationEnter(FunctionDeclaration statement) {
    _recordDeclaration(statement.variable, statement.fileOffset);
  }

  void functionExpressionEnter(
      FunctionExpression expression, DartType typeContext) {
    _recordDeclaration(expression, expression.fileOffset);
  }

  void functionExpressionExit(
      FunctionExpression expression, DartType inferredType) {
    // We don't need to record the inferred type.
    // It is already set in the function declaration.
  }

  void genericExpressionEnter(
      String expressionType, Expression expression, DartType typeContext) {}

  void genericExpressionExit(
      String expressionType, Expression expression, DartType inferredType) {
    _recordType(inferredType, expression.fileOffset);
  }

  void ifNullBeforeRhs(Expression expression) {
    _deferType(expression.fileOffset);
  }

  void ifNullExit(Expression expression, DartType inferredType) {
    _replaceType(inferredType);
  }

  void indexAssignAfterReceiver(Expression write, DartType typeContext) {
    _deferReference(write.fileOffset);
    _recordType(const IndexAssignNullFunctionType(), write.fileOffset);
    _recordType(const IndexAssignNullFunctionType(), write.fileOffset);
    _recordType(new TypeArgumentsDartType(<DartType>[]), write.fileOffset);
    _deferType(write.fileOffset);
  }

  void indexAssignExit(Expression expression, Expression write,
      Member writeMember, Procedure combiner, DartType inferredType) {
    _replaceReference(writeMember);
    _replaceType(inferredType);
    _recordReference(
        combiner ?? const NullNode('assign-combiner'), write.fileOffset);
    _recordType(inferredType, write.fileOffset);
  }

  void isExpressionExit(IsExpression expression, DartType inferredType) {
    _recordType(expression.type, expression.fileOffset);
    _recordType(inferredType, expression.fileOffset);
  }

  void isNotExpressionExit(
      Not expression, DartType type, DartType inferredType) {
    _recordType(type, expression.fileOffset);
    _recordType(inferredType, expression.fileOffset);
  }

  void logicalExpressionBeforeRhs(LogicalExpression expression) {
    _deferType(expression.fileOffset);
  }

  void logicalExpressionExit(
      LogicalExpression expression, DartType inferredType) {
    _replaceType(inferredType);
  }

  void methodInvocationBeforeArgs(Expression expression, bool isImplicitCall) {
    if (!isImplicitCall) {
      // When the invocation target is `VariableGet`, we record the target
      // before arguments. To ensure this order for method invocations, we
      // first record `null`, and then replace it on exit.
      _deferReference(expression.fileOffset);
      _deferType(expression.fileOffset); // callee type
    }
    _deferType(expression.fileOffset); // invoke type
    _deferType(expression.fileOffset); // type arguments
    _deferType(expression.fileOffset); // result type
  }

  void methodInvocationExit(
      Expression expression,
      Arguments arguments,
      bool isImplicitCall,
      Member interfaceMember,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    int resultOffset = arguments.fileOffset != -1
        ? arguments.fileOffset
        : expression.fileOffset;
    _replaceType(inferredType, resultOffset);
    _replaceType(new TypeArgumentsDartType(arguments.types), resultOffset);

    FunctionType invokeType = substitution == null
        ? calleeType
        : substitution.substituteType(calleeType.withoutTypeParameters);
    _replaceType(invokeType, resultOffset);

    if (!isImplicitCall) {
      interfaceMember = _getRealTarget(interfaceMember);
      _replaceReference(interfaceMember);
      _replaceType(const NullType()); // callee type
    }
  }

  void methodInvocationExitCall(
      Expression expression,
      Arguments arguments,
      bool isImplicitCall,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    int resultOffset = arguments.fileOffset != -1
        ? arguments.fileOffset
        : expression.fileOffset;
    _replaceType(inferredType, resultOffset);
    _replaceType(new TypeArgumentsDartType(arguments.types), resultOffset);

    FunctionType invokeType = substitution == null
        ? calleeType
        : substitution.substituteType(calleeType.withoutTypeParameters);
    _replaceType(invokeType, resultOffset);

    if (!isImplicitCall) {
      _replaceReference(const NullNode('explicit-call'));
      _replaceType(const NullType()); // callee type
    }
  }

  void propertyAssignEnter(
      Expression expression, Expression write, DartType typeContext) {
    _deferReference(write.fileOffset);
    _deferType(write.fileOffset);
  }

  void propertyAssignExit(
      Expression expression,
      Expression write,
      Member writeMember,
      DartType writeContext,
      Procedure combiner,
      DartType inferredType) {
    writeMember = _getRealTarget(writeMember);
    _replaceReference(new MemberSetterNode(writeMember));
    _replaceType(writeContext);
    _recordReference(
        combiner ?? const NullNode('assign-combiner'), write.fileOffset);
    _recordType(inferredType, write.fileOffset);
  }

  void propertyGetExit(
      Expression expression, Member member, DartType inferredType) {
    _recordReference(new MemberGetterNode(member), expression.fileOffset);
  }

  void propertyGetExitCall(Expression expression, DartType inferredType) {
    _recordReference(const NullNode('explicit-call'), expression.fileOffset);
    _recordType(const NullType(), expression.fileOffset);
  }

  void redirectingInitializerEnter(RedirectingInitializer initializer) {
    _recordReference(initializer.target, initializer.fileOffset);
  }

  void staticAssignEnter(
      Expression expression,
      String prefixName,
      int targetOffset,
      Class targetClass,
      Expression write,
      DartType typeContext) {
    // if there was an import prefix, record it.
    _recordImportPrefix(prefixName);
    // If the static target is explicit (and is a class), record it.
    if (targetClass != null) {
      _recordReference(targetClass, targetOffset);
      _recordType(targetClass.rawType, targetOffset);
    }

    _deferReference(write.fileOffset);
    _deferType(write.fileOffset);
  }

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

  void staticGetEnter(StaticGet expression, String prefixName, int targetOffset,
      Class targetClass, DartType typeContext) {
    // if there was an import prefix, record it.
    _recordImportPrefix(prefixName);
    // If the static target is explicit (and is a class), record it.
    if (targetClass != null) {
      _recordReference(targetClass, targetOffset);
      _recordType(targetClass.rawType, targetOffset);
    }
  }

  void staticGetExit(StaticGet expression, DartType inferredType) {
    _recordReference(
        new MemberGetterNode(expression.target), expression.fileOffset);
  }

  void staticInvocationEnter(StaticInvocation expression, String prefixName,
      int targetOffset, Class targetClass, DartType typeContext) {
    // if there was an import prefix, record it.
    _recordImportPrefix(prefixName);
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
    _deferType(expression.fileOffset); // callee type
    _deferType(expression.arguments.fileOffset); // invoke type
    _deferType(expression.arguments.fileOffset); // type arguments
    _deferType(expression.arguments.fileOffset); // result type
  }

  void staticInvocationExit(
      StaticInvocation expression,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    _replaceType(inferredType);
    _replaceReference(expression.target);
    _replaceType(new TypeArgumentsDartType(expression.arguments.types));
    FunctionType invokeType = substitution == null
        ? calleeType
        : substitution.substituteType(calleeType.withoutTypeParameters);
    _replaceType(invokeType);
    _replaceType(const NullType()); // callee type
  }

  void stringConcatenationExit(
      StringConcatenation expression, DartType inferredType) {
    // We don't need the type - we already know that it is String.
    // Moreover, the file offset for StringConcatenation is `-1`.
  }

  void thisExpressionExit(ThisExpression expression, DartType inferredType) {}

  void typeLiteralEnter(@override TypeLiteral expression, String prefixName,
      DartType typeContext) {
    // if there was an import prefix, record it.
    _recordImportPrefix(prefixName);
  }

  void typeLiteralExit(TypeLiteral expression, DartType inferredType) {
    _recordReference(expression.type, expression.fileOffset);
  }

  void variableAssignEnter(
      Expression expression, DartType typeContext, Expression write) {
    _deferReference(write.fileOffset);
    _deferType(write.fileOffset);
  }

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

  void variableDeclarationEnter(VariableDeclaration statement) {
    _recordDeclaration(statement, statement.fileOffset);
    _deferType(statement.fileOffset);
  }

  void variableDeclarationExit(
      VariableDeclaration statement, DartType inferredType) {
    _replaceType(statement.type);
  }

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
    _recordType(inferredType, expression.fileOffset);
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

  /// If the [prefixName] is not `null` record the reference to it.
  void _recordImportPrefix(String prefixName) {
    if (prefixName != null) {
      _recordReference(new ImportPrefixNode(prefixName), UNKNOWN_OFFSET);
      _recordType(const NullType(), UNKNOWN_OFFSET);
    }
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

  /// If the [member] is a forwarding stub, return the target it forwards to.
  /// Otherwise return the given [member].
  static Member _getRealTarget(Member member) {
    if (member is Procedure && member.isForwardingStub) {
      return member.forwardingStubInterfaceTarget;
    }
    return member;
  }
}

/// A [DartType] wrapper around invocation type arguments.
class TypeArgumentsDartType implements DartType {
  final List<DartType> types;

  TypeArgumentsDartType(this.types);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '<${types.join(', ')}>';
  }
}
