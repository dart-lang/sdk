// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:kernel/ast.dart';

/// Type inference listener that records inferred types and file offsets for
/// later use by [ValidatingResolutionApplier].
class InstrumentedResolutionStorer extends ResolutionStorer {
  /// Indicates whether debug messages should be printed.
  static const bool _debug = false;

  final List<int> _declarationOffsets;
  final List<int> _referenceOffsets;
  final List<int> _typeOffsets;
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
  void _recordReference(Node target, int offset) {
    if (_debug) {
      print('Recording reference to $target for offset $offset');
    }
    _referenceOffsets.add(offset);
    super._recordReference(target, offset);
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
  void _replaceType(DartType type) {
    if (_debug) {
      int offset = _deferredTypeOffsets.removeLast();
      print('Replacing type $type for offset $offset');
    }
    super._replaceType(type);
  }
}

/// Type inference listener that records inferred types for later use by
/// [ResolutionApplier].
class ResolutionStorer extends TypeInferenceListener {
  final List<Statement> _declarations;
  final List<Node> _references;
  final List<DartType> _types;

  /// Indices into [_types] which need to be filled in later.
  final _deferredTypeSlots = <int>[];

  ResolutionStorer(this._declarations, this._references, this._types);

  /// Verifies that all deferred work has been completed.
  void finished() {
    assert(_deferredTypeSlots.isEmpty);
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

  void typeLiteralExit(TypeLiteral expression, DartType inferredType) {
    _recordReference(expression.type, expression.fileOffset);
    super.typeLiteralExit(expression, inferredType);
  }

  @override
  void methodInvocationExit(Expression expression, Arguments arguments,
      bool isImplicitCall, Object interfaceMember, DartType inferredType) {
    if (!isImplicitCall) {
      // TODO(paulberry): get the actual callee function type from the inference
      // engine
      var calleeType = const DynamicType();
      _replaceType(calleeType);
      _recordReference(interfaceMember, expression.fileOffset);
    }
    _recordType(inferredType, arguments.fileOffset);
    super.genericExpressionExit("methodInvocation", expression, inferredType);
  }

  @override
  void staticGetExit(StaticGet expression, DartType inferredType) {
    _recordReference(expression.target, expression.fileOffset);
    super.staticGetExit(expression, inferredType);
  }

  @override
  bool staticInvocationEnter(
      StaticInvocation expression, DartType typeContext) {
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
    // TODO(paulberry): get the actual callee function type from the inference
    // engine
    var calleeType = const DynamicType();
    _replaceType(calleeType);
    _recordType(inferredType, expression.arguments.fileOffset);
    _recordReference(expression.target, expression.fileOffset);
    super.genericExpressionExit("staticInvocation", expression, inferredType);
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
    _replaceType(inferredType);
    super.variableDeclarationExit(statement, inferredType);
  }

  @override
  void variableGetExit(VariableGet expression, DartType inferredType) {
    _recordReference(expression.variable, expression.fileOffset);
    super.variableGetExit(expression, inferredType);
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

  void _recordReference(Node target, int offset) {
    _references.add(target);
  }

  int _recordType(DartType type, int offset) {
    int slot = _types.length;
    _types.add(type);
    return slot;
  }

  void _replaceType(DartType type) {
    int slot = _deferredTypeSlots.removeLast();
    _types[slot] = type;
  }
}
