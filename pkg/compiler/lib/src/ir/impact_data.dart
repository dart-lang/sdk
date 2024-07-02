// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/static_weak_references.dart' as ir
    show StaticWeakReferences;
import 'package:front_end/src/api_unstable/dart2js.dart' show Operator;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;

import '../common.dart';
import '../common/elements.dart';
import '../common/names.dart' show Identifiers, Uris;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../kernel/element_map.dart';
import '../options.dart';
import '../util/enumset.dart';
import 'constants.dart';
import 'impact.dart';
import 'protobuf_impacts.dart';
import 'runtime_type_analysis.dart';
import 'util.dart';

/// Checks [node] against available [ConditionalImpactHandler] to see if any
/// are applicable to it. Returns null if there is no matching handler.
ConditionalImpactHandler? _getConditionalImpactHandler(
    KernelToElementMap elementMap, ir.Member node) {
  return ProtobufImpactHandler.createIfApplicable(elementMap, node);
}

abstract class ConditionalImpactHandler {
  /// Invoked before children of [node] are analyzed. Returns a temporary
  /// [ImpactData] if one should be used for the scope of [node] or null
  /// otherwise.
  ImpactData? beforeInstanceInvocation(ir.InstanceInvocation node);

  /// Invoked after children of [node] are analyzed. Returns a
  /// [ConditionalImpactData] containing the conditional data to register for
  /// [node]. Returns null if [node] is not relevant to this handler.
  ConditionalImpactData? afterInstanceInvocation(ir.InstanceInvocation node);
}

class _ConditionalImpactBuilder extends ImpactBuilder {
  final ConditionalImpactHandler _conditionalHandler;

  _ConditionalImpactBuilder._(
      super.elementMap, super.node, this._conditionalHandler)
      : super._();

  @override
  void visitInstanceInvocation(ir.InstanceInvocation node) {
    final oldData = _data;
    _data = _conditionalHandler.beforeInstanceInvocation(node) ?? _data;

    super.visitInstanceInvocation(node);

    final conditionalData = _conditionalHandler.afterInstanceInvocation(node);
    if (conditionalData != null) {
      final replacement = conditionalData.replacement;
      if (replacement != null) {
        final replacementImpact = _data = ImpactData();
        replacement.accept(this);
        conditionalData.replacementImpactData = replacementImpact;
      }
      _data = oldData;
      registerConditionalImpact(conditionalData);
    } else {
      _data = oldData;
    }
  }
}

/// Visitor that builds an [ImpactData] object for the world impact.
class ImpactBuilder extends ir.RecursiveVisitor implements ImpactRegistry {
  ImpactData _data = ImpactData();
  final ir.Member node;
  final KernelToElementMap _elementMap;
  final ir.StaticTypeContext staticTypeContext;

  factory ImpactBuilder(KernelToElementMap elementMap, ir.Member node) {
    final conditionalHandler = _getConditionalImpactHandler(elementMap, node);

    return conditionalHandler != null
        ? _ConditionalImpactBuilder._(elementMap, node, conditionalHandler)
        : ImpactBuilder._(elementMap, node);
  }

  ImpactBuilder._(this._elementMap, this.node)
      : staticTypeContext =
            ir.StaticTypeContext(node, _elementMap.typeEnvironment);

  CommonElements get _commonElements => _elementMap.commonElements;
  DiagnosticReporter get _reporter => _elementMap.reporter;
  ir.ClassHierarchy get classHierarchy => _elementMap.classHierarchy;
  ir.TypeEnvironment get typeEnvironment => _elementMap.typeEnvironment;
  CompilerOptions get _options => _elementMap.options;

  String _typeToString(DartType type) =>
      type.toStructuredText(_elementMap.types, _elementMap.options);

  /// Return the named arguments names as a list of strings.
  List<String> _getNamedArguments(ir.Arguments arguments) =>
      arguments.named.map((n) => n.name).toList();

  ImpactBuilderData computeImpact() {
    node.accept(this);
    return ImpactBuilderData(node, _data);
  }

  @override
  void visitBlock(ir.Block node) {
    assert(_pendingRuntimeTypeUseData.isEmpty,
        "Incomplete RuntimeTypeUseData: $_pendingRuntimeTypeUseData");
    node.statements.forEach((e) => e.accept(this));
    assert(_pendingRuntimeTypeUseData.isEmpty,
        "Incomplete RuntimeTypeUseData: $_pendingRuntimeTypeUseData");
  }

