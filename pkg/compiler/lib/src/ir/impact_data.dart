// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../common.dart';
import '../common/elements.dart';
import '../common/names.dart' show Uris;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/scope.dart';
import '../kernel/element_map.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../util/enumset.dart';
import 'constants.dart';
import 'impact.dart';
import 'runtime_type_analysis.dart';
import 'static_type.dart';
import 'util.dart';

/// Visitor that builds an [ImpactData] object for the world impact.
class ImpactBuilder extends StaticTypeVisitor implements ImpactRegistry {
  final ImpactData _data = ImpactData();
  final KernelToElementMap _elementMap;

  // Note: this may be null for builders associated with abstract methods.
  final VariableScopeModel? _variableScopeModel;

  @override
  final ir.StaticTypeContext staticTypeContext;

  @override
  final bool useAsserts;

  @override
  final inferEffectivelyFinalVariableTypes;

  ImpactBuilder(
      this._elementMap,
      this.staticTypeContext,
      StaticTypeCacheImpl staticTypeCache,
      ir.ClassHierarchy classHierarchy,
      this._variableScopeModel,
      {this.useAsserts = false,
      this.inferEffectivelyFinalVariableTypes = true})
      : super(
            staticTypeContext.typeEnvironment, classHierarchy, staticTypeCache);

  @override
  VariableScopeModel get variableScopeModel => _variableScopeModel!;

  CommonElements get _commonElements => _elementMap.commonElements;

  DiagnosticReporter get _reporter => _elementMap.reporter;

  String _typeToString(DartType type) =>
      type.toStructuredText(_elementMap.types, _elementMap.options);

  CompilerOptions get _options => _elementMap.options;

  /// Return the named arguments names as a list of strings.
  List<String> _getNamedArguments(ir.Arguments arguments) =>
      arguments.named.map((n) => n.name).toList();

  ImpactBuilderData computeImpact(ir.Member node) {
    if (retainDataForTesting) {
      typeMapsForTesting = {};
    }
    node.accept(this);
    return ImpactBuilderData(
        node, impactData, typeMapsForTesting, getStaticTypeCache());
  }

  ImpactData get impactData => _data;

  @override
  void handleIntLiteral(ir.IntLiteral node) {
    registerIntLiteral();
  }

  @override
  void handleDoubleLiteral(ir.DoubleLiteral node) {
    registerDoubleLiteral();
  }

  @override
  void handleBoolLiteral(ir.BoolLiteral node) {
    registerBoolLiteral();
  }

  @override
  void handleStringLiteral(ir.StringLiteral node) {
    registerStringLiteral();
  }

  @override
  void handleSymbolLiteral(ir.SymbolLiteral node) {
    registerSymbolLiteral();
  }

  @override
  void handleNullLiteral(ir.NullLiteral node) {
    registerNullLiteral();
  }

  @override
  void handleListLiteral(ir.ListLiteral node) {
    registerListLiteral(node.typeArgument,
        isConst: node.isConst, isEmpty: node.expressions.isEmpty);
  }

  @override
  void handleSetLiteral(ir.SetLiteral node) {
    registerSetLiteral(node.typeArgument,
        isConst: node.isConst, isEmpty: node.expressions.isEmpty);
  }

  @override
  void handleMapLiteral(ir.MapLiteral node) {
    registerMapLiteral(node.keyType, node.valueType,
        isConst: node.isConst, isEmpty: node.entries.isEmpty);
  }

  @override
  void handleRecordLiteral(ir.RecordLiteral node) {
    registerRecordLiteral(node.recordType, isConst: node.isConst);
  }

  @override
  void handleStaticGet(
      ir.Expression node, ir.Member target, ir.DartType resultType) {
    assert(!(target is ir.Procedure && target.kind == ir.ProcedureKind.Method),
        "Static tear off registered as static get: $node");
    registerStaticGet(target, getDeferredImport(node));
  }

  @override
  void handleStaticTearOff(
      ir.Expression node, ir.Procedure target, ir.DartType resultType) {
    assert(target.kind == ir.ProcedureKind.Method,
        "Static get registered as static tear off: $node");
    registerStaticTearOff(target, getDeferredImport(node));
  }

  @override
  void handleWeakStaticTearOff(ir.Expression node, ir.Procedure target) {
    registerWeakStaticTearOff(target, getDeferredImport(node));
  }

  @override
  void handleStaticSet(ir.StaticSet node, ir.DartType valueType) {
    registerStaticSet(node.target, getDeferredImport(node));
  }

  @override
  void handleAssertStatement(ir.AssertStatement node) {
    registerAssert(withMessage: node.message != null);
  }

  @override
  void handleInstantiation(ir.Instantiation node,
      ir.FunctionType expressionType, ir.DartType resultType) {
    registerGenericInstantiation(expressionType, node.typeArguments);
  }

  void handleAsyncMarker(ir.FunctionNode function) {
    ir.AsyncMarker asyncMarker = function.asyncMarker;
    ir.DartType returnType = function.returnType;

    switch (asyncMarker) {
      case ir.AsyncMarker.Sync:
        break;
      case ir.AsyncMarker.SyncStar:
        ir.DartType elementType = const ir.DynamicType();
        if (returnType is ir.InterfaceType) {
          if (returnType.classNode == typeEnvironment.coreTypes.iterableClass) {
            elementType = returnType.typeArguments.first;
          }
        }
        registerSyncStar(elementType);
        break;

      case ir.AsyncMarker.Async:
        ir.DartType elementType = const ir.DynamicType();
        if (returnType is ir.InterfaceType &&
            returnType.classNode == typeEnvironment.coreTypes.futureClass) {
          elementType = returnType.typeArguments.first;
        } else if (returnType is ir.FutureOrType) {
          elementType = returnType.typeArgument;
        }
        registerAsync(elementType);
        break;

      case ir.AsyncMarker.AsyncStar:
        ir.DartType elementType = const ir.DynamicType();
        if (returnType is ir.InterfaceType) {
          if (returnType.classNode == typeEnvironment.coreTypes.streamClass) {
            elementType = returnType.typeArguments.first;
          }
        }
        registerAsyncStar(elementType);
        break;
    }
  }

  @override
  void handleStringConcatenation(ir.StringConcatenation node) {
    registerStringConcatenation();
  }

  @override
  void handleFunctionDeclaration(ir.FunctionDeclaration node) {
    registerLocalFunction(node);
    handleAsyncMarker(node.function);
  }

  @override
  void handleFunctionExpression(ir.FunctionExpression node) {
    registerLocalFunction(node);
    handleAsyncMarker(node.function);
  }

  @override
  void handleVariableDeclaration(ir.VariableDeclaration node) {
    if (node.initializer == null) {
      registerLocalWithoutInitializer();
    }
  }

  @override
  void handleIsExpression(ir.IsExpression node) {
    registerIsCheck(node.type);
  }

  @override
  void handleAsExpression(ir.AsExpression node, ir.DartType operandType,
      {bool? isCalculatedTypeSubtype}) {
    if (isCalculatedTypeSubtype ??
        typeEnvironment.isSubtypeOf(operandType, node.type,
            ir.SubtypeCheckMode.ignoringNullabilities)) {
      // Skip unneeded casts.
      return;
    }
    if (node.isTypeError) {
      registerImplicitCast(node.type);
    } else {
      registerAsCast(node.type);
    }
  }

  @override
  void handleThrow(ir.Throw node) {
    registerThrow();
  }

  @override
  void handleForInStatement(ir.ForInStatement node, ir.DartType iterableType,
      ir.DartType iteratorType) {
    if (node.isAsync) {
      registerAsyncForIn(iterableType, iteratorType,
          computeClassRelationFromType(iteratorType));
    } else {
      registerSyncForIn(iterableType, iteratorType,
          computeClassRelationFromType(iteratorType));
    }
  }

