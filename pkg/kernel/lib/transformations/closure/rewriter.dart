// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure.rewriter;

import '../../ast.dart';
import 'converter.dart' show ClosureConverter;

/// Used by the [Context] to initialize and update the context variable
/// used to capture the variables closed over by functions.
abstract class AstRewriter {
  /// The declared variable that holds the context.
  VariableDeclaration contextDeclaration;

  /// The expression used to initialize the size of the context stored in
  /// [contextDeclaration]. This expression is modified when the context is
  /// extended.
  IntLiteral contextSize;

  /// Creates a new [AstRewriter] for a (nested) [Block].
  BlockRewriter forNestedBlock(Block block);

  /// Inserts an allocation of a context and initializes [contextDeclaration]
  /// and [contextSize].
  void insertContextDeclaration(Class contextClass, Expression accessParent);

  /// Inserts an expression or statement that extends the context, where
  /// [arguments] holds a pair of the new index and the initial value.
  void insertExtendContext(Expression accessContext, Arguments arguments);

  void _createDeclaration(Class contextClass) {
    assert(contextDeclaration == null && contextSize == null);

    contextSize = new IntLiteral(0);
    contextDeclaration = new VariableDeclaration.forValue(
        new ConstructorInvocation(contextClass.constructors.first,
            new Arguments(<Expression>[contextSize])),
        type: new InterfaceType(contextClass));
    contextDeclaration.name = "#context";
  }
}

/// Adds a local variable for the context and adds update [Statement]s to the
/// current block.
class BlockRewriter extends AstRewriter {
  Block _currentBlock;
  int _insertionIndex;

  BlockRewriter(this._currentBlock) : _insertionIndex = 0;

  BlockRewriter forNestedBlock(Block block) {
    return _currentBlock != block ? new BlockRewriter(block) : this;
  }

  void transformStatements(Block block, ClosureConverter converter) {
    while (_insertionIndex < _currentBlock.statements.length) {
      var original = _currentBlock.statements[_insertionIndex];
      var transformed = original.accept(converter);
      assert(_currentBlock.statements[_insertionIndex] == original);
      if (transformed == null) {
        _currentBlock.statements.removeAt(_insertionIndex);
      } else {
        _currentBlock.statements[_insertionIndex++] = transformed;
        transformed.parent = _currentBlock;
      }
    }
  }

  void _insertStatement(Statement statement) {
    _currentBlock.statements.insert(_insertionIndex++, statement);
    statement.parent = _currentBlock;
  }

  void insertContextDeclaration(Class contextClass, Expression accessParent) {
    _createDeclaration(contextClass);
    _insertStatement(contextDeclaration);
    if (accessParent is! NullLiteral) {
      _insertStatement(new ExpressionStatement(new PropertySet(
          new VariableGet(contextDeclaration),
          new Name('parent'),
          accessParent)));
    }
  }

  void insertExtendContext(Expression accessContext, Arguments arguments) {
    _insertStatement(new ExpressionStatement(
        new MethodInvocation(accessContext, new Name('[]='), arguments)));
  }
}

/// Creates and updates the context as [Let] bindings around the initializer
/// expression.
class InitializerRewriter extends AstRewriter {
  final Expression initializingExpression;

  InitializerRewriter(this.initializingExpression) {
    assert(initializingExpression.parent is FieldInitializer);
  }

  @override
  BlockRewriter forNestedBlock(Block block) {
    return new BlockRewriter(block);
  }

  @override
  void insertContextDeclaration(Class contextClass, Expression accessParent) {
    _createDeclaration(contextClass);
    FieldInitializer parent = initializingExpression.parent;
    Let binding = new Let(contextDeclaration, initializingExpression);
    initializingExpression.parent = binding;
    parent.value = binding;
    binding.parent = parent;
  }

  @override
  void insertExtendContext(Expression accessContext, Arguments arguments) {
    Expression extendContext =
        new MethodInvocation(accessContext, new Name('[]='), arguments);
    Let parent = initializingExpression.parent;
    Let binding = new Let(
        new VariableDeclaration(null, initializer: extendContext),
        initializingExpression);
    parent.body = binding;
    binding.parent = parent;
  }
}