  @override
  void visitIntLiteral(ir.IntLiteral node) {
    registerIntLiteral();
  }

  @override
  void visitDoubleLiteral(ir.DoubleLiteral node) {
    registerDoubleLiteral();
  }

  @override
  void visitBoolLiteral(ir.BoolLiteral node) {
    registerBoolLiteral();
  }

  @override
  void visitStringLiteral(ir.StringLiteral node) {
    registerStringLiteral();
  }

  @override
  void visitSymbolLiteral(ir.SymbolLiteral node) {
    registerSymbolLiteral();
  }

  @override
  void visitNullLiteral(ir.NullLiteral node) {
    registerNullLiteral();
  }

  @override
  void visitListLiteral(ir.ListLiteral node) {
    registerListLiteral(node.typeArgument,
        isConst: node.isConst, isEmpty: node.expressions.isEmpty);
    node.expressions.forEach((e) => e.accept(this));
  }

  @override
  void visitSetLiteral(ir.SetLiteral node) {
    registerSetLiteral(node.typeArgument,
        isConst: node.isConst, isEmpty: node.expressions.isEmpty);
    node.expressions.forEach((e) => e.accept(this));
  }

  @override
  void visitMapLiteral(ir.MapLiteral node) {
    registerMapLiteral(node.keyType, node.valueType,
        isConst: node.isConst, isEmpty: node.entries.isEmpty);
    node.entries.forEach((e) => e.accept(this));
  }

  @override
  void visitRecordLiteral(ir.RecordLiteral node) {
    registerRecordLiteral(node.recordType, isConst: node.isConst);
    node.positional.forEach((e) => e.accept(this));
    node.named.forEach((e) => e.value.accept(this));
  }

  @override
  void visitStaticGet(ir.StaticGet node) {
    registerStaticGet(node.target, getDeferredImport(node));
  }

  @override
  void visitStaticTearOff(ir.StaticTearOff node) {
    registerStaticTearOff(node.target, getDeferredImport(node));
  }

  @override
  void visitStaticSet(ir.StaticSet node) {
    registerStaticSet(node.target, getDeferredImport(node));
    node.value.accept(this);
  }

  @override
  void visitAssertStatement(ir.AssertStatement node) {
    registerAssert(withMessage: node.message != null);
    node.condition.accept(this);
    node.message?.accept(this);
  }

  @override
  void visitInstantiation(ir.Instantiation node) {
    registerGenericInstantiation(
        node.expression.getStaticType(staticTypeContext) as ir.FunctionType,
        node.typeArguments);
    node.expression.accept(this);
  }

  void handleAsyncMarker(ir.FunctionNode function) {
    switch (function.asyncMarker) {
      case ir.AsyncMarker.Sync:
        break;

      case ir.AsyncMarker.SyncStar:
        registerSyncStar(function.emittedValueType!);
        break;

      case ir.AsyncMarker.Async:
        registerAsync(function.emittedValueType!);
        break;

      case ir.AsyncMarker.AsyncStar:
        registerAsyncStar(function.emittedValueType!);
        break;
    }
  }

  @override
  void visitStringConcatenation(ir.StringConcatenation node) {
    registerStringConcatenation();
    node.expressions.forEach((e) => e.accept(this));
  }

  @override
  void visitFunctionDeclaration(ir.FunctionDeclaration node) {
    registerLocalFunction(node);
    node.function.accept(this);
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression node) {
    registerLocalFunction(node);
    node.function.accept(this);
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration node) {
    if (node.initializer == null) {
      registerLocalWithoutInitializer();
    }
    // Don't visit the annotations as any impacts generated by that code are not
    // real and should not be included in compiled code.
    node.initializer?.accept(this);
  }

  @override
  void visitIsExpression(ir.IsExpression node) {
    registerIsCheck(node.type);
    node.operand.accept(this);
  }

  @override
  void visitAsExpression(ir.AsExpression node) {
    final operandType = node.operand.getStaticType(staticTypeContext);
    final isCalculatedTypeSubtype = typeEnvironment.isSubtypeOf(
        operandType, node.type, ir.SubtypeCheckMode.withNullabilities);
    if (!isCalculatedTypeSubtype) {
      // Only register needed cast.
      if (node.isTypeError) {
        registerImplicitCast(node.type);
      } else {
        registerAsCast(node.type);
      }
    }
    node.operand.accept(this);
  }