  @override
  void handleCatch(ir.Catch node) {
    registerCatch();
    if (node.stackTrace != null) {
      registerStackTrace();
    }
    if (node.guard is! ir.DynamicType) {
      registerCatchType(node.guard);
    }
  }

  @override
  void handleTypeLiteral(ir.TypeLiteral node) {
    registerTypeLiteral(node.type, getDeferredImport(node));
  }

  @override
  void handleFieldInitializer(ir.FieldInitializer node) {
    registerFieldInitialization(node.field);
  }

  @override
  void handleLoadLibrary(ir.LoadLibrary node) {
    registerLoadLibrary();
  }

  @override
  void handleRedirectingInitializer(
      ir.RedirectingInitializer node, ArgumentTypes argumentTypes) {
    registerRedirectingInitializer(
        node.target,
        node.arguments.positional.length,
        _getNamedArguments(node.arguments),
        node.arguments.types);
  }

  @override
  void handleParameter(ir.VariableDeclaration parameter) {
    registerParameterCheck(parameter.type);
  }

  @override
  void handleSignature(ir.FunctionNode node) {
    for (ir.TypeParameter parameter in node.typeParameters) {
      registerParameterCheck(parameter.bound);
    }
  }

  @override
  void handleConstructor(ir.Constructor node) {
    if (node.isExternal) registerExternalConstructorNode(node);
  }

  @override
  void handleField(ir.Field field) {
    registerParameterCheck(field.type);
    if (field.initializer != null) {
      if (!field.isInstanceMember &&
          !field.isConst &&
          field.initializer is! ir.NullLiteral) {
        registerLazyField();
      }
    } else {
      registerNullLiteral();
    }
    // TODO(sigmund): only save relevant fields (e.g. those for jsinterop
    // or native types).
    registerFieldNode(field);
  }

  @override
  void handleProcedure(ir.Procedure procedure) {
    handleAsyncMarker(procedure.function);
    if (procedure.isExternal) registerExternalProcedureNode(procedure);
  }

  void _handleConstConstructorInvocation(ir.ConstructorInvocation node) {
    assert(node.isConst);
    ConstructorEntity constructor = _elementMap.getConstructor(node.target);
    if (_commonElements.isSymbolConstructor(constructor)) {
      DartType argumentType = _elementMap.getDartType(
          node.arguments.positional.first.getStaticType(staticTypeContext));
      // TODO(joshualitt): Does the CFE check this for us?
      if (argumentType != _commonElements.stringType) {
        // TODO(het): Get the actual span for the Symbol constructor argument
        _reporter.reportErrorMessage(CURRENT_ELEMENT_SPANNABLE,
            MessageKind.STRING_EXPECTED, {'type': _typeToString(argumentType)});
        return;
      }
      registerConstSymbolConstructorInvocationNode();
    }
  }

  @override
  void handleConstructorInvocation(ir.ConstructorInvocation node,
      ArgumentTypes argumentTypes, ir.DartType resultType) {
    registerNew(
        node.target,
        node.constructedType,
        node.arguments.positional.length,
        _getNamedArguments(node.arguments),
        node.arguments.types,
        getDeferredImport(node),
        isConst: node.isConst);
    if (node.isConst) {
      _handleConstConstructorInvocation(node);
    }
  }

