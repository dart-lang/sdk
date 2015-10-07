// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.registry;

import '../common/backend_api.dart' show
    Backend,
    ForeignResolver;
import '../common/resolution.dart' show
    Feature,
    ListLiteralUse,
    MapLiteralUse,
    ResolutionWorldImpact;
import '../common/registry.dart' show
    Registry;
import '../compiler.dart' show
    Compiler;
import '../constants/expressions.dart';
import '../dart_types.dart';
import '../diagnostics/invariant.dart' show
    invariant;
import '../enqueue.dart' show
    ResolutionEnqueuer;
import '../elements/elements.dart';
import '../helpers/helpers.dart';
import '../tree/tree.dart';
import '../util/util.dart' show
    Setlet;
import '../universe/call_structure.dart' show
    CallStructure;
import '../universe/selector.dart' show
    Selector;
import '../universe/universe.dart' show
    UniverseSelector;
import '../world.dart' show World;

import 'send_structure.dart';

import 'members.dart' show
    ResolverVisitor;
import 'tree_elements.dart' show
    TreeElementMapping;

// TODO(johnniwinther): Remove this.
class EagerRegistry implements Registry {
  final Compiler compiler;
  final TreeElementMapping mapping;

  EagerRegistry(this.compiler, this.mapping);

  ResolutionEnqueuer get world => compiler.enqueuer.resolution;

  @override
  bool get isForResolution => true;

  @override
  Iterable<Element> get otherDependencies => mapping.otherDependencies;

  @override
  void registerAssert(bool hasMessage) {
    // TODO(johnniwinther): Do something here?
  }

  @override
  void registerDependency(Element element) {
    mapping.registerDependency(element);
  }

  @override
  void registerDynamicGetter(UniverseSelector selector) {
    world.registerDynamicGetter(selector);
  }

  @override
  void registerDynamicInvocation(UniverseSelector selector) {
    world.registerDynamicInvocation(selector);
  }

  @override
  void registerDynamicSetter(UniverseSelector selector) {
    world.registerDynamicSetter(selector);
  }

  @override
  void registerGetOfStaticFunction(FunctionElement element) {
    world.registerGetOfStaticFunction(element);
  }

  @override
  void registerInstantiation(InterfaceType type) {
    world.registerInstantiatedType(type);
  }

  @override
  void registerStaticInvocation(Element element) {
    registerDependency(element);
    world.registerStaticUse(element);
  }

  String toString() => 'EagerRegistry for ${mapping.analyzedElement}';
}

class _ResolutionWorldImpact implements ResolutionWorldImpact {
  final Registry registry;
  // TODO(johnniwinther): Do we benefit from lazy initialization of the
  // [Setlet]s?
  Setlet<UniverseSelector> _dynamicInvocations;
  Setlet<UniverseSelector> _dynamicGetters;
  Setlet<UniverseSelector> _dynamicSetters;
  Setlet<InterfaceType> _instantiatedTypes;
  Setlet<Element> _staticUses;
  Setlet<DartType> _isChecks;
  Setlet<DartType> _asCasts;
  Setlet<DartType> _checkedModeChecks;
  Setlet<MethodElement> _closurizedFunctions;
  Setlet<LocalFunctionElement> _closures;
  Setlet<Feature> _features;
  // TODO(johnniwinther): This seems to be a union of other sets.
  Setlet<DartType> _requiredTypes;
  Setlet<MapLiteralUse> _mapLiterals;
  Setlet<ListLiteralUse> _listLiterals;
  Setlet<DartType> _typeLiterals;
  Setlet<String> _constSymbolNames;

  _ResolutionWorldImpact(Compiler compiler, TreeElementMapping mapping)
      : this.registry = new EagerRegistry(compiler, mapping);

  void registerDependency(Element element) {
    registry.registerDependency(element);
  }

  void registerDynamicGetter(UniverseSelector selector) {
    if (_dynamicGetters == null) {
      _dynamicGetters = new Setlet<UniverseSelector>();
    }
    _dynamicGetters.add(selector);
  }