  @override
  void visitThrow(ir.Throw node) {
    registerThrow();
    node.expression.accept(this);
  }

  ir.InterfaceType? getInterfaceTypeOf(ir.DartType type) {
    while (type is ir.TypeParameterType) {
      type = type.parameter.bound;
    }
    if (type is ir.InterfaceType) {
      return type;
    } else if (type is ir.NullType) {
      return typeEnvironment.coreTypes.deprecatedNullType;
    }
    return null;
  }

  @override
  void visitForInStatement(ir.ForInStatement node) {
    // TODO(fishythefish): Clean up this logic.
    ir.DartType iterableType = node.iterable.getStaticType(staticTypeContext);
    ir.DartType iteratorType = const ir.DynamicType();
    ir.InterfaceType? iterableInterfaceType = getInterfaceTypeOf(iterableType);
    if (iterableInterfaceType != null) {
      if (node.isAsync) {
        List<ir.DartType>? typeArguments =
            typeEnvironment.getTypeArgumentsAsInstanceOf(
                iterableInterfaceType, typeEnvironment.coreTypes.streamClass);
        if (typeArguments != null) {
          iteratorType = ir.InterfaceType(
              typeEnvironment.coreTypes.streamIteratorClass,
              ir.Nullability.nonNullable,
              typeArguments);
        }
      } else {
        ir.Member? member = classHierarchy.getInterfaceMember(
            iterableInterfaceType.classNode, ir.Name(Identifiers.iterator));
        if (member != null) {
          iteratorType = ir.Substitution.fromTypeDeclarationType(
                  typeEnvironment.getTypeAsInstanceOf(iterableInterfaceType,
                      member.enclosingClass!, typeEnvironment.coreTypes)!)
              .substituteType(member.getterType);
        }
      }
    }
    if (node.isAsync) {
      registerAsyncForIn(
        iterableType,
        iteratorType,
      );
    } else {
      registerSyncForIn(iterableType, iteratorType);
    }
    node.iterable.accept(this);
    node.variable.accept(this);
    node.body.accept(this);
  }

  @override
  void visitCatch(ir.Catch node) {
    registerCatch();
    if (node.stackTrace != null) {
      registerStackTrace();
    }
    if (node.guard is! ir.DynamicType) {
      registerCatchType(node.guard);
    }
    node.body.accept(this);
  }

  @override
  void visitTypeLiteral(ir.TypeLiteral node) {
    registerTypeLiteral(node.type, getDeferredImport(node));
  }

  @override
  void visitFieldInitializer(ir.FieldInitializer node) {
    registerFieldInitialization(node.field);
    node.value.accept(this);
  }

  @override
  void visitLoadLibrary(ir.LoadLibrary node) {
    registerLoadLibrary();
  }

  @override
  void visitRedirectingInitializer(ir.RedirectingInitializer node) {
    registerRedirectingInitializer(
        node.target,
        node.arguments.positional.length,
        _getNamedArguments(node.arguments),
        node.arguments.types);
    node.arguments.accept(this);
  }

  @override
  void visitFunctionNode(ir.FunctionNode node) {
    handleAsyncMarker(node);
    for (ir.TypeParameter parameter in node.typeParameters) {
      registerParameterCheck(parameter.bound);
    }
    for (ir.VariableDeclaration parameter in node.positionalParameters) {
      registerParameterCheck(parameter.type);
      parameter.initializer?.accept(this);
    }
    for (ir.VariableDeclaration parameter in node.namedParameters) {
      registerParameterCheck(parameter.type);
      parameter.initializer?.accept(this);
    }
    node.body?.accept(this);
  }

  @override
  void visitConstructor(ir.Constructor node) {
    if (node.isExternal) registerExternalConstructorNode(node);
    // Don't visit the annotations as any impacts generated by that code are not
    // real and should not be included in compiled code.
    node.initializers.forEach((e) => e.accept(this));
    node.function.accept(this);
  }

