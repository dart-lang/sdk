// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart'
    show operatorFromString;

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/names.dart';
import '../common/resolution.dart';
import '../common_elements.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/static_type.dart';
import '../ir/util.dart';
import '../js_backend/native_data.dart';
import '../options.dart';
import '../resolution/registry.dart' show ResolutionWorldImpactBuilder;
import '../universe/call_structure.dart';
import '../universe/feature.dart';
import '../universe/selector.dart';
import '../universe/use.dart';
import '../universe/world_builder.dart';
import 'element_map.dart';
import 'runtime_type_analysis.dart';

ResolutionImpact buildKernelImpact(
    ir.Member member,
    KernelToElementMap elementMap,
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

class KernelImpactBuilder extends StaticTypeVisitor {
  final ResolutionWorldImpactBuilder impactBuilder;
  final KernelToElementMap elementMap;
  final DiagnosticReporter reporter;
  final CompilerOptions _options;
  final MemberEntity currentMember;

  KernelImpactBuilder(
      this.elementMap, this.currentMember, this.reporter, this._options)
      : this.impactBuilder =
            new ResolutionWorldImpactBuilder('${currentMember}'),
        super(elementMap.typeEnvironment);

  CommonElements get commonElements => elementMap.commonElements;

  NativeBasicData get _nativeBasicData => elementMap.nativeBasicData;

  /// Add a checked-mode type use of [type] if it is not `dynamic`.
  DartType checkType(ir.DartType irType, TypeUseKind kind) {
    DartType type = elementMap.getDartType(irType);
    if (kind != null && !type.isDynamic) {
      switch (kind) {
        case TypeUseKind.PARAMETER_CHECK:
          impactBuilder.registerTypeUse(new TypeUse.parameterCheck(type));
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

  /// Add checked-mode type use for the parameter type and constant for the
  /// default value of [parameter].
  void handleParameter(ir.VariableDeclaration parameter) {
    checkType(parameter.type, TypeUseKind.PARAMETER_CHECK);
    visitNode(parameter.initializer);
  }

  /// Add checked-mode type use for parameter and return types, and add
  /// constants for default values.
  void handleSignature(ir.FunctionNode node) {
    node.positionalParameters.forEach(handleParameter);
    node.namedParameters.forEach(handleParameter);
    for (ir.TypeParameter parameter in node.typeParameters) {
      checkType(parameter.bound, TypeUseKind.PARAMETER_CHECK);
    }
  }

  ResolutionImpact buildField(ir.Field field) {
    typeEnvironment.thisType = field.enclosingClass?.thisType;
    checkType(field.type, TypeUseKind.PARAMETER_CHECK);
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
      bool isJsInterop = _nativeBasicData.isJsInteropMember(member);
      impactBuilder.registerNativeData(elementMap
          .getNativeBehaviorForFieldLoad(field, isJsInterop: isJsInterop));
      impactBuilder
          .registerNativeData(elementMap.getNativeBehaviorForFieldStore(field));
    }
    typeEnvironment.thisType = null;
    return impactBuilder;
  }

  ResolutionImpact buildConstructor(ir.Constructor constructor) {
    typeEnvironment.thisType = constructor.enclosingClass.thisType;
    handleSignature(constructor.function);
    visitNodes(constructor.initializers);
    visitNode(constructor.function.body);
    MemberEntity member = elementMap.getMember(constructor);
    if (constructor.isExternal && !commonElements.isForeignHelper(member)) {
      bool isJsInterop = _nativeBasicData.isJsInteropMember(member);
      impactBuilder.registerNativeData(elementMap
          .getNativeBehaviorForMethod(constructor, isJsInterop: isJsInterop));
    }
    typeEnvironment.thisType = null;
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
    typeEnvironment.thisType = procedure.enclosingClass?.thisType;
    handleSignature(procedure.function);
    visitNode(procedure.function.body);
    handleAsyncMarker(procedure.function);
    MemberEntity member = elementMap.getMember(procedure);
    if (procedure.isExternal && !commonElements.isForeignHelper(member)) {
      bool isJsInterop = _nativeBasicData.isJsInteropMember(member);
      impactBuilder.registerNativeData(elementMap
          .getNativeBehaviorForMethod(procedure, isJsInterop: isJsInterop));
    }
    typeEnvironment.thisType = null;
    return impactBuilder;
  }

  @override
  Null visitBlock(ir.Block node) => visitNodes(node.statements);

  @override
  Null visitExpressionStatement(ir.ExpressionStatement node) {
    visitNode(node.expression);
  }

  @override
  Null visitReturnStatement(ir.ReturnStatement node) {
    visitNode(node.expression);
  }

  @override
  Null visitIfStatement(ir.IfStatement node) {
    visitNode(node.condition);
    visitNode(node.then);
    visitNode(node.otherwise);
  }

  @override
  ir.DartType visitIntLiteral(ir.IntLiteral node) {
    impactBuilder.registerConstantLiteral(
        new IntConstantExpression(new BigInt.from(node.value).toUnsigned(64)));
    return super.visitIntLiteral(node);
  }

  @override
  ir.DartType visitDoubleLiteral(ir.DoubleLiteral node) {
    impactBuilder
        .registerConstantLiteral(new DoubleConstantExpression(node.value));
    return super.visitDoubleLiteral(node);
  }

  @override
  ir.DartType visitBoolLiteral(ir.BoolLiteral node) {
    impactBuilder
        .registerConstantLiteral(new BoolConstantExpression(node.value));
    return super.visitBoolLiteral(node);
  }

  @override
  ir.DartType visitStringLiteral(ir.StringLiteral node) {
    impactBuilder
        .registerConstantLiteral(new StringConstantExpression(node.value));
    return super.visitStringLiteral(node);
  }

  @override
  ir.DartType visitSymbolLiteral(ir.SymbolLiteral node) {
    impactBuilder.registerConstSymbolName(node.value);
    return super.visitSymbolLiteral(node);
  }

  @override
  ir.DartType visitNullLiteral(ir.NullLiteral node) {
    impactBuilder.registerConstantLiteral(new NullConstantExpression());
    return super.visitNullLiteral(node);
  }

  @override
  ir.DartType visitListLiteral(ir.ListLiteral node) {
    visitNodes(node.expressions);
    DartType elementType = elementMap.getDartType(node.typeArgument);

    impactBuilder.registerListLiteral(new ListLiteralUse(
        commonElements.listType(elementType),
        isConstant: node.isConst,
        isEmpty: node.expressions.isEmpty));
    return super.visitListLiteral(node);
  }

  @override
  ir.DartType visitMapLiteral(ir.MapLiteral node) {
    visitNodes(node.entries);
    DartType keyType = elementMap.getDartType(node.keyType);
    DartType valueType = elementMap.getDartType(node.valueType);
    impactBuilder.registerMapLiteral(new MapLiteralUse(
        commonElements.mapType(keyType, valueType),
        isConstant: node.isConst,
        isEmpty: node.entries.isEmpty));
    return super.visitMapLiteral(node);
  }

  @override
  Null visitMapEntry(ir.MapEntry entry) {
    visitNode(entry.key);
    visitNode(entry.value);
  }

  @override
  ir.DartType visitConditionalExpression(ir.ConditionalExpression node) {
    visitNode(node.condition);
    visitNode(node.then);
    visitNode(node.otherwise);
    return super.visitConditionalExpression(node);
  }

  List<DartType> _visitArguments(ir.Arguments arguments) {
    visitNodes(arguments.positional);
    visitNodes(arguments.named);
    if (arguments.types.isEmpty) return null;
    return arguments.types.map(elementMap.getDartType).toList();
  }

  @override
  ir.DartType visitConstructorInvocation(ir.ConstructorInvocation node) {
    handleNew(node, node.target, isConst: node.isConst);
    return super.visitConstructorInvocation(node);
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
      // We need to register the external constructor as live below, so don't
      // return here.
    }

    InterfaceType type = elementMap.createInterfaceType(
        target.enclosingClass, node.arguments.types);
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
  Null visitSuperInitializer(ir.SuperInitializer node) {
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
  ir.DartType visitStaticInvocation(ir.StaticInvocation node) {
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
      List<DartType> typeArguments = _visitArguments(node.arguments);
      if (commonElements.isExtractTypeArguments(target)) {
        _handleExtractTypeArguments(node, target, typeArguments);
        return super.visitStaticInvocation(node);
      }
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
    return super.visitStaticInvocation(node);
  }

  void _handleExtractTypeArguments(ir.StaticInvocation node,
      FunctionEntity target, List<DartType> typeArguments) {
    // extractTypeArguments<Map>(obj, fn) has additional impacts:
    //
    //   1. All classes implementing Map need to carry type arguments (similar
    //      to checking `o is Map<K, V>`).
    //
    //   2. There is an invocation of fn with some number of type arguments.
    //
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
  ir.DartType visitStaticGet(ir.StaticGet node) {
    ir.Member target = node.target;
    if (target is ir.Procedure && target.kind == ir.ProcedureKind.Method) {
      FunctionEntity method = elementMap.getMethod(target);
      impactBuilder.registerStaticUse(new StaticUse.staticTearOff(method));
    } else {
      MemberEntity member = elementMap.getMember(target);
      impactBuilder.registerStaticUse(new StaticUse.staticGet(member));
    }
    return super.visitStaticGet(node);
  }

  @override
  ir.DartType visitStaticSet(ir.StaticSet node) {
    MemberEntity member = elementMap.getMember(node.target);
    impactBuilder.registerStaticUse(new StaticUse.staticSet(member));
    return super.visitStaticSet(node);
  }

  void handleSuperInvocation(ir.Name name, ir.Node arguments) {
    FunctionEntity method =
        elementMap.getSuperMember(currentMember, name, setter: false);
    List<DartType> typeArguments = _visitArguments(arguments);
    if (method != null) {
      impactBuilder.registerStaticUse(new StaticUse.superInvoke(
          method, elementMap.getCallStructure(arguments), typeArguments));
    } else {
      impactBuilder.registerStaticUse(new StaticUse.superInvoke(
          elementMap.getSuperNoSuchMethod(currentMember.enclosingClass),
          CallStructure.ONE_ARG));
      impactBuilder.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
    }
  }

  @override
  ir.DartType visitDirectMethodInvocation(ir.DirectMethodInvocation node) {
    List<DartType> typeArguments = _visitArguments(node.arguments);
    MemberEntity member = elementMap.getMember(node.target);
    // TODO(johnniwinther): Restrict the dynamic use to only match the known
    // target.
    // TODO(johnniwinther): Restrict this to subclasses?
    Object constraint = new StrongModeConstraint(
        commonElements, _nativeBasicData, member.enclosingClass);
    impactBuilder.registerDynamicUse(new ConstrainedDynamicUse(
        new Selector.call(
            member.memberName, elementMap.getCallStructure(node.arguments)),
        constraint,
        typeArguments));
    return super.visitDirectMethodInvocation(node);
  }

  @override
  ir.DartType visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    // TODO(johnniwinther): Should we support this or always use the
    // [MixinFullResolution] transformer?
    handleSuperInvocation(node.name, node.arguments);
    return super.visitSuperMethodInvocation(node);
  }

  void handleSuperGet(ir.Name name, ir.Member target) {
    MemberEntity member =
        elementMap.getSuperMember(currentMember, name, setter: false);
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
  ir.DartType visitDirectPropertyGet(ir.DirectPropertyGet node) {
    // TODO(johnniwinther): Restrict the dynamic use to only match the known
    // target.
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.getter(elementMap.getMember(node.target).memberName)));
    return super.visitDirectPropertyGet(node);
  }

  @override
  ir.DartType visitSuperPropertyGet(ir.SuperPropertyGet node) {
    handleSuperGet(node.name, node.interfaceTarget);
    return super.visitSuperPropertyGet(node);
  }

  void handleSuperSet(ir.Name name, ir.Node target, ir.Node value) {
    MemberEntity member =
        elementMap.getSuperMember(currentMember, name, setter: true);
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
  ir.DartType visitDirectPropertySet(ir.DirectPropertySet node) {
    // TODO(johnniwinther): Restrict the dynamic use to only match the known
    // target.
    impactBuilder.registerDynamicUse(new DynamicUse(
        new Selector.setter(elementMap.getMember(node.target).memberName)));
    return super.visitDirectPropertySet(node);
  }

  @override
  ir.DartType visitSuperPropertySet(ir.SuperPropertySet node) {
    handleSuperSet(node.name, node.interfaceTarget, node.value);
    return super.visitSuperPropertySet(node);
  }

  @override
  ir.DartType visitMethodInvocation(ir.MethodInvocation node) {
    Selector selector = elementMap.getSelector(node);
    List<DartType> typeArguments;
    if (isSpecialCasedBinaryOperator(node.interfaceTarget)) {
      typeArguments = <DartType>[];
    } else {
      typeArguments = _visitArguments(node.arguments);
    }
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType returnType = computeMethodInvocationType(node, receiverType);
    receiverType = narrowInstanceReceiver(node.interfaceTarget, receiverType);
    var receiver = node.receiver;
    if (receiver is ir.VariableGet &&
        receiver.variable.isFinal &&
        receiver.variable.parent is ir.FunctionDeclaration) {
      Local localFunction =
          elementMap.getLocalFunction(receiver.variable.parent);
      // Invocation of a local function. No need for dynamic use, but
      // we need to track the type arguments.
      impactBuilder.registerStaticUse(new StaticUse.closureCall(
          localFunction, selector.callStructure, typeArguments));
      // TODO(johnniwinther): Yet, alas, we need the dynamic use for now. Remove
      // this when kernel adds an `isFunctionCall` flag to
      // [ir.MethodInvocation].
      impactBuilder.registerDynamicUse(
          new ConstrainedDynamicUse(selector, null, typeArguments));
    } else {
      DartType receiverDartType = elementMap.getDartType(receiverType);

      ir.Member interfaceTarget = node.interfaceTarget;
      if (interfaceTarget == null) {
        // TODO(johnniwinther): Avoid treating a known function call as a
        // dynamic call when CFE provides a way to distinguish the two.
        impactBuilder.registerDynamicUse(
            new ConstrainedDynamicUse(selector, null, typeArguments));
        if (operatorFromString(node.name.name) == null) {
          impactBuilder.registerDynamicUse(new ConstrainedDynamicUse(
              selector.toCallSelector(), null, typeArguments));
        }
      } else {
        Object constraint;
        if (receiverDartType is InterfaceType) {
          constraint = new StrongModeConstraint(
              commonElements, _nativeBasicData, receiverDartType.element);
        }

        if (interfaceTarget is ir.Field ||
            interfaceTarget is ir.Procedure &&
                interfaceTarget.kind == ir.ProcedureKind.Getter) {
          impactBuilder.registerDynamicUse(
              new ConstrainedDynamicUse(selector, constraint, typeArguments));
          // An `o.foo()` invocation is (potentially) an `o.foo.call()`
          // invocation.
          Object getterConstraint;
          if (interfaceTarget != null) {
            DartType receiverType =
                elementMap.getDartType(interfaceTarget.getterType);
            if (receiverType is InterfaceType) {
              getterConstraint = new StrongModeConstraint(
                  commonElements, _nativeBasicData, receiverType.element);
            }
          }

          impactBuilder.registerDynamicUse(new ConstrainedDynamicUse(
              selector.toCallSelector(), getterConstraint, typeArguments));
        } else {
          impactBuilder.registerDynamicUse(
              new ConstrainedDynamicUse(selector, constraint, typeArguments));
        }
      }
    }
    return returnType;
  }

  @override
  ir.DartType visitPropertyGet(ir.PropertyGet node) {
    Object constraint;
    ir.DartType receiverType = visitNode(node.receiver);
    ir.DartType resultType = computePropertyGetType(node, receiverType);
    receiverType = narrowInstanceReceiver(node.interfaceTarget, receiverType);

    DartType receiverDartType = elementMap.getDartType(receiverType);
    if (receiverDartType is InterfaceType) {
      constraint = new StrongModeConstraint(
          commonElements, _nativeBasicData, receiverDartType.element);
    }
    impactBuilder.registerDynamicUse(new ConstrainedDynamicUse(
        new Selector.getter(elementMap.getName(node.name)),
        constraint, const <DartType>[]));

    if (node.name.name == Identifiers.runtimeType_) {
      RuntimeTypeUse runtimeTypeUse = computeRuntimeTypeUse(elementMap, node);
      if (_options.omitImplicitChecks) {
        switch (runtimeTypeUse.kind) {
          case RuntimeTypeUseKind.string:
            if (!_options.laxRuntimeTypeToString) {
              if (runtimeTypeUse.receiverType == commonElements.objectType) {
                reporter.reportHintMessage(computeSourceSpanFromTreeNode(node),
                    MessageKind.RUNTIME_TYPE_TO_STRING_OBJECT);
              } else {
                reporter.reportHintMessage(
                    computeSourceSpanFromTreeNode(node),
                    MessageKind.RUNTIME_TYPE_TO_STRING_SUBTYPE,
                    {'receiverType': '${runtimeTypeUse.receiverType}.'});
              }
            }
            break;
          case RuntimeTypeUseKind.equals:
          case RuntimeTypeUseKind.unknown:
            break;
        }
      }
      impactBuilder.registerRuntimeTypeUse(runtimeTypeUse);
    }
    return resultType;
  }

  @override
  ir.DartType visitPropertySet(ir.PropertySet node) {
    Object constraint;
    ir.DartType receiverType = visitNode(node.receiver);
    receiverType = narrowInstanceReceiver(node.interfaceTarget, receiverType);
    DartType receiverDartType = elementMap.getDartType(receiverType);
    if (receiverDartType is InterfaceType) {
      constraint = new StrongModeConstraint(
          commonElements, _nativeBasicData, receiverDartType.element);
    }
    impactBuilder.registerDynamicUse(new ConstrainedDynamicUse(
        new Selector.setter(elementMap.getName(node.name)),
        constraint, const <DartType>[]));
    return super.visitPropertySet(node);
  }

  @override
  Null visitAssertStatement(ir.AssertStatement node) {
    impactBuilder.registerFeature(
        node.message != null ? Feature.ASSERT_WITH_MESSAGE : Feature.ASSERT);
    visitNode(node.condition);
    visitNode(node.message);
  }

  @override
  ir.DartType visitInstantiation(ir.Instantiation node) {
    // TODO(johnniwinther): Track which arities are used in instantiation.
    ir.FunctionType expressionType = visitNode(node.expression);
    impactBuilder.registerInstantiation(new GenericInstantiation(
        elementMap.getDartType(expressionType),
        node.typeArguments.map(elementMap.getDartType).toList()));
    return computeInstantiationType(node, expressionType);
  }

  @override
  ir.DartType visitStringConcatenation(ir.StringConcatenation node) {
    impactBuilder.registerFeature(Feature.STRING_INTERPOLATION);
    impactBuilder.registerFeature(Feature.STRING_JUXTAPOSITION);
    visitNodes(node.expressions);
    return super.visitStringConcatenation(node);
  }

  @override
  Null visitFunctionDeclaration(ir.FunctionDeclaration node) {
    Local function = elementMap.getLocalFunction(node);
    impactBuilder.registerStaticUse(new StaticUse.closure(function));
    handleSignature(node.function);
    handleAsyncMarker(node.function);
    visitNode(node.function.body);
  }

  @override
  ir.DartType visitFunctionExpression(ir.FunctionExpression node) {
    Local function = elementMap.getLocalFunction(node);
    impactBuilder.registerStaticUse(new StaticUse.closure(function));
    handleSignature(node.function);
    handleAsyncMarker(node.function);
    visitNode(node.function.body);
    return super.visitFunctionExpression(node);
  }

  @override
  Null visitVariableDeclaration(ir.VariableDeclaration node) {
    if (node.initializer != null) {
      visitNode(node.initializer);
    } else {
      impactBuilder.registerFeature(Feature.LOCAL_WITHOUT_INITIALIZER);
    }
  }

  @override
  ir.DartType visitIsExpression(ir.IsExpression node) {
    impactBuilder.registerTypeUse(
        new TypeUse.isCheck(elementMap.getDartType(node.type)));
    visitNode(node.operand);
    return super.visitIsExpression(node);
  }

  @override
  ir.DartType visitAsExpression(ir.AsExpression node) {
    DartType type = elementMap.getDartType(node.type);
    if (node.isTypeError) {
      impactBuilder.registerTypeUse(new TypeUse.implicitCast(type));
    } else {
      impactBuilder.registerTypeUse(new TypeUse.asCast(type));
    }
    visitNode(node.operand);
    return super.visitAsExpression(node);
  }

  @override
  ir.DartType visitThrow(ir.Throw node) {
    impactBuilder.registerFeature(Feature.THROW_EXPRESSION);
    visitNode(node.expression);
    return super.visitThrow(node);
  }

  @override
  Null visitForInStatement(ir.ForInStatement node) {
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
  Null visitTryCatch(ir.TryCatch node) {
    visitNode(node.body);
    visitNodes(node.catches);
  }

  @override
  Null visitCatch(ir.Catch node) {
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
  Null visitTryFinally(ir.TryFinally node) {
    visitNode(node.body);
    visitNode(node.finalizer);
  }

  @override
  ir.DartType visitTypeLiteral(ir.TypeLiteral node) {
    impactBuilder.registerTypeUse(
        new TypeUse.typeLiteral(elementMap.getDartType(node.type)));
    if (node.type is ir.FunctionType) {
      ir.FunctionType functionType = node.type;
      assert(functionType.typedef != null);
      // TODO(johnniwinther): Can we avoid the typedef type altogether?
      // We need to ensure that the typedef is live.
      elementMap.getTypedefType(functionType.typedef);
    }
    return super.visitTypeLiteral(node);
  }

  @override
  Null visitFieldInitializer(ir.FieldInitializer node) {
    impactBuilder.registerStaticUse(
        new StaticUse.fieldInit(elementMap.getField(node.field)));
    visitNode(node.value);
  }

  @override
  Null visitRedirectingInitializer(ir.RedirectingInitializer node) {
    _visitArguments(node.arguments);
    ConstructorEntity target = elementMap.getConstructor(node.target);
    impactBuilder.registerStaticUse(new StaticUse.superConstructorInvoke(
        target, elementMap.getCallStructure(node.arguments)));
  }

  @override
  ir.DartType visitLogicalExpression(ir.LogicalExpression node) {
    visitNode(node.left);
    visitNode(node.right);
    return super.visitLogicalExpression(node);
  }

  ir.DartType visitNot(ir.Not node) {
    visitNode(node.operand);
    return super.visitNot(node);
  }

  @override
  ir.DartType visitLoadLibrary(ir.LoadLibrary node) {
    impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
        commonElements.loadDeferredLibrary, CallStructure.ONE_ARG));
    impactBuilder.registerFeature(Feature.LOAD_LIBRARY);
    return super.visitLoadLibrary(node);
  }

  @override
  Null visitEmptyStatement(ir.EmptyStatement node) {}

  @override
  Null visitForStatement(ir.ForStatement node) {
    visitNodes(node.variables);
    visitNode(node.condition);
    visitNodes(node.updates);
    visitNode(node.body);
  }

  @override
  Null visitDoStatement(ir.DoStatement node) {
    visitNode(node.body);
    visitNode(node.condition);
  }

  @override
  Null visitWhileStatement(ir.WhileStatement node) {
    visitNode(node.condition);
    visitNode(node.body);
  }

  @override
  Null visitSwitchStatement(ir.SwitchStatement node) {
    visitNode(node.expression);
    visitNodes(node.cases);
  }

  @override
  Null visitSwitchCase(ir.SwitchCase node) {
    visitNodes(node.expressions);
    visitNode(node.body);
  }

  @override
  Null visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {}

  @override
  Null visitLabeledStatement(ir.LabeledStatement node) {
    visitNode(node.body);
  }

  @override
  Null visitBreakStatement(ir.BreakStatement node) {}

  @override
  Null visitYieldStatement(ir.YieldStatement node) {
    visitNode(node.expression);
  }

  @override
  ir.DartType visitLet(ir.Let node) {
    visitNode(node.variable);
    return super.visitLet(node);
  }

  @override
  Null visitAssertInitializer(ir.AssertInitializer node) {
    visitNode(node.statement);
  }

  @override
  ir.DartType visitNamedExpression(ir.NamedExpression node) =>
      visitNode(node.value);

  // TODO(johnniwinther): Make this throw and visit child nodes explicitly
  // instead to ensure that we don't visit unwanted parts of the ir.
  @override
  ir.DartType defaultNode(ir.Node node) =>
      throw UnsupportedError('Unhandled node $node (${node.runtimeType})');
}
