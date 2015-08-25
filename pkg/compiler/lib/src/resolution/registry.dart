// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.registry;

import '../common/backend_api.dart' show
    Backend;
import '../common/registry.dart' show
    Registry;
import '../compiler.dart' show
    Compiler,
    isPrivateName;
import '../constants/expressions.dart';
import '../dart_types.dart';
import '../diagnostics/invariant.dart' show
    invariant;
import '../enqueue.dart' show
    ResolutionEnqueuer,
    WorldImpact;
import '../elements/elements.dart';
import '../tree/tree.dart';
import '../util/util.dart' show
    Setlet;
import '../universe/universe.dart' show
    CallStructure,
    Selector,
    SelectorKind,
    UniverseSelector;
import '../world.dart' show World;

import 'send_structure.dart';

import 'members.dart' show
    ResolverVisitor;
import 'tree_elements.dart' show
    TreeElementMapping;

/// [ResolutionRegistry] collects all resolution information. It stores node
/// related information in a [TreeElements] mapping and registers calls with
/// [Backend], [World] and [Enqueuer].
// TODO(johnniwinther): Split this into an interface and implementation class.

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
    // TODO(johnniwinther): Remove the need for passing `this`.
    world.registerInstantiatedType(type, this);
  }

  @override
  void registerStaticInvocation(Element element) {
    registerDependency(element);
    world.registerStaticUse(element);
  }
}

class ResolutionWorldImpact implements WorldImpact {
  final Registry registry;
  Setlet<UniverseSelector> _dynamicInvocations;
  Setlet<UniverseSelector> _dynamicGetters;
  Setlet<UniverseSelector> _dynamicSetters;
  Setlet<InterfaceType> _instantiatedTypes;
  Setlet<Element> _staticUses;
  Setlet<DartType> _checkedTypes;
  Setlet<MethodElement> _closurizedFunctions;

  ResolutionWorldImpact(Compiler compiler, TreeElementMapping mapping)
      : this.registry = new EagerRegistry(compiler, mapping);

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
    // TODO(johnniwinther): Enable this when registration doesn't require a
    // [Registry].
    throw new UnsupportedError(
        'Lazy registration of instantiated not supported.');
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

  void registerCheckedType(DartType type) {
    if (_checkedTypes == null) {
      _checkedTypes = new Setlet<DartType>();
    }
    _checkedTypes.add(type);
  }

  @override
  Iterable<DartType> get checkedTypes {
    return _checkedTypes != null
        ? _checkedTypes : const <DartType>[];
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
}

class ResolutionRegistry implements Registry {
  final Compiler compiler;
  final TreeElementMapping mapping;
  final ResolutionWorldImpact worldImpact;

  ResolutionRegistry(Compiler compiler, TreeElementMapping mapping)
      : this.compiler = compiler,
        this.mapping = mapping,
        this.worldImpact = new ResolutionWorldImpact(compiler, mapping);

  bool get isForResolution => true;

  ResolutionEnqueuer get world => compiler.enqueuer.resolution;

  World get universe => compiler.world;

  Backend get backend => compiler.backend;

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
    universe.registerImplicitSuperCall(this, superConstructor);
  }

  // TODO(johnniwinther): Remove this.
  // Use [registerInstantiatedType] of `rawType` instead.
  @deprecated
  void registerInstantiatedClass(ClassElement element) {
    element.ensureResolved(compiler);
    registerInstantiatedType(element.rawType);
  }

  void registerLazyField() {
    backend.resolutionCallbacks.onLazyField(this);
  }

  void registerMetadataConstant(MetadataAnnotation metadata,
                                Element annotatedElement) {
    backend.registerMetadataConstant(metadata, annotatedElement, this);
  }

  void registerThrowRuntimeError() {
    backend.resolutionCallbacks.onThrowRuntimeError(this);
  }

  void registerCompileTimeError(ErroneousElement error) {
    backend.resolutionCallbacks.onCompileTimeError(this, error);
  }

  void registerTypeVariableBoundCheck() {
    backend.resolutionCallbacks.onTypeVariableBoundCheck(this);
  }

  void registerThrowNoSuchMethod() {
    backend.resolutionCallbacks.onThrowNoSuchMethod(this);
  }