  @override
  Iterable<UniverseSelector> get dynamicGetters {
    return _dynamicGetters != null
        ? _dynamicGetters : const <UniverseSelector>[];
  }

  void registerDynamicInvocation(UniverseSelector selector) {
    if (_dynamicInvocations == null) {
      _dynamicInvocations = new Setlet<UniverseSelector>();
    }
    _dynamicInvocations.add(selector);
  }

  @override
  Iterable<UniverseSelector> get dynamicInvocations {
    return _dynamicInvocations != null
        ? _dynamicInvocations : const <UniverseSelector>[];
  }

  void registerDynamicSetter(UniverseSelector selector) {
    if (_dynamicSetters == null) {
      _dynamicSetters = new Setlet<UniverseSelector>();
    }
    _dynamicSetters.add(selector);
  }

  @override
  Iterable<UniverseSelector> get dynamicSetters {
    return _dynamicSetters != null
        ? _dynamicSetters : const <UniverseSelector>[];
  }

  void registerInstantiatedType(InterfaceType type) {
    if (_instantiatedTypes == null) {
      _instantiatedTypes = new Setlet<InterfaceType>();
    }
    _instantiatedTypes.add(type);
  }

  @override
  Iterable<InterfaceType> get instantiatedTypes {
    return _instantiatedTypes != null
        ? _instantiatedTypes : const <InterfaceType>[];
  }

  void registerTypeLiteral(DartType type) {
    if (_typeLiterals == null) {
      _typeLiterals = new Setlet<DartType>();
    }
    _typeLiterals.add(type);
  }

  @override
  Iterable<DartType> get typeLiterals {
    return _typeLiterals != null
        ? _typeLiterals : const <DartType>[];
  }

  void registerRequiredType(DartType type) {
    if (_requiredTypes == null) {
      _requiredTypes = new Setlet<DartType>();
    }
    _requiredTypes.add(type);
  }

  @override
  Iterable<DartType> get requiredTypes {
    return _requiredTypes != null
        ? _requiredTypes : const <DartType>[];
  }

  void registerMapLiteral(MapLiteralUse mapLiteralUse) {
    if (_mapLiterals == null) {
      _mapLiterals = new Setlet<MapLiteralUse>();
    }
    _mapLiterals.add(mapLiteralUse);
  }

  @override
  Iterable<MapLiteralUse> get mapLiterals {
    return _mapLiterals != null
        ? _mapLiterals : const <MapLiteralUse>[];
  }

  void registerListLiteral(ListLiteralUse listLiteralUse) {
    if (_listLiterals == null) {
      _listLiterals = new Setlet<ListLiteralUse>();
    }
    _listLiterals.add(listLiteralUse);
  }

  @override
  Iterable<ListLiteralUse> get listLiterals {
    return _listLiterals != null
        ? _listLiterals : const <ListLiteralUse>[];
  }

  void registerStaticUse(Element element) {
    if (_staticUses == null) {
      _staticUses = new Setlet<Element>();
    }
    _staticUses.add(element);
  }

  @override
  Iterable<Element> get staticUses {
    return _staticUses != null ? _staticUses : const <Element>[];
  }

  void registerIsCheck(DartType type) {
    if (_isChecks == null) {
      _isChecks = new Setlet<DartType>();
    }
    _isChecks.add(type);
  }

  @override
  Iterable<DartType> get isChecks {
    return _isChecks != null
        ? _isChecks : const <DartType>[];
  }

  void registerAsCast(DartType type) {
    if (_asCasts == null) {
      _asCasts = new Setlet<DartType>();
    }
    _asCasts.add(type);
  }

  @override
  Iterable<DartType> get asCasts {
    return _asCasts != null
        ? _asCasts : const <DartType>[];
  }

  void registerCheckedModeCheckedType(DartType type) {
    if (_checkedModeChecks == null) {
      _checkedModeChecks = new Setlet<DartType>();
    }
    _checkedModeChecks.add(type);
  }

