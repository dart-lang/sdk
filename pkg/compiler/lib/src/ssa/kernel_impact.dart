// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/names.dart';
import '../common/resolution.dart';
import '../common_elements.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../kernel/element_map.dart';
import '../resolution/registry.dart' show ResolutionWorldImpactBuilder;
import '../universe/call_structure.dart';
import '../universe/feature.dart';
import '../universe/selector.dart';
import '../universe/use.dart';

ResolutionImpact buildKernelImpact(ir.Member member,
    KernelToElementMapForImpact elementMap, DiagnosticReporter reporter) {
  KernelImpactBuilder builder = new KernelImpactBuilder(
      elementMap, elementMap.getMember(member), reporter);
  if (member is ir.Procedure) {
    return builder.buildProcedure(member);
  } else if (member is ir.Constructor) {
    return builder.buildConstructor(member);
  } else if (member is ir.Field) {
    return builder.buildField(member);
  }
  throw new UnsupportedError("Unsupported member: $member");
}

class KernelImpactBuilder extends ir.Visitor {
  final ResolutionWorldImpactBuilder impactBuilder;
  final KernelToElementMapForImpact elementMap;
  final DiagnosticReporter reporter;
  final MemberEntity currentMember;
  _ClassEnsurer classEnsurer;

  KernelImpactBuilder(this.elementMap, this.currentMember, this.reporter)
      : this.impactBuilder =
            new ResolutionWorldImpactBuilder('${currentMember.name}') {
    this.classEnsurer = new _ClassEnsurer(this);
  }

  CommonElements get commonElements => elementMap.commonElements;

  /// Add a checked-mode type use of [type] if it is not `dynamic`.
  DartType checkType(ir.DartType irType) {
    DartType type = elementMap.getDartType(irType);
    if (!type.isDynamic) {
      impactBuilder.registerTypeUse(new TypeUse.checkedModeCheck(type));
    }
    return type;
  }

  void registerSeenClasses(ir.DartType irType) {
    DartType type = elementMap.getDartType(irType);
    classEnsurer.ensureClassesInType(type);
  }

  /// Add checked-mode type use for the parameter type and constant for the
  /// default value of [parameter].
  void handleParameter(ir.VariableDeclaration parameter) {
    checkType(parameter.type);
    registerSeenClasses(parameter.type);
    visitNode(parameter.initializer);
  }

  /// Add checked-mode type use for parameter and return types, and add
  /// constants for default values.
  void handleSignature(ir.FunctionNode node, {bool checkReturnType: true}) {
    if (checkReturnType) {
      checkType(node.returnType);
    }
    registerSeenClasses(node.returnType);
    node.positionalParameters.forEach(handleParameter);
    node.namedParameters.forEach(handleParameter);
  }

  ResolutionImpact buildField(ir.Field field) {
    checkType(field.type);
    registerSeenClasses(field.type);
    if (field.initializer != null) {
      visitNode(field.initializer);
      if (!field.isInstanceMember &&
          !field.isConst &&
          field.initializer is! ir.NullLiteral) {
        impactBuilder.registerFeature(Feature.LAZY_FIELD);
      }
    } else {
      impactBuilder.registerConstantLiteral(new NullConstantExpression());
    }

    if (field.isInstanceMember &&
        elementMap.isNativeClass(field.enclosingClass)) {
      MemberEntity member = elementMap.getMember(field);
      bool isJsInterop = elementMap.nativeBasicData.isJsInteropMember(member);
      impactBuilder.registerNativeData(elementMap
          .getNativeBehaviorForFieldLoad(field, isJsInterop: isJsInterop));
      impactBuilder
          .registerNativeData(elementMap.getNativeBehaviorForFieldStore(field));
    }
    return impactBuilder;
  }

  ResolutionImpact buildConstructor(ir.Constructor constructor) {
    handleSignature(constructor.function, checkReturnType: false);
    visitNodes(constructor.initializers);
    visitNode(constructor.function.body);
    if (constructor.isExternal &&
        !elementMap.isForeignLibrary(constructor.enclosingLibrary)) {
      MemberEntity member = elementMap.getMember(constructor);
      bool isJsInterop = elementMap.nativeBasicData.isJsInteropMember(member);
      impactBuilder.registerNativeData(elementMap
          .getNativeBehaviorForMethod(constructor, isJsInterop: isJsInterop));
    }
    return impactBuilder;
  }

