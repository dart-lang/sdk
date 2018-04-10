// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' hide MapEntry;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/visitor.dart' show ExpressionVisitor, DartTypeVisitor;

import '../names.dart'
    show
        ampersandName,
        barName,
        caretName,
        divisionName,
        equalsName,
        greaterThanName,
        greaterThanOrEqualsName,
        identicalName,
        leftShiftName,
        lengthName,
        lessThanName,
        lessThanOrEqualsName,
        minusName,
        multiplyName,
        mustacheName,
        negationName,
        percentName,
        plusName,
        rightShiftName,
        tildeName,
        unaryMinusName;

import '../fasta_codes.dart' show templateInternalVisitorUnsupportedDefault;

import '../problems.dart' show unsupported;

/// Evaluates constness of the given constructor invocation.
///
/// TODO(dmitryas): Share code with the constant evaluator from
/// pkg/kernel/lib/transformations/constants.dart.
class ConstnessEvaluator
    implements ExpressionVisitor<bool>, DartTypeVisitor<bool> {
  final CoreTypes coreTypes;

  /// [Uri] of the file containing the expressions that are to be evaluated.
  final Uri uri;

  ConstnessEvaluator(this.coreTypes, this.uri);

  @override
  defaultExpression(Expression node) {
    return unsupported(
        templateInternalVisitorUnsupportedDefault
            .withArguments("${node.runtimeType}")
            .message,
        node?.fileOffset ?? -1,
        uri);
  }

  @override
  defaultBasicLiteral(BasicLiteral node) {
    return defaultExpression(node);
  }

  @override
  defaultDartType(DartType node) {
    return unsupported(
        templateInternalVisitorUnsupportedDefault
            .withArguments("${node.runtimeType}")
            .message,
        -1,
        uri);
  }

  @override
  visitInvalidType(InvalidType node) => false;

  @override
  visitDynamicType(DynamicType node) => true;

  @override
  visitVoidType(VoidType node) => true;

  @override
  visitBottomType(BottomType node) => true;

  @override
  visitInterfaceType(InterfaceType node) {
    for (var type in node.typeArguments) {
      if (!type.accept(this)) return false;
    }
    return true;
  }

  @override
  visitVectorType(VectorType node) => true;

  @override
  visitFunctionType(FunctionType node) {
    if (!node.returnType.accept(this)) return false;
    for (var parameter in node.positionalParameters) {
      if (!parameter.accept(this)) return false;
    }
    for (var parameter in node.namedParameters) {
      if (!parameter.type.accept(this)) return false;
    }
    for (var typeParameter in node.typeParameters) {
      if (!typeParameter.bound.accept(this)) return false;
    }
    return true;
  }

  @override
  visitTypeParameterType(TypeParameterType node) => false;

  @override
  visitTypedefType(TypedefType node) {
    for (var type in node.typeArguments) {
      if (!type.accept(this)) return false;
    }
    return true;
  }

  bool evaluate(Expression node) {
    return node.accept(this);
  }

  @override
  visitNullLiteral(NullLiteral node) {
    return true;
  }

  @override
  visitBoolLiteral(BoolLiteral node) {
    return true;
  }

  @override
  visitIntLiteral(IntLiteral node) {
    return true;
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    return true;
  }

  @override
  visitStringLiteral(StringLiteral node) {
    return true;
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    return true;
  }

  @override
  visitTypeLiteral(TypeLiteral node) {
    // TODO(dmitryas): Figure out how to handle deferred types.
    return node.type.accept(this);
  }

  @override
  visitListLiteral(ListLiteral node) {
    return node.isConst;
  }

  @override
  visitMapLiteral(MapLiteral node) {
    return node.isConst;
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    if (!node.target.isConst) {
      return false;
    }

    for (var type in node.arguments.types) {
      if (!type.accept(this)) return false;
    }
    for (var expression in node.arguments.positional) {
      if (!expression.accept(this)) return false;
    }
    for (var namedExpression in node.arguments.named) {
      if (!namedExpression.value.accept(this)) return false;
    }

    return true;
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (node.arguments.named.isNotEmpty ||
        node.arguments.types.isNotEmpty ||
        !isConstantMethodName(node.name, node.arguments.positional.length)) {
      return false;
    }

    if (!node.receiver.accept(this)) return false;
    for (var expression in node.arguments.positional) {
      if (!expression.accept(this)) return false;
    }

    return true;
  }

  @override
  visitLogicalExpression(LogicalExpression node) {
    return node.left.accept(this) && node.right.accept(this);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    return node.condition.accept(this) &&
        node.then.accept(this) &&
        node.otherwise.accept(this);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    if (!isConstantPropertyName(node.name)) return false;
    return node.receiver.accept(this);
  }

  @override
  visitLet(Let node) {
    return node.variable.initializer.accept(this) && node.body.accept(this);
  }

  @override
  visitVariableGet(VariableGet node) {
    return node.variable.isConst;
  }

  @override
  visitStaticGet(StaticGet node) {
    Member target = node.target;
    if (target is Field) {
      return target.isConst;
    } else {
      // TODO(dmitryas): Figure out how to deal with deferred functions.
      return true;
    }
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    for (var expression in node.expressions) {
      if (!expression.accept(this)) return false;
    }
    return true;
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    Member target = node.target;
    if (target is Procedure) {
      if (target.isConst && target.isFactory) {
        for (var type in node.arguments.types) {
          if (!type.accept(this)) return false;
        }
        for (var expression in node.arguments.positional) {
          if (!expression.accept(this)) return false;
        }
        for (var namedExpression in node.arguments.named) {
          if (!namedExpression.value.accept(this)) return false;
        }
        return true;
      } else if (target.name == identicalName) {
        final TreeNode parent = target.parent;
        if (parent is Library && parent == coreTypes.coreLibrary) {
          assert(node.arguments.positional.length == 2);
          return node.arguments.positional[0].accept(this) &&
              node.arguments.positional[1].accept(this);
        }
      }
    }
    return false;
  }

  @override
  visitAsExpression(AsExpression node) {
    return node.operand.accept(this) && node.type.accept(this);
  }

  @override
  visitNot(Not node) {
    return node.operand.accept(this);
  }

  @override
  visitInvalidExpression(InvalidExpression node) => false;

  @override
  visitVariableSet(VariableSet node) => false;

  @override
  visitPropertySet(PropertySet node) => false;

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    if (!isConstantPropertyName(node.target.name)) return false;
    return node.receiver.accept(this);
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) => false;

  @override
  visitSuperPropertyGet(SuperPropertyGet node) => false;

  @override
  visitSuperPropertySet(SuperPropertySet node) => false;

  @override
  visitStaticSet(StaticSet node) => false;

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    if (node.arguments.named.isNotEmpty ||
        node.arguments.types.isNotEmpty ||
        !isConstantMethodName(node.name, node.arguments.positional.length)) {
      return false;
    }

    if (!node.receiver.accept(this)) return false;
    for (var expression in node.arguments.positional) {
      if (!expression.accept(this)) return false;
    }

    return true;
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) => false;

  @override
  visitIsExpression(IsExpression node) {
    return node.operand.accept(this) && node.type.accept(this);
  }

  @override
  visitThisExpression(ThisExpression node) => false;

  @override
  visitRethrow(Rethrow node) => false;

  @override
  visitThrow(Throw node) => false;

  @override
  visitAwaitExpression(AwaitExpression node) => false;

  @override
  visitFunctionExpression(FunctionExpression node) => false;

  @override
  visitConstantExpression(ConstantExpression node) => true;

  @override
  visitInstantiation(Instantiation node) => false;

  @override
  visitLoadLibrary(LoadLibrary node) => false;

  @override
  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) => false;

  @override
  visitVectorCreation(VectorCreation node) => false;

  @override
  visitVectorGet(VectorGet node) => false;

  @override
  visitVectorSet(VectorSet node) => false;

  @override
  visitVectorCopy(VectorCopy node) => false;

  @override
  visitClosureCreation(ClosureCreation node) => false;

  /// Returns null if `receiver.name(arguments)` is not a constant.
  static bool isConstantMethodName(Name name, int argumentCount) {
    if (argumentCount == 0) {
      if (name == tildeName) return true;
      if (name == unaryMinusName) return true;
    } else if (argumentCount == 1) {
      if (name == ampersandName) return true;
      if (name == barName) return true;
      if (name == caretName) return true;
      if (name == divisionName) return true;
      if (name == equalsName) return true;
      if (name == greaterThanName) return true;
      if (name == greaterThanOrEqualsName) return true;
      if (name == leftShiftName) return true;
      if (name == lessThanName) return true;
      if (name == lessThanOrEqualsName) return true;
      if (name == minusName) return true;
      if (name == multiplyName) return true;
      if (name == mustacheName) return true;
      if (name == negationName) return true;
      if (name == percentName) return true;
      if (name == plusName) return true;
      if (name == rightShiftName) return true;
    }
    return false;
  }

  static bool isConstantPropertyName(Name name) {
    return name == lengthName;
  }
}

// TODO(32717): Remove this helper function when the issue is resolved.
bool evaluateConstness(Expression expression, CoreTypes coreTypes, Uri uri) {
  return new ConstnessEvaluator(coreTypes, uri).evaluate(expression);
}
