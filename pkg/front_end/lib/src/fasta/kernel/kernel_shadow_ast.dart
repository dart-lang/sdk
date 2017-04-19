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
import 'package:front_end/src/base/instrumentation.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

/// Concrete shadow object representing a statement block in kernel form.
class KernelBlock extends Block implements KernelStatement {
  KernelBlock(List<KernelStatement> statements) : super(statements);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    // TODO(paulberry): implement.
  }
}

/// Common base class for shadow objects representing expressions in kernel
/// form.
abstract class KernelExpression implements Expression {
  /// Calls back to [inferrer] to perform type inference for whatever concrete
  /// type of [KernelExpression] this is.
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded);
}

/// Concrete shadow object representing a function expression in kernel form.
class KernelFunctionExpression extends FunctionExpression
    implements KernelExpression {
  KernelFunctionExpression(FunctionNode function) : super(function);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(paulberry): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete shadow object representing an integer literal in kernel form.
class KernelIntLiteral extends IntLiteral implements KernelExpression {
  KernelIntLiteral(int value) : super(value);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(paulberry): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete shadow object representing a list literal in kernel form.
class KernelListLiteral extends ListLiteral implements KernelExpression {
  KernelListLiteral(List<KernelExpression> expressions,
      {DartType typeArgument, bool isConst: false})
      : super(expressions, typeArgument: typeArgument, isConst: isConst);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(paulberry): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete shadow object representing a null literal in kernel form.
class KernelNullLiteral extends NullLiteral implements KernelExpression {
  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(paulberry): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}

/// Concrete shadow object representing a return statement in kernel form.
class KernelReturnStatement extends ReturnStatement implements KernelStatement {
  KernelReturnStatement([KernelExpression expression]) : super(expression);

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    // TODO(paulberry): implement.
  }
}

/// Common base class for shadow objects representing statements in kernel
/// form.
abstract class KernelStatement extends Statement {
  /// Calls back to [inferrer] to perform type inference for whatever concrete
  /// type of [KernelStatement] this is.
  void _inferStatement(KernelTypeInferrer inferrer);
}

/// Concrete implementation of [TypeInferrer] specialized to work with kernel
/// objects.
class KernelTypeInferrer extends TypeInferrer<Statement, Expression,
    KernelVariableDeclaration, Field> {
  KernelTypeInferrer(CoreTypes coreTypes, ClassHierarchy classHierarchy,
      Instrumentation instrumentation)
      : super(coreTypes, classHierarchy, instrumentation);

  @override
  DartType inferExpression(
      Expression expression, DartType typeContext, bool typeNeeded) {
    if (expression is KernelExpression) {
      // Use polymorphic dispatch on [KernelExpression] to perform whatever kind
      // of type inference is correct for this kind of statement.
      // TODO(paulberry): experiment to see if dynamic dispatch would be better,
      // so that the type hierarchy will be simpler (which may speed up "is"
      // checks).
      return expression._inferExpression(this, typeContext, typeNeeded);
    } else {
      // Encountered an expression type for which type inference is not yet
      // implemented, so just infer dynamic for now.
      // TODO(paulberry): once the BodyBuilder uses shadow classes for
      // everything, this case should no longer be needed.
      return typeNeeded ? const DynamicType() : null;
    }
  }

  @override
  void inferStatement(Statement statement) {
    if (statement is KernelStatement) {
      // Use polymorphic dispatch on [KernelStatement] to perform whatever kind
      // of type inference is correct for this kind of statement.
      // TODO(paulberry): experiment to see if dynamic dispatch would be better,
      // so that the type hierarchy will be simpler (which may speed up "is"
      // checks).
      return statement._inferStatement(this);
    } else {
      // Encountered a statement type for which type inference is not yet
      // implemented, so just skip it for now.
      // TODO(paulberry): once the BodyBuilder uses shadow classes for
      // everything, this case should no longer be needed.
    }
  }
}

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

  @override
  void _inferStatement(KernelTypeInferrer inferrer) {
    // TODO(paulberry): implement.
  }
}

/// Concrete shadow object representing a read from a variable in kernel form.
class KernelVariableGet extends VariableGet implements KernelExpression {
  KernelVariableGet(VariableDeclaration variable, [DartType promotedType])
      : super(variable, promotedType);

  @override
  DartType _inferExpression(
      KernelTypeInferrer inferrer, DartType typeContext, bool typeNeeded) {
    // TODO(paulberry): implement.
    return typeNeeded ? const DynamicType() : null;
  }
}
