// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

/// [ResolutionRegistry] collects all resolution information. It stores node
/// related information in a [TreeElements] mapping and registers calls with
/// [Backend], [World] and [Enqueuer].
// TODO(johnniwinther): Split this into an interface and implementation class.
class ResolutionRegistry extends Registry {
  final Compiler compiler;
  final TreeElementMapping mapping;

  ResolutionRegistry(Compiler compiler, Element element)
      : this.internal(compiler, _ensureTreeElements(element));

  ResolutionRegistry.internal(this.compiler, this.mapping);

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

  Constant getConstant(Node node) => mapping.getConstant(node);

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
    world.registerStaticUse(element);
  }

  void registerImplicitSuperCall(FunctionElement superConstructor) {
    universe.registerImplicitSuperCall(this, superConstructor);
  }

  void registerInstantiatedClass(ClassElement element) {
    world.registerInstantiatedClass(element, this);
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

  void registerTypeVariableBoundCheck() {
    backend.resolutionCallbacks.onTypeVariableBoundCheck(this);
  }

  void registerThrowNoSuchMethod() {
    backend.resolutionCallbacks.onThrowNoSuchMethod(this);
  }

  void registerIsCheck(DartType type) {
    world.registerIsCheck(type, this);
    backend.resolutionCallbacks.onIsCheck(type, this);
  }

  void registerAsCheck(DartType type) {
    registerIsCheck(type);
    backend.resolutionCallbacks.onAsCheck(type, this);
  }

  void registerClosure(LocalFunctionElement element) {
    world.registerClosure(element, this);
  }

  void registerSuperUse(Node node) {
    mapping.addSuperUse(node);
  }

  void registerDynamicInvocation(Selector selector) {
    world.registerDynamicInvocation(selector);
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
    world.registerInstantiatedClass(compiler.typeClass, this);
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

  void registerGetOfStaticFunction(FunctionElement element) {
    world.registerGetOfStaticFunction(element);
  }

  void registerDynamicGetter(Selector selector) {
    world.registerDynamicGetter(selector);
  }

  void registerDynamicSetter(Selector selector) {
    world.registerDynamicSetter(selector);
  }

  void registerConstSymbol(String name) {
    backend.registerConstSymbol(name, this);
  }

  void registerSymbolConstructor() {
    backend.resolutionCallbacks.onSymbolConstructor(this);
  }

  void registerInstantiatedType(InterfaceType type) {
    world.registerInstantiatedType(type, this);
  }

  void registerFactoryWithTypeArguments() {
    world.registerFactoryWithTypeArguments(this);
  }

  void registerAbstractClassInstantiation() {
    backend.resolutionCallbacks.onAbstractClassInstantiation(this);
  }

  void registerNewSymbol() {
    backend.registerNewSymbol(this);
  }

  void registerRequiredType(DartType type, Element enclosingElement) {
    backend.registerRequiredType(type, enclosingElement);
  }

  void registerStringInterpolation() {
    backend.resolutionCallbacks.onStringInterpolation(this);
  }

  void registerConstantMap() {
    backend.resolutionCallbacks.onConstantMap(this);
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
    if (element == null) return;
    world.addToWorkList(element);
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
}
