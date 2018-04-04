// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' hide MapEntry;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/visitor.dart' show ExpressionVisitor;

import '../names.dart'
    show
        ampersandName,
        barName,
        caretName,
        divisionName,
        doubleAmpersandName,
        doubleBarName,
        doubleQuestionName,
        equalsName,
        greaterThanName,
        greaterThanOrEqualsName,
        identicalName,
        leftShiftName,
        lessThanName,
        lessThanOrEqualsName,
        minusName,
        multiplyName,
        mustacheName,
        negationName,
        percentName,
        plusName,
        rightShiftName,
        tildaName,
        unaryMinusName;

import '../fasta_codes.dart' show templateInternalVisitorUnsupportedDefault;

import '../problems.dart' show unsupported;

enum ConstnessEffect {
  decidedNew,
  allowedConst,
  taintedConst,
}

enum ConstantKind {
  nullConstant,
  boolConstant,
  intConstant,
  doubleConstant,
  stringConstant,
  symbolConstant,
  typeConstant,
  listConstant,
  mapConstant,
  interfaceConstant,
}

class ConstnessInfo {
  final ConstnessEffect effect;
  final ConstantKind kind;
  final Map<Reference, ConstnessInfo> fields;

  // TODO(dmitryas): Find a way to impose the following restrictions:
  //   * `kind == null || effect != ConstnessEffect.decidedNew`
  //   * `fields == null || kind == ConstantKind.interfaceConstant`.
  const ConstnessInfo(this.effect, [this.kind, this.fields]);

  const ConstnessInfo.decidedNew()
      : this(ConstnessEffect.decidedNew, null, null);

  const ConstnessInfo.allowedConst(ConstantKind kind,
      [Map<Reference, ConstnessInfo> fields])
      : this(ConstnessEffect.allowedConst, kind, fields);

  const ConstnessInfo.taintedConst(ConstantKind kind,
      [Map<Reference, ConstnessInfo> fields])
      : this(ConstnessEffect.taintedConst, kind, fields);

  bool get isConst => effect != ConstnessEffect.decidedNew;

  bool get isPrimitiveConstant => kind != ConstantKind.interfaceConstant;

  bool get isInterfaceConstant => kind == ConstantKind.interfaceConstant;
}

/// Evaluates constness of the given constructor invocation.
///
/// TODO(dmitryas): Share code with the constant evaluator from
/// pkg/kernel/lib/transformations/constants.dart.
class ConstnessEvaluator implements ExpressionVisitor<ConstnessInfo> {
  final Map<Expression, ConstnessInfo> constnesses =
      <Expression, ConstnessInfo>{};

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

  ConstnessInfo evaluate(Expression node) {
    return node.accept(this);
  }

  List<ConstnessInfo> evaluateList(List<Expression> nodes) {
    List<ConstnessInfo> result = new List<ConstnessInfo>(nodes.length);
    for (int i = 0; i < nodes.length; ++i) {
      result[i] = nodes[i].accept(this);
    }
    return result;
  }

  @override
  visitNullLiteral(NullLiteral node) {
    return const ConstnessInfo.allowedConst(ConstantKind.nullConstant);
  }

  @override
  visitBoolLiteral(BoolLiteral node) {
    return const ConstnessInfo.allowedConst(ConstantKind.boolConstant);
  }

  @override
  visitIntLiteral(IntLiteral node) {
    return const ConstnessInfo.allowedConst(ConstantKind.intConstant);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    return const ConstnessInfo.allowedConst(ConstantKind.doubleConstant);
  }

  @override
  visitStringLiteral(StringLiteral node) {
    return const ConstnessInfo.allowedConst(ConstantKind.stringConstant);
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    return const ConstnessInfo.allowedConst(ConstantKind.symbolConstant);
  }

  @override
  visitTypeLiteral(TypeLiteral node) {
    return const ConstnessInfo.allowedConst(ConstantKind.typeConstant);
  }