  @override
  void visitField(ir.Field node) {
    registerParameterCheck(node.type);
    if (node.initializer != null) {
      if (!node.isInstanceMember &&
          !node.isConst &&
          node.initializer is! ir.NullLiteral) {
        registerLazyField();
      }
    } else {
      registerNullLiteral();
    }
    // TODO(sigmund): only save relevant fields (e.g. those for jsinterop
    // or native types).
    registerFieldNode(node);
    // Don't visit the annotations as any impacts generated by that code are not
    // real and should not be included in compiled code.
    node.initializer?.accept(this);
  }

  @override
  void visitProcedure(ir.Procedure node) {
    if (node.isExternal) registerExternalProcedureNode(node);
    // Don't visit the annotations as any impacts generated by that code are not
    // real and should not be included in compiled code.
    node.function.accept(this);
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
  void visitConstructorInvocation(ir.ConstructorInvocation node) {
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
    node.arguments.accept(this);
  }

  @override
  void visitStaticInvocation(ir.StaticInvocation node) {
    if (ir.StaticWeakReferences.isWeakReference(node)) {
      registerWeakStaticTearOff(
          ir.StaticWeakReferences.getWeakReferenceTarget(node),
          getDeferredImport(
              ir.StaticWeakReferences.getWeakReferenceArgument(node)));
      // We don't explicitly visit the argument for weak references.
    } else {
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
      node.arguments.accept(this);
    }
  }

  @override
  void visitDynamicInvocation(ir.DynamicInvocation node) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
    final receiverType = node.receiver.getStaticType(staticTypeContext);
    registerDynamicInvocation(receiverType, node.name, positionArguments,
        namedArguments, typeArguments);
    if (Operator.fromText(node.name.text) == null &&
        receiverType is ir.DynamicType) {
      // We might implicitly call a getter that returns a function.
      registerFunctionInvocation(const ir.DynamicType(), positionArguments,
          namedArguments, typeArguments);
    }
    node.arguments.accept(this);
    node.receiver.accept(this);
  }

