// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file declares a "shadow hierarchy" of concrete classes which extend
/// the kernel class hierarchy using mixins from `builder/shadow_ast.dart`.
///
/// Instances of these classes may be created using the factory methods in
/// `ast_factory.dart`.
///
/// Note that these classes represent the Dart language prior to desugaring.
/// When a single Dart construct desugars to a tree containing multiple kernel
/// AST nodes, the shadow class extends the kernel object at the top of the
/// desugared tree.
///
/// This means that in some cases multiple shadow classes may extend the same
/// kernel class, because multiple constructs in Dart may desugar to a tree
/// with the same kind of root node.
import 'package:kernel/ast.dart';

import '../builder/shadow_ast.dart';

/// Concrete shadow object representing a statement block in kernel form.
class KernelBlock extends Block with ShadowBlock implements KernelStatement {
  KernelBlock(List<KernelStatement> statements) : super(statements);

  @override
  List<KernelStatement> get shadowStatements => statements;
}

/// Common base class for shadow objects representing expressions in kernel
/// form.
abstract class KernelExpression implements Expression, ShadowExpression {}

/// Concrete shadow object representing a function expression in kernel form.
class KernelFunctionExpression extends FunctionExpression
    with ShadowFunctionExpression
    implements KernelExpression {
  KernelFunctionExpression(FunctionNode function) : super(function);

  @override
  KernelStatement get shadowBody => function.body;

  @override
  DartType get shadowFunctionType {
    return function.functionType;
  }

  @override
  bool get shadowIsAsync {
    // TODO(paulberry): is there a helper function in kernel that does this?
    var asyncMarker = function.asyncMarker;
    return asyncMarker == AsyncMarker.Async ||
        asyncMarker == AsyncMarker.AsyncStar;
  }

  @override
  bool get shadowIsExpressionFunction => function.body is ReturnStatement;

  @override
  bool get shadowIsGenerator {
    // TODO(paulberry): is there a helper function in kernel that does this?
    var asyncMarker = function.asyncMarker;
    return asyncMarker == AsyncMarker.SyncStar ||
        asyncMarker == AsyncMarker.AsyncStar;
  }

  @override
  set shadowReturnType(DartType type) {
    function.returnType = type;
  }
}

/// Concrete shadow object representing an integer literal in kernel form.
class KernelIntLiteral extends IntLiteral
    with ShadowIntLiteral
    implements KernelExpression {
  KernelIntLiteral(int value) : super(value);
}

/// Concrete shadow object representing a list literal in kernel form.
class KernelListLiteral extends _KernelListLiteral
    with ShadowListLiteral
    implements KernelExpression {
  /// TODO(paulberry): see if we can eliminate the need for this by allowing
  /// `null` to be stored in [ListLiteral] prior to type inference.
  DartType _declaredTypeArgument;

  KernelListLiteral(List<KernelExpression> expressions,
      {DartType typeArgument, bool isConst: false})
      : _declaredTypeArgument = typeArgument,
        super(expressions, typeArgument ?? const DynamicType(), isConst);

  @override
  Iterable<KernelExpression> get shadowExpressions {
    List<KernelExpression> shadowExpressions = expressions;
    return shadowExpressions;
  }

  @override
  DartType get shadowTypeArgument => _declaredTypeArgument;

  @override
  set shadowTypeArgument(DartType type) {
    typeArgument = type;
  }
}

/// Concrete shadow object representing a null literal in kernel form.
class KernelNullLiteral extends NullLiteral
    with ShadowNullLiteral
    implements KernelExpression {}

/// Concrete shadow object representing a return statement in kernel form.
class KernelReturnStatement extends _KernelReturnStatement
    with ShadowReturnStatement
    implements KernelStatement {
  KernelReturnStatement([KernelExpression expression]) : super(expression);

  @override
  KernelExpression get shadowExpression => expression;
}

/// Common base class for shadow objects representing statements in kernel
/// form.
abstract class KernelStatement extends Statement implements ShadowStatement {}

/// Concrete shadow object representing a variable declaration in kernel form.
class KernelVariableDeclaration extends _KernelVariableDeclaration
    with ShadowVariableDeclaration
    implements KernelStatement {
  /// TODO(paulberry): see if we can eliminate the need for this by allowing
  /// `null` to be stored in [VariableDeclaration] prior to type
  /// inference.  Alternative: create a subclass of DynamicType which represents
  /// implicit dynamic ("MissingType" or "ImplicitDynamicType" perhaps).
  DartType _declaredType;

  KernelVariableDeclaration(String name,
      {KernelExpression initializer,
      DartType type,
      bool isFinal: false,
      bool isConst: false})
      : _declaredType = type,
        super(name, initializer, type ?? const DynamicType(), isFinal, isConst);

  @override
  KernelExpression get shadowInitializer => initializer;

  @override
  DartType get shadowType => _declaredType;

  @override
  set shadowType(DartType type) {
    this.type = type;
  }

  @override
  set type(DartType type) {
    super.type = _declaredType = type;
  }
}

/// Concrete shadow object representing a read from a variable in kernel form.
class KernelVariableGet extends _KernelVariableGet
    with ShadowVariableGet
    implements KernelExpression {
  KernelVariableGet(VariableDeclaration variable, [DartType promotedType])
      : super(variable, promotedType);

  @override
  KernelVariableDeclaration get shadowDeclaration => variable;
}

/// Adaptor class allowing [ListLiteral] to be extended with a mixin.
///
/// TODO(paulberry): see if we can eliminate the need for this class by adding
/// a named constructor to [ListLiteral] in which all arguments are
/// required.
class _KernelListLiteral extends ListLiteral {
  _KernelListLiteral(
      List<Expression> expressions, DartType typeArgument, bool isConst)
      : super(expressions, typeArgument: typeArgument, isConst: isConst);
}

/// Adaptor class allowing [ReturnStatement] to be extended with a mixin.
///
/// TODO(paulberry): see if we can eliminate the need for this class by adding
/// a named constructor to [ReturnStatement] in which all arguments are
/// required.
class _KernelReturnStatement extends ReturnStatement {
  _KernelReturnStatement(KernelExpression expression) : super(expression);
}

/// Adaptor class allowing [VariableDeclaration] to be extended with a
/// mixin.
///
/// TODO(paulberry): see if we can eliminate the need for this class by adding
/// a named constructor to [VariableDeclaration] in which all arguments
/// are required.
class _KernelVariableDeclaration extends VariableDeclaration {
  _KernelVariableDeclaration(String name, Expression initializer, DartType type,
      bool isFinal, bool isConst)
      : super(name,
            initializer: initializer,
            type: type,
            isFinal: isFinal,
            isConst: isConst);
}

/// Adaptor class allowing [VariableGet] to be extended with a mixin.
///
/// TODO(paulberry): see if we can eliminate the need for this class by adding
/// a named constructor to [VariableGet] in which all arguments are
/// required.
class _KernelVariableGet extends VariableGet {
  _KernelVariableGet(VariableDeclaration variable, DartType promotedType)
      : super(variable, promotedType);
}
