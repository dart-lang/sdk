// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/names.dart';
import '../compiler.dart';
import '../constants/expressions.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../kernel/kernel.dart';
import '../kernel/kernel_debug.dart';
import '../kernel/kernel_visitor.dart';
import '../resolution/registry.dart' show ResolutionWorldImpactBuilder;
import '../universe/call_structure.dart';
import '../universe/feature.dart';
import '../universe/selector.dart';
import '../universe/use.dart';

import 'kernel_ast_adapter.dart';
import '../common/resolution.dart';

/// Computes the [ResolutionImpact] for [resolvedAst] through kernel.
ResolutionImpact build(Compiler compiler, ResolvedAst resolvedAst) {
  AstElement element = resolvedAst.element;
  JavaScriptBackend backend = compiler.backend;
  Kernel kernel = backend.kernelTask.kernel;
  KernelImpactBuilder builder =
      new KernelImpactBuilder(resolvedAst, compiler, kernel);
  if (element.isFunction ||
      element.isGetter ||
      element.isSetter ||
      element.isFactoryConstructor) {
    ir.Procedure function = kernel.functions[element];
    if (function == null) {
      throw "FOUND NULL FUNCTION: $element";
    } else {
      return builder.buildProcedure(function);
    }
  } else if (element.isGenerativeConstructor) {
    ir.Constructor constructor = kernel.functions[element];
    if (constructor == null) {
      throw "FOUND NULL CONSTRUCTOR: $element";
    } else {
      return builder.buildConstructor(constructor);
    }
  } else if (element.isField) {
    ir.Field field = kernel.fields[element];
    if (field == null) {
      throw "FOUND NULL FIELD: $element";
    } else {
      return builder.buildField(field);
    }
  } else {
    throw new UnsupportedError("Unsupported element: $element");
  }
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

  /// Add checked-mode type use for the parameter type and constant for the
  /// default value of [parameter].
  void handleParameter(ir.VariableDeclaration parameter) {
    checkType(parameter.type);
    visitNode(parameter.initializer);
  }

  /// Add checked-mode type use for parameter and return types, and add
  /// constants for default values.
  void handleSignature(ir.FunctionNode node, {bool checkReturnType: true}) {
    if (checkReturnType) {
      checkType(node.returnType);
    }
    node.positionalParameters.forEach(handleParameter);
    node.namedParameters.forEach(handleParameter);
  }

  ResolutionImpact buildField(ir.Field field) {
    checkType(field.type);
    if (field.initializer != null) {
      visitNode(field.initializer);
      if (!field.isConst) {
        impactBuilder.registerFeature(Feature.LAZY_FIELD);
      }
    } else {
      impactBuilder.registerFeature(Feature.FIELD_WITHOUT_INITIALIZER);
    }
    return impactBuilder;
  }

  ResolutionImpact buildConstructor(ir.Constructor constructor) {
    handleSignature(constructor.function, checkReturnType: false);
    visitNodes(constructor.initializers);
    visitNode(constructor.function.body);
    return impactBuilder;
  }

  ResolutionImpact buildProcedure(ir.Procedure procedure) {
    handleSignature(procedure.function);
    visitNode(procedure.function.body);
    switch (procedure.function.asyncMarker) {
      case ir.AsyncMarker.Sync:
        break;
      case ir.AsyncMarker.SyncStar:
        impactBuilder.registerFeature(Feature.SYNC_STAR);
        break;
      case ir.AsyncMarker.Async:
        impactBuilder.registerFeature(Feature.ASYNC);
        break;
      case ir.AsyncMarker.AsyncStar:
        impactBuilder.registerFeature(Feature.ASYNC_STAR);
        break;
      case ir.AsyncMarker.SyncYielding:
        compiler.reporter.internalError(resolvedAst.element,
            "Unexpected async marker: ${procedure.function.asyncMarker}");
    }
    return impactBuilder;
  }

  void visitNode(ir.Node node) => node?.accept(this);

  void visitNodes(Iterable<ir.Node> nodes) {
    nodes.forEach(visitNode);
  }

  @override
  void visitBlock(ir.Block block) => visitNodes(block.statements);

  @override
  void visitExpressionStatement(ir.ExpressionStatement exprStatement) {
    visitNode(exprStatement.expression);
  }

  @override
  void visitReturnStatement(ir.ReturnStatement returnStatement) {
    visitNode(returnStatement.expression);
  }

  @override
  void visitIfStatement(ir.IfStatement ifStatement) {
    visitNode(ifStatement.condition);
    visitNode(ifStatement.then);
    visitNode(ifStatement.otherwise);
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
    visitNode(entry.key);
    visitNode(entry.value);
  }

  void _visitArguments(ir.Arguments arguments) {
    arguments.positional.forEach(visitNode);
    arguments.named.forEach(visitNode);
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation node) {
    handleNew(node, node.target, isConst: node.isConst);
  }

  void handleNew(ir.InvocationExpression node, ir.Member target,
      {bool isConst: false}) {
    _visitArguments(node.arguments);
    Element element = astAdapter.getElement(target).declaration;
    ClassElement cls = astAdapter.getElement(target.enclosingClass);
    List<DartType> typeArguments =
        astAdapter.getDartTypes(node.arguments.types);
    InterfaceType type = new InterfaceType(cls, typeArguments);
    CallStructure callStructure = astAdapter.getCallStructure(node.arguments);
    impactBuilder.registerStaticUse(isConst
        ? new StaticUse.constConstructorInvoke(element, callStructure, type)
        : new StaticUse.typedConstructorInvoke(element, callStructure, type));
    if (typeArguments.any((DartType type) => !type.isDynamic)) {
      impactBuilder.registerFeature(Feature.TYPE_VARIABLE_BOUNDS_CHECK);
    }
  }

  @override
  void visitSuperInitializer(ir.SuperInitializer node) {
    Element target = astAdapter.getElement(node.target).declaration;
    _visitArguments(node.arguments);
    impactBuilder.registerStaticUse(new StaticUse.superConstructorInvoke(
        target, astAdapter.getCallStructure(node.arguments)));
  }

  @override
  void visitStaticInvocation(ir.StaticInvocation node) {
    Element target = astAdapter.getElement(node.target).declaration;
    if (target.isFactoryConstructor) {
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
      handleNew(node, node.target);
    } else {
      _visitArguments(node.arguments);
      impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
          target, astAdapter.getCallStructure(node.arguments)));
    }
  }

  @override
  void visitStaticGet(ir.StaticGet node) {
    ir.Member target = node.target;
    Element element = astAdapter.getElement(target).declaration;
    if (target is ir.Procedure && target.kind == ir.ProcedureKind.Method) {
      impactBuilder.registerStaticUse(new StaticUse.staticTearOff(element));
    } else {
      impactBuilder.registerStaticUse(new StaticUse.staticGet(element));
    }
  }

  @override
  void visitStaticSet(ir.StaticSet node) {
    visitNode(node.value);
    Element element = astAdapter.getElement(node.target).declaration;
    impactBuilder.registerStaticUse(new StaticUse.staticSet(element));
  }

  @override
  void visitMethodInvocation(ir.MethodInvocation invocation) {
    var receiver = invocation.receiver;
    if (receiver is ir.VariableGet &&
        receiver.variable.isFinal &&
        receiver.variable.parent is ir.FunctionDeclaration) {
      // Invocation of a local function. No need for dynamic use.
    } else {
      visitNode(invocation.receiver);
      impactBuilder.registerDynamicUse(
          new DynamicUse(astAdapter.getSelector(invocation), null));
    }
    _visitArguments(invocation.arguments);
  }

  @override
  void visitPropertyGet(ir.PropertyGet node) {
    visitNode(node.receiver);
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.getter(astAdapter.getName(node.name)), null));
  }

  @override
  void visitPropertySet(ir.PropertySet node) {
    visitNode(node.receiver);
    visitNode(node.value);
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.setter(astAdapter.getName(node.name)), null));
  }

  @override
  void visitAssertStatement(ir.AssertStatement node) {
    impactBuilder.registerFeature(
        node.message != null ? Feature.ASSERT_WITH_MESSAGE : Feature.ASSERT);
    visitNode(node.condition);
    visitNode(node.message);
  }

  @override
  void visitStringConcatenation(ir.StringConcatenation node) {
    impactBuilder.registerFeature(Feature.STRING_INTERPOLATION);
    impactBuilder.registerFeature(Feature.STRING_JUXTAPOSITION);
    visitNodes(node.expressions);
  }

  @override
  void visitFunctionDeclaration(ir.FunctionDeclaration node) {
    impactBuilder
        .registerStaticUse(new StaticUse.closure(astAdapter.getElement(node)));
    handleSignature(node.function);
    visitNode(node.function.body);
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression node) {
    impactBuilder
        .registerStaticUse(new StaticUse.closure(astAdapter.getElement(node)));
    handleSignature(node.function);
    visitNode(node.function.body);
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration node) {
    checkType(node.type);
    if (node.initializer != null) {
      visitNode(node.initializer);
    } else {
      impactBuilder.registerFeature(Feature.LOCAL_WITHOUT_INITIALIZER);
    }
  }

  @override
  void visitIsExpression(ir.IsExpression node) {
    impactBuilder.registerTypeUse(
        new TypeUse.isCheck(astAdapter.getDartType(node.type)));
  }

  @override
  void visitAsExpression(ir.AsExpression node) {
    impactBuilder
        .registerTypeUse(new TypeUse.asCast(astAdapter.getDartType(node.type)));
  }

  @override
  void visitThrow(ir.Throw node) {
    impactBuilder.registerFeature(Feature.THROW_EXPRESSION);
    visitNode(node.expression);
  }

  @override
  void visitForInStatement(ir.ForInStatement node) {
    visitNode(node.variable);
    visitNode(node.iterable);
    visitNode(node.body);
    if (node.isAsync) {
      impactBuilder.registerFeature(Feature.ASYNC_FOR_IN);
    } else {
      impactBuilder.registerFeature(Feature.SYNC_FOR_IN);
      impactBuilder
          .registerDynamicUse(new DynamicUse(Selectors.iterator, null));
    }
    impactBuilder.registerDynamicUse(new DynamicUse(Selectors.current, null));
    impactBuilder.registerDynamicUse(new DynamicUse(Selectors.moveNext, null));
  }

  @override
  void visitTryCatch(ir.TryCatch node) {
    visitNode(node.body);
    visitNodes(node.catches);
  }

  @override
  void visitCatch(ir.Catch node) {
    impactBuilder.registerFeature(Feature.CATCH_STATEMENT);
    visitNode(node.exception);
    if (node.stackTrace != null) {
      impactBuilder.registerFeature(Feature.STACK_TRACE_IN_CATCH);
    }
    if (node.guard is! ir.DynamicType) {
      impactBuilder.registerTypeUse(
          new TypeUse.catchType(astAdapter.getDartType(node.guard)));
    }
    visitNode(node.body);
  }

  @override
  void visitTryFinally(ir.TryFinally node) {
    visitNode(node.body);
    visitNode(node.finalizer);
  }

  // TODO(johnniwinther): Make this throw and visit child nodes explicitly
  // instead to ensure that we don't visit unwanted parts of the ir.
  @override
  void defaultNode(ir.Node node) => node.visitChildren(this);
}