  @override
  visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      return const ConstnessInfo.allowedConst(ConstantKind.listConstant);
    }
    return const ConstnessInfo.decidedNew();
  }

  @override
  visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      return const ConstnessInfo.allowedConst(ConstantKind.mapConstant);
    }
    return const ConstnessInfo.decidedNew();
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    if (constnesses[node] != null) return constnesses[node];

    if (!node.target.isConst) {
      return const ConstnessInfo.decidedNew();
    }

    List<ConstnessInfo> positionalArgumentsInfos =
        new List<ConstnessInfo>(node.arguments.positional.length);
    for (int i = 0; i < positionalArgumentsInfos.length; ++i) {
      positionalArgumentsInfos[i] = node.arguments.positional[i].accept(this);
    }

    Map<String, ConstnessInfo> namedArgumentsInfos = <String, ConstnessInfo>{};
    for (NamedExpression namedArgument in node.arguments.named) {
      namedArgumentsInfos[namedArgument.name] =
          namedArgument.value.accept(this);
    }

    ConstnessEffect resultEffect =
        minConstnessEffectOnInfos(positionalArgumentsInfos);
    if (resultEffect != null) {
      resultEffect = minConstnessEffectOnPair(
          resultEffect, minConstnessEffectOnInfos(namedArgumentsInfos.values));
    } else {
      resultEffect = minConstnessEffectOnInfos(namedArgumentsInfos.values);
    }
    resultEffect ??= ConstnessEffect.allowedConst;

    if (resultEffect == ConstnessEffect.decidedNew) {
      return const ConstnessInfo.decidedNew();
    }

    return constnesses[node] =
        new ConstnessInfo(resultEffect, ConstantKind.interfaceConstant);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    Expression receiver = node.receiver;
    ConstnessInfo receiverConstness = receiver.accept(this);
    List<ConstnessInfo> positionalArgumentConstness =
        new List<ConstnessInfo>(node.arguments.positional.length);
    for (int i = 0; i < positionalArgumentConstness.length; ++i) {
      positionalArgumentConstness[i] =
          node.arguments.positional[i].accept(this);
    }
    Map<String, ConstnessInfo> namedArgumentConstness =
        <String, ConstnessInfo>{};
    for (NamedExpression namedArgument in node.arguments.named) {
      namedArgumentConstness[namedArgument.name] =
          namedArgument.value.accept(this);
    }

    ConstnessEffect minimumConstnessEffect = receiverConstness.effect;
    minimumConstnessEffect = minConstnessEffectOnPair(minimumConstnessEffect,
        minConstnessEffectOnInfos(positionalArgumentConstness));
    minimumConstnessEffect = minConstnessEffectOnPair(minimumConstnessEffect,
        minConstnessEffectOnInfos(namedArgumentConstness.values));

    if (minimumConstnessEffect == ConstnessEffect.decidedNew) {
      return const ConstnessInfo.decidedNew();
    }

    // Special case: ==.
    if (node.name == equalsName) {
      assert(node.arguments.positional.length == 1);
      return new ConstnessInfo(
          minimumConstnessEffect, ConstantKind.boolConstant);
    }

    // Check for operations that are known to yield a constant value, like the
    // addition of two integer constants.
    if (node.arguments.named.length == 0) {
      List<ConstantKind> argumentsKinds =
          new List<ConstantKind>(positionalArgumentConstness.length);
      for (int i = 0; i < argumentsKinds.length; ++i) {
        argumentsKinds[i] = positionalArgumentConstness[i].kind;
      }
      ConstantKind resultKind = evaluateConstantMethodInvocationKind(
          receiverConstness.kind, node.name, argumentsKinds);
      if (resultKind != null) {
        return new ConstnessInfo(minimumConstnessEffect, resultKind);
      }
    }

    return const ConstnessInfo.decidedNew();
  }

  @override
  visitLogicalExpression(LogicalExpression node) {
    ConstnessInfo left = node.left.accept(this);
    if (node.operator == doubleBarName) {
      ConstnessInfo right = node.right.accept(this);
      if (left.isConst && right.isConst) {
        return new ConstnessInfo(
            minConstnessEffectOnPair(left.effect, right.effect),
            ConstantKind.boolConstant);
      }
      // TODO(dmitryas): Handle the case where [left] is `true`.
    } else if (node.operator == doubleAmpersandName) {
      ConstnessInfo right = node.right.accept(this);
      if (left.isConst && right.isConst) {
        return new ConstnessInfo(
            minConstnessEffectOnPair(left.effect, right.effect),
            ConstantKind.boolConstant);
      }
      // TODO(dmitryas): Handle the case when [left] is `false`.
    } else if (node.operator == doubleQuestionName) {
      ConstnessInfo right = node.right.accept(this);
      if (left.isConst && left.kind == ConstantKind.nullConstant) {
        if (right.isConst) {
          return right;
        }
      } else {
        if (left.isConst) {
          return left;
        }
      }
    }
    return const ConstnessInfo.decidedNew();
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    // TODO(dmitryas): Handle this case after boolean constants are handled.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    // TODO(dmitryas): Handle this case after fields are handled.
    ConstnessInfo receiverInfo = node.receiver.accept(this);
    if (receiverInfo.isConst &&
        receiverInfo.kind == ConstantKind.stringConstant) {
      return new ConstnessInfo(receiverInfo.effect, ConstantKind.intConstant);
    }
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitLet(Let node) {
    return node.body.accept(this);
  }

  @override
  visitVariableGet(VariableGet node) {
    if (!node.variable.isConst) return const ConstnessInfo.decidedNew();
    // TODO(dmitryas): Handle the case of recursive dependencies.
    return node.variable.initializer.accept(this);
  }

  @override
  visitStaticGet(StaticGet node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    List<ConstnessInfo> infos =
        new List<ConstnessInfo>(node.expressions.length);
    bool isPrimitiveConstant = true;
    for (int i = 0; i < infos.length; ++i) {
      infos[i] = node.expressions[i].accept(this);
      isPrimitiveConstant = isPrimitiveConstant && infos[i].isPrimitiveConstant;
    }
    ConstnessEffect effect = minConstnessEffectOnInfos(infos);

    // Only primitive constants are allowed during const string interpolation.
    if (effect == ConstnessEffect.decidedNew || !isPrimitiveConstant) {
      return const ConstnessInfo.decidedNew();
    }

    return new ConstnessInfo(effect, ConstantKind.stringConstant);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    // TODO(dmitryas): Handle this case better.
    Member target = node.target;
    if (target.name == identicalName) {
      final TreeNode parent = target.parent;
      if (parent is Library && parent == coreTypes.coreLibrary) {
        assert(node.arguments.positional.length == 2);
        ConstnessEffect effect = minConstnessEffectOnPair(
            node.arguments.positional[0].accept(this).effect,
            node.arguments.positional[1].accept(this).effect);
        if (effect == ConstnessEffect.decidedNew) {
          return const ConstnessInfo.decidedNew();
        }
        return new ConstnessInfo(effect, ConstantKind.boolConstant);
      }
    }
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitAsExpression(AsExpression node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitNot(Not node) {
    return node.operand.accept(this);
  }

  @override
  visitInvalidExpression(InvalidExpression node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitVariableSet(VariableSet node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitPropertySet(PropertySet node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitStaticSet(StaticSet node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitIsExpression(IsExpression node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitThisExpression(ThisExpression node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitRethrow(Rethrow node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitThrow(Throw node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitAwaitExpression(AwaitExpression node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitConstantExpression(ConstantExpression node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitInstantiation(Instantiation node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitLoadLibrary(LoadLibrary node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitVectorCreation(VectorCreation node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitVectorGet(VectorGet node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitVectorSet(VectorSet node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitVectorCopy(VectorCopy node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  @override
  visitClosureCreation(ClosureCreation node) {
    // TODO(dmitryas): Handle this case.
    return const ConstnessInfo.taintedConst(null);
  }

  /// Tells the minimum constness effect assuming the following:
  ///   * [ConstnessEffect.allowedConst] > [ConstnessEffect.taintedConst]
  ///   * [ConstnessEffect.taintedConst] > [ConstnessEffect.decidedNew]
  static ConstnessEffect minConstnessEffectOnPair(
      ConstnessEffect x, ConstnessEffect y) {
    if (x == ConstnessEffect.decidedNew) {
      return x;
    }
    if (x == ConstnessEffect.allowedConst) {
      return y;
    }
    // x == ConstnessEffect.taintedConst.
    if (y == ConstnessEffect.decidedNew) {
      return y;
    }
    return x;
  }

  /// Calculates minimum constness effect in [effects] using
  /// [minConstnessEffectOnPair].  Returns null if [effects] is null or empty.
  static ConstnessEffect minConstnessEffect(Iterable<ConstnessEffect> effects) {
    if (effects == null || effects.isEmpty) return null;

    ConstnessEffect result = ConstnessEffect.allowedConst;
    for (ConstnessEffect effect in effects) {
      result = minConstnessEffectOnPair(result, effect);
    }
    return result;
  }

  /// Calculates minimum constness effect in [infos] using
  /// [minConstnessEffectOnPair].  Returns null if [infos] is null or empty.
  static ConstnessEffect minConstnessEffectOnInfos(
      Iterable<ConstnessInfo> infos) {
    if (infos == null || infos.isEmpty) return null;

    ConstnessEffect result = ConstnessEffect.allowedConst;
    for (ConstnessInfo info in infos) {
      result = minConstnessEffectOnPair(result, info.effect);
    }
    return result;
  }

  /// Returns null if `receiver.name(arguments)` is not a constant.
  static ConstantKind evaluateConstantMethodInvocationKind(
      ConstantKind receiver, Name name, List<ConstantKind> arguments) {
    if (receiver == ConstantKind.stringConstant) {
      if (arguments.length == 1) {
        if (arguments[0] == ConstantKind.stringConstant) {
          if (name == plusName) return ConstantKind.intConstant;
        }
      }
    } else if (receiver == ConstantKind.boolConstant) {
      if (arguments.length == 1) {
        if (name == negationName) return ConstantKind.boolConstant;
      } else if (arguments.length == 2) {
        // TODO(dmitryas): Figure out if `&&` and `||` can be methods.
      }
    } else if (receiver == ConstantKind.intConstant) {
      if (arguments.length == 0) {
        if (name == unaryMinusName) return ConstantKind.intConstant;
        if (name == tildaName) return ConstantKind.intConstant;
      } else if (arguments.length == 1) {
        if (arguments[0] == ConstantKind.intConstant) {
          if (name == barName) return ConstantKind.intConstant;
          if (name == ampersandName) return ConstantKind.intConstant;
          if (name == caretName) return ConstantKind.intConstant;
          if (name == leftShiftName) return ConstantKind.intConstant;
          if (name == rightShiftName) return ConstantKind.intConstant;
        }
        if (arguments[0] == ConstantKind.intConstant ||
            arguments[0] == ConstantKind.doubleConstant) {
          if (name == plusName) return arguments[0];
          if (name == minusName) return arguments[0];
          if (name == multiplyName) return arguments[0];
          if (name == divisionName) return arguments[0];
          if (name == mustacheName) return arguments[0];
          if (name == percentName) return arguments[0];
          if (name == lessThanName) return ConstantKind.boolConstant;
          if (name == lessThanOrEqualsName) return ConstantKind.boolConstant;
          if (name == greaterThanOrEqualsName) return ConstantKind.boolConstant;
          if (name == greaterThanName) return ConstantKind.boolConstant;
        }
      }
    } else if (receiver == ConstantKind.doubleConstant) {
      if (arguments.length == 0) {
        if (name == unaryMinusName) return ConstantKind.doubleConstant;
      } else if (arguments.length == 1) {
        if (arguments[0] == ConstantKind.intConstant ||
            arguments[0] == ConstantKind.doubleConstant) {
          if (name == plusName) return ConstantKind.doubleConstant;
          if (name == minusName) return ConstantKind.doubleConstant;
          if (name == multiplyName) return ConstantKind.doubleConstant;
          if (name == divisionName) return ConstantKind.doubleConstant;
          if (name == mustacheName) return ConstantKind.doubleConstant;
          if (name == percentName) return ConstantKind.doubleConstant;
          if (name == lessThanName) return ConstantKind.boolConstant;
          if (name == lessThanOrEqualsName) return ConstantKind.boolConstant;
          if (name == greaterThanOrEqualsName) return ConstantKind.boolConstant;
          if (name == greaterThanName) return ConstantKind.boolConstant;
        }
      }
    }

    return null;
  }
}

// TODO(32717): Remove this helper function when the issue is resolved.
ConstnessInfo evaluateConstness(
    Expression expression, CoreTypes coreTypes, Uri uri) {
  return new ConstnessEvaluator(coreTypes, uri).evaluate(expression);
}