  @override
  Iterable<DartType> get checkedModeChecks {
    return _checkedModeChecks != null
        ? _checkedModeChecks : const <DartType>[];
  }

  void registerClosurizedFunction(MethodElement element) {
    if (_closurizedFunctions == null) {
      _closurizedFunctions = new Setlet<MethodElement>();
    }
    _closurizedFunctions.add(element);
  }

  @override
  Iterable<MethodElement> get closurizedFunctions {
    return _closurizedFunctions != null
        ? _closurizedFunctions : const <MethodElement>[];
  }

  void registerClosure(LocalFunctionElement element) {
    if (_closures == null) {
      _closures = new Setlet<LocalFunctionElement>();
    }
    _closures.add(element);
  }

  @override
  Iterable<LocalFunctionElement> get closures {
    return _closures != null
        ? _closures : const <LocalFunctionElement>[];
  }

  void registerConstSymbolName(String name) {
    if (_constSymbolNames == null) {
      _constSymbolNames = new Setlet<String>();
    }
    _constSymbolNames.add(name);
  }

  @override
  Iterable<String> get constSymbolNames {
    return _constSymbolNames != null
        ? _constSymbolNames : const <String>[];
  }

  void registerFeature(Feature feature) {
    if (_features == null) {
      _features = new Setlet<Feature>();
    }
    _features.add(feature);
  }

  @override
  Iterable<Feature> get features {
    return _features != null ? _features : const <Feature>[];
  }

  String toString() => '$registry';
}

/// [ResolutionRegistry] collects all resolution information. It stores node
/// related information in a [TreeElements] mapping and registers calls with
/// [Backend], [World] and [Enqueuer].
// TODO(johnniwinther): Split this into an interface and implementation class.
class ResolutionRegistry implements Registry {
  final Compiler compiler;
  final TreeElementMapping mapping;
  final _ResolutionWorldImpact worldImpact;

  ResolutionRegistry(Compiler compiler, TreeElementMapping mapping)
      : this.compiler = compiler,
        this.mapping = mapping,
        this.worldImpact = new _ResolutionWorldImpact(compiler, mapping);

  bool get isForResolution => true;

  ResolutionEnqueuer get world => compiler.enqueuer.resolution;

  World get universe => compiler.world;

  Backend get backend => compiler.backend;

  String toString() => 'ResolutionRegistry for ${mapping.analyzedElement}';

  //////////////////////////////////////////////////////////////////////////////
  //  Node-to-Element mapping functionality.
  //////////////////////////////////////////////////////////////////////////////

  /// Register [node] as the declaration of [element].
  void defineFunction(FunctionExpression node, FunctionElement element) {
    // TODO(sigurdm): Remove when not needed by the dart2dart backend.
    if (node.name != null) {
      mapping[node.name] = element;
    }
    mapping[node] = element;
  }

  /// Register [node] as a reference to [element].
  Element useElement(Node node, Element element) {
    if (element == null) return null;
    return mapping[node] = element;
  }

  /// Register [node] as the declaration of [element].
  void defineElement(Node node, Element element) {
    mapping[node] = element;
  }

  /// Returns the [Element] defined by [node].
  Element getDefinition(Node node) {
    return mapping[node];
  }

  /// Sets the loop variable of the for-in [node] to be [element].
  void setForInVariable(ForIn node, Element element) {
    mapping[node] = element;
  }

  /// Sets the target constructor [node] to be [element].
  void setRedirectingTargetConstructor(RedirectingFactoryBody node,
                                       ConstructorElement element) {
    useElement(node, element);
  }

  //////////////////////////////////////////////////////////////////////////////
  //  Node-to-Selector mapping functionality.
  //////////////////////////////////////////////////////////////////////////////

  void setSelector(Node node, Selector selector) {
    mapping.setSelector(node, selector);
  }

  Selector getSelector(Node node) => mapping.getSelector(node);

