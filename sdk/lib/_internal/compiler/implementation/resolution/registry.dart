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

  Element get currentElement => mapping.currentElement;

  ResolutionEnqueuer get world => compiler.enqueuer.resolution;

  World get universe => compiler.world;

  Backend get backend => compiler.backend;

  //////////////////////////////////////////////////////////////////////////////
  //  Node-to-Element mapping functionality.
  //////////////////////////////////////////////////////////////////////////////

  /// Register [node] as a reference to [element].
  Element useElement(Node node, Element element) {
    if (element == null) return null;
    return mapping[node] = element;
  }

  /// Register [node] as a declaration of [element].
  void defineElement(Node node, Element element) {
    mapping[node] = element;
  }

  /// Unregister the element declared by [node].
  // TODO(johnniwinther): Try to remove this.
  void undefineElement(Node node) {
    mapping.remove(node);
  }

  /// Returns the [Element] defined by [node].
  Element getDefinition(Node node) {
    return mapping[node];
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
      useElement(annotation, type.element);
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
  void defineLabel(Label node, LabelElement label) {
    defineElement(node, label);
  }

  /// Undefine the label of [node].
  /// This is used to cleanup and detect unused labels.
  void undefineLabel(Label node) {
    undefineElement(node);
  }

  /// Register the target of [node] as reference to [label].
  void useLabel(GotoStatement node, LabelElement label) {
    mapping[node.target] = label;
  }

  /// Register [node] to be the declaration of [target].
  void defineTarget(Node node, TargetElement target) {
    assert(invariant(node, node is Statement || node is SwitchCase,
        message: "Only statements and switch cases can define targets."));
    defineElement(node, target);
  }

  /// Returns the [TargetElement] defined by [node].
  TargetElement getTargetDefinition(Node node) {
    assert(invariant(node, node is Statement || node is SwitchCase,
        message: "Only statements and switch cases can define targets."));
    return getDefinition(node);
  }

  /// Undefine the target of [node]. This is used to cleanup unused targets.
  void undefineTarget(Node node) {
    assert(invariant(node, node is Statement || node is SwitchCase,
        message: "Only statements and switch cases can define targets."));
    undefineElement(node);
  }

  /// Register the target of [node] to be [target].
  void registerTargetOf(GotoStatement node, TargetElement target) {
    mapping[node] = target;
  }

  /// Returns the target of [node].
  // TODO(johnniwinther): Change [Node] to [GotoStatement] when we store
  // target def and use in separate locations.
  TargetElement getTargetOf(Node node) {
    return mapping[node];
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
    backend.registerLazyField(this);
  }

  void registerMetadataConstant(Constant constant) {
    backend.registerMetadataConstant(constant, this);
  }

  void registerThrowRuntimeError() {
    backend.registerThrowRuntimeError(this);
  }

  void registerTypeVariableBoundCheck() {
    backend.registerTypeVariableBoundCheck(this);
  }

  void registerThrowNoSuchMethod() {
    backend.registerThrowNoSuchMethod(this);
  }

  void registerIsCheck(DartType type) {
    world.registerIsCheck(type, this);
  }

  void registerAsCheck(DartType type) {
    world.registerAsCheck(type, this);
  }

  void registerClosure(Element element) {
    world.registerClosure(element, this);
  }

  void registerSuperUse(Node node) {
    mapping.superUses.add(node);
  }

  void registerDynamicInvocation(Selector selector) {
    world.registerDynamicInvocation(selector);
  }

  void registerSuperNoSuchMethod() {
    backend.registerSuperNoSuchMethod(this);
  }

  void registerClassUsingVariableExpression(ClassElement element) {
    backend.registerClassUsingVariableExpression(element);
  }

  void registerTypeVariableExpression() {
    backend.registerTypeVariableExpression(this);
  }

  void registerTypeLiteral(Send node, DartType type) {
    mapping.setType(node, type);
    world.registerTypeLiteral(type, this);
  }

  // TODO(johnniwinther): Remove the [ResolverVisitor] dependency. Its only
  // needed to lookup types in the current scope.
  void registerJsCall(Node node, ResolverVisitor visitor) {
    world.registerJsCall(node, visitor);
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
    world.registerConstSymbol(name, this);
  }

  void registerSymbolConstructor() {
    backend.registerSymbolConstructor(this);
  }

  void registerInstantiatedType(InterfaceType type) {
    world.registerInstantiatedType(type, this);
  }

  void registerFactoryWithTypeArguments() {
    world.registerFactoryWithTypeArguments(this);
  }

  void registerAbstractClassInstantiation() {
    backend.registerAbstractClassInstantiation(this);
  }

  void registerNewSymbol() {
    world.registerNewSymbol(this);
  }

  void registerRequiredType(DartType type, Element enclosingElement) {
    backend.registerRequiredType(type, enclosingElement);
  }

  void registerStringInterpolation() {
    backend.registerStringInterpolation(this);
  }

  void registerConstantMap() {
    backend.registerConstantMap(this);
  }

  void registerFallThroughError() {
    backend.registerFallThroughError(this);
  }

  void registerCatchStatement() {
    backend.registerCatchStatement(world, this);
  }

  void registerStackTraceInCatch() {
    backend.registerStackTraceInCatch(this);
  }

  ClassElement defaultSuperclass(ClassElement element) {
    return backend.defaultSuperclass(element);
  }

  void registerMixinUse(MixinApplicationElement mixinApplication,
                        ClassElement mixin) {
    universe.registerMixinUse(mixinApplication, mixin);
  }

  void registerThrowExpression() {
    backend.registerThrowExpression(this);
  }

  void registerDependency(Element element) {
    mapping.registerDependency(element);
  }

  Setlet<Element> get otherDependencies => mapping.otherDependencies;
}