  @override
  void handleStaticInvocation(ir.StaticInvocation node,
      ArgumentTypes argumentTypes, ir.DartType returnType) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
    if (node.target.kind == ir.ProcedureKind.Factory) {
      // TODO(johnniwinther): We should not mark the type as instantiated but
      // rather follow the type arguments directly.
      //
      // Consider this:
      //
      //    abstract class A<T> {
      //      factory A.regular() => B<T>();
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
      registerNew(
          node.target,
          ir.InterfaceType(node.target.enclosingClass!,
              node.target.enclosingLibrary.nonNullable, typeArguments),
          positionArguments,
          namedArguments,
          node.arguments.types,
          getDeferredImport(node),
          isConst: node.isConst);
    } else {
      registerStaticInvocation(node.target, positionArguments, namedArguments,
          typeArguments, getDeferredImport(node));
    }
    // TODO(sigmund): consider using `_elementMap.getForeignKind` here. We
    // currently don't use it because when this step is run modularly we try
    // to keep most operations at the kernel level, otherwise it may triggers
    // additional unnecessary work.
    final name = node.target.name.text;
    if (node.target.enclosingClass == null &&
        node.target.enclosingLibrary.importUri == Uris.dart__foreign_helper &&
        getForeignKindFromName(name) != ForeignKind.NONE) {
      registerForeignStaticInvocationNode(node);
    }
  }

  @override
  void handleDynamicInvocation(
      ir.InvocationExpression node,
      ir.DartType receiverType,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
    ClassRelation relation = computeClassRelationFromType(receiverType);
    registerDynamicInvocation(receiverType, relation, node.name,
        positionArguments, namedArguments, typeArguments);
  }

  @override
  void handleFunctionInvocation(
      ir.InvocationExpression node,
      ir.DartType receiverType,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
    registerFunctionInvocation(
        receiverType, positionArguments, namedArguments, typeArguments);
  }

  @override
  void handleInstanceInvocation(
      ir.InvocationExpression node,
      ir.DartType receiverType,
      ir.Member interfaceTarget,
      ArgumentTypes argumentTypes) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
    ClassRelation relation = computeClassRelationFromType(receiverType);

    if (interfaceTarget is ir.Field ||
        interfaceTarget is ir.Procedure &&
            interfaceTarget.kind == ir.ProcedureKind.Getter) {
      registerInstanceInvocation(receiverType, relation, interfaceTarget,
          positionArguments, namedArguments, typeArguments);
      registerFunctionInvocation(interfaceTarget.getterType, positionArguments,
          namedArguments, typeArguments);
    } else {
      registerInstanceInvocation(receiverType, relation, interfaceTarget,
          positionArguments, namedArguments, typeArguments);
    }
  }

  @override
  void handleLocalFunctionInvocation(
      ir.InvocationExpression node,
      ir.FunctionDeclaration function,
      ArgumentTypes argumentTypes,
      ir.DartType returnType) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
    registerLocalFunctionInvocation(
        function, positionArguments, namedArguments, typeArguments);
  }

  @override
  void handleEqualsCall(ir.Expression left, ir.DartType leftType,
      ir.Expression right, ir.DartType rightType, ir.Member interfaceTarget) {
    ClassRelation relation = computeClassRelationFromType(leftType);
    registerInstanceInvocation(leftType, relation, interfaceTarget, 1,
        const <String>[], const <ir.DartType>[]);
  }

  @override
  void handleEqualsNull(ir.EqualsNull node, ir.DartType expressionType) {
    registerNullLiteral();
  }

  @override
  void handleDynamicGet(ir.Expression node, ir.DartType receiverType,
      ir.Name name, ir.DartType resultType) {
    ClassRelation relation = computeClassRelationFromType(receiverType);
    registerDynamicGet(receiverType, relation, name);
  }

  @override
  void handleInstanceGet(ir.Expression node, ir.DartType receiverType,
      ir.Member interfaceTarget, ir.DartType resultType) {
    ClassRelation relation = computeClassRelationFromType(receiverType);
    registerInstanceGet(receiverType, relation, interfaceTarget);
  }

  @override
  void handleDynamicSet(ir.Expression node, ir.DartType receiverType,
      ir.Name name, ir.DartType valueType) {
    ClassRelation relation = computeClassRelationFromType(receiverType);
    registerDynamicSet(receiverType, relation, name);
  }

  @override
  void handleInstanceSet(ir.Expression node, ir.DartType receiverType,
      ir.Member interfaceTarget, ir.DartType valueType) {
    ClassRelation relation = computeClassRelationFromType(receiverType);
    registerInstanceSet(receiverType, relation, interfaceTarget);
  }

  @override
  void handleSuperMethodInvocation(ir.SuperMethodInvocation node,
      ArgumentTypes argumentTypes, ir.DartType returnType) {
    registerSuperInvocation(
        getEffectiveSuperTarget(node.interfaceTarget)!,
        node.arguments.positional.length,
        _getNamedArguments(node.arguments),
        node.arguments.types);
  }

  @override
  void handleSuperPropertyGet(
      ir.SuperPropertyGet node, ir.DartType resultType) {
    registerSuperGet(getEffectiveSuperTarget(node.interfaceTarget)!);
  }

  @override
  void handleSuperPropertySet(ir.SuperPropertySet node, ir.DartType valueType) {
    registerSuperSet(getEffectiveSuperTarget(node.interfaceTarget)!);
  }

  @override
  void handleSuperInitializer(
      ir.SuperInitializer node, ArgumentTypes argumentTypes) {
    registerSuperInitializer(
        node.parent as ir.Constructor,
        node.target,
        node.arguments.positional.length,
        _getNamedArguments(node.arguments),
        node.arguments.types);
  }

  @override
  ir.DartType visitSwitchStatement(ir.SwitchStatement node) {
    registerSwitchStatementNode(node);
    return super.visitSwitchStatement(node);
  }

  @override
  void handleRuntimeTypeUse(ir.Expression node, RuntimeTypeUseKind kind,
      ir.DartType receiverType, ir.DartType? argumentType) {
    if (_options.omitImplicitChecks) {
      switch (kind) {
        case RuntimeTypeUseKind.string:
          if (!_options.laxRuntimeTypeToString) {
            _reporter.reportHintMessage(computeSourceSpanFromTreeNode(node),
                MessageKind.RUNTIME_TYPE_TO_STRING);
          }
          break;
        case RuntimeTypeUseKind.equals:
        case RuntimeTypeUseKind.unknown:
          break;
      }
    }
    registerRuntimeTypeUse(kind, receiverType, argumentType);
  }

  @override
  void handleConstantExpression(ir.ConstantExpression node) {
    // Evaluate any [ir.UnevaluatedConstant]s to ensure they are processed for
    // impacts correctly.
    // TODO(joshualitt): Remove this when we have CFE constants.
    if (node.constant is ir.UnevaluatedConstant) {
      _elementMap.constantEvaluator.evaluate(staticTypeContext, node);
    }
    ir.LibraryDependency? import = getDeferredImport(node);
    ConstantImpactVisitor(this, import, node, staticTypeContext)
        .visitConstant(node.constant);
  }

  void _registerFeature(_Feature feature) {
    (_data._features ??= EnumSet<_Feature>()).add(feature);
  }

  void _registerTypeUse(ir.DartType type, _TypeUseKind kind) {
    (_data._typeUses ??= []).add(_TypeUse(type, kind));
  }

  @override
  void registerSuperInitializer(
      ir.Constructor source,
      ir.Constructor target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    (_data._superInitializers ??= []).add(
      _SuperInitializer(source, target,
          _CallStructure(positionalArguments, namedArguments, typeArguments)),
    );
  }

  @override
  void registerSuperSet(ir.Member? target) {
    (_data._superSets ??= []).add(target!);
  }

  @override
  void registerSuperGet(ir.Member? target) {
    (_data._superGets ??= []).add(target!);
  }

  @override
  void registerSuperInvocation(ir.Member? target, int positionalArguments,
      List<String> namedArguments, List<ir.DartType> typeArguments) {
    (_data._superInvocations ??= []).add(_SuperInvocation(target!,
        _CallStructure(positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerInstanceSet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target) {
    (_data._instanceSets ??= [])
        .add(_InstanceAccess(receiverType, relation, target));
  }

  @override
  void registerDynamicSet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name) {
    (_data._dynamicSets ??= [])
        .add(_DynamicAccess(receiverType, relation, name));
  }

  @override
  void registerInstanceGet(
      ir.DartType receiverType, ClassRelation relation, ir.Member target) {
    (_data._instanceGets ??= [])
        .add(_InstanceAccess(receiverType, relation, target));
  }

  @override
  void registerDynamicGet(
      ir.DartType receiverType, ClassRelation relation, ir.Name name) {
    (_data._dynamicGets ??= [])
        .add(_DynamicAccess(receiverType, relation, name));
  }

  @override
  void registerFunctionInvocation(
      ir.DartType receiverType,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    (_data._functionInvocations ??= []).add(_FunctionInvocation(receiverType,
        _CallStructure(positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerInstanceInvocation(
      ir.DartType receiverType,
      ClassRelation relation,
      ir.Member target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    (_data._instanceInvocations ??= []).add(_InstanceInvocation(
        receiverType,
        relation,
        target,
        _CallStructure(positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerDynamicInvocation(
      ir.DartType receiverType,
      ClassRelation relation,
      ir.Name name,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    (_data._dynamicInvocations ??= []).add(_DynamicInvocation(
        receiverType,
        relation,
        name,
        _CallStructure(positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerLocalFunctionInvocation(
      ir.FunctionDeclaration localFunction,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    (_data._localFunctionInvocations ??= []).add(_LocalFunctionInvocation(
        localFunction,
        _CallStructure(positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerStaticInvocation(
      ir.Procedure target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments,
      ir.LibraryDependency? import) {
    (_data._staticInvocations ??= []).add(_StaticInvocation(
        target,
        _CallStructure(positionalArguments, namedArguments, typeArguments),
        import));
  }

  @override
  void registerNew(
      ir.Member constructor,
      ir.InterfaceType type,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments,
      ir.LibraryDependency? import,
      {required bool isConst}) {
    (_data._constructorInvocations ??= []).add(_ConstructorInvocation(
        constructor,
        type,
        _CallStructure(positionalArguments, namedArguments, typeArguments),
        import,
        isConst: isConst));
  }

  @override
  void registerConstInstantiation(ir.Class cls, List<ir.DartType> typeArguments,
      ir.LibraryDependency? import) {
    (_data._constInstantiations ??= [])
        .add(_ConstInstantiation(cls, typeArguments, import));
  }

  @override
  void registerLazyField() {
    _registerFeature(_Feature.lazyField);
  }

  @override
  void registerParameterCheck(ir.DartType type) {
    _registerTypeUse(type, _TypeUseKind.parameterCheck);
  }

  @override
  void registerRedirectingInitializer(
      ir.Constructor constructor,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    (_data._redirectingInitializers ??= []).add(_RedirectingInitializer(
        constructor,
        _CallStructure(positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerLoadLibrary() {
    _registerFeature(_Feature.loadLibrary);
  }

  @override
  void registerFieldInitialization(ir.Field node) {
    (_data._fieldInitializers ??= []).add(node);
  }

  @override
  void registerFieldConstantInitialization(
      ir.Field node, ConstantReference constant) {
    (_data._fieldConstantInitializers ??= {})
        .putIfAbsent(node, () => [])
        .add(constant);
  }

  @override
  void registerTypeLiteral(ir.DartType type, ir.LibraryDependency? import) {
    (_data._typeLiterals ??= []).add(_TypeLiteral(type, import));
  }

  @override
  void registerCatchType(ir.DartType type) {
    _registerTypeUse(type, _TypeUseKind.catchType);
  }

  @override
  void registerStackTrace() {
    _registerFeature(_Feature.stackTrace);
  }

  @override
  void registerCatch() {
    _registerFeature(_Feature.catchClause);
  }

  @override
  void registerAsyncForIn(ir.DartType iterableType, ir.DartType iteratorType,
      ClassRelation iteratorClassRelation) {
    (_data._forInData ??= []).add(_ForInData(
        iterableType, iteratorType, iteratorClassRelation,
        isAsync: true));
  }

  @override
  void registerSyncForIn(ir.DartType iterableType, ir.DartType iteratorType,
      ClassRelation iteratorClassRelation) {
    (_data._forInData ??= []).add(_ForInData(
        iterableType, iteratorType, iteratorClassRelation,
        isAsync: false));
  }

  @override
  void registerThrow() {
    _registerFeature(_Feature.throwExpression);
  }

  @override
  void registerAsCast(ir.DartType type) {
    _registerTypeUse(type, _TypeUseKind.asCast);
  }

  @override
  void registerImplicitCast(ir.DartType type) {
    _registerTypeUse(type, _TypeUseKind.implicitCast);
  }

  @override
  void registerIsCheck(ir.DartType type) {
    _registerTypeUse(type, _TypeUseKind.isCheck);
  }

  @override
  void registerLocalWithoutInitializer() {
    _registerFeature(_Feature.localWithoutInitializer);
  }

  @override
  void registerLocalFunction(ir.TreeNode node) {
    (_data._localFunctions ??= []).add(node);
  }

  @override
  void registerStringConcatenation() {
    _registerFeature(_Feature.stringConcatenation);
  }

  @override
  void registerAsyncStar(ir.DartType elementType) {
    _registerTypeUse(elementType, _TypeUseKind.asyncStarMarker);
  }

  @override
  void registerAsync(ir.DartType elementType) {
    _registerTypeUse(elementType, _TypeUseKind.asyncMarker);
  }

  @override
  void registerSyncStar(ir.DartType elementType) {
    _registerTypeUse(elementType, _TypeUseKind.syncStarMarker);
  }

  @override
  void registerGenericInstantiation(
      ir.FunctionType expressionType, List<ir.DartType> typeArguments) {
    (_data._genericInstantiations ??= [])
        .add(_GenericInstantiation(expressionType, typeArguments));
  }

  @override
  void registerAssert({required bool withMessage}) {
    _registerFeature(withMessage
        ? _Feature.assertWithMessage
        : _Feature.assertWithoutMessage);
  }

  @override
  void registerStaticSet(ir.Member member, ir.LibraryDependency? import) {
    (_data._staticSets ??= []).add(_StaticAccess(member, import));
  }

  @override
  void registerStaticGet(ir.Member member, ir.LibraryDependency? import) {
    (_data._staticGets ??= []).add(_StaticAccess(member, import));
  }

  @override
  void registerStaticTearOff(
      ir.Procedure procedure, ir.LibraryDependency? import) {
    (_data._staticTearOffs ??= []).add(_StaticAccess(procedure, import));
  }

  @override
  void registerWeakStaticTearOff(
      ir.Procedure procedure, ir.LibraryDependency? import) {
    (_data._weakStaticTearOffs ??= []).add(_StaticAccess(procedure, import));
  }

  @override
  void registerMapLiteral(ir.DartType keyType, ir.DartType valueType,
      {required bool isConst, required bool isEmpty}) {
    (_data._mapLiterals ??= []).add(
        _MapLiteral(keyType, valueType, isConst: isConst, isEmpty: isEmpty));
  }

  @override
  void registerListLiteral(ir.DartType elementType,
      {required bool isConst, required bool isEmpty}) {
    (_data._listLiterals ??= []).add(
        _ContainerLiteral(elementType, isConst: isConst, isEmpty: isEmpty));
  }

  @override
  void registerSetLiteral(ir.DartType elementType,
      {required bool isConst, required bool isEmpty}) {
    (_data._setLiterals ??= []).add(
        _ContainerLiteral(elementType, isConst: isConst, isEmpty: isEmpty));
  }

  @override
  void registerRecordLiteral(ir.RecordType recordType,
      {required bool isConst}) {
    (_data._recordLiterals ??= [])
        .add(_RecordLiteral(recordType, isConst: isConst));
  }

  @override
  void registerNullLiteral() {
    _registerFeature(_Feature.nullLiteral);
  }

  @override
  void registerSymbolLiteral() {
    _registerFeature(_Feature.symbolLiteral);
  }

  @override
  void registerStringLiteral() {
    _registerFeature(_Feature.stringLiteral);
  }

  @override
  void registerBoolLiteral() {
    _registerFeature(_Feature.boolLiteral);
  }

  @override
  void registerDoubleLiteral() {
    _registerFeature(_Feature.doubleLiteral);
  }

  @override
  void registerIntLiteral() {
    _registerFeature(_Feature.intLiteral);
  }

  @override
  void registerRuntimeTypeUse(RuntimeTypeUseKind kind, ir.DartType receiverType,
      ir.DartType? argumentType) {
    (_data._runtimeTypeUses ??= [])
        .add(_RuntimeTypeUse(kind, receiverType, argumentType));
  }

  @override
  void registerExternalConstructorNode(ir.Constructor node) {
    (_data._externalConstructorNodes ??= []).add(node);
  }

  @override
  void registerFieldNode(ir.Field node) {
    (_data._fieldNodes ??= []).add(node);
  }

  @override
  void registerExternalProcedureNode(ir.Procedure node) {
    (_data._externalProcedureNodes ??= []).add(node);
  }

  @override
  void registerForeignStaticInvocationNode(ir.StaticInvocation node) {
    (_data._foreignStaticInvocationNodes ??= []).add(node);
  }

  @override
  void registerSwitchStatementNode(ir.SwitchStatement node) {
    (_data._switchStatementNodes ??= []).add(node);
  }

  @override
  void registerConstSymbolConstructorInvocationNode() {
    _data._hasConstSymbolConstructorInvocation = true;
  }
}

/// Data object that contains the world impact data derived purely from kernel.
/// It is critical that all of the data in this class be invariant to changes in
/// the AST that occur after modular compilation and before deserializing the
/// impact data.
class ImpactData {
  static const String tag = 'ImpactData';

  List<_SuperInitializer>? _superInitializers;
  List<ir.Member>? _superSets;
  List<ir.Member>? _superGets;
  List<_SuperInvocation>? _superInvocations;
  List<_InstanceAccess>? _instanceSets;
  List<_DynamicAccess>? _dynamicSets;
  List<_InstanceAccess>? _instanceGets;
  List<_DynamicAccess>? _dynamicGets;
  List<_FunctionInvocation>? _functionInvocations;
  List<_InstanceInvocation>? _instanceInvocations;
  List<_DynamicInvocation>? _dynamicInvocations;
  List<_LocalFunctionInvocation>? _localFunctionInvocations;
  List<_StaticInvocation>? _staticInvocations;
  List<_ConstructorInvocation>? _constructorInvocations;
  List<_ConstInstantiation>? _constInstantiations;
  EnumSet<_Feature>? _features;
  List<_TypeUse>? _typeUses;
  List<_RedirectingInitializer>? _redirectingInitializers;
  List<ir.Field>? _fieldInitializers;
  Map<ir.Field, List<ConstantReference>>? _fieldConstantInitializers;
  List<_TypeLiteral>? _typeLiterals;
  List<ir.TreeNode>? _localFunctions;
  List<_GenericInstantiation>? _genericInstantiations;
  List<_StaticAccess>? _staticSets;
  List<_StaticAccess>? _staticGets;
  List<_StaticAccess>? _staticTearOffs;
  List<_StaticAccess>? _weakStaticTearOffs;
  List<_MapLiteral>? _mapLiterals;
  List<_ContainerLiteral>? _listLiterals;
  List<_ContainerLiteral>? _setLiterals;
  List<_RecordLiteral>? _recordLiterals;
  List<_RuntimeTypeUse>? _runtimeTypeUses;
  List<_ForInData>? _forInData;

  // TODO(johnniwinther): Remove these when CFE provides constants.
  List<ir.Constructor>? _externalConstructorNodes;
  List<ir.Field>? _fieldNodes;
  List<ir.Procedure>? _externalProcedureNodes;
  List<ir.SwitchStatement>? _switchStatementNodes;
  List<ir.StaticInvocation>? _foreignStaticInvocationNodes;
  bool _hasConstSymbolConstructorInvocation = false;

  ImpactData();

  ImpactData.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    _superInitializers =
        source.readListOrNull(() => _SuperInitializer.fromDataSource(source));
    _superSets = source.readListOrNull(() => source.readMemberNode());
    _superGets = source.readListOrNull(() => source.readMemberNode());
    _superInvocations =
        source.readListOrNull(() => _SuperInvocation.fromDataSource(source));
    _instanceSets =
        source.readListOrNull(() => _InstanceAccess.fromDataSource(source));
    _dynamicSets =
        source.readListOrNull(() => _DynamicAccess.fromDataSource(source));
    _instanceGets =
        source.readListOrNull(() => _InstanceAccess.fromDataSource(source));
    _dynamicGets =
        source.readListOrNull(() => _DynamicAccess.fromDataSource(source));
    _functionInvocations =
        source.readListOrNull(() => _FunctionInvocation.fromDataSource(source));
    _instanceInvocations =
        source.readListOrNull(() => _InstanceInvocation.fromDataSource(source));
    _dynamicInvocations =
        source.readListOrNull(() => _DynamicInvocation.fromDataSource(source));
    _localFunctionInvocations = source
        .readListOrNull(() => _LocalFunctionInvocation.fromDataSource(source));
    _staticInvocations =
        source.readListOrNull(() => _StaticInvocation.fromDataSource(source));
    _constructorInvocations = source
        .readListOrNull(() => _ConstructorInvocation.fromDataSource(source));
    _features = EnumSet<_Feature>.fromValue(source.readInt());
    _typeUses = source.readListOrNull(() => _TypeUse.fromDataSource(source));
    _redirectingInitializers = source
        .readListOrNull(() => _RedirectingInitializer.fromDataSource(source));
    _fieldInitializers = source.readMemberNodesOrNull<ir.Field>();
    _fieldConstantInitializers =
        source.readMemberNodeMapOrNull(source.readTreeNodes);
    _typeLiterals =
        source.readListOrNull(() => _TypeLiteral.fromDataSource(source));
    _localFunctions = source.readTreeNodesOrNull();
    _genericInstantiations = source
        .readListOrNull(() => _GenericInstantiation.fromDataSource(source));
    _staticSets =
        source.readListOrNull(() => _StaticAccess.fromDataSource(source));
    _staticGets =
        source.readListOrNull(() => _StaticAccess.fromDataSource(source));
    _staticTearOffs =
        source.readListOrNull(() => _StaticAccess.fromDataSource(source));
    _weakStaticTearOffs =
        source.readListOrNull(() => _StaticAccess.fromDataSource(source));
    _mapLiterals =
        source.readListOrNull(() => _MapLiteral.fromDataSource(source));
    _listLiterals =
        source.readListOrNull(() => _ContainerLiteral.fromDataSource(source));
    _setLiterals =
        source.readListOrNull(() => _ContainerLiteral.fromDataSource(source));
    _recordLiterals =
        source.readListOrNull(() => _RecordLiteral.fromDataSource(source));
    _runtimeTypeUses =
        source.readListOrNull(() => _RuntimeTypeUse.fromDataSource(source));
    _forInData = source.readListOrNull(() => _ForInData.fromDataSource(source));

    // TODO(johnniwinther): Remove these when CFE provides constants.
    _externalConstructorNodes = source.readMemberNodesOrNull<ir.Constructor>();
    _fieldNodes = source.readMemberNodesOrNull<ir.Field>();
    _externalProcedureNodes = source.readMemberNodesOrNull<ir.Procedure>();
    _switchStatementNodes = source.readTreeNodesOrNull<ir.SwitchStatement>();
    _foreignStaticInvocationNodes =
        source.readTreeNodesOrNull<ir.StaticInvocation>();
    _hasConstSymbolConstructorInvocation = source.readBool();
    source.end(tag);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);

    sink.writeList(
        _superInitializers, (_SuperInitializer o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_superSets, sink.writeMemberNode, allowNull: true);
    sink.writeList(_superGets, sink.writeMemberNode, allowNull: true);
    sink.writeList(
        _superInvocations, (_SuperInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_instanceSets, (_InstanceAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_dynamicSets, (_DynamicAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_instanceGets, (_InstanceAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_dynamicGets, (_DynamicAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(
        _functionInvocations, (_FunctionInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(
        _instanceInvocations, (_InstanceInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(
        _dynamicInvocations, (_DynamicInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_localFunctionInvocations,
        (_LocalFunctionInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(
        _staticInvocations, (_StaticInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_constructorInvocations,
        (_ConstructorInvocation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeInt(_features?.value ?? 0);
    sink.writeList(_typeUses, (_TypeUse o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_redirectingInitializers,
        (_RedirectingInitializer o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeMemberNodes(_fieldInitializers, allowNull: true);
    sink.writeMemberNodeMap(_fieldConstantInitializers, sink.writeTreeNodes,
        allowNull: true);
    sink.writeList(_typeLiterals, (_TypeLiteral o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeTreeNodes(_localFunctions, allowNull: true);
    sink.writeList(
        _genericInstantiations, (_GenericInstantiation o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_staticSets, (_StaticAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_staticGets, (_StaticAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_staticTearOffs, (_StaticAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_weakStaticTearOffs, (_StaticAccess o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_mapLiterals, (_MapLiteral o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_listLiterals, (_ContainerLiteral o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_setLiterals, (_ContainerLiteral o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_recordLiterals, (_RecordLiteral o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_runtimeTypeUses, (_RuntimeTypeUse o) => o.toDataSink(sink),
        allowNull: true);
    sink.writeList(_forInData, (_ForInData o) => o.toDataSink(sink),
        allowNull: true);

    sink.writeMemberNodes(_externalConstructorNodes, allowNull: true);
    sink.writeMemberNodes(_fieldNodes, allowNull: true);
    sink.writeMemberNodes(_externalProcedureNodes, allowNull: true);
    sink.writeTreeNodes(_switchStatementNodes, allowNull: true);
    sink.writeTreeNodes(_foreignStaticInvocationNodes, allowNull: true);
    sink.writeBool(_hasConstSymbolConstructorInvocation);

    sink.end(tag);
  }

  /// Registers the impact data with [registry].
  void apply(ImpactRegistry registry) {
    if (_superInitializers != null) {
      for (_SuperInitializer data in _superInitializers!) {
        registry.registerSuperInitializer(
            data.source,
            data.target,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_superSets != null) {
      for (ir.Member data in _superSets!) {
        registry.registerSuperSet(data);
      }
    }
    if (_superGets != null) {
      for (ir.Member data in _superGets!) {
        registry.registerSuperGet(data);
      }
    }
    if (_superInvocations != null) {
      for (_SuperInvocation data in _superInvocations!) {
        registry.registerSuperInvocation(
            data.target,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_instanceSets != null) {
      for (_InstanceAccess data in _instanceSets!) {
        registry.registerInstanceSet(
            data.receiverType, data.classRelation, data.target);
      }
    }
    if (_dynamicSets != null) {
      for (_DynamicAccess data in _dynamicSets!) {
        registry.registerDynamicSet(
            data.receiverType, data.classRelation, data.name);
      }
    }
    if (_instanceGets != null) {
      for (_InstanceAccess data in _instanceGets!) {
        registry.registerInstanceGet(
            data.receiverType, data.classRelation, data.target);
      }
    }
    if (_dynamicGets != null) {
      for (_DynamicAccess data in _dynamicGets!) {
        registry.registerDynamicGet(
            data.receiverType, data.classRelation, data.name);
      }
    }
    if (_functionInvocations != null) {
      for (_FunctionInvocation data in _functionInvocations!) {
        registry.registerFunctionInvocation(
            data.receiverType,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_instanceInvocations != null) {
      for (_InstanceInvocation data in _instanceInvocations!) {
        registry.registerInstanceInvocation(
            data.receiverType,
            data.classRelation,
            data.target,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_dynamicInvocations != null) {
      for (_DynamicInvocation data in _dynamicInvocations!) {
        registry.registerDynamicInvocation(
            data.receiverType,
            data.classRelation,
            data.name,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_localFunctionInvocations != null) {
      for (_LocalFunctionInvocation data in _localFunctionInvocations!) {
        registry.registerLocalFunctionInvocation(
            data.localFunction,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_staticInvocations != null) {
      for (_StaticInvocation data in _staticInvocations!) {
        registry.registerStaticInvocation(
            data.target,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments,
            data.import);
        ;
      }
    }
    if (_constructorInvocations != null) {
      for (_ConstructorInvocation data in _constructorInvocations!) {
        registry.registerNew(
            data.constructor,
            data.type,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments,
            data.import,
            isConst: data.isConst);
      }
    }
    if (_constInstantiations != null) {
      for (_ConstInstantiation data in _constInstantiations!) {
        registry.registerConstInstantiation(
            data.cls, data.typeArguments, data.import);
      }
    }
    if (_features != null) {
      for (_Feature data in _features!.iterable(_Feature.values)) {
        switch (data) {
          case _Feature.lazyField:
            registry.registerLazyField();
            break;
          case _Feature.loadLibrary:
            registry.registerLoadLibrary();
            break;
          case _Feature.stackTrace:
            registry.registerStackTrace();
            break;
          case _Feature.catchClause:
            registry.registerCatch();
            break;
          case _Feature.throwExpression:
            registry.registerThrow();
            break;
          case _Feature.localWithoutInitializer:
            registry.registerLocalWithoutInitializer();
            break;
          case _Feature.stringConcatenation:
            registry.registerStringConcatenation();
            break;
          case _Feature.assertWithMessage:
            registry.registerAssert(withMessage: true);
            break;
          case _Feature.assertWithoutMessage:
            registry.registerAssert(withMessage: false);
            break;
          case _Feature.nullLiteral:
            registry.registerNullLiteral();
            break;
          case _Feature.symbolLiteral:
            registry.registerSymbolLiteral();
            break;
          case _Feature.stringLiteral:
            registry.registerStringLiteral();
            break;
          case _Feature.boolLiteral:
            registry.registerBoolLiteral();
            break;
          case _Feature.doubleLiteral:
            registry.registerDoubleLiteral();
            break;
          case _Feature.intLiteral:
            registry.registerIntLiteral();
            break;
        }
      }
    }
    if (_typeUses != null) {
      for (_TypeUse data in _typeUses!) {
        switch (data.kind) {
          case _TypeUseKind.parameterCheck:
            registry.registerParameterCheck(data.type);
            break;
          case _TypeUseKind.catchType:
            registry.registerCatchType(data.type);
            break;
          case _TypeUseKind.asCast:
            registry.registerAsCast(data.type);
            break;
          case _TypeUseKind.implicitCast:
            registry.registerImplicitCast(data.type);
            break;
          case _TypeUseKind.isCheck:
            registry.registerIsCheck(data.type);
            break;
          case _TypeUseKind.asyncStarMarker:
            registry.registerAsyncStar(data.type);
            break;
          case _TypeUseKind.asyncMarker:
            registry.registerAsync(data.type);
            break;
          case _TypeUseKind.syncStarMarker:
            registry.registerSyncStar(data.type);
            break;
        }
      }
    }
    if (_redirectingInitializers != null) {
      for (_RedirectingInitializer data in _redirectingInitializers!) {
        registry.registerRedirectingInitializer(
            data.constructor,
            data.callStructure.positionalArguments,
            data.callStructure.namedArguments,
            data.callStructure.typeArguments);
      }
    }
    if (_fieldInitializers != null) {
      for (ir.Field data in _fieldInitializers!) {
        registry.registerFieldInitialization(data);
      }
    }
    if (_fieldConstantInitializers != null) {
      _fieldConstantInitializers!
          .forEach((ir.Field field, List<ConstantReference> constants) {
        for (ConstantReference constant in constants) {
          registry.registerFieldConstantInitialization(field, constant);
        }
      });
    }
    if (_typeLiterals != null) {
      for (_TypeLiteral data in _typeLiterals!) {
        registry.registerTypeLiteral(data.type, data.import);
      }
    }
    if (_localFunctions != null) {
      for (ir.TreeNode data in _localFunctions!) {
        registry.registerLocalFunction(data);
      }
    }
    if (_genericInstantiations != null) {
      for (_GenericInstantiation data in _genericInstantiations!) {
        registry.registerGenericInstantiation(
            data.expressionType, data.typeArguments);
      }
    }
    if (_staticSets != null) {
      for (_StaticAccess data in _staticSets!) {
        registry.registerStaticSet(data.target, data.import);
      }
    }
    if (_staticGets != null) {
      for (_StaticAccess data in _staticGets!) {
        registry.registerStaticGet(data.target, data.import);
      }
    }
    if (_staticTearOffs != null) {
      for (_StaticAccess data in _staticTearOffs!) {
        registry.registerStaticTearOff(
            data.target as ir.Procedure, data.import);
      }
    }
    if (_weakStaticTearOffs != null) {
      for (_StaticAccess data in _weakStaticTearOffs!) {
        registry.registerWeakStaticTearOff(
            data.target as ir.Procedure, data.import);
      }
    }
    if (_mapLiterals != null) {
      for (_MapLiteral data in _mapLiterals!) {
        registry.registerMapLiteral(data.keyType, data.valueType,
            isConst: data.isConst, isEmpty: data.isEmpty);
      }
    }
    if (_listLiterals != null) {
      for (_ContainerLiteral data in _listLiterals!) {
        registry.registerListLiteral(data.elementType,
            isConst: data.isConst, isEmpty: data.isEmpty);
      }
    }
    if (_setLiterals != null) {
      for (_ContainerLiteral data in _setLiterals!) {
        registry.registerSetLiteral(data.elementType,
            isConst: data.isConst, isEmpty: data.isEmpty);
      }
    }
    if (_recordLiterals != null) {
      for (_RecordLiteral data in _recordLiterals!) {
        registry.registerRecordLiteral(data.recordType, isConst: data.isConst);
      }
    }
    if (_runtimeTypeUses != null) {
      for (_RuntimeTypeUse data in _runtimeTypeUses!) {
        registry.registerRuntimeTypeUse(
            data.kind, data.receiverType, data.argumentType);
      }
    }
    if (_forInData != null) {
      for (_ForInData data in _forInData!) {
        if (data.isAsync) {
          registry.registerAsyncForIn(
              data.iterableType, data.iteratorType, data.iteratorClassRelation);
        } else {
          registry.registerSyncForIn(
              data.iterableType, data.iteratorType, data.iteratorClassRelation);
        }
      }
    }

    // TODO(johnniwinther): Remove these when CFE provides constants.
    if (_externalConstructorNodes != null) {
      for (ir.Constructor data in _externalConstructorNodes!) {
        registry.registerExternalConstructorNode(data);
      }
    }
    if (_fieldNodes != null) {
      for (ir.Field data in _fieldNodes!) {
        registry.registerFieldNode(data);
      }
    }
    if (_externalProcedureNodes != null) {
      for (ir.Procedure data in _externalProcedureNodes!) {
        registry.registerExternalProcedureNode(data);
      }
    }
    if (_switchStatementNodes != null) {
      for (ir.SwitchStatement data in _switchStatementNodes!) {
        registry.registerSwitchStatementNode(data);
      }
    }
    if (_foreignStaticInvocationNodes != null) {
      for (ir.StaticInvocation data in _foreignStaticInvocationNodes!) {
        registry.registerForeignStaticInvocationNode(data);
      }
    }
    if (_hasConstSymbolConstructorInvocation) {
      registry.registerConstSymbolConstructorInvocationNode();
    }
  }
}

class _CallStructure {
  static const String tag = '_CallStructure';

  final List<ir.DartType> typeArguments;
  final int positionalArguments;
  final List<String> namedArguments;

  _CallStructure.internal(
      this.typeArguments, this.positionalArguments, this.namedArguments);

  factory _CallStructure(int positionalArguments, List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    return _CallStructure.internal(
        typeArguments, positionalArguments, namedArguments);
  }

  factory _CallStructure.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    List<ir.DartType> typeArguments = source.readDartTypeNodes();
    int positionalArguments = source.readInt();
    List<String> namedArguments = source.readStrings() ?? const [];
    source.end(tag);
    return _CallStructure.internal(
        typeArguments, positionalArguments, namedArguments);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNodes(typeArguments);
    sink.writeInt(positionalArguments);
    sink.writeStrings(namedArguments);
    sink.end(tag);
  }
}

class _SuperInitializer {
  static const String tag = '_SuperInitializer';

  final ir.Constructor source;
  final ir.Constructor target;
  final _CallStructure callStructure;

  _SuperInitializer(this.source, this.target, this.callStructure);

  factory _SuperInitializer.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Constructor sourceConstructor =
        source.readMemberNode() as ir.Constructor;
    ir.Constructor targetConstructor =
        source.readMemberNode() as ir.Constructor;
    _CallStructure callStructure = _CallStructure.fromDataSource(source);
    source.end(tag);
    return _SuperInitializer(
        sourceConstructor, targetConstructor, callStructure);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeMemberNode(source);
    sink.writeMemberNode(target);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _SuperInvocation {
  static const String tag = '_SuperInvocation';

  final ir.Member target;
  final _CallStructure callStructure;

  _SuperInvocation(this.target, this.callStructure);

  factory _SuperInvocation.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Member member = source.readMemberNode();
    _CallStructure callStructure = _CallStructure.fromDataSource(source);
    source.end(tag);
    return _SuperInvocation(member, callStructure);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeMemberNode(target);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _InstanceAccess {
  static const String tag = '_InstanceAccess';

  final ir.DartType receiverType;
  final ClassRelation classRelation;
  final ir.Member target;

  _InstanceAccess(this.receiverType, this.classRelation, this.target);

  factory _InstanceAccess.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.DartType receiverType = source.readDartTypeNode();
    ClassRelation classRelation = source.readEnum(ClassRelation.values);
    ir.Member target = source.readMemberNode();
    source.end(tag);
    return _InstanceAccess(receiverType, classRelation, target);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(receiverType);
    sink.writeEnum(classRelation);
    sink.writeMemberNode(target);
    sink.end(tag);
  }
}

class _DynamicAccess {
  static const String tag = '_DynamicAccess';

  final ir.DartType receiverType;
  final ClassRelation classRelation;
  final ir.Name name;

  _DynamicAccess(this.receiverType, this.classRelation, this.name);

  factory _DynamicAccess.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.DartType receiverType = source.readDartTypeNode();
    ClassRelation classRelation = source.readEnum(ClassRelation.values);
    ir.Name name = source.readName();
    source.end(tag);
    return _DynamicAccess(receiverType, classRelation, name);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(receiverType);
    sink.writeEnum(classRelation);
    sink.writeName(name);
    sink.end(tag);
  }
}

class _FunctionInvocation {
  static const String tag = '_FunctionInvocation';

  final ir.DartType receiverType;
  final _CallStructure callStructure;

  _FunctionInvocation(this.receiverType, this.callStructure);

  factory _FunctionInvocation.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.DartType receiverType = source.readDartTypeNode();
    _CallStructure callStructure = _CallStructure.fromDataSource(source);
    source.end(tag);
    return _FunctionInvocation(receiverType, callStructure);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(receiverType);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _InstanceInvocation {
  static const String tag = '_InstanceInvocation';

  final ir.DartType receiverType;
  final ClassRelation classRelation;
  final ir.Member target;
  final _CallStructure callStructure;

  _InstanceInvocation(
      this.receiverType, this.classRelation, this.target, this.callStructure);

  factory _InstanceInvocation.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.DartType receiverType = source.readDartTypeNode();
    ClassRelation classRelation = source.readEnum(ClassRelation.values);
    ir.Member target = source.readMemberNode();
    _CallStructure callStructure = _CallStructure.fromDataSource(source);
    source.end(tag);
    return _InstanceInvocation(
        receiverType, classRelation, target, callStructure);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(receiverType);
    sink.writeEnum(classRelation);
    sink.writeMemberNode(target);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _DynamicInvocation {
  static const String tag = '_DynamicInvocation';

  final ir.DartType receiverType;
  final ClassRelation classRelation;
  final ir.Name name;
  final _CallStructure callStructure;

  _DynamicInvocation(
      this.receiverType, this.classRelation, this.name, this.callStructure);

  factory _DynamicInvocation.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.DartType receiverType = source.readDartTypeNode();
    ClassRelation classRelation = source.readEnum(ClassRelation.values);
    ir.Name name = source.readName();
    _CallStructure callStructure = _CallStructure.fromDataSource(source);
    source.end(tag);
    return _DynamicInvocation(receiverType, classRelation, name, callStructure);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(receiverType);
    sink.writeEnum(classRelation);
    sink.writeName(name);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _LocalFunctionInvocation {
  static const String tag = '_LocalFunctionInvocation';

  final ir.FunctionDeclaration localFunction;
  final _CallStructure callStructure;

  _LocalFunctionInvocation(this.localFunction, this.callStructure);

  factory _LocalFunctionInvocation.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.FunctionDeclaration localFunction =
        source.readTreeNode() as ir.FunctionDeclaration;
    _CallStructure callStructure = _CallStructure.fromDataSource(source);
    source.end(tag);
    return _LocalFunctionInvocation(localFunction, callStructure);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeTreeNode(localFunction);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _StaticInvocation {
  static const String tag = '_StaticInvocation';

  final ir.Procedure target;
  final _CallStructure callStructure;
  final ir.LibraryDependency? import;

  _StaticInvocation(this.target, this.callStructure, this.import);

  factory _StaticInvocation.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Procedure target = source.readMemberNode() as ir.Procedure;
    _CallStructure callStructure = _CallStructure.fromDataSource(source);
    ir.LibraryDependency? import = source.readLibraryDependencyNodeOrNull();
    source.end(tag);
    return _StaticInvocation(target, callStructure, import);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeMemberNode(target);
    callStructure.toDataSink(sink);
    sink.writeLibraryDependencyNodeOrNull(import);
    sink.end(tag);
  }
}

class _ConstructorInvocation {
  static const String tag = '_ConstructorInvocation';

  final ir.Member constructor;
  final ir.InterfaceType type;
  final _CallStructure callStructure;
  final ir.LibraryDependency? import;
  final bool isConst;

  _ConstructorInvocation(
      this.constructor, this.type, this.callStructure, this.import,
      {required this.isConst});

  factory _ConstructorInvocation.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Member constructor = source.readMemberNode();
    ir.InterfaceType type = source.readDartTypeNode() as ir.InterfaceType;
    _CallStructure callStructure = _CallStructure.fromDataSource(source);
    ir.LibraryDependency? import = source.readLibraryDependencyNodeOrNull();
    bool isConst = source.readBool();
    source.end(tag);
    return _ConstructorInvocation(constructor, type, callStructure, import,
        isConst: isConst);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeMemberNode(constructor);
    sink.writeDartTypeNode(type);
    callStructure.toDataSink(sink);
    sink.writeLibraryDependencyNodeOrNull(import);
    sink.writeBool(isConst);
    sink.end(tag);
  }
}

class _ConstInstantiation {
  final ir.Class cls;
  final List<ir.DartType> typeArguments;
  final ir.LibraryDependency? import;

  _ConstInstantiation(this.cls, this.typeArguments, this.import);
}

enum _Feature {
  lazyField,
  loadLibrary,
  stackTrace,
  catchClause,
  throwExpression,
  localWithoutInitializer,
  stringConcatenation,
  assertWithMessage,
  assertWithoutMessage,
  nullLiteral,
  stringLiteral,
  boolLiteral,
  intLiteral,
  symbolLiteral,
  doubleLiteral,
}

class _TypeUse {
  static const String tag = '_TypeUse';

  final ir.DartType type;
  final _TypeUseKind kind;

  _TypeUse(this.type, this.kind);

  factory _TypeUse.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.DartType type = source.readDartTypeNode();
    _TypeUseKind kind = source.readEnum(_TypeUseKind.values);
    source.end(tag);
    return _TypeUse(type, kind);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(type);
    sink.writeEnum(kind);
    sink.end(tag);
  }
}

enum _TypeUseKind {
  parameterCheck,
  catchType,
  asCast,
  implicitCast,
  isCheck,
  asyncStarMarker,
  asyncMarker,
  syncStarMarker,
}

class _RedirectingInitializer {
  static const String tag = '_RedirectingInitializer';

  final ir.Constructor constructor;
  final _CallStructure callStructure;

  _RedirectingInitializer(this.constructor, this.callStructure);

  factory _RedirectingInitializer.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Constructor constructor = source.readMemberNode() as ir.Constructor;
    _CallStructure callStructure = _CallStructure.fromDataSource(source);
    source.end(tag);
    return _RedirectingInitializer(constructor, callStructure);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeMemberNode(constructor);
    callStructure.toDataSink(sink);
    sink.end(tag);
  }
}

class _TypeLiteral {
  static const String tag = '_TypeLiteral';

  final ir.DartType type;
  final ir.LibraryDependency? import;

  _TypeLiteral(this.type, this.import);

  factory _TypeLiteral.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.DartType type = source.readDartTypeNode();
    ir.LibraryDependency? import = source.readLibraryDependencyNodeOrNull();
    source.end(tag);
    return _TypeLiteral(type, import);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(type);
    sink.writeLibraryDependencyNodeOrNull(import);
    sink.end(tag);
  }
}

class _GenericInstantiation {
  static const String tag = '_GenericInstantiation';

  final ir.FunctionType expressionType;
  final List<ir.DartType> typeArguments;

  _GenericInstantiation(this.expressionType, this.typeArguments);

  factory _GenericInstantiation.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.FunctionType expressionType =
        source.readDartTypeNode() as ir.FunctionType;
    List<ir.DartType> typeArguments = source.readDartTypeNodes();
    source.end(tag);
    return _GenericInstantiation(expressionType, typeArguments);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(expressionType);
    sink.writeDartTypeNodes(typeArguments);
    sink.end(tag);
  }
}

class _StaticAccess {
  static const String tag = '_StaticAccess';

  final ir.Member target;
  final ir.LibraryDependency? import;

  _StaticAccess(this.target, this.import);

  factory _StaticAccess.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Member target = source.readMemberNode();
    ir.LibraryDependency? import = source.readLibraryDependencyNodeOrNull();
    source.end(tag);
    return _StaticAccess(target, import);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeMemberNode(target);
    sink.writeLibraryDependencyNodeOrNull(import);
    sink.end(tag);
  }
}

class _MapLiteral {
  static const String tag = '_MapLiteral';

  final ir.DartType keyType;
  final ir.DartType valueType;
  final bool isConst;
  final bool isEmpty;

  _MapLiteral(this.keyType, this.valueType,
      {required this.isConst, required this.isEmpty});

  factory _MapLiteral.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.DartType keyType = source.readDartTypeNode();
    ir.DartType valueType = source.readDartTypeNode();
    bool isConst = source.readBool();
    bool isEmpty = source.readBool();
    source.end(tag);
    return _MapLiteral(keyType, valueType, isConst: isConst, isEmpty: isEmpty);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(keyType);
    sink.writeDartTypeNode(valueType);
    sink.writeBool(isConst);
    sink.writeBool(isEmpty);
    sink.end(tag);
  }
}

class _ContainerLiteral {
  static const String tag = '_ContainerLiteral';

  final ir.DartType elementType;
  final bool isConst;
  final bool isEmpty;

  _ContainerLiteral(this.elementType,
      {required this.isConst, required this.isEmpty});

  factory _ContainerLiteral.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.DartType elementType = source.readDartTypeNode();
    bool isConst = source.readBool();
    bool isEmpty = source.readBool();
    source.end(tag);
    return _ContainerLiteral(elementType, isConst: isConst, isEmpty: isEmpty);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(elementType);
    sink.writeBool(isConst);
    sink.writeBool(isEmpty);
    sink.end(tag);
  }
}

class _RecordLiteral {
  static const String tag = '_RecordLiteral';

  final ir.RecordType recordType;
  final bool isConst;

  _RecordLiteral(this.recordType, {required this.isConst});

  factory _RecordLiteral.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.RecordType recordType = source.readDartTypeNode() as ir.RecordType;
    bool isConst = source.readBool();
    source.end(tag);
    return _RecordLiteral(recordType, isConst: isConst);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(recordType);
    sink.writeBool(isConst);
    sink.end(tag);
  }
}

class _RuntimeTypeUse {
  static const String tag = '_RuntimeTypeUse';

  final RuntimeTypeUseKind kind;
  final ir.DartType receiverType;
  final ir.DartType? argumentType;

  _RuntimeTypeUse(this.kind, this.receiverType, this.argumentType);

  factory _RuntimeTypeUse.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    RuntimeTypeUseKind kind = source.readEnum(RuntimeTypeUseKind.values);
    ir.DartType receiverType = source.readDartTypeNode();
    ir.DartType? argumentType = source.readDartTypeNodeOrNull();
    source.end(tag);
    return _RuntimeTypeUse(kind, receiverType, argumentType);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    sink.writeDartTypeNode(receiverType);
    sink.writeDartTypeNodeOrNull(argumentType);
    sink.end(tag);
  }
}

class _ForInData {
  static const String tag = '_ForInData';

  final ir.DartType iterableType;
  final ir.DartType iteratorType;
  final ClassRelation iteratorClassRelation;
  final bool isAsync;

  _ForInData(this.iterableType, this.iteratorType, this.iteratorClassRelation,
      {required this.isAsync});

  factory _ForInData.fromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.DartType iterableType = source.readDartTypeNode();
    ir.DartType iteratorType = source.readDartTypeNode();
    ClassRelation iteratorClassRelation = source.readEnum(ClassRelation.values);
    bool isAsync = source.readBool();
    source.end(tag);
    return _ForInData(iterableType, iteratorType, iteratorClassRelation,
        isAsync: isAsync);
  }

  void toDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartTypeNode(iteratorType);
    sink.writeDartTypeNode(iteratorType);
    sink.writeEnum(iteratorClassRelation);
    sink.writeBool(isAsync);
    sink.end(tag);
  }
}