  void setGetterSelectorInComplexSendSet(SendSet node, Selector selector) {
    mapping.setGetterSelectorInComplexSendSet(node, selector);
  }

  void setOperatorSelectorInComplexSendSet(SendSet node, Selector selector) {
    mapping.setOperatorSelectorInComplexSendSet(node, selector);
  }

  void setIteratorSelector(ForIn node, Selector selector) {
    mapping.setIteratorSelector(node, selector);
  }

  void setMoveNextSelector(ForIn node, Selector selector) {
    mapping.setMoveNextSelector(node, selector);
  }

  void setCurrentSelector(ForIn node, Selector selector) {
    mapping.setCurrentSelector(node, selector);
  }

  //////////////////////////////////////////////////////////////////////////////
  //  Node-to-Type mapping functionality.
  //////////////////////////////////////////////////////////////////////////////

  DartType useType(Node annotation, DartType type) {
    if (type != null) {
      mapping.setType(annotation, type);
    }
    return type;
  }

  void setType(Node node, DartType type) => mapping.setType(node, type);

  DartType getType(Node node) => mapping.getType(node);

  //////////////////////////////////////////////////////////////////////////////
  //  Node-to-Constant mapping functionality.
  //////////////////////////////////////////////////////////////////////////////

  ConstantExpression getConstant(Node node) => mapping.getConstant(node);

  void setConstant(Node node, ConstantExpression constant) {
    mapping.setConstant(node, constant);
  }

  //////////////////////////////////////////////////////////////////////////////
  //  Target/Label functionality.
  //////////////////////////////////////////////////////////////////////////////

  /// Register [node] to be the declaration of [label].
  void defineLabel(Label node, LabelDefinition label) {
    mapping.defineLabel(node, label);
  }

  /// Undefine the label of [node].
  /// This is used to cleanup and detect unused labels.
  void undefineLabel(Label node) {
    mapping.undefineLabel(node);
  }

  /// Register the target of [node] as reference to [label].
  void useLabel(GotoStatement node, LabelDefinition label) {
    mapping.registerTargetLabel(node, label);
  }

  /// Register [node] to be the declaration of [target].
  void defineTarget(Node node, JumpTarget target) {
    assert(invariant(node, node is Statement || node is SwitchCase,
        message: "Only statements and switch cases can define targets."));
    mapping.defineTarget(node, target);
  }

  /// Returns the [JumpTarget] defined by [node].
  JumpTarget getTargetDefinition(Node node) {
    assert(invariant(node, node is Statement || node is SwitchCase,
        message: "Only statements and switch cases can define targets."));
    return mapping.getTargetDefinition(node);
  }

  /// Undefine the target of [node]. This is used to cleanup unused targets.
  void undefineTarget(Node node) {
    assert(invariant(node, node is Statement || node is SwitchCase,
        message: "Only statements and switch cases can define targets."));
    mapping.undefineTarget(node);
  }

  /// Register the target of [node] to be [target].
  void registerTargetOf(GotoStatement node, JumpTarget target) {
    mapping.registerTargetOf(node, target);
  }

  //////////////////////////////////////////////////////////////////////////////
  //  Potential access registration.
  //////////////////////////////////////////////////////////////////////////////

  void setAccessedByClosureIn(Node contextNode, VariableElement element,
                              Node accessNode) {
    mapping.setAccessedByClosureIn(contextNode, element, accessNode);
  }

  void registerPotentialMutation(VariableElement element, Node mutationNode) {
    mapping.registerPotentialMutation(element, mutationNode);
  }

  void registerPotentialMutationInClosure(VariableElement element,
                                           Node mutationNode) {
    mapping.registerPotentialMutationInClosure(element, mutationNode);
  }

  void registerPotentialMutationIn(Node contextNode, VariableElement element,
                                    Node mutationNode) {
    mapping.registerPotentialMutationIn(contextNode, element, mutationNode);
  }

  //////////////////////////////////////////////////////////////////////////////
  //  Various Backend/Enqueuer/World registration.
  //////////////////////////////////////////////////////////////////////////////

