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
import '../options.dart';
import '../resolution/registry.dart' show ResolutionWorldImpactBuilder;
import '../universe/call_structure.dart';
import '../universe/feature.dart';
import '../universe/selector.dart';
import '../universe/use.dart';
import '../universe/world_builder.dart';

ResolutionImpact buildKernelImpact(
    ir.Member member,
    KernelToElementMapForImpact elementMap,
    DiagnosticReporter reporter,
    CompilerOptions options) {
  KernelImpactBuilder builder = new KernelImpactBuilder(
      elementMap, elementMap.getMember(member), reporter, options);
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
  final CompilerOptions _options;
  final MemberEntity currentMember;
  _ClassEnsurer classEnsurer;

  KernelImpactBuilder(
      this.elementMap, this.currentMember, this.reporter, this._options)
      : this.impactBuilder =
            new ResolutionWorldImpactBuilder('${currentMember.name}') {
    this.classEnsurer = new _ClassEnsurer(this, this.elementMap.types);
  }

  CommonElements get commonElements => elementMap.commonElements;

  /// Add a checked-mode type use of [type] if it is not `dynamic`.
  DartType checkType(ir.DartType irType, TypeUseKind kind) {
    DartType type = elementMap.getDartType(irType);
    if (kind != null && !type.isDynamic) {
      switch (kind) {
        case TypeUseKind.CHECKED_MODE_CHECK:
          if (!_options.strongMode) {
            impactBuilder.registerTypeUse(new TypeUse.checkedModeCheck(type));
          }
          break;
        case TypeUseKind.PARAMETER_CHECK:
          if (!_options.strongMode) {
            impactBuilder.registerTypeUse(new TypeUse.checkedModeCheck(type));
          } else {
            impactBuilder.registerTypeUse(new TypeUse.parameterCheck(type));
          }
          break;
        case TypeUseKind.IMPLICIT_CAST:
          impactBuilder.registerTypeUse(new TypeUse.implicitCast(type));
          break;
        default:
          throw new UnsupportedError("Unexpected type check kind: $kind");
      }
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
    checkType(parameter.type, TypeUseKind.PARAMETER_CHECK);
    registerSeenClasses(parameter.type);
    visitNode(parameter.initializer);
  }

  /// Add checked-mode type use for parameter and return types, and add
  /// constants for default values.
  void handleSignature(ir.FunctionNode node, {bool checkReturnType: true}) {
    if (checkReturnType) {
      checkType(node.returnType, TypeUseKind.CHECKED_MODE_CHECK);
    }
    registerSeenClasses(node.returnType);
    node.positionalParameters.forEach(handleParameter);
    node.namedParameters.forEach(handleParameter);
    if (_options.strongMode) {
      for (ir.TypeParameter parameter in node.typeParameters) {
        checkType(parameter.bound, TypeUseKind.PARAMETER_CHECK);
      }
    }
  }

  ResolutionImpact buildField(ir.Field field) {
    checkType(field.type, TypeUseKind.PARAMETER_CHECK);
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

  void handleAsyncMarker(ir.FunctionNode function) {
    ir.AsyncMarker asyncMarker = function.asyncMarker;
    if (asyncMarker == ir.AsyncMarker.Sync) return;

    DartType elementType =
        elementMap.getFunctionAsyncOrSyncStarElementType(function);

    switch (asyncMarker) {
      case ir.AsyncMarker.SyncStar:
        impactBuilder.registerFeature(Feature.SYNC_STAR);
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            commonElements.syncStarIterableFactory,
            const CallStructure.unnamed(1, 1),
            <DartType>[elementType]));
        break;

      case ir.AsyncMarker.Async:
        impactBuilder.registerFeature(Feature.ASYNC);
        var completerFactory = _options.startAsyncSynchronously
            ? commonElements.asyncAwaitCompleterFactory
            : commonElements.syncCompleterFactory;
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            completerFactory,
            const CallStructure.unnamed(0, 1),
            <DartType>[elementType]));
        break;

      case ir.AsyncMarker.AsyncStar:
        impactBuilder.registerFeature(Feature.ASYNC_STAR);
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            commonElements.asyncStarStreamControllerFactory,
            const CallStructure.unnamed(1, 1),
            <DartType>[elementType]));
        break;

      case ir.AsyncMarker.Sync:
      case ir.AsyncMarker.SyncYielding:
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "Unexpected async marker: ${asyncMarker}");
    }
  }

  ResolutionImpact buildProcedure(ir.Procedure procedure) {
    handleSignature(procedure.function);
    visitNode(procedure.function.body);
    handleAsyncMarker(procedure.function);
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
    DartType elementType =
        checkType(literal.typeArgument, TypeUseKind.CHECKED_MODE_CHECK);
    registerSeenClasses(literal.typeArgument);

    impactBuilder.registerListLiteral(new ListLiteralUse(
        commonElements.listType(elementType),
        isConstant: literal.isConst,
        isEmpty: literal.expressions.isEmpty));
  }

  @override
  void visitMapLiteral(ir.MapLiteral literal) {
    visitNodes(literal.entries);
    DartType keyType =
        checkType(literal.keyType, TypeUseKind.CHECKED_MODE_CHECK);
    DartType valueType =
        checkType(literal.valueType, TypeUseKind.CHECKED_MODE_CHECK);
    registerSeenClasses(literal.keyType);
    registerSeenClasses(literal.valueType);
    impactBuilder.registerMapLiteral(new MapLiteralUse(
        commonElements.mapType(keyType, valueType),
        isConstant: literal.isConst,
        isEmpty: literal.entries.isEmpty));
  }

  @override
  void visitMapEntry(ir.MapEntry entry) {
    visitNode(entry.key);
    visitNode(entry.value);
  }

  @override
  void visitConditionalExpression(ir.ConditionalExpression node) {
    visitNode(node.condition);
    visitNode(node.then);
    visitNode(node.otherwise);
    // Don't visit the static type.
  }

  List<DartType> _visitArguments(ir.Arguments arguments) {
    arguments.positional.forEach(visitNode);
    arguments.named.forEach(visitNode);
    if (arguments.types.isEmpty) return null;
    return _options.strongMode
        ? arguments.types.map(elementMap.getDartType).toList()
        : const <DartType>[];
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
      impactBuilder.registerConstSymbolName(stringValue.stringValue);
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
      if (_options.strongMode &&
          target == commonElements.extractTypeArguments) {
        _handleExtractTypeArguments(node, target);
        return;
      }
      List<DartType> typeArguments = _visitArguments(node.arguments);
      impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
          target, elementMap.getCallStructure(node.arguments), typeArguments));
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

  void _handleExtractTypeArguments(
      ir.StaticInvocation node, FunctionEntity target) {
    // extractTypeArguments<Map>(obj, fn) has additional impacts:
    //
    //   1. All classes implementing Map need to carry type arguments (similar
    //      to checking `o is Map<K, V>`).
    //
    //   2. There is an invocation of fn with some number of type arguments.
    //
    List<DartType> typeArguments = _visitArguments(node.arguments);
    impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
        target, elementMap.getCallStructure(node.arguments), typeArguments));

    if (typeArguments.length != 1) return;
    DartType matchedType = typeArguments.first;

    if (matchedType is! InterfaceType) return;
    InterfaceType interfaceType = matchedType;
    ClassEntity cls = interfaceType.element;
    InterfaceType thisType = elementMap.elementEnvironment.getThisType(cls);

    impactBuilder.registerTypeUse(new TypeUse.isCheck(thisType));

    Selector selector = new Selector.callClosure(
        0, const <String>[], thisType.typeArguments.length);
    impactBuilder.registerDynamicUse(
        new ConstrainedDynamicUse(selector, null, thisType.typeArguments));
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
    List<DartType> typeArguments = _visitArguments(node.arguments);
    // TODO(johnniwinther): Restrict the dynamic use to only match the known
    // target.
    ReceiverConstraint constraint;
    MemberEntity member = elementMap.getMember(node.target);
    if (_options.strongMode && useStrongModeWorldStrategy) {
      // TODO(johnniwinther): Restrict this to subclasses?
      constraint = new StrongModeConstraint(member.enclosingClass);
    }
    impactBuilder.registerDynamicUse(new ConstrainedDynamicUse(
        new Selector.call(
            member.memberName, elementMap.getCallStructure(node.arguments)),
        constraint,
        typeArguments));
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
        new Selector.getter(elementMap.getMember(node.target).memberName)));
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
        new Selector.setter(elementMap.getMember(node.target).memberName)));
  }

  @override
  void visitSuperPropertySet(ir.SuperPropertySet node) {
    handleSuperSet(node.name, node.interfaceTarget, node.value);
  }

  @override
  void visitMethodInvocation(ir.MethodInvocation node) {
    Selector selector = elementMap.getSelector(node);
    List<DartType> typeArguments = _visitArguments(node.arguments);
    var receiver = node.receiver;
    if (receiver is ir.VariableGet &&
        receiver.variable.isFinal &&
        receiver.variable.parent is ir.FunctionDeclaration) {
      Local localFunction =
          elementMap.getLocalFunction(receiver.variable.parent);
      // Invocation of a local function. No need for dynamic use.
      if (_options.strongMode) {
        // We need to track the type arguments.
        impactBuilder.registerStaticUse(new StaticUse.closureCall(
            localFunction, selector.callStructure, typeArguments));
      }
    } else {
      visitNode(node.receiver);
      ReceiverConstraint constraint;
      if (_options.strongMode && useStrongModeWorldStrategy) {
        DartType receiverType = elementMap.getStaticType(node.receiver);
        if (receiverType is InterfaceType) {
          constraint = new StrongModeConstraint(receiverType.element);
        }
      }

      impactBuilder.registerDynamicUse(
          new ConstrainedDynamicUse(selector, constraint, typeArguments));
    }
  }

  @override
  void visitPropertyGet(ir.PropertyGet node) {
    visitNode(node.receiver);
    ReceiverConstraint constraint;
    if (_options.strongMode && useStrongModeWorldStrategy) {
      DartType receiverType = elementMap.getStaticType(node.receiver);
      if (receiverType is InterfaceType) {
        constraint = new StrongModeConstraint(receiverType.element);
      }
    }
    impactBuilder.registerDynamicUse(new ConstrainedDynamicUse(
        new Selector.getter(elementMap.getName(node.name)),
        constraint, const <DartType>[]));
  }

  @override
  void visitPropertySet(ir.PropertySet node) {
    visitNode(node.receiver);
    visitNode(node.value);
    ReceiverConstraint constraint;
    if (_options.strongMode && useStrongModeWorldStrategy) {
      DartType receiverType = elementMap.getStaticType(node.receiver);
      if (receiverType is InterfaceType) {
        constraint = new StrongModeConstraint(receiverType.element);
      }
    }
    impactBuilder.registerDynamicUse(new ConstrainedDynamicUse(
        new Selector.setter(elementMap.getName(node.name)),
        constraint, const <DartType>[]));
  }

  @override
  void visitAssertStatement(ir.AssertStatement node) {
    impactBuilder.registerFeature(
        node.message != null ? Feature.ASSERT_WITH_MESSAGE : Feature.ASSERT);
    visitNode(node.condition);
    visitNode(node.message);
  }

  @override
  void visitInstantiation(ir.Instantiation node) {
    // TODO(johnniwinther): Track which arities are used in instantiation.
    impactBuilder.registerFeature(Feature.GENERIC_INSTANTIATION);
    node.visitChildren(this);
  }

  @override
  void visitStringConcatenation(ir.StringConcatenation node) {
    impactBuilder.registerFeature(Feature.STRING_INTERPOLATION);
    impactBuilder.registerFeature(Feature.STRING_JUXTAPOSITION);
    visitNodes(node.expressions);
  }

  @override
  void visitFunctionDeclaration(ir.FunctionDeclaration node) {
    Local function = elementMap.getLocalFunction(node);
    impactBuilder.registerStaticUse(new StaticUse.closure(function));
    handleSignature(node.function);
    handleAsyncMarker(node.function);
    visitNode(node.function.body);
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression node) {
    Local function = elementMap.getLocalFunction(node);
    impactBuilder.registerStaticUse(new StaticUse.closure(function));
    handleSignature(node.function);
    handleAsyncMarker(node.function);
    visitNode(node.function.body);
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration node) {
    checkType(node.type, TypeUseKind.CHECKED_MODE_CHECK);
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
    DartType type = elementMap.getDartType(node.type);
    if (node.isTypeError) {
      impactBuilder.registerTypeUse(new TypeUse.implicitCast(type));
    } else {
      impactBuilder.registerTypeUse(new TypeUse.asCast(type));
    }
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
    // TODO(johnniwinther): Use receiver constraints for the dynamic uses in
    // strong mode.
    if (node.isAsync) {
      impactBuilder.registerFeature(Feature.ASYNC_FOR_IN);
      impactBuilder.registerDynamicUse(new DynamicUse(Selectors.cancel));
    } else {
      impactBuilder.registerFeature(Feature.SYNC_FOR_IN);
      impactBuilder.registerDynamicUse(new DynamicUse(Selectors.iterator));
    }
    impactBuilder.registerDynamicUse(new DynamicUse(Selectors.current));
    impactBuilder.registerDynamicUse(new DynamicUse(Selectors.moveNext));
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

  @override
  void visitLoadLibrary(ir.LoadLibrary node) {
    impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
        commonElements.loadDeferredLibrary, CallStructure.ONE_ARG));
    impactBuilder.registerFeature(Feature.LOAD_LIBRARY);
  }

  // TODO(johnniwinther): Make this throw and visit child nodes explicitly
  // instead to ensure that we don't visit unwanted parts of the ir.
  @override
  void defaultNode(ir.Node node) => node.visitChildren(this);
}

class _ClassEnsurer extends BaseDartTypeVisitor<dynamic, Null> {
  final KernelImpactBuilder builder;
  final DartTypes types;
  final seenTypes = new Set<InterfaceType>();

  _ClassEnsurer(this.builder, this.types);

  void ensureClassesInType(DartType type) {
    seenTypes.clear();
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
    if (!seenTypes.add(type)) {
      return;
    }
    builder.impactBuilder.registerSeenClass(type.element);
    type.typeArguments.forEach((t) {
      t.accept(this, null);
    });
    var supertype = types.getSupertype(type.element);
    supertype?.accept(this, null);
  }

  @override
  visitTypedefType(TypedefType type, _) {
    type.typeArguments.forEach((t) {
      t.accept(this, null);
    });
  }
}