  void handleAsyncMarker(ir.AsyncMarker asyncMarker) {
    switch (asyncMarker) {
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
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "Unexpected async marker: ${asyncMarker}");
    }
  }

  ResolutionImpact buildProcedure(ir.Procedure procedure) {
    handleSignature(procedure.function);
    visitNode(procedure.function.body);
    handleAsyncMarker(procedure.function.asyncMarker);
    if (procedure.isExternal &&
        !elementMap.isForeignLibrary(procedure.enclosingLibrary)) {
      MemberEntity member = elementMap.getMember(procedure);
      bool isJsInterop = elementMap.nativeBasicData.isJsInteropMember(member);
      impactBuilder.registerNativeData(elementMap
          .getNativeBehaviorForMethod(procedure, isJsInterop: isJsInterop));
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
    registerSeenClasses(literal.typeArgument);

    impactBuilder.registerListLiteral(new ListLiteralUse(
        commonElements.listType(elementType),
        isConstant: literal.isConst,
        isEmpty: literal.expressions.isEmpty));
  }

  @override
  void visitMapLiteral(ir.MapLiteral literal) {
    visitNodes(literal.entries);
    DartType keyType = checkType(literal.keyType);
    DartType valueType = checkType(literal.valueType);
    registerSeenClasses(literal.keyType);
    registerSeenClasses(literal.valueType);
    impactBuilder.registerMapLiteral(new MapLiteralUse(
        commonElements.mapType(keyType, valueType),
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
    ConstructorEntity constructor = elementMap.getConstructor(target);
    if (commonElements.isSymbolConstructor(constructor)) {
      impactBuilder.registerFeature(Feature.SYMBOL_CONSTRUCTOR);
    }

    if (target.isExternal &&
        constructor.isFromEnvironmentConstructor &&
        !isConst) {
      impactBuilder.registerFeature(Feature.THROW_UNSUPPORTED_ERROR);
      return;
    }

    InterfaceType type = elementMap.createInterfaceType(
        target.enclosingClass, node.arguments.types);
    classEnsurer.ensureClassesInType(type);
    CallStructure callStructure = elementMap.getCallStructure(node.arguments);
    impactBuilder.registerStaticUse(isConst
        ? new StaticUse.constConstructorInvoke(constructor, callStructure, type)
        : new StaticUse.typedConstructorInvoke(
            constructor, callStructure, type));
    if (type.typeArguments.any((DartType type) => !type.isDynamic)) {
      impactBuilder.registerFeature(Feature.TYPE_VARIABLE_BOUNDS_CHECK);
    }
    if (isConst && commonElements.isSymbolConstructor(constructor)) {
      ConstantValue value =
          elementMap.getConstantValue(node.arguments.positional.first);
      if (!value.isString) {
        // TODO(het): Get the actual span for the Symbol constructor argument
        reporter.reportErrorMessage(
            CURRENT_ELEMENT_SPANNABLE,
            MessageKind.STRING_EXPECTED,
            {'type': value.getType(elementMap.commonElements)});
        return;
      }
      StringConstantValue stringValue = value;
      impactBuilder.registerConstSymbolName(stringValue.primitiveValue);
    }
  }

  @override
  void visitSuperInitializer(ir.SuperInitializer node) {
    // TODO(johnniwinther): Maybe rewrite `node.target` to point to a
    // synthesized unnamed mixin constructor when needed. This would require us
    // to consider impact building a required pre-step for inference and
    // ssa-building.
    ConstructorEntity target =
        elementMap.getSuperConstructor(node.parent, node.target);
    _visitArguments(node.arguments);
    impactBuilder.registerStaticUse(new StaticUse.superConstructorInvoke(
        target, elementMap.getCallStructure(node.arguments)));
  }

  @override
  void visitStaticInvocation(ir.StaticInvocation node) {
    if (node.target.kind == ir.ProcedureKind.Factory) {
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
      handleNew(node, node.target, isConst: node.isConst);
    } else {
      FunctionEntity target = elementMap.getMethod(node.target);
      _visitArguments(node.arguments);
      impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
          target, elementMap.getCallStructure(node.arguments)));
    }
    switch (elementMap.getForeignKind(node)) {
      case ForeignKind.JS:
        impactBuilder
            .registerNativeData(elementMap.getNativeBehaviorForJsCall(node));
        break;
      case ForeignKind.JS_BUILTIN:
        impactBuilder.registerNativeData(
            elementMap.getNativeBehaviorForJsBuiltinCall(node));
        break;
      case ForeignKind.JS_EMBEDDED_GLOBAL:
        impactBuilder.registerNativeData(
            elementMap.getNativeBehaviorForJsEmbeddedGlobalCall(node));
        break;
      case ForeignKind.JS_INTERCEPTOR_CONSTANT:
        InterfaceType type =
            elementMap.getInterfaceTypeForJsInterceptorCall(node);
        if (type != null) {
          impactBuilder.registerTypeUse(new TypeUse.instantiation(type));
        }
        break;
      case ForeignKind.NONE:
        break;
    }
  }

  @override
  void visitStaticGet(ir.StaticGet node) {
    ir.Member target = node.target;
    registerSeenClasses(target.getterType);
    if (target is ir.Procedure && target.kind == ir.ProcedureKind.Method) {
      FunctionEntity method = elementMap.getMethod(target);
      impactBuilder.registerStaticUse(new StaticUse.staticTearOff(method));
    } else {
      MemberEntity member = elementMap.getMember(target);
      impactBuilder.registerStaticUse(new StaticUse.staticGet(member));
    }
  }

  @override
  void visitStaticSet(ir.StaticSet node) {
    visitNode(node.value);
    MemberEntity member = elementMap.getMember(node.target);
    registerSeenClasses(node.target.setterType);
    impactBuilder.registerStaticUse(new StaticUse.staticSet(member));
  }

  void handleSuperInvocation(ir.Name name, ir.Node target, ir.Node arguments) {
    FunctionEntity method =
        elementMap.getSuperMember(currentMember, name, target, setter: false);
    _visitArguments(arguments);
    if (method != null) {
      impactBuilder.registerStaticUse(new StaticUse.superInvoke(
          method, elementMap.getCallStructure(arguments)));
    } else {
      impactBuilder.registerStaticUse(new StaticUse.superInvoke(
          elementMap.getSuperNoSuchMethod(currentMember.enclosingClass),
          CallStructure.ONE_ARG));
      impactBuilder.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
    }
  }

  @override
  void visitDirectMethodInvocation(ir.DirectMethodInvocation node) {
    _visitArguments(node.arguments);
    // TODO(johnniwinther): Restrict the dynamic use to only match the known
    // target.
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.call(elementMap.getMember(node.target).memberName,
            elementMap.getCallStructure(node.arguments)),
        null));
  }

  @override
  void visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    // TODO(johnniwinther): Should we support this or always use the
    // [MixinFullResolution] transformer?
    handleSuperInvocation(node.name, node.interfaceTarget, node.arguments);
  }

  void handleSuperGet(ir.Name name, ir.Member target) {
    MemberEntity member =
        elementMap.getSuperMember(currentMember, name, target, setter: false);
    if (member != null) {
      if (member.isFunction) {
        impactBuilder.registerStaticUse(new StaticUse.superTearOff(member));
      } else {
        impactBuilder.registerStaticUse(new StaticUse.superGet(member));
      }
    } else {
      impactBuilder.registerStaticUse(new StaticUse.superInvoke(
          elementMap.getSuperNoSuchMethod(currentMember.enclosingClass),
          CallStructure.ONE_ARG));
      impactBuilder.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
    }
  }

  @override
  void visitDirectPropertyGet(ir.DirectPropertyGet node) {
    // TODO(johnniwinther): Restrict the dynamic use to only match the known
    // target.
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.getter(elementMap.getMember(node.target).memberName),
        null));
  }

  @override
  void visitSuperPropertyGet(ir.SuperPropertyGet node) {
    handleSuperGet(node.name, node.interfaceTarget);
  }

  void handleSuperSet(ir.Name name, ir.Node target, ir.Node value) {
    visitNode(value);
    MemberEntity member =
        elementMap.getSuperMember(currentMember, name, target, setter: true);
    if (member != null) {
      if (member.isField) {
        impactBuilder.registerStaticUse(new StaticUse.superFieldSet(member));
      } else {
        impactBuilder.registerStaticUse(new StaticUse.superSetterSet(member));
      }
    } else {
      impactBuilder.registerStaticUse(new StaticUse.superInvoke(
          elementMap.getSuperNoSuchMethod(currentMember.enclosingClass),
          CallStructure.ONE_ARG));
      impactBuilder.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
    }
  }

  @override
  void visitDirectPropertySet(ir.DirectPropertySet node) {
    visitNode(node.value);
    // TODO(johnniwinther): Restrict the dynamic use to only match the known
    // target.
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.setter(elementMap.getMember(node.target).memberName),
        null));
  }

  @override
  void visitSuperPropertySet(ir.SuperPropertySet node) {
    handleSuperSet(node.name, node.interfaceTarget, node.value);
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
          new DynamicUse(elementMap.getSelector(invocation), null));
    }
    _visitArguments(invocation.arguments);
  }

  @override
  void visitPropertyGet(ir.PropertyGet node) {
    visitNode(node.receiver);
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.getter(elementMap.getName(node.name)), null));
  }

  @override
  void visitPropertySet(ir.PropertySet node) {
    visitNode(node.receiver);
    visitNode(node.value);
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.setter(elementMap.getName(node.name)), null));
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
    impactBuilder.registerStaticUse(
        new StaticUse.closure(elementMap.getLocalFunction(node)));
    handleSignature(node.function);
    handleAsyncMarker(node.function.asyncMarker);
    visitNode(node.function.body);
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression node) {
    impactBuilder.registerStaticUse(
        new StaticUse.closure(elementMap.getLocalFunction(node)));
    handleSignature(node.function);
    handleAsyncMarker(node.function.asyncMarker);
    visitNode(node.function.body);
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration node) {
    checkType(node.type);
    registerSeenClasses(node.type);
    if (node.initializer != null) {
      visitNode(node.initializer);
    } else {
      impactBuilder.registerFeature(Feature.LOCAL_WITHOUT_INITIALIZER);
    }
  }

  @override
  void visitIsExpression(ir.IsExpression node) {
    impactBuilder.registerTypeUse(
        new TypeUse.isCheck(elementMap.getDartType(node.type)));
    registerSeenClasses(node.type);
    visitNode(node.operand);
  }

  @override
  void visitAsExpression(ir.AsExpression node) {
    impactBuilder
        .registerTypeUse(new TypeUse.asCast(elementMap.getDartType(node.type)));
    registerSeenClasses(node.type);
    visitNode(node.operand);
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
    if (node.stackTrace != null) {
      impactBuilder.registerFeature(Feature.STACK_TRACE_IN_CATCH);
    }
    if (node.guard is! ir.DynamicType) {
      impactBuilder.registerTypeUse(
          new TypeUse.catchType(elementMap.getDartType(node.guard)));
    }
    visitNode(node.body);
  }

  @override
  void visitTryFinally(ir.TryFinally node) {
    visitNode(node.body);
    visitNode(node.finalizer);
  }

  @override
  void visitTypeLiteral(ir.TypeLiteral node) {
    impactBuilder.registerTypeUse(
        new TypeUse.typeLiteral(elementMap.getDartType(node.type)));
  }

  @override
  void visitFieldInitializer(ir.FieldInitializer node) {
    impactBuilder.registerStaticUse(
        new StaticUse.fieldInit(elementMap.getField(node.field)));
    visitNode(node.value);
  }

  @override
  void visitRedirectingInitializer(ir.RedirectingInitializer node) {
    _visitArguments(node.arguments);
    ConstructorEntity target = elementMap.getConstructor(node.target);
    impactBuilder.registerStaticUse(new StaticUse.superConstructorInvoke(
        target, elementMap.getCallStructure(node.arguments)));
  }

  // TODO(johnniwinther): Make this throw and visit child nodes explicitly
  // instead to ensure that we don't visit unwanted parts of the ir.
  @override
  void defaultNode(ir.Node node) => node.visitChildren(this);
}

class _ClassEnsurer extends BaseDartTypeVisitor<dynamic, Null> {
  final KernelImpactBuilder builder;

  _ClassEnsurer(this.builder);

  void ensureClassesInType(DartType type) {
    type.accept(this, null);
  }

  @override
  visitType(DartType type, _) {}

  @override
  visitFunctionType(FunctionType type, _) {
    type.returnType.accept(this, null);
    type.parameterTypes.forEach((t) {
      t.accept(this, null);
    });
    type.optionalParameterTypes.forEach((t) {
      t.accept(this, null);
    });
    type.namedParameterTypes.forEach((t) {
      t.accept(this, null);
    });
  }

  @override
  visitInterfaceType(InterfaceType type, _) {
    builder.impactBuilder.registerSeenClass(type.element);
    type.typeArguments.forEach((t) {
      t.accept(this, null);
    });
  }

  @override
  visitTypedefType(TypedefType type, _) {
    type.typeArguments.forEach((t) {
      t.accept(this, null);
    });
  }
}
