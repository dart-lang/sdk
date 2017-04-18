// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file declares a "shadow hierarchy" of concrete classes which extend
/// the kernel class hierarchy, adding methods and fields needed by the
/// BodyBuilder.
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

/// Concrete shadow object representing a statement block in kernel form.
class KernelBlock extends Block implements KernelStatement {
  KernelBlock(List<KernelStatement> statements) : super(statements);
}

/// Common base class for shadow objects representing expressions in kernel
/// form.
abstract class KernelExpression implements Expression {}

/// Concrete shadow object representing a function expression in kernel form.
class KernelFunctionExpression extends FunctionExpression
    implements KernelExpression {
  KernelFunctionExpression(FunctionNode function) : super(function);
}

/// Concrete shadow object representing an integer literal in kernel form.
class KernelIntLiteral extends IntLiteral implements KernelExpression {
  KernelIntLiteral(int value) : super(value);
}

/// Concrete shadow object representing a list literal in kernel form.
class KernelListLiteral extends ListLiteral implements KernelExpression {
  KernelListLiteral(List<KernelExpression> expressions,
      {DartType typeArgument, bool isConst: false})
      : super(expressions, typeArgument: typeArgument, isConst: isConst);
}

/// Concrete shadow object representing a null literal in kernel form.
class KernelNullLiteral extends NullLiteral implements KernelExpression {}

/// Concrete shadow object representing a return statement in kernel form.
class KernelReturnStatement extends ReturnStatement implements KernelStatement {
  KernelReturnStatement([KernelExpression expression]) : super(expression);
}

/// Common base class for shadow objects representing statements in kernel
/// form.
abstract class KernelStatement extends Statement {}

/// Concrete shadow object representing a variable declaration in kernel form.
class KernelVariableDeclaration extends VariableDeclaration
    implements KernelStatement {
  KernelVariableDeclaration(String name,
      {KernelExpression initializer,
      DartType type,
      bool isFinal: false,
      bool isConst: false})
      : super(name,
            initializer: initializer,
            type: type,
            isFinal: isFinal,
            isConst: isConst);
}

/// Concrete shadow object representing a read from a variable in kernel form.
class KernelVariableGet extends VariableGet implements KernelExpression {
  KernelVariableGet(VariableDeclaration variable, [DartType promotedType])
      : super(variable, promotedType);
}