  void registerIsCheck(DartType type) {
    worldImpact.registerCheckedType(type);
    backend.resolutionCallbacks.onIsCheck(type, this);
    mapping.addRequiredType(type);
  }

  void registerAsCheck(DartType type) {
    registerIsCheck(type);
    backend.resolutionCallbacks.onAsCheck(type, this);
    mapping.addRequiredType(type);
  }

  void registerClosure(LocalFunctionElement element) {
    world.registerClosure(element, this);
  }

  void registerSuperUse(Node node) {
    mapping.addSuperUse(node);
  }

  void registerDynamicInvocation(UniverseSelector selector) {
    worldImpact.registerDynamicInvocation(selector);
  }

  void registerSuperNoSuchMethod() {
    backend.resolutionCallbacks.onSuperNoSuchMethod(this);
  }

  void registerClassUsingVariableExpression(ClassElement element) {
    backend.registerClassUsingVariableExpression(element);
  }

  void registerTypeVariableExpression() {
    backend.resolutionCallbacks.onTypeVariableExpression(this);
  }

  void registerTypeLiteral(Send node, DartType type) {
    mapping.setType(node, type);
    backend.resolutionCallbacks.onTypeLiteral(type, this);
    world.registerInstantiatedType(compiler.coreTypes.typeType, this);
  }

  void registerMapLiteral(Node node, DartType type, bool isConstant) {
    setType(node, type);
    backend.resolutionCallbacks.onMapLiteral(this, type, isConstant);
  }

  // TODO(johnniwinther): Remove the [ResolverVisitor] dependency. Its only
  // needed to lookup types in the current scope.
  void registerJsCall(Node node, ResolverVisitor visitor) {
    world.registerJsCall(node, visitor);
  }

  // TODO(johnniwinther): Remove the [ResolverVisitor] dependency. Its only
  // needed to lookup types in the current scope.
  void registerJsEmbeddedGlobalCall(Node node, ResolverVisitor visitor) {
    world.registerJsEmbeddedGlobalCall(node, visitor);
  }

  // TODO(johnniwinther): Remove the [ResolverVisitor] dependency. Its only
  // needed to lookup types in the current scope.
  void registerJsBuiltinCall(Node node, ResolverVisitor visitor) {
    world.registerJsBuiltinCall(node, visitor);
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
    backend.registerConstSymbol(name, this);
  }

  void registerSymbolConstructor() {
    backend.resolutionCallbacks.onSymbolConstructor(this);
  }

  void registerInstantiatedType(InterfaceType type) {
    world.registerInstantiatedType(type, this);
    mapping.addRequiredType(type);
  }

  void registerAbstractClassInstantiation() {
    backend.resolutionCallbacks.onAbstractClassInstantiation(this);
  }

  void registerNewSymbol() {
    backend.registerNewSymbol(this);
  }

  void registerRequiredType(DartType type, Element enclosingElement) {
    backend.registerRequiredType(type, enclosingElement);
    mapping.addRequiredType(type);
  }

  void registerStringInterpolation() {
    backend.resolutionCallbacks.onStringInterpolation(this);
  }

  void registerFallThroughError() {
    backend.resolutionCallbacks.onFallThroughError(this);
  }

  void registerCatchStatement() {
    backend.resolutionCallbacks.onCatchStatement(this);
  }

  void registerStackTraceInCatch() {
    backend.resolutionCallbacks.onStackTraceInCatch(this);
  }

  void registerSyncForIn(Node node) {
    backend.resolutionCallbacks.onSyncForIn(this);
  }

  ClassElement defaultSuperclass(ClassElement element) {
    return backend.defaultSuperclass(element);
  }

  void registerMixinUse(MixinApplicationElement mixinApplication,
                        ClassElement mixin) {
    universe.registerMixinUse(mixinApplication, mixin);
  }

  void registerThrowExpression() {
    backend.resolutionCallbacks.onThrowExpression(this);
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
    world.registerInstantiatedType(type, this);
  }

  void registerAssert(Send node) {
    mapping.setAssert(node);
    backend.resolutionCallbacks.onAssert(node, this);
  }

  bool isAssert(Send node) {
    return mapping.isAssert(node);
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
    backend.registerAsyncMarker(element, world, this);
  }

  void registerAsyncForIn(AsyncForIn node) {
    backend.resolutionCallbacks.onAsyncForIn(node, this);
  }
}
