// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../compiler.dart';
import '../constants/expressions.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../kernel/kernel.dart';
import '../kernel/kernel_visitor.dart';
import '../resolution/registry.dart' show ResolutionWorldImpactBuilder;
import '../universe/feature.dart';
import '../universe/use.dart';

import 'kernel_ast_adapter.dart';
import '../common/resolution.dart';

/// Computes the [ResolutionImpact] for [resolvedAst] through kernel.
ResolutionImpact build(Compiler compiler, ResolvedAst resolvedAst) {
  AstElement element = resolvedAst.element.implementation;
  JavaScriptBackend backend = compiler.backend;
  Kernel kernel = backend.kernelTask.kernel;
  ir.Procedure function = kernel.functions[element];
  if (function == null) {
    print("FOUND NULL FUNCTION: $element");
    print(kernel.functions);
  }
  KernelImpactBuilder builder =
      new KernelImpactBuilder(function, element, resolvedAst, compiler, kernel);
  return builder.build();
}

class KernelImpactBuilder extends ir.Visitor {
  final ir.Procedure function;
  final FunctionElement functionElement;
  final ResolvedAst resolvedAst;
  final Compiler compiler;

  JavaScriptBackend get backend => compiler.backend;

  ResolutionWorldImpactBuilder impactBuilder;
  KernelAstAdapter astAdapter;

  KernelImpactBuilder(this.function, this.functionElement, this.resolvedAst,
      this.compiler, Kernel kernel) {
    this.impactBuilder = new ResolutionWorldImpactBuilder('$functionElement');
    this.astAdapter = new KernelAstAdapter(
        compiler.backend,
        resolvedAst,
        kernel.nodeToAst,
        kernel.nodeToElement,
        kernel.functions,
        kernel.classes,
        kernel.libraries);
  }

  ResolutionImpact build() {
    if (function.kind == ir.ProcedureKind.Method ||
        function.kind == ir.ProcedureKind.Operator) {
      buildMethod(function);
    } else {
      compiler.reporter.internalError(
          functionElement,
          "Unable to compute resolution impact for this kind of Kernel "
          "procedure: ${function.kind}");
    }
    return impactBuilder;
  }

  /// Add a checked-mode type use of [type] if it is not `dynamic`.
  DartType checkType(DartType type) {
    if (!type.isDynamic) {
      impactBuilder.registerTypeUse(new TypeUse.checkedModeCheck(type));
    }
    return type;
  }

  void buildMethod(ir.Procedure method) {
    method.function.body.accept(this);
  }

  void visitNodes(Iterable<ir.Node> nodes) {
    nodes.forEach((ir.Node node) => node.accept(this));
  }

  @override
  void visitBlock(ir.Block block) => visitNodes(block.statements);

  @override
  void visitExpressionStatement(ir.ExpressionStatement exprStatement) {
    exprStatement.expression.accept(this);
  }

  @override
  void visitReturnStatement(ir.ReturnStatement returnStatement) {
    returnStatement.expression?.accept(this);
  }

  @override
  void visitIfStatement(ir.IfStatement ifStatement) {
    ifStatement.condition.accept(this);
    ifStatement.then.accept(this);
    ifStatement.otherwise?.accept(this);
  }

  @override
  void visitIntLiteral(ir.IntLiteral literal) {
    impactBuilder
        .registerConstantLiteral(new IntConstantExpression(literal.value));
  }

  @override
  void visitDoubleLiteral(ir.DoubleLiteral literal) {
    impactBuilder
        .registerConstantLiteral(new DoubleConstantExpression(literal.value));
  }

  @override
  void visitBoolLiteral(ir.BoolLiteral literal) {
    impactBuilder
        .registerConstantLiteral(new BoolConstantExpression(literal.value));
  }

  @override
  void visitStringLiteral(ir.StringLiteral literal) {
    impactBuilder
        .registerConstantLiteral(new StringConstantExpression(literal.value));
  }

  @override
  void visitSymbolLiteral(ir.SymbolLiteral literal) {
    impactBuilder.registerConstSymbolName(literal.value);
  }

  @override
  void visitNullLiteral(ir.NullLiteral literal) {
    impactBuilder.registerConstantLiteral(new NullConstantExpression());
  }

  @override
  void visitListLiteral(ir.ListLiteral literal) {
    visitNodes(literal.expressions);
    DartType elementType =
        checkType(astAdapter.getDartType(literal.typeArgument));

    impactBuilder.registerListLiteral(new ListLiteralUse(
        compiler.coreTypes.listType(elementType),
        isConstant: literal.isConst,
        isEmpty: literal.expressions.isEmpty));
  }

  @override
  void visitMapLiteral(ir.MapLiteral literal) {
    visitNodes(literal.entries);
    DartType keyType = checkType(astAdapter.getDartType(literal.keyType));
    DartType valueType = checkType(astAdapter.getDartType(literal.valueType));
    impactBuilder.registerMapLiteral(new MapLiteralUse(
        compiler.coreTypes.mapType(keyType, valueType),
        isConstant: literal.isConst,
        isEmpty: literal.entries.isEmpty));
  }

  void visitMapEntry(ir.MapEntry entry) {
    entry.key.accept(this);
    entry.value.accept(this);
  }

  void _visitArguments(ir.Arguments arguments) {
    for (ir.Expression argument in arguments.positional) {
      argument.accept(this);
    }
    for (ir.NamedExpression argument in arguments.named) {
      argument.value.accept(this);
    }
  }

  @override
  void visitStaticInvocation(ir.StaticInvocation invocation) {
    _visitArguments(invocation.arguments);
    Element target = astAdapter.getElement(invocation.target).declaration;
    impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
        target, astAdapter.getCallStructure(invocation.arguments)));
  }

  @override
  void visitMethodInvocation(ir.MethodInvocation invocation) {
    invocation.receiver.accept(this);
    _visitArguments(invocation.arguments);
    impactBuilder.registerDynamicUse(
        new DynamicUse(astAdapter.getSelector(invocation), null));
  }

  @override
  void visitNot(ir.Not not) {
    not.operand.accept(this);
  }
}
