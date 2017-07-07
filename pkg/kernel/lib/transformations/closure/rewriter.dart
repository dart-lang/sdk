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

  /// Expression that is used to initialize the vector representing the context.
  /// It's [length] field is modified by the [extend] operation
  VectorCreation vectorCreation;

  /// Creates a new [AstRewriter] for a (nested) [Block].
  BlockRewriter forNestedBlock(Block block);

  /// Inserts an allocation of a context and initializes [contextDeclaration]
  /// and [vectorCreation].
  void insertContextDeclaration(Expression accessParent);

  /// Inserts an expression or statement that extends the context.
  void insertExtendContext(VectorSet extender);

  void _createDeclaration() {
    assert(contextDeclaration == null && vectorCreation == null);

    // Context size is set to 1 initially, because the 0-th element of it works
    // as a link to the parent context.
    vectorCreation = new VectorCreation(1);
    contextDeclaration = new VariableDeclaration.forValue(vectorCreation,
        type: new VectorType());
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

  void insertContextDeclaration(Expression accessParent) {
    _createDeclaration();
    _insertStatement(contextDeclaration);
    if (accessParent is! NullLiteral) {
      // Index 0 of a context always points to the parent.
      _insertStatement(new ExpressionStatement(
          new VectorSet(new VariableGet(contextDeclaration), 0, accessParent)));
    }
  }

  void insertExtendContext(VectorSet extender) {
    _insertStatement(new ExpressionStatement(extender));
  }
}

/// Creates and updates the context as [Let] bindings around the initializer
/// expression.
abstract class InitializerRewriter extends AstRewriter {
  final Expression initializingExpression;

  InitializerRewriter(this.initializingExpression);

  @override
  BlockRewriter forNestedBlock(Block block) {
    return new BlockRewriter(block);
  }

  @override
  void insertContextDeclaration(Expression accessParent) {
    _createDeclaration();
    Let binding = new Let(contextDeclaration, initializingExpression);
    setInitializerExpression(binding);
    initializingExpression.parent = binding;
  }

  @override
  void insertExtendContext(VectorSet extender) {
    Let parent = initializingExpression.parent;
    Let binding = new Let(new VariableDeclaration(null, initializer: extender),
        initializingExpression);
    parent.body = binding;
    binding.parent = parent;
  }

  void setInitializerExpression(Expression expression);
}

class FieldInitializerRewriter extends InitializerRewriter {
  FieldInitializerRewriter(Expression initializingExpression)
      : super(initializingExpression) {
    assert(initializingExpression.parent is FieldInitializer);
  }

  void setInitializerExpression(Expression expression) {
    assert(initializingExpression.parent is FieldInitializer);
    FieldInitializer parent = initializingExpression.parent;
    parent.value = expression;
    expression.parent = parent;
  }
}

class LocalInitializerRewriter extends InitializerRewriter {
  LocalInitializerRewriter(Expression initializingExpression)
      : super(initializingExpression) {
    assert(initializingExpression.parent is LocalInitializer);
  }

  void setInitializerExpression(Expression expression) {
    assert(initializingExpression.parent is LocalInitializer);
    LocalInitializer parent = initializingExpression.parent;
    parent.variable.initializer = expression;
    expression.parent = parent;
  }
}