  void registerStaticUse(Element element) {
    worldImpact.registerStaticUse(element);
  }

  void registerImplicitSuperCall(FunctionElement superConstructor) {
    registerDependency(superConstructor);
  }

  // TODO(johnniwinther): Remove this.
  // Use [registerInstantiatedType] of `rawType` instead.
  @deprecated
  void registerInstantiatedClass(ClassElement element) {
    element.ensureResolved(compiler.resolution);
    registerInstantiatedType(element.rawType);
  }

  void registerLazyField() {
    worldImpact.registerFeature(Feature.LAZY_FIELD);
  }

  void registerMetadataConstant(MetadataAnnotation metadata) {
    backend.registerMetadataConstant(metadata, metadata.annotatedElement, this);
  }

  void registerThrowRuntimeError() {
    worldImpact.registerFeature(Feature.THROW_RUNTIME_ERROR);
  }

  void registerCompileTimeError(ErroneousElement error) {
    worldImpact.registerFeature(Feature.COMPILE_TIME_ERROR);
  }

  void registerTypeVariableBoundCheck() {
    worldImpact.registerFeature(Feature.TYPE_VARIABLE_BOUNDS_CHECK);
  }

  void registerThrowNoSuchMethod() {
    worldImpact.registerFeature(Feature.THROW_NO_SUCH_METHOD);
  }

  /// Register a checked mode check against [type].
  void registerCheckedModeCheck(DartType type) {
    worldImpact.registerCheckedModeCheckedType(type);
    mapping.addRequiredType(type);
  }

  /// Register an is-test or is-not-test of [type].
  void registerIsCheck(DartType type) {
    worldImpact.registerIsCheck(type);
    mapping.addRequiredType(type);
  }

  /// Register an as-cast of [type].
  void registerAsCast(DartType type) {
    worldImpact.registerAsCast(type);
    mapping.addRequiredType(type);
  }

  void registerClosure(LocalFunctionElement element) {
    worldImpact.registerClosure(element);
  }

  void registerSuperUse(Node node) {
    mapping.addSuperUse(node);
  }

  void registerDynamicInvocation(UniverseSelector selector) {
    worldImpact.registerDynamicInvocation(selector);
  }

  void registerSuperNoSuchMethod() {
    worldImpact.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
  }

  void registerTypeLiteral(Send node, DartType type) {
    mapping.setType(node, type);
    worldImpact.registerTypeLiteral(type);
  }

  void registerLiteralList(Node node,
                           InterfaceType type,
                           {bool isConstant,
                            bool isEmpty}) {
    setType(node, type);
    worldImpact.registerListLiteral(
        new ListLiteralUse(type, isConstant: isConstant, isEmpty: isEmpty));
  }

  void registerMapLiteral(Node node,
                          InterfaceType type,
                          {bool isConstant,
                           bool isEmpty}) {
    setType(node, type);
    worldImpact.registerMapLiteral(
        new MapLiteralUse(type, isConstant: isConstant, isEmpty: isEmpty));
  }

  void registerForeignCall(Node node,
                           Element element,
                           CallStructure callStructure,
                           ResolverVisitor visitor) {
    backend.registerForeignCall(
        node, element, callStructure,
        new ForeignResolutionResolver(visitor, this));
  }

  void registerGetOfStaticFunction(FunctionElement element) {
    worldImpact.registerClosurizedFunction(element);
  }

  void registerDynamicGetter(UniverseSelector selector) {
    assert(selector.selector.isGetter);
    worldImpact.registerDynamicGetter(selector);
  }

  void registerDynamicSetter(UniverseSelector selector) {
    assert(selector.selector.isSetter);
    worldImpact.registerDynamicSetter(selector);
  }

  void registerConstSymbol(String name) {
    worldImpact.registerConstSymbolName(name);
  }

  void registerSymbolConstructor() {
    worldImpact.registerFeature(Feature.SYMBOL_CONSTRUCTOR);
  }

