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
import 'package:kernel/ast.dart' as kernel;
import 'package:kernel/ast.dart' show DartType;

import '../builder/shadow_ast.dart' as builder;

/// Concrete shadow object representing a statement block in kernel form.
class KernelBlock extends kernel.Block
    with builder.ShadowBlock
    implements KernelStatement {
  KernelBlock(List<KernelStatement> statements) : super(statements);

  @override
  List<KernelStatement> get shadowStatements => statements;
}

/// Common base class for shadow objects representing expressions in kernel
/// form.
abstract class KernelExpression
    implements kernel.Expression, builder.ShadowExpression {}

/// Concrete shadow object representing a function expression in kernel form.
class KernelFunctionExpression extends kernel.FunctionExpression
    with builder.ShadowFunctionExpression
    implements KernelExpression {
  KernelFunctionExpression(kernel.FunctionNode function) : super(function);

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
    return asyncMarker == kernel.AsyncMarker.Async ||
        asyncMarker == kernel.AsyncMarker.AsyncStar;
  }

  @override
  bool get shadowIsExpressionFunction =>
      function.body is kernel.ReturnStatement;

  @override
  bool get shadowIsGenerator {
    // TODO(paulberry): is there a helper function in kernel that does this?
    var asyncMarker = function.asyncMarker;
    return asyncMarker == kernel.AsyncMarker.SyncStar ||
        asyncMarker == kernel.AsyncMarker.AsyncStar;
  }

  @override
  set shadowReturnType(DartType type) {
    function.returnType = type;
  }
}

/// Concrete shadow object representing an integer literal in kernel form.
class KernelIntLiteral extends kernel.IntLiteral
    with builder.ShadowIntLiteral
    implements KernelExpression {
  KernelIntLiteral(int value) : super(value);
}

/// Concrete shadow object representing a list literal in kernel form.
class KernelListLiteral extends _KernelListLiteral
    with builder.ShadowListLiteral
    implements KernelExpression {
  /// TODO(paulberry): see if we can eliminate the need for this by allowing
  /// `null` to be stored in [kernel.ListLiteral] prior to type inference.
  DartType _declaredTypeArgument;

  KernelListLiteral(List<KernelExpression> expressions,
      {DartType typeArgument, bool isConst: false})
      : _declaredTypeArgument = typeArgument,
        super(expressions, typeArgument ?? const kernel.DynamicType(), isConst);

  @override
  Iterable<KernelExpression> get shadowExpressions {
    List<KernelExpression> shadowExpressions = expressions;
    return shadowExpressions;
  }

  @override
  kernel.DartType get shadowTypeArgument => _declaredTypeArgument;

  @override
  set shadowTypeArgument(kernel.DartType type) {
    typeArgument = type;
  }
}

/// Concrete shadow object representing a null literal in kernel form.
class KernelNullLiteral extends kernel.NullLiteral
    with builder.ShadowNullLiteral
    implements KernelExpression {}

/// Concrete shadow object representing a return statement in kernel form.
class KernelReturnStatement extends _KernelReturnStatement
    with builder.ShadowReturnStatement
    implements KernelStatement {
  KernelReturnStatement([KernelExpression expression]) : super(expression);

  @override
  KernelExpression get shadowExpression => expression;
}

/// Common base class for shadow objects representing statements in kernel
/// form.
abstract class KernelStatement extends kernel.Statement
    implements builder.ShadowStatement {}

/// Concrete shadow object representing a variable declaration in kernel form.
class KernelVariableDeclaration extends _KernelVariableDeclaration
    with builder.ShadowVariableDeclaration
    implements KernelStatement {
  /// TODO(paulberry): see if we can eliminate the need for this by allowing
  /// `null` to be stored in [kernel.VariableDeclaration] prior to type
  /// inference.  Alternative: create a subclass of DynamicType which represents
  /// implicit dynamic ("MissingType" or "ImplicitDynamicType" perhaps).
  DartType _declaredType;

  KernelVariableDeclaration(String name,
      {KernelExpression initializer,
      DartType type,
      bool isFinal: false,
      bool isConst: false})
      : _declaredType = type,
        super(name, initializer, type ?? const kernel.DynamicType(), isFinal,
            isConst);

  @override
  KernelExpression get shadowInitializer => initializer;

  @override
  DartType get shadowType => _declaredType;

  @override
  set shadowType(kernel.DartType type) {
    this.type = type;
  }

  @override
  set type(kernel.DartType type) {
    super.type = _declaredType = type;
  }
}

/// Concrete shadow object representing a read from a variable in kernel form.
class KernelVariableGet extends _KernelVariableGet
    with builder.ShadowVariableGet
    implements KernelExpression {
  KernelVariableGet(kernel.VariableDeclaration variable,
      [DartType promotedType])
      : super(variable, promotedType);

  @override
  KernelVariableDeclaration get shadowDeclaration => variable;
}

/// Adaptor class allowing [kernel.ListLiteral] to be extended with a mixin.
///
/// TODO(paulberry): see if we can eliminate the need for this class by adding
/// a named constructor to [kernel.ListLiteral] in which all arguments are
/// required.
class _KernelListLiteral extends kernel.ListLiteral {
  _KernelListLiteral(
      List<kernel.Expression> expressions, DartType typeArgument, bool isConst)
      : super(expressions, typeArgument: typeArgument, isConst: isConst);
}

/// Adaptor class allowing [kernel.ReturnStatement] to be extended with a mixin.
///
/// TODO(paulberry): see if we can eliminate the need for this class by adding
/// a named constructor to [kernel.ReturnStatement] in which all arguments are
/// required.
class _KernelReturnStatement extends kernel.ReturnStatement {
  _KernelReturnStatement(KernelExpression expression) : super(expression);
}

/// Adaptor class allowing [kernel.VariableDeclaration] to be extended with a
/// mixin.
///
/// TODO(paulberry): see if we can eliminate the need for this class by adding
/// a named constructor to [kernel.VariableDeclaration] in which all arguments
/// are required.
class _KernelVariableDeclaration extends kernel.VariableDeclaration {
  _KernelVariableDeclaration(String name, kernel.Expression initializer,
      DartType type, bool isFinal, bool isConst)
      : super(name,
            initializer: initializer,
            type: type,
            isFinal: isFinal,
            isConst: isConst);
}

/// Adaptor class allowing [kernel.VariableGet] to be extended with a mixin.
///
/// TODO(paulberry): see if we can eliminate the need for this class by adding
/// a named constructor to [kernel.VariableGet] in which all arguments are
/// required.
class _KernelVariableGet extends kernel.VariableGet {
  _KernelVariableGet(kernel.VariableDeclaration variable, DartType promotedType)
      : super(variable, promotedType);
}
