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
import '../kernel/kernel_debug.dart';
import '../kernel/kernel_visitor.dart';
import '../resolution/registry.dart' show ResolutionWorldImpactBuilder;
import '../universe/feature.dart';
import '../universe/selector.dart';
import '../universe/use.dart';

import 'kernel_ast_adapter.dart';
import '../common/resolution.dart';

/// Computes the [ResolutionImpact] for [resolvedAst] through kernel.
ResolutionImpact build(Compiler compiler, ResolvedAst resolvedAst) {
  AstElement element = resolvedAst.element.implementation;
  JavaScriptBackend backend = compiler.backend;
  Kernel kernel = backend.kernelTask.kernel;
  KernelImpactBuilder builder =
      new KernelImpactBuilder(resolvedAst, compiler, kernel);
  if (element.isFunction) {
    ir.Procedure function = kernel.functions[element];
    if (function == null) {
      print("FOUND NULL FUNCTION: $element");
    } else {
      return builder.buildProcedure(function);
    }
  } else {
    ir.Field field = kernel.fields[element];
    if (field == null) {
      print("FOUND NULL FUNCTION: $element");
    } else {
      return builder.buildField(field);
    }
  }
  return null;
}

class KernelImpactBuilder extends ir.Visitor {
  final ResolvedAst resolvedAst;
  final Compiler compiler;

  JavaScriptBackend get backend => compiler.backend;

  ResolutionWorldImpactBuilder impactBuilder;
  KernelAstAdapter astAdapter;

  KernelImpactBuilder(this.resolvedAst, this.compiler, Kernel kernel) {
    this.impactBuilder =
        new ResolutionWorldImpactBuilder('${resolvedAst.element}');
    this.astAdapter = new KernelAstAdapter(kernel, compiler.backend,
        resolvedAst, kernel.nodeToAst, kernel.nodeToElement);
  }

  /// Add a checked-mode type use of [type] if it is not `dynamic`.
  DartType checkType(ir.DartType irType) {
    DartType type = astAdapter.getDartType(irType);
    if (!type.isDynamic) {
      impactBuilder.registerTypeUse(new TypeUse.checkedModeCheck(type));
    }
    return type;
  }

  ResolutionImpact buildField(ir.Field field) {
    checkType(field.type);
    if (field.initializer != null) {
      field.initializer.accept(this);
    } else {
      impactBuilder.registerFeature(Feature.FIELD_WITHOUT_INITIALIZER);
    }
    return impactBuilder;
  }

  ResolutionImpact buildProcedure(ir.Procedure procedure) {
    if (procedure.kind == ir.ProcedureKind.Method ||
        procedure.kind == ir.ProcedureKind.Operator) {
      checkType(procedure.function.returnType);
      procedure.function.positionalParameters.forEach((v) => checkType(v.type));
      procedure.function.namedParameters.forEach((v) => checkType(v.type));
      procedure.function.body.accept(this);
    } else {
      compiler.reporter.internalError(
          resolvedAst.element,
          "Unable to compute resolution impact for this kind of Kernel "
          "procedure: ${procedure.kind}");
    }
    return impactBuilder;
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
    DartType elementType = checkType(literal.typeArgument);

    impactBuilder.registerListLiteral(new ListLiteralUse(
        compiler.coreTypes.listType(elementType),
        isConstant: literal.isConst,
        isEmpty: literal.expressions.isEmpty));
  }

  @override
  void visitMapLiteral(ir.MapLiteral literal) {
    visitNodes(literal.entries);
    DartType keyType = checkType(literal.keyType);
    DartType valueType = checkType(literal.valueType);
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
    if (target.isFactoryConstructor) {
      impactBuilder.registerStaticUse(new StaticUse.constructorInvoke(
          target, astAdapter.getCallStructure(invocation.arguments)));
      // TODO(johnniwinther): We should not mark the type as instantiated but
      // rather follow the type arguments directly.
      //
      // Consider this:
      //
      //    abstract class A<T> {
      //      factory A.regular() => new B<T>();
      //      factory A.redirect() = B<T>;
      //    }
      //
      //    class B<T> implements A<T> {}
      //
      //    main() {
      //      print(new A<int>.regular() is B<int>);
      //      print(new A<String>.redirect() is B<String>);
      //    }
      //
      // To track that B is actually instantiated as B<int> and B<String> we
      // need to follow the type arguments passed to A.regular and A.redirect
      // to B. Currently, we only do this soundly if we register A<int> and
      // A<String> as instantiated. We should instead register that A.T is
      // instantiated as int and String.
      ClassElement cls =
          astAdapter.getElement(invocation.target.enclosingClass);
      List<DartType> typeArguments =
          astAdapter.getDartTypes(invocation.arguments.types);
      impactBuilder.registerTypeUse(
          new TypeUse.instantiation(new InterfaceType(cls, typeArguments)));
      if (typeArguments.any((DartType type) => !type.isDynamic)) {
        impactBuilder.registerFeature(Feature.TYPE_VARIABLE_BOUNDS_CHECK);
      }
    } else {
      impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
          target, astAdapter.getCallStructure(invocation.arguments)));
    }
  }

  @override
  void visitStaticGet(ir.StaticGet node) {
    Element target = astAdapter.getElement(node.target).declaration;
    impactBuilder.registerStaticUse(new StaticUse.staticGet(target));
  }

  @override
  void visitMethodInvocation(ir.MethodInvocation invocation) {
    invocation.receiver.accept(this);
    _visitArguments(invocation.arguments);
    impactBuilder.registerDynamicUse(
        new DynamicUse(astAdapter.getSelector(invocation), null));
  }

  @override
  void visitPropertyGet(ir.PropertyGet node) {
    node.receiver.accept(this);
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.getter(astAdapter.getName(node.name)), null));
  }

  @override
  void visitPropertySet(ir.PropertySet node) {
    node.receiver.accept(this);
    node.value.accept(this);
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.setter(astAdapter.getName(node.name)), null));
  }

  @override
  void visitNot(ir.Not not) {
    not.operand.accept(this);
  }

  @override
  void visitAssertStatement(ir.AssertStatement node) {
    impactBuilder.registerFeature(
        node.message != null ? Feature.ASSERT_WITH_MESSAGE : Feature.ASSERT);
    node.visitChildren(this);
  }

  @override
  void defaultNode(ir.Node node) => node.visitChildren(this);
}