  void registerInstantiatedType(InterfaceType type) {
    worldImpact.registerInstantiatedType(type);
    mapping.addRequiredType(type);
  }

  void registerAbstractClassInstantiation() {
    worldImpact.registerFeature(Feature.ABSTRACT_CLASS_INSTANTIATION);
  }

  void registerNewSymbol() {
    worldImpact.registerFeature(Feature.NEW_SYMBOL);
  }

  void registerRequiredType(DartType type, Element enclosingElement) {
    worldImpact.registerRequiredType(type);
    mapping.addRequiredType(type);
  }

  void registerStringInterpolation() {
    worldImpact.registerFeature(Feature.STRING_INTERPOLATION);
  }

  void registerFallThroughError() {
    worldImpact.registerFeature(Feature.FALL_THROUGH_ERROR);
  }

  void registerCatchStatement() {
    worldImpact.registerFeature(Feature.CATCH_STATEMENT);
  }

  void registerStackTraceInCatch() {
    worldImpact.registerFeature(Feature.STACK_TRACE_IN_CATCH);
  }

  void registerSyncForIn(Node node) {
    worldImpact.registerFeature(Feature.SYNC_FOR_IN);
  }

  ClassElement defaultSuperclass(ClassElement element) {
    return backend.defaultSuperclass(element);
  }

  void registerMixinUse(MixinApplicationElement mixinApplication,
                        ClassElement mixin) {
    universe.registerMixinUse(mixinApplication, mixin);
  }

  void registerThrowExpression() {
    worldImpact.registerFeature(Feature.THROW_EXPRESSION);
  }

  void registerDependency(Element element) {
    mapping.registerDependency(element);
  }

  Setlet<Element> get otherDependencies => mapping.otherDependencies;

  void registerStaticInvocation(Element element) {
    // TODO(johnniwinther): Increase precision of [registerStaticUse] and
    // [registerDependency].
    if (element == null) return;
    registerStaticUse(element);
    registerDependency(element);
  }

  void registerInstantiation(InterfaceType type) {
    registerInstantiatedType(type);
  }

  void registerAssert(bool hasMessage) {
    worldImpact.registerFeature(
        hasMessage ? Feature.ASSERT_WITH_MESSAGE : Feature.ASSERT);
  }

  void registerSendStructure(Send node, SendStructure sendStructure) {
    mapping.setSendStructure(node, sendStructure);
  }

  // TODO(johnniwinther): Remove this when [SendStructure]s are part of the
  // [ResolutionResult].
  SendStructure getSendStructure(Send node) {
    return mapping.getSendStructure(node);
  }

  void registerAsyncMarker(FunctionElement element) {
    switch (element.asyncMarker) {
      case AsyncMarker.SYNC:
        break;
      case AsyncMarker.SYNC_STAR:
        worldImpact.registerFeature(Feature.SYNC_STAR);
        break;
      case AsyncMarker.ASYNC:
        worldImpact.registerFeature(Feature.ASYNC);
        break;
      case AsyncMarker.ASYNC_STAR:
        worldImpact.registerFeature(Feature.ASYNC_STAR);
        break;
    }
  }

  void registerAsyncForIn(AsyncForIn node) {
    worldImpact.registerFeature(Feature.ASYNC_FOR_IN);
  }

  void registerIncDecOperation() {
    worldImpact.registerFeature(Feature.INC_DEC_OPERATION);
  }

  void registerTryStatement() {
    mapping.containsTryStatement = true;
  }
}

class ForeignResolutionResolver implements ForeignResolver {
  final ResolverVisitor visitor;
  final ResolutionRegistry registry;

  ForeignResolutionResolver(this.visitor, this.registry);

  @override
  ConstantExpression getConstant(Node node) {
    return registry.getConstant(node);
  }

  @override
  void registerInstantiatedType(InterfaceType type) {
    registry.registerInstantiatedType(type);
  }

  @override
  DartType resolveTypeFromString(Node node, String typeName) {
    return visitor.resolveTypeFromString(node, typeName);
  }
}