  @override
  void visitFunctionInvocation(ir.FunctionInvocation node) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
    final receiverType = node.receiver.getStaticType(staticTypeContext);
    registerFunctionInvocation(
        receiverType, positionArguments, namedArguments, typeArguments);
    node.arguments.accept(this);
    node.receiver.accept(this);
  }

  @override
  void visitInstanceInvocation(ir.InstanceInvocation node) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
    final receiverType = node.receiver.getStaticType(staticTypeContext);
    final interfaceTarget = node.interfaceTarget;

    if (interfaceTarget.kind == ir.ProcedureKind.Getter) {
      registerInstanceInvocation(receiverType, interfaceTarget,
          positionArguments, namedArguments, typeArguments);
      registerFunctionInvocation(interfaceTarget.getterType, positionArguments,
          namedArguments, typeArguments);
    } else {
      registerInstanceInvocation(receiverType, interfaceTarget,
          positionArguments, namedArguments, typeArguments);
    }
    node.arguments.accept(this);
    node.receiver.accept(this);
  }

  @override
  void visitLocalFunctionInvocation(ir.LocalFunctionInvocation node) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
    registerLocalFunctionInvocation(
        node.localFunction, positionArguments, namedArguments, typeArguments);
    node.arguments.accept(this);
  }

  @override
  void visitEqualsCall(ir.EqualsCall node) {
    final leftType = node.left.getStaticType(staticTypeContext);
    registerInstanceInvocation(leftType, node.interfaceTarget, 1,
        const <String>[], const <ir.DartType>[]);
    node.left.accept(this);
    node.right.accept(this);
  }

  @override
  void visitEqualsNull(ir.EqualsNull node) {
    registerNullLiteral();
    node.expression.accept(this);
  }

  @override
  void visitDynamicGet(ir.DynamicGet node) {
    final receiverType = node.receiver.getStaticType(staticTypeContext);
    registerDynamicGet(receiverType, node.name);
    node.receiver.accept(this);
  }

  @override
  void visitInstanceGet(ir.InstanceGet node) {
    final receiverType = node.receiver.getStaticType(staticTypeContext);
    registerInstanceGet(receiverType, node.interfaceTarget);
    if (node.name.text == Identifiers.runtimeType_) {
      // This handles `runtimeType` access on non-Never types, like in
      // `'foo'.runtimeType`.
      handleRuntimeTypeGet(receiverType, node);
    }
    node.receiver.accept(this);
  }

  @override
  void visitInstanceTearOff(ir.InstanceTearOff node) {
    final receiverType = node.receiver.getStaticType(staticTypeContext);
    registerInstanceGet(receiverType, node.interfaceTarget);
    assert(node.name.text != Identifiers.runtimeType_,
        "Unexpected .runtimeType instance tear-off.");
    node.receiver.accept(this);
  }

  @override
  void visitFunctionTearOff(ir.FunctionTearOff node) {
    final receiverType = node.receiver.getStaticType(staticTypeContext);
    registerDynamicGet(receiverType, ir.Name.callName);
    node.receiver.accept(this);
  }

  @override
  void visitInstanceGetterInvocation(ir.InstanceGetterInvocation node) {
    int positionArguments = node.arguments.positional.length;
    List<String> namedArguments = _getNamedArguments(node.arguments);
    List<ir.DartType> typeArguments = node.arguments.types;
    final receiverType = node.receiver.getStaticType(staticTypeContext);
    final interfaceTarget = node.interfaceTarget;

    if (interfaceTarget is ir.Field ||
        (interfaceTarget is ir.Procedure &&
            interfaceTarget.kind == ir.ProcedureKind.Getter)) {
      registerInstanceInvocation(receiverType, interfaceTarget,
          positionArguments, namedArguments, typeArguments);
      registerFunctionInvocation(interfaceTarget.getterType, positionArguments,
          namedArguments, typeArguments);
    } else {
      registerInstanceInvocation(receiverType, interfaceTarget,
          positionArguments, namedArguments, typeArguments);
    }
    node.receiver.accept(this);
    node.arguments.accept(this);
  }

  @override
  void visitDynamicSet(ir.DynamicSet node) {
    final receiverType = node.receiver.getStaticType(staticTypeContext);
    registerDynamicSet(receiverType, node.name);
    node.receiver.accept(this);
    node.value.accept(this);
  }

  @override
  void visitInstanceSet(ir.InstanceSet node) {
    final receiverType = node.receiver.getStaticType(staticTypeContext);
    registerInstanceSet(receiverType, node.interfaceTarget);
    node.receiver.accept(this);
    node.value.accept(this);
  }

  @override
  void visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    registerSuperInvocation(
        getEffectiveSuperTarget(node.interfaceTarget),
        node.arguments.positional.length,
        _getNamedArguments(node.arguments),
        node.arguments.types);
    node.arguments.accept(this);
  }

  @override
  void visitSuperPropertyGet(ir.SuperPropertyGet node) {
    registerSuperGet(getEffectiveSuperTarget(node.interfaceTarget));
  }

  @override
  void visitSuperPropertySet(ir.SuperPropertySet node) {
    registerSuperSet(getEffectiveSuperTarget(node.interfaceTarget));
    node.value.accept(this);
  }

  @override
  void visitSuperInitializer(ir.SuperInitializer node) {
    registerSuperInitializer(
        node.parent as ir.Constructor,
        node.target,
        node.arguments.positional.length,
        _getNamedArguments(node.arguments),
        node.arguments.types);
    node.arguments.accept(this);
  }

  final Map<ir.InstanceGet, RuntimeTypeUseData> _pendingRuntimeTypeUseData = {};

  void handleRuntimeTypeGet(ir.DartType receiverType, ir.InstanceGet node) {
    RuntimeTypeUseData data =
        computeRuntimeTypeUse(_pendingRuntimeTypeUseData, node);
    if (data.leftRuntimeTypeExpression == node) {
      // [node] is the left (or single) occurrence of `.runtimeType` so we
      // can set the static type of the receiver expression.
      data.receiverType = receiverType;
    } else {
      // [node] is the right occurrence of `.runtimeType` so we
      // can set the static type of the argument expression.
      assert(data.rightRuntimeTypeExpression == node,
          "Unexpected RuntimeTypeUseData for $node: $data");
      data.argumentType = receiverType;
    }
    if (data.isComplete) {
      /// We now have all need static types so we can remove the data from
      /// the cache and handle the runtime type use.
      _pendingRuntimeTypeUseData.remove(data.leftRuntimeTypeExpression);
      if (data.rightRuntimeTypeExpression != null) {
        _pendingRuntimeTypeUseData.remove(data.rightRuntimeTypeExpression);
      }
      handleRuntimeTypeUse(
          node, data.kind, data.receiverType!, data.argumentType);
    }
  }

  void handleRuntimeTypeUse(ir.Expression node, RuntimeTypeUseKind kind,
      ir.DartType receiverType, ir.DartType? argumentType) {
    if (_options.omitImplicitChecks) {
      switch (kind) {
        case RuntimeTypeUseKind.string:
          if (!_options.laxRuntimeTypeToString &&
              // Silent on Golem to avoid excessive compiler diagnostics.
              !_options.benchmarkingProduction) {
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
  void visitConstantExpression(ir.ConstantExpression node) {
    assert(node.constant is! ir.UnevaluatedConstant);
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
  void registerSuperSet(ir.Member target) {
    (_data._superSets ??= []).add(target);
  }

  @override
  void registerSuperGet(ir.Member target) {
    (_data._superGets ??= []).add(target);
  }

  @override
  void registerSuperInvocation(ir.Member target, int positionalArguments,
      List<String> namedArguments, List<ir.DartType> typeArguments) {
    (_data._superInvocations ??= []).add(_SuperInvocation(target,
        _CallStructure(positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerInstanceSet(ir.DartType receiverType, ir.Member target) {
    (_data._instanceSets ??= []).add(_InstanceAccess(receiverType, target));
  }

  @override
  void registerDynamicSet(ir.DartType receiverType, ir.Name name) {
    (_data._dynamicSets ??= []).add(_DynamicAccess(receiverType, name));
  }

  @override
  void registerInstanceGet(ir.DartType receiverType, ir.Member target) {
    (_data._instanceGets ??= []).add(_InstanceAccess(receiverType, target));
  }

  @override
  void registerDynamicGet(ir.DartType receiverType, ir.Name name) {
    (_data._dynamicGets ??= []).add(_DynamicAccess(receiverType, name));
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
      ir.Member target,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    (_data._instanceInvocations ??= []).add(_InstanceInvocation(
        receiverType,
        target,
        _CallStructure(positionalArguments, namedArguments, typeArguments)));
  }

  @override
  void registerDynamicInvocation(
      ir.DartType receiverType,
      ir.Name name,
      int positionalArguments,
      List<String> namedArguments,
      List<ir.DartType> typeArguments) {
    (_data._dynamicInvocations ??= []).add(_DynamicInvocation(
        receiverType,
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
  void registerAsyncForIn(ir.DartType iterableType, ir.DartType iteratorType) {
    (_data._forInData ??= [])
        .add(_ForInData(iterableType, iteratorType, isAsync: true));
  }

  @override
  void registerSyncForIn(ir.DartType iterableType, ir.DartType iteratorType) {
    (_data._forInData ??= [])
        .add(_ForInData(iterableType, iteratorType, isAsync: false));
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
  void registerConstSymbolConstructorInvocationNode() {
    _data._hasConstSymbolConstructorInvocation = true;
  }

  @override
  void registerConditionalImpact(ConditionalImpactData impact) {
    // Ensure conditional impact is registered on parent impact, `_data`.
    (_data._conditionalImpacts ??= []).add(impact);
  }
}

class ConditionalImpactData {
  final ir.TreeNode? original;
  final ir.TreeNode? replacement;
  final List<ir.Member> originalConditions;
  final ImpactData impactData;
  late ImpactData replacementImpactData;

  ConditionalImpactData(this.originalConditions, this.impactData,
      {this.original, this.replacement});
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
  List<ConditionalImpactData>? _conditionalImpacts;

  // TODO(johnniwinther): Remove these when CFE provides constants.
  List<ir.Constructor>? _externalConstructorNodes;
  List<ir.Field>? _fieldNodes;
  List<ir.Procedure>? _externalProcedureNodes;
  List<ir.StaticInvocation>? _foreignStaticInvocationNodes;
  bool _hasConstSymbolConstructorInvocation = false;

  ImpactData();

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
        registry.registerInstanceSet(data.receiverType, data.target);
      }
    }
    if (_dynamicSets != null) {
      for (_DynamicAccess data in _dynamicSets!) {
        registry.registerDynamicSet(data.receiverType, data.name);
      }
    }
    if (_instanceGets != null) {
      for (_InstanceAccess data in _instanceGets!) {
        registry.registerInstanceGet(data.receiverType, data.target);
      }
    }
    if (_dynamicGets != null) {
      for (_DynamicAccess data in _dynamicGets!) {
        registry.registerDynamicGet(data.receiverType, data.name);
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
          registry.registerAsyncForIn(data.iterableType, data.iteratorType);
        } else {
          registry.registerSyncForIn(data.iterableType, data.iteratorType);
        }
      }
    }

    _conditionalImpacts?.forEach(registry.registerConditionalImpact);

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
}

class _SuperInitializer {
  final ir.Constructor source;
  final ir.Constructor target;
  final _CallStructure callStructure;

  _SuperInitializer(this.source, this.target, this.callStructure);
}

class _SuperInvocation {
  final ir.Member target;
  final _CallStructure callStructure;

  _SuperInvocation(this.target, this.callStructure);
}

class _InstanceAccess {
  final ir.DartType receiverType;
  final ir.Member target;

  _InstanceAccess(this.receiverType, this.target);
}

class _DynamicAccess {
  final ir.DartType receiverType;
  final ir.Name name;

  _DynamicAccess(this.receiverType, this.name);
}

class _FunctionInvocation {
  final ir.DartType receiverType;
  final _CallStructure callStructure;

  _FunctionInvocation(this.receiverType, this.callStructure);
}

class _InstanceInvocation {
  final ir.DartType receiverType;
  final ir.Member target;
  final _CallStructure callStructure;

  _InstanceInvocation(this.receiverType, this.target, this.callStructure);
}

class _DynamicInvocation {
  final ir.DartType receiverType;
  final ir.Name name;
  final _CallStructure callStructure;

  _DynamicInvocation(this.receiverType, this.name, this.callStructure);
}

class _LocalFunctionInvocation {
  final ir.FunctionDeclaration localFunction;
  final _CallStructure callStructure;

  _LocalFunctionInvocation(this.localFunction, this.callStructure);
}

class _StaticInvocation {
  final ir.Procedure target;
  final _CallStructure callStructure;
  final ir.LibraryDependency? import;

  _StaticInvocation(this.target, this.callStructure, this.import);
}

class _ConstructorInvocation {
  final ir.Member constructor;
  final ir.InterfaceType type;
  final _CallStructure callStructure;
  final ir.LibraryDependency? import;
  final bool isConst;

  _ConstructorInvocation(
      this.constructor, this.type, this.callStructure, this.import,
      {required this.isConst});
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
  final ir.DartType type;
  final _TypeUseKind kind;

  _TypeUse(this.type, this.kind);
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
  final ir.Constructor constructor;
  final _CallStructure callStructure;

  _RedirectingInitializer(this.constructor, this.callStructure);
}

class _TypeLiteral {
  final ir.DartType type;
  final ir.LibraryDependency? import;

  _TypeLiteral(this.type, this.import);
}

class _GenericInstantiation {
  final ir.FunctionType expressionType;
  final List<ir.DartType> typeArguments;

  _GenericInstantiation(this.expressionType, this.typeArguments);
}

class _StaticAccess {
  final ir.Member target;
  final ir.LibraryDependency? import;

  _StaticAccess(this.target, this.import);
}

class _MapLiteral {
  final ir.DartType keyType;
  final ir.DartType valueType;
  final bool isConst;
  final bool isEmpty;

  _MapLiteral(this.keyType, this.valueType,
      {required this.isConst, required this.isEmpty});
}

class _ContainerLiteral {
  final ir.DartType elementType;
  final bool isConst;
  final bool isEmpty;

  _ContainerLiteral(this.elementType,
      {required this.isConst, required this.isEmpty});
}

class _RecordLiteral {
  final ir.RecordType recordType;
  final bool isConst;

  _RecordLiteral(this.recordType, {required this.isConst});
}

class _RuntimeTypeUse {
  final RuntimeTypeUseKind kind;
  final ir.DartType receiverType;
  final ir.DartType? argumentType;

  _RuntimeTypeUse(this.kind, this.receiverType, this.argumentType);
}

class _ForInData {
  final ir.DartType iterableType;
  final ir.DartType iteratorType;
  final bool isAsync;

  _ForInData(this.iterableType, this.iteratorType, {required this.isAsync});
}
