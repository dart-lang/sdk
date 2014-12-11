// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

abstract class TreeElements {
  AnalyzableElement get analyzedElement;
  Iterable<Node> get superUses;

  /// Iterables of the dependencies that this [TreeElement] records of
  /// [analyzedElement].
  Iterable<Element> get allElements;
  void forEachConstantNode(f(Node n, ConstantExpression c));

  /// A set of additional dependencies.  See [registerDependency] below.
  Iterable<Element> get otherDependencies;

  Element operator[](Node node);

  // TODO(johnniwinther): Investigate whether [Node] could be a [Send].
  Selector getSelector(Node node);
  Selector getGetterSelectorInComplexSendSet(SendSet node);
  Selector getOperatorSelectorInComplexSendSet(SendSet node);
  DartType getType(Node node);
  void setSelector(Node node, Selector selector);
  void setGetterSelectorInComplexSendSet(SendSet node, Selector selector);
  void setOperatorSelectorInComplexSendSet(SendSet node, Selector selector);

  /// Returns the for-in loop variable for [node].
  Element getForInVariable(ForIn node);
  Selector getIteratorSelector(ForIn node);
  Selector getMoveNextSelector(ForIn node);
  Selector getCurrentSelector(ForIn node);
  void setIteratorSelector(ForIn node, Selector selector);
  void setMoveNextSelector(ForIn node, Selector selector);
  void setCurrentSelector(ForIn node, Selector selector);
  void setConstant(Node node, ConstantExpression constant);
  ConstantExpression getConstant(Node node);
  bool isAssert(Send send);

  /// Returns the [FunctionElement] defined by [node].
  FunctionElement getFunctionDefinition(FunctionExpression node);

  /// Returns target constructor for the redirecting factory body [node].
  ConstructorElement getRedirectingTargetConstructor(
      RedirectingFactoryBody node);

  /**
   * Returns [:true:] if [node] is a type literal.
   *
   * Resolution marks this by setting the type on the node to be the
   * type that the literal refers to.
   */
  bool isTypeLiteral(Send node);

  /// Returns the type that the type literal [node] refers to.
  DartType getTypeLiteralType(Send node);

  /// Register additional dependencies required by [analyzedElement].
  /// For example, elements that are used by a backend.
  void registerDependency(Element element);

  /// Returns a list of nodes that potentially mutate [element] anywhere in its
  /// scope.
  List<Node> getPotentialMutations(VariableElement element);

  /// Returns a list of nodes that potentially mutate [element] in [node].
  List<Node> getPotentialMutationsIn(Node node, VariableElement element);

  /// Returns a list of nodes that potentially mutate [element] in a closure.
  List<Node> getPotentialMutationsInClosure(VariableElement element);

  /// Returns a list of nodes that access [element] within a closure in [node].
  List<Node> getAccessesByClosureIn(Node node, VariableElement element);

  /// Returns the jump target defined by [node].
  JumpTarget getTargetDefinition(Node node);

  /// Returns the jump target of the [node].
  JumpTarget getTargetOf(GotoStatement node);

  /// Returns the label defined by [node].
  LabelDefinition getLabelDefinition(Label node);

  /// Returns the label that [node] targets.
  LabelDefinition getTargetLabel(GotoStatement node);
}

class TreeElementMapping implements TreeElements {
  final AnalyzableElement analyzedElement;
  Map<Spannable, Selector> _selectors;
  Map<Node, DartType> _types;
  Setlet<Node> _superUses;
  Setlet<Element> _otherDependencies;
  Map<Node, ConstantExpression> _constants;
  Map<VariableElement, List<Node>> _potentiallyMutated;
  Map<Node, Map<VariableElement, List<Node>>> _potentiallyMutatedIn;
  Map<VariableElement, List<Node>> _potentiallyMutatedInClosure;
  Map<Node, Map<VariableElement, List<Node>>> _accessedByClosureIn;
  Setlet<Element> _elements;
  Setlet<Send> _asserts;

  /// Map from nodes to the targets they define.
  Map<Node, JumpTarget> _definedTargets;

  /// Map from goto statements to their targets.
  Map<GotoStatement, JumpTarget> _usedTargets;

  /// Map from labels to their label definition.
  Map<Label, LabelDefinition> _definedLabels;

  /// Map from labeled goto statements to the labels they target.
  Map<GotoStatement, LabelDefinition> _targetLabels;

  final int hashCode = ++_hashCodeCounter;
  static int _hashCodeCounter = 0;

  TreeElementMapping(this.analyzedElement);

  operator []=(Node node, Element element) {
    // TODO(johnniwinther): Simplify this invariant to use only declarations in
    // [TreeElements].
    assert(invariant(node, () {
      if (!element.isErroneous && analyzedElement != null && element.isPatch) {
        return analyzedElement.implementationLibrary.isPatch;
      }
      return true;
    }));
    // TODO(ahe): Investigate why the invariant below doesn't hold.
    // assert(invariant(node,
    //                  getTreeElement(node) == element ||
    //                  getTreeElement(node) == null,
    //                  message: '${getTreeElement(node)}; $element'));

    if (_elements == null) {
      _elements = new Setlet<Element>();
    }
    _elements.add(element);
    setTreeElement(node, element);
  }

  operator [](Node node) => getTreeElement(node);

  void setType(Node node, DartType type) {
    if (_types == null) {
      _types = new Maplet<Node, DartType>();
    }
    _types[node] = type;
  }

  DartType getType(Node node) => _types != null ? _types[node] : null;

  Iterable<Node> get superUses {
    return _superUses != null ? _superUses : const <Node>[];
  }

  void addSuperUse(Node node) {
    if (_superUses == null) {
      _superUses = new Setlet<Node>();
    }
    _superUses.add(node);
  }

  Selector _getSelector(Spannable node) {
    return _selectors != null ? _selectors[node] : null;
  }

  void _setSelector(Spannable node, Selector selector) {
    if (_selectors == null) {
      _selectors = new Maplet<Spannable, Selector>();
    }
    _selectors[node] = selector;
  }

  void setSelector(Node node, Selector selector) {
    _setSelector(node, selector);
  }

  Selector getSelector(Node node) => _getSelector(node);

  int getSelectorCount() => _selectors == null ? 0 : _selectors.length;

  void setGetterSelectorInComplexSendSet(SendSet node, Selector selector) {
    _setSelector(node.selector, selector);
  }

  Selector getGetterSelectorInComplexSendSet(SendSet node) {
    return _getSelector(node.selector);
  }

  void setOperatorSelectorInComplexSendSet(SendSet node, Selector selector) {
    _setSelector(node.assignmentOperator, selector);
  }

  Selector getOperatorSelectorInComplexSendSet(SendSet node) {
    return _getSelector(node.assignmentOperator);
  }

  // The following methods set selectors on the "for in" node. Since
  // we're using three selectors, we need to use children of the node,
  // and we arbitrarily choose which ones.

  void setIteratorSelector(ForIn node, Selector selector) {
    _setSelector(node, selector);
  }

  Selector getIteratorSelector(ForIn node) {
    return _getSelector(node);
  }

  void setMoveNextSelector(ForIn node, Selector selector) {
    _setSelector(node.forToken, selector);
  }

  Selector getMoveNextSelector(ForIn node) {
    return _getSelector(node.forToken);
  }

  void setCurrentSelector(ForIn node, Selector selector) {
    _setSelector(node.inToken, selector);
  }

  Selector getCurrentSelector(ForIn node) {
    return _getSelector(node.inToken);
  }

  Element getForInVariable(ForIn node) {
    return this[node];
  }

  void setConstant(Node node, ConstantExpression constant) {
    if (_constants == null) {
      _constants = new Maplet<Node, ConstantExpression>();
    }
    _constants[node] = constant;
  }

  ConstantExpression getConstant(Node node) {
    return _constants != null ? _constants[node] : null;
  }

  bool isTypeLiteral(Send node) {
    return getType(node) != null;
  }

  DartType getTypeLiteralType(Send node) {
    return getType(node);
  }

  void registerDependency(Element element) {
    if (element == null) return;
    if (_otherDependencies == null) {
      _otherDependencies = new Setlet<Element>();
    }
    _otherDependencies.add(element.implementation);
  }

  Iterable<Element> get otherDependencies {
    return _otherDependencies != null ? _otherDependencies : const <Element>[];
  }

  List<Node> getPotentialMutations(VariableElement element) {
    if (_potentiallyMutated == null) return const <Node>[];
    List<Node> mutations = _potentiallyMutated[element];
    if (mutations == null) return const <Node>[];
    return mutations;
  }

  void registerPotentialMutation(VariableElement element, Node mutationNode) {
    if (_potentiallyMutated == null) {
      _potentiallyMutated = new Maplet<VariableElement, List<Node>>();
    }
    _potentiallyMutated.putIfAbsent(element, () => <Node>[]).add(mutationNode);
  }

  List<Node> getPotentialMutationsIn(Node node, VariableElement element) {
    if (_potentiallyMutatedIn == null) return const <Node>[];
    Map<VariableElement, List<Node>> mutationsIn = _potentiallyMutatedIn[node];
    if (mutationsIn == null) return const <Node>[];
    List<Node> mutations = mutationsIn[element];
    if (mutations == null) return const <Node>[];
    return mutations;
  }

  void registerPotentialMutationIn(Node contextNode, VariableElement element,
                                    Node mutationNode) {
    if (_potentiallyMutatedIn == null) {
      _potentiallyMutatedIn =
          new Maplet<Node, Map<VariableElement, List<Node>>>();
    }
    Map<VariableElement, List<Node>> mutationMap =
        _potentiallyMutatedIn.putIfAbsent(contextNode,
          () => new Maplet<VariableElement, List<Node>>());
    mutationMap.putIfAbsent(element, () => <Node>[]).add(mutationNode);
  }

  List<Node> getPotentialMutationsInClosure(VariableElement element) {
    if (_potentiallyMutatedInClosure == null) return const <Node>[];
    List<Node> mutations = _potentiallyMutatedInClosure[element];
    if (mutations == null) return const <Node>[];
    return mutations;
  }

  void registerPotentialMutationInClosure(VariableElement element,
                                          Node mutationNode) {
    if (_potentiallyMutatedInClosure == null) {
      _potentiallyMutatedInClosure = new Maplet<VariableElement, List<Node>>();
    }
    _potentiallyMutatedInClosure.putIfAbsent(
        element, () => <Node>[]).add(mutationNode);
  }

  List<Node> getAccessesByClosureIn(Node node, VariableElement element) {
    if (_accessedByClosureIn == null) return const <Node>[];
    Map<VariableElement, List<Node>> accessesIn = _accessedByClosureIn[node];
    if (accessesIn == null) return const <Node>[];
    List<Node> accesses = accessesIn[element];
    if (accesses == null) return const <Node>[];
    return accesses;
  }

  void setAccessedByClosureIn(Node contextNode, VariableElement element,
                              Node accessNode) {
    if (_accessedByClosureIn == null) {
      _accessedByClosureIn = new Map<Node, Map<VariableElement, List<Node>>>();
    }
    Map<VariableElement, List<Node>> accessMap =
        _accessedByClosureIn.putIfAbsent(contextNode,
          () => new Maplet<VariableElement, List<Node>>());
    accessMap.putIfAbsent(element, () => <Node>[]).add(accessNode);
  }

  String toString() => 'TreeElementMapping($analyzedElement)';

  Iterable<Element> get allElements {
    return _elements != null ? _elements : const <Element>[];
  }

  void forEachConstantNode(f(Node n, ConstantExpression c)) {
    if (_constants != null) {
      _constants.forEach(f);
    }
  }

  void setAssert(Send node) {
    if (_asserts == null) {
      _asserts = new Setlet<Send>();
    }
    _asserts.add(node);
  }

  bool isAssert(Send node) {
    return _asserts != null && _asserts.contains(node);
  }

  FunctionElement getFunctionDefinition(FunctionExpression node) {
    return this[node];
  }

  ConstructorElement getRedirectingTargetConstructor(
      RedirectingFactoryBody node) {
    return this[node];
  }

  void defineTarget(Node node, JumpTarget target) {
    if (_definedTargets == null) {
      _definedTargets = new Maplet<Node, JumpTarget>();
    }
    _definedTargets[node] = target;
  }

  void undefineTarget(Node node) {
    if (_definedTargets != null) {
      _definedTargets.remove(node);
      if (_definedTargets.isEmpty) {
        _definedTargets = null;
      }
    }
  }

  JumpTarget getTargetDefinition(Node node) {
    return _definedTargets != null ? _definedTargets[node] : null;
  }

  void registerTargetOf(GotoStatement node, JumpTarget target) {
    if (_usedTargets == null) {
      _usedTargets = new Maplet<GotoStatement, JumpTarget>();
    }
    _usedTargets[node] = target;
  }

  JumpTarget getTargetOf(GotoStatement node) {
    return _usedTargets != null ? _usedTargets[node] : null;
  }

  void defineLabel(Label label, LabelDefinition target) {
    if (_definedLabels == null) {
      _definedLabels = new Maplet<Label, LabelDefinition>();
    }
    _definedLabels[label] = target;
  }

  void undefineLabel(Label label) {
    if (_definedLabels != null) {
      _definedLabels.remove(label);
      if (_definedLabels.isEmpty) {
        _definedLabels = null;
      }
    }
  }

  LabelDefinition getLabelDefinition(Label label) {
    return _definedLabels != null ? _definedLabels[label] : null;
  }

  void registerTargetLabel(GotoStatement node, LabelDefinition label) {
    assert(node.target != null);
    if (_targetLabels == null) {
      _targetLabels = new Maplet<GotoStatement, LabelDefinition>();
    }
    _targetLabels[node] = label;
  }

  LabelDefinition getTargetLabel(GotoStatement node) {
    assert(node.target != null);
    return _targetLabels != null ? _targetLabels[node] : null;
  }
}

class ResolverTask extends CompilerTask {
  final ConstantCompiler constantCompiler;

  ResolverTask(Compiler compiler, this.constantCompiler) : super(compiler);

  String get name => 'Resolver';

  TreeElements resolve(Element element) {
    return measure(() {
      if (Elements.isErroneousElement(element)) return null;

      processMetadata([result]) {
        for (MetadataAnnotation metadata in element.metadata) {
          metadata.ensureResolved(compiler);
        }
        return result;
      }

      ElementKind kind = element.kind;
      if (identical(kind, ElementKind.GENERATIVE_CONSTRUCTOR) ||
          identical(kind, ElementKind.FUNCTION) ||
          identical(kind, ElementKind.GETTER) ||
          identical(kind, ElementKind.SETTER)) {
        return processMetadata(resolveMethodElement(element));
      }

      if (identical(kind, ElementKind.FIELD)) {
        return processMetadata(resolveField(element));
      }
      if (element.isClass) {
        ClassElement cls = element;
        cls.ensureResolved(compiler);
        return processMetadata();
      } else if (element.isTypedef) {
        TypedefElement typdef = element;
        return processMetadata(resolveTypedef(typdef));
      }

      compiler.unimplemented(element, "resolve($element)");
    });
  }

  void resolveRedirectingConstructor(InitializerResolver resolver,
                                     Node node,
                                     FunctionElement constructor,
                                     FunctionElement redirection) {
    assert(invariant(node, constructor.isImplementation,
        message: 'Redirecting constructors must be resolved on implementation '
                 'elements.'));
    Setlet<FunctionElement> seen = new Setlet<FunctionElement>();
    seen.add(constructor);
    while (redirection != null) {
      // Ensure that we follow redirections through implementation elements.
      redirection = redirection.implementation;
      if (seen.contains(redirection)) {
        resolver.visitor.error(node, MessageKind.REDIRECTING_CONSTRUCTOR_CYCLE);
        return;
      }
      seen.add(redirection);
      redirection = resolver.visitor.resolveConstructorRedirection(redirection);
    }
  }

  static void processAsyncMarker(Compiler compiler,
                                 BaseFunctionElementX element) {
    FunctionExpression functionExpression = element.node;
    AsyncModifier asyncModifier = functionExpression.asyncModifier;
    if (asyncModifier != null) {
      if (!compiler.enableAsyncAwait) {
        compiler.reportError(asyncModifier,
            MessageKind.EXPERIMENTAL_ASYNC_AWAIT,
            {'modifier': element.asyncMarker});
      } else if (!compiler.analyzeOnly) {
        compiler.reportError(asyncModifier,
            MessageKind.EXPERIMENTAL_ASYNC_AWAIT,
            {'modifier': element.asyncMarker});
      }

      if (asyncModifier.isAsynchronous) {
        element.asyncMarker = asyncModifier.isYielding
            ? AsyncMarker.ASYNC_STAR : AsyncMarker.ASYNC;
      } else {
        element.asyncMarker = AsyncMarker.SYNC_STAR;
      }
      if (element.isAbstract) {
        compiler.reportError(asyncModifier,
            MessageKind.ASYNC_MODIFIER_ON_ABSTRACT_METHOD,
            {'modifier': element.asyncMarker});
      } else if (element.isConstructor) {
        compiler.reportError(asyncModifier,
            MessageKind.ASYNC_MODIFIER_ON_CONSTRUCTOR,
            {'modifier': element.asyncMarker});
      } else if (functionExpression.body.asReturn() != null &&
                 element.asyncMarker.isYielding) {
        compiler.reportError(asyncModifier,
            MessageKind.YIELDING_MODIFIER_ON_ARROW_BODY,
            {'modifier': element.asyncMarker});
      }
    }
  }

  TreeElements resolveMethodElementImplementation(
      FunctionElement element, FunctionExpression tree) {
    return compiler.withCurrentElement(element, () {
      if (element.isExternal && tree.hasBody()) {
        compiler.reportError(element,
            MessageKind.EXTERNAL_WITH_BODY,
            {'functionName': element.name});
      }
      if (element.isConstructor) {
        if (tree.returnType != null) {
          compiler.reportError(tree, MessageKind.CONSTRUCTOR_WITH_RETURN_TYPE);
        }
        if (element.isConst &&
            tree.hasBody() &&
            !tree.isRedirectingFactory) {
          compiler.reportError(tree, MessageKind.CONST_CONSTRUCTOR_HAS_BODY);
        }
      }

      ResolverVisitor visitor = visitorFor(element);
      ResolutionRegistry registry = visitor.registry;
      registry.defineFunction(tree, element);
      visitor.setupFunction(tree, element);

      if (element.isGenerativeConstructor) {
        // Even if there is no initializer list we still have to do the
        // resolution in case there is an implicit super constructor call.
        InitializerResolver resolver = new InitializerResolver(visitor);
        FunctionElement redirection =
            resolver.resolveInitializers(element, tree);
        if (redirection != null) {
          resolveRedirectingConstructor(resolver, tree, element, redirection);
        }
      } else if (tree.initializers != null) {
        error(tree, MessageKind.FUNCTION_WITH_INITIALIZER);
      }

      if (!compiler.analyzeSignaturesOnly || tree.isRedirectingFactory) {
        // We need to analyze the redirecting factory bodies to ensure that
        // we can analyze compile-time constants.
        visitor.visit(tree.body);
      }

      // Get the resolution tree and check that the resolved
      // function doesn't use 'super' if it is mixed into another
      // class. This is the part of the 'super' mixin check that
      // happens when a function is resolved after the mixin
      // application has been performed.
      TreeElements resolutionTree = registry.mapping;
      ClassElement enclosingClass = element.enclosingClass;
      if (enclosingClass != null) {
        // TODO(johnniwinther): Find another way to obtain mixin uses.
        Iterable<MixinApplicationElement> mixinUses =
            compiler.world.allMixinUsesOf(enclosingClass);
        ClassElement mixin = enclosingClass;
        for (MixinApplicationElement mixinApplication in mixinUses) {
          checkMixinSuperUses(resolutionTree, mixinApplication, mixin);
        }
      }
      return resolutionTree;
    });

  }

  TreeElements resolveMethodElement(FunctionElementX element) {
    assert(invariant(element, element.isDeclaration));
    return compiler.withCurrentElement(element, () {
      if (compiler.enqueuer.resolution.hasBeenResolved(element)) {
        // TODO(karlklose): Remove the check for [isConstructor]. [elememts]
        // should never be non-null, not even for constructors.
        assert(invariant(element, element.isConstructor,
            message: 'Non-constructor element $element '
                     'has already been analyzed.'));
        return element.resolvedAst.elements;
      }
      if (element.isSynthesized) {
        if (element.isGenerativeConstructor) {
          ResolutionRegistry registry =
              new ResolutionRegistry(compiler, element);
          ConstructorElement constructor = element.asFunctionElement();
          ConstructorElement target = constructor.definingConstructor;
          // Ensure the signature of the synthesized element is
          // resolved. This is the only place where the resolver is
          // seeing this element.
          element.computeSignature(compiler);
          if (!target.isErroneous) {
            registry.registerStaticUse(target);
            registry.registerImplicitSuperCall(target);
          }
          return registry.mapping;
        } else {
          assert(element.isDeferredLoaderGetter);
          return _ensureTreeElements(element);
        }
      } else {
        element.parseNode(compiler);
        element.computeType(compiler);
        processAsyncMarker(compiler, element);
        FunctionElementX implementation = element;
        if (element.isExternal) {
          implementation = compiler.backend.resolveExternalFunction(element);
        }
        return resolveMethodElementImplementation(
            implementation, implementation.node);
      }
    });
  }

  /// Creates a [ResolverVisitor] for resolving an AST in context of [element].
  /// If [useEnclosingScope] is `true` then the initial scope of the visitor
  /// does not include inner scope of [element].
  ///
  /// This method should only be used by this library (or tests of
  /// this library).
  ResolverVisitor visitorFor(Element element, {bool useEnclosingScope: false}) {
    return new ResolverVisitor(compiler, element,
        new ResolutionRegistry(compiler, element),
        useEnclosingScope: useEnclosingScope);
  }

  TreeElements resolveField(FieldElementX element) {
    VariableDefinitions tree = element.parseNode(compiler);
    if(element.modifiers.isStatic && element.isTopLevel) {
      error(element.modifiers.getStatic(),
            MessageKind.TOP_LEVEL_VARIABLE_DECLARED_STATIC);
    }
    ResolverVisitor visitor = visitorFor(element);
    ResolutionRegistry registry = visitor.registry;
    // TODO(johnniwinther): Maybe remove this when placeholderCollector migrates
    // to the backend ast.
    registry.defineElement(tree.definitions.nodes.head, element);
    // TODO(johnniwinther): Share the resolved type between all variables
    // declared in the same declaration.
    if (tree.type != null) {
      element.variables.type = visitor.resolveTypeAnnotation(tree.type);
    } else {
      element.variables.type = const DynamicType();
    }

    Expression initializer = element.initializer;
    Modifiers modifiers = element.modifiers;
    if (initializer != null) {
      // TODO(johnniwinther): Avoid analyzing initializers if
      // [Compiler.analyzeSignaturesOnly] is set.
      visitor.visit(initializer);
    } else if (modifiers.isConst) {
      compiler.reportError(element, MessageKind.CONST_WITHOUT_INITIALIZER);
    } else if (modifiers.isFinal && !element.isInstanceMember) {
      compiler.reportError(element, MessageKind.FINAL_WITHOUT_INITIALIZER);
    } else {
      registry.registerInstantiatedClass(compiler.nullClass);
    }

    if (Elements.isStaticOrTopLevelField(element)) {
      visitor.addDeferredAction(element, () {
        if (element.modifiers.isConst) {
          constantCompiler.compileConstant(element);
        } else {
          constantCompiler.compileVariable(element);
        }
      });
      if (initializer != null) {
        if (!element.modifiers.isConst) {
          // TODO(johnniwinther): Determine the const-ness eagerly to avoid
          // unnecessary registrations.
          registry.registerLazyField();
        }
      }
    }

    // Perform various checks as side effect of "computing" the type.
    element.computeType(compiler);

    return registry.mapping;
  }

  DartType resolveTypeAnnotation(Element element, TypeAnnotation annotation) {
    DartType type = resolveReturnType(element, annotation);
    if (type.isVoid) {
      error(annotation, MessageKind.VOID_NOT_ALLOWED);
    }
    return type;
  }

  DartType resolveReturnType(Element element, TypeAnnotation annotation) {
    if (annotation == null) return const DynamicType();
    DartType result = visitorFor(element).resolveTypeAnnotation(annotation);
    if (result == null) {
      // TODO(karklose): warning.
      return const DynamicType();
    }
    return result;
  }

  void resolveRedirectionChain(ConstructorElementX constructor,
                               Spannable node) {
    ConstructorElementX target = constructor;
    InterfaceType targetType;
    List<Element> seen = new List<Element>();
    // Follow the chain of redirections and check for cycles.
    while (target.isRedirectingFactory) {
      if (target.internalEffectiveTarget != null) {
        // We found a constructor that already has been processed.
        targetType = target.effectiveTargetType;
        assert(invariant(target, targetType != null,
            message: 'Redirection target type has not been computed for '
                     '$target'));
        target = target.internalEffectiveTarget;
        break;
      }

      Element nextTarget = target.immediateRedirectionTarget;
      if (seen.contains(nextTarget)) {
        error(node, MessageKind.CYCLIC_REDIRECTING_FACTORY);
        break;
      }
      seen.add(target);
      target = nextTarget;
    }

    if (targetType == null) {
      assert(!target.isRedirectingFactory);
      targetType = target.enclosingClass.thisType;
    }

    // [target] is now the actual target of the redirections.  Run through
    // the constructors again and set their [redirectionTarget], so that we
    // do not have to run the loop for these constructors again. Furthermore,
    // compute [redirectionTargetType] for each factory by computing the
    // substitution of the target type with respect to the factory type.
    while (!seen.isEmpty) {
      ConstructorElementX factory = seen.removeLast();

      // [factory] must already be analyzed but the [TreeElements] might not
      // have been stored in the enqueuer cache yet.
      // TODO(johnniwinther): Store [TreeElements] in the cache before
      // resolution of the element.
      TreeElements treeElements = factory.treeElements;
      assert(invariant(node, treeElements != null,
          message: 'No TreeElements cached for $factory.'));
      FunctionExpression functionNode = factory.parseNode(compiler);
      RedirectingFactoryBody redirectionNode = functionNode.body;
      InterfaceType factoryType = treeElements.getType(redirectionNode);

      targetType = targetType.substByContext(factoryType);
      factory.effectiveTarget = target;
      factory.effectiveTargetType = targetType;
    }
  }

  /**
   * Load and resolve the supertypes of [cls].
   *
   * Warning: do not call this method directly. It should only be
   * called by [resolveClass] and [ClassSupertypeResolver].
   */
  void loadSupertypes(BaseClassElementX cls, Spannable from) {
    compiler.withCurrentElement(cls, () => measure(() {
      if (cls.supertypeLoadState == STATE_DONE) return;
      if (cls.supertypeLoadState == STATE_STARTED) {
        compiler.reportError(from, MessageKind.CYCLIC_CLASS_HIERARCHY,
                                 {'className': cls.name});
        cls.supertypeLoadState = STATE_DONE;
        cls.hasIncompleteHierarchy = true;
        cls.allSupertypesAndSelf =
            compiler.objectClass.allSupertypesAndSelf.extendClass(
                cls.computeType(compiler));
        cls.supertype = cls.allSupertypes.head;
        assert(invariant(from, cls.supertype != null,
            message: 'Missing supertype on cyclic class $cls.'));
        cls.interfaces = const Link<DartType>();
        return;
      }
      cls.supertypeLoadState = STATE_STARTED;
      compiler.withCurrentElement(cls, () {
        // TODO(ahe): Cache the node in cls.
        cls.parseNode(compiler).accept(
            new ClassSupertypeResolver(compiler, cls));
        if (cls.supertypeLoadState != STATE_DONE) {
          cls.supertypeLoadState = STATE_DONE;
        }
      });
    }));
  }

  // TODO(johnniwinther): Remove this queue when resolution has been split into
  // syntax and semantic resolution.
  TypeDeclarationElement currentlyResolvedTypeDeclaration;
  Queue<ClassElement> pendingClassesToBeResolved = new Queue<ClassElement>();
  Queue<ClassElement> pendingClassesToBePostProcessed =
      new Queue<ClassElement>();

  /// Resolve [element] using [resolveTypeDeclaration].
  ///
  /// This methods ensure that class declarations encountered through type
  /// annotations during the resolution of [element] are resolved after
  /// [element] has been resolved.
  // TODO(johnniwinther): Encapsulate this functionality in a
  // 'TypeDeclarationResolver'.
  _resolveTypeDeclaration(TypeDeclarationElement element,
                          resolveTypeDeclaration()) {
    return compiler.withCurrentElement(element, () {
      return measure(() {
        TypeDeclarationElement previousResolvedTypeDeclaration =
            currentlyResolvedTypeDeclaration;
        currentlyResolvedTypeDeclaration = element;
        var result = resolveTypeDeclaration();
        if (previousResolvedTypeDeclaration == null) {
          do {
            while (!pendingClassesToBeResolved.isEmpty) {
              pendingClassesToBeResolved.removeFirst().ensureResolved(compiler);
            }
            while (!pendingClassesToBePostProcessed.isEmpty) {
              _postProcessClassElement(
                  pendingClassesToBePostProcessed.removeFirst());
            }
          } while (!pendingClassesToBeResolved.isEmpty);
          assert(pendingClassesToBeResolved.isEmpty);
          assert(pendingClassesToBePostProcessed.isEmpty);
        }
        currentlyResolvedTypeDeclaration = previousResolvedTypeDeclaration;
        return result;
      });
    });
  }

  /**
   * Resolve the class [element].
   *
   * Before calling this method, [element] was constructed by the
   * scanner and most fields are null or empty. This method fills in
   * these fields and also ensure that the supertypes of [element] are
   * resolved.
   *
   * Warning: Do not call this method directly. Instead use
   * [:element.ensureResolved(compiler):].
   */
  TreeElements resolveClass(BaseClassElementX element) {
    return _resolveTypeDeclaration(element, () {
      // TODO(johnniwinther): Store the mapping in the resolution enqueuer.
      ResolutionRegistry registry = new ResolutionRegistry(compiler, element);
      resolveClassInternal(element, registry);
      return element.treeElements;
    });
  }

  void _ensureClassWillBeResolved(ClassElement element) {
    if (currentlyResolvedTypeDeclaration == null) {
      element.ensureResolved(compiler);
    } else {
      pendingClassesToBeResolved.add(element);
    }
  }

  void resolveClassInternal(BaseClassElementX element,
                            ResolutionRegistry registry) {
    if (!element.isPatch) {
      compiler.withCurrentElement(element, () => measure(() {
        assert(element.resolutionState == STATE_NOT_STARTED);
        element.resolutionState = STATE_STARTED;
        Node tree = element.parseNode(compiler);
        loadSupertypes(element, tree);

        ClassResolverVisitor visitor =
            new ClassResolverVisitor(compiler, element, registry);
        visitor.visit(tree);
        element.resolutionState = STATE_DONE;
        compiler.onClassResolved(element);
        pendingClassesToBePostProcessed.add(element);
      }));
      if (element.isPatched) {
        // Ensure handling patch after origin.
        element.patch.ensureResolved(compiler);
      }
    } else { // Handle patch classes:
      element.resolutionState = STATE_STARTED;
      // Ensure handling origin before patch.
      element.origin.ensureResolved(compiler);
      // Ensure that the type is computed.
      element.computeType(compiler);
      // Copy class hierarchy from origin.
      element.supertype = element.origin.supertype;
      element.interfaces = element.origin.interfaces;
      element.allSupertypesAndSelf = element.origin.allSupertypesAndSelf;
      // Stepwise assignment to ensure invariant.
      element.supertypeLoadState = STATE_STARTED;
      element.supertypeLoadState = STATE_DONE;
      element.resolutionState = STATE_DONE;
      // TODO(johnniwinther): Check matching type variables and
      // empty extends/implements clauses.
    }
  }

  void _postProcessClassElement(BaseClassElementX element) {
    for (MetadataAnnotation metadata in element.metadata) {
      metadata.ensureResolved(compiler);
      if (!element.isProxy &&
          metadata.constant.value == compiler.proxyConstant) {
        element.isProxy = true;
      }
    }

    // Force resolution of metadata on non-instance members since they may be
    // inspected by the backend while emitting. Metadata on instance members is
    // handled as a result of processing instantiated class members in the
    // enqueuer.
    // TODO(ahe): Avoid this eager resolution.
    element.forEachMember((_, Element member) {
      if (!member.isInstanceMember) {
        compiler.withCurrentElement(member, () {
          for (MetadataAnnotation metadata in member.metadata) {
            metadata.ensureResolved(compiler);
          }
        });
      }
    });

    computeClassMember(element, Compiler.CALL_OPERATOR_NAME);
  }

  void computeClassMembers(ClassElement element) {
    MembersCreator.computeAllClassMembers(compiler, element);
  }

  void computeClassMember(ClassElement element, String name) {
    MembersCreator.computeClassMembersByName(compiler, element, name);
  }

  void checkClass(ClassElement element) {
    computeClassMembers(element);
    if (element.isMixinApplication) {
      checkMixinApplication(element);
    } else {
      checkClassMembers(element);
    }
  }

  void checkMixinApplication(MixinApplicationElementX mixinApplication) {
    Modifiers modifiers = mixinApplication.modifiers;
    int illegalFlags = modifiers.flags & ~Modifiers.FLAG_ABSTRACT;
    if (illegalFlags != 0) {
      Modifiers illegalModifiers = new Modifiers.withFlags(null, illegalFlags);
      compiler.reportError(
          modifiers,
          MessageKind.ILLEGAL_MIXIN_APPLICATION_MODIFIERS,
          {'modifiers': illegalModifiers});
    }

    // In case of cyclic mixin applications, the mixin chain will have
    // been cut. If so, we have already reported the error to the
    // user so we just return from here.
    ClassElement mixin = mixinApplication.mixin;
    if (mixin == null) return;

    // Check that we're not trying to use Object as a mixin.
    if (mixin.superclass == null) {
      compiler.reportError(mixinApplication,
                               MessageKind.ILLEGAL_MIXIN_OBJECT);
      // Avoid reporting additional errors for the Object class.
      return;
    }

    if (mixin.isEnumClass) {
      // Mixing in an enum has already caused a compile-time error.
      return;
    }

    // Check that the mixed in class has Object as its superclass.
    if (!mixin.superclass.isObject) {
      compiler.reportError(mixin, MessageKind.ILLEGAL_MIXIN_SUPERCLASS);
    }

    // Check that the mixed in class doesn't have any constructors and
    // make sure we aren't mixing in methods that use 'super'.
    mixin.forEachLocalMember((AstElement member) {
      if (member.isGenerativeConstructor && !member.isSynthesized) {
        compiler.reportError(member, MessageKind.ILLEGAL_MIXIN_CONSTRUCTOR);
      } else {
        // Get the resolution tree and check that the resolved member
        // doesn't use 'super'. This is the part of the 'super' mixin
        // check that happens when a function is resolved before the
        // mixin application has been performed.
        // TODO(johnniwinther): Obtain the [TreeElements] for [member]
        // differently.
        if (compiler.enqueuer.resolution.hasBeenResolved(member)) {
          checkMixinSuperUses(
              member.resolvedAst.elements,
              mixinApplication,
              mixin);
        }
      }
    });
  }

  void checkMixinSuperUses(TreeElements resolutionTree,
                           MixinApplicationElement mixinApplication,
                           ClassElement mixin) {
    // TODO(johnniwinther): Avoid the use of [TreeElements] here.
    if (resolutionTree == null) return;
    Iterable<Node> superUses = resolutionTree.superUses;
    if (superUses.isEmpty) return;
    compiler.reportError(mixinApplication,
                         MessageKind.ILLEGAL_MIXIN_WITH_SUPER,
                         {'className': mixin.name});
    // Show the user the problematic uses of 'super' in the mixin.
    for (Node use in superUses) {
      compiler.reportInfo(
          use,
          MessageKind.ILLEGAL_MIXIN_SUPER_USE);
    }
  }

  void checkClassMembers(ClassElement cls) {
    assert(invariant(cls, cls.isDeclaration));
    if (cls.isObject) return;
    // TODO(johnniwinther): Should this be done on the implementation element as
    // well?
    List<Element> constConstructors = <Element>[];
    List<Element> nonFinalInstanceFields = <Element>[];
    cls.forEachMember((holder, member) {
      compiler.withCurrentElement(member, () {
        // Perform various checks as side effect of "computing" the type.
        member.computeType(compiler);

        // Check modifiers.
        if (member.isFunction && member.modifiers.isFinal) {
          compiler.reportError(
              member, MessageKind.ILLEGAL_FINAL_METHOD_MODIFIER);
        }
        if (member.isConstructor) {
          final mismatchedFlagsBits =
              member.modifiers.flags &
              (Modifiers.FLAG_STATIC | Modifiers.FLAG_ABSTRACT);
          if (mismatchedFlagsBits != 0) {
            final mismatchedFlags =
                new Modifiers.withFlags(null, mismatchedFlagsBits);
            compiler.reportError(
                member,
                MessageKind.ILLEGAL_CONSTRUCTOR_MODIFIERS,
                {'modifiers': mismatchedFlags});
          }
          if (member.modifiers.isConst) {
            constConstructors.add(member);
          }
        }
        if (member.isField) {
          if (member.modifiers.isConst && !member.modifiers.isStatic) {
            compiler.reportError(
                member, MessageKind.ILLEGAL_CONST_FIELD_MODIFIER);
          }
          if (!member.modifiers.isStatic && !member.modifiers.isFinal) {
            nonFinalInstanceFields.add(member);
          }
        }
        checkAbstractField(member);
        checkUserDefinableOperator(member);
      });
    });
    if (!constConstructors.isEmpty && !nonFinalInstanceFields.isEmpty) {
      Spannable span = constConstructors.length > 1
          ? cls : constConstructors[0];
      compiler.reportError(span,
          MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS,
          {'className': cls.name});
      if (constConstructors.length > 1) {
        for (Element constructor in constConstructors) {
          compiler.reportInfo(constructor,
              MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_CONSTRUCTOR);
        }
      }
      for (Element field in nonFinalInstanceFields) {
        compiler.reportInfo(field,
            MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_FIELD);
      }
    }
  }

  void checkAbstractField(Element member) {
    // Only check for getters. The test can only fail if there is both a setter
    // and a getter with the same name, and we only need to check each abstract
    // field once, so we just ignore setters.
    if (!member.isGetter) return;

    // Find the associated abstract field.
    ClassElement classElement = member.enclosingClass;
    Element lookupElement = classElement.lookupLocalMember(member.name);
    if (lookupElement == null) {
      compiler.internalError(member,
          "No abstract field for accessor");
    } else if (!identical(lookupElement.kind, ElementKind.ABSTRACT_FIELD)) {
      compiler.internalError(member,
          "Inaccessible abstract field for accessor");
    }
    AbstractFieldElement field = lookupElement;

    FunctionElementX getter = field.getter;
    if (getter == null) return;
    FunctionElementX setter = field.setter;
    if (setter == null) return;
    int getterFlags = getter.modifiers.flags | Modifiers.FLAG_ABSTRACT;
    int setterFlags = setter.modifiers.flags | Modifiers.FLAG_ABSTRACT;
    if (!identical(getterFlags, setterFlags)) {
      final mismatchedFlags =
        new Modifiers.withFlags(null, getterFlags ^ setterFlags);
      compiler.reportError(
          field.getter,
          MessageKind.GETTER_MISMATCH,
          {'modifiers': mismatchedFlags});
      compiler.reportError(
          field.setter,
          MessageKind.SETTER_MISMATCH,
          {'modifiers': mismatchedFlags});
    }
  }

  void checkUserDefinableOperator(Element member) {
    FunctionElement function = member.asFunctionElement();
    if (function == null) return;
    String value = member.name;
    if (value == null) return;
    if (!(isUserDefinableOperator(value) || identical(value, 'unary-'))) return;

    bool isMinus = false;
    int requiredParameterCount;
    MessageKind messageKind;
    if (identical(value, 'unary-')) {
      isMinus = true;
      messageKind = MessageKind.MINUS_OPERATOR_BAD_ARITY;
      requiredParameterCount = 0;
    } else if (isMinusOperator(value)) {
      isMinus = true;
      messageKind = MessageKind.MINUS_OPERATOR_BAD_ARITY;
      requiredParameterCount = 1;
    } else if (isUnaryOperator(value)) {
      messageKind = MessageKind.UNARY_OPERATOR_BAD_ARITY;
      requiredParameterCount = 0;
    } else if (isBinaryOperator(value)) {
      messageKind = MessageKind.BINARY_OPERATOR_BAD_ARITY;
      requiredParameterCount = 1;
      if (identical(value, '==')) checkOverrideHashCode(member);
    } else if (isTernaryOperator(value)) {
      messageKind = MessageKind.TERNARY_OPERATOR_BAD_ARITY;
      requiredParameterCount = 2;
    } else {
      compiler.internalError(function,
          'Unexpected user defined operator $value');
    }
    checkArity(function, requiredParameterCount, messageKind, isMinus);
  }

  void checkOverrideHashCode(FunctionElement operatorEquals) {
    if (operatorEquals.isAbstract) return;
    ClassElement cls = operatorEquals.enclosingClass;
    Element hashCodeImplementation =
        cls.lookupLocalMember('hashCode');
    if (hashCodeImplementation != null) return;
    compiler.reportHint(
        operatorEquals, MessageKind.OVERRIDE_EQUALS_NOT_HASH_CODE,
        {'class': cls.name});
  }

  void checkArity(FunctionElement function,
                  int requiredParameterCount, MessageKind messageKind,
                  bool isMinus) {
    FunctionExpression node = function.node;
    FunctionSignature signature = function.functionSignature;
    if (signature.requiredParameterCount != requiredParameterCount) {
      Node errorNode = node;
      if (node.parameters != null) {
        if (isMinus ||
            signature.requiredParameterCount < requiredParameterCount) {
          // If there are too few parameters, point to the whole parameter list.
          // For instance
          //
          //     int operator +() {}
          //                   ^^
          //
          //     int operator []=(value) {}
          //                     ^^^^^^^
          //
          // For operator -, always point the whole parameter list, like
          //
          //     int operator -(a, b) {}
          //                   ^^^^^^
          //
          // instead of
          //
          //     int operator -(a, b) {}
          //                       ^
          //
          // since the correction might not be to remove 'b' but instead to
          // remove 'a, b'.
          errorNode = node.parameters;
        } else {
          errorNode = node.parameters.nodes.skip(requiredParameterCount).head;
        }
      }
      compiler.reportError(
          errorNode, messageKind, {'operatorName': function.name});
    }
    if (signature.optionalParameterCount != 0) {
      Node errorNode =
          node.parameters.nodes.skip(signature.requiredParameterCount).head;
      if (signature.optionalParametersAreNamed) {
        compiler.reportError(
            errorNode,
            MessageKind.OPERATOR_NAMED_PARAMETERS,
            {'operatorName': function.name});
      } else {
        compiler.reportError(
            errorNode,
            MessageKind.OPERATOR_OPTIONAL_PARAMETERS,
            {'operatorName': function.name});
      }
    }
  }

  reportErrorWithContext(Element errorneousElement,
                         MessageKind errorMessage,
                         Element contextElement,
                         MessageKind contextMessage) {
    compiler.reportError(
        errorneousElement,
        errorMessage,
        {'memberName': contextElement.name,
         'className': contextElement.enclosingClass.name});
    compiler.reportInfo(contextElement, contextMessage);
  }


  FunctionSignature resolveSignature(FunctionElementX element) {
    MessageKind defaultValuesError = null;
    if (element.isFactoryConstructor) {
      FunctionExpression body = element.parseNode(compiler);
      if (body.isRedirectingFactory) {
        defaultValuesError = MessageKind.REDIRECTING_FACTORY_WITH_DEFAULT;
      }
    }
    return compiler.withCurrentElement(element, () {
      FunctionExpression node =
          compiler.parser.measure(() => element.parseNode(compiler));
      return measure(() => SignatureResolver.analyze(
          compiler, node.parameters, node.returnType, element,
          new ResolutionRegistry(compiler, element),
          defaultValuesError: defaultValuesError,
          createRealParameters: true));
    });
  }

  TreeElements resolveTypedef(TypedefElementX element) {
    if (element.isResolved) return element.treeElements;
    compiler.world.allTypedefs.add(element);
    return _resolveTypeDeclaration(element, () {
      ResolutionRegistry registry = new ResolutionRegistry(compiler, element);
      return compiler.withCurrentElement(element, () {
        return measure(() {
          assert(element.resolutionState == STATE_NOT_STARTED);
          element.resolutionState = STATE_STARTED;
          Typedef node =
            compiler.parser.measure(() => element.parseNode(compiler));
          TypedefResolverVisitor visitor =
            new TypedefResolverVisitor(compiler, element, registry);
          visitor.visit(node);
          element.resolutionState = STATE_DONE;
          return registry.mapping;
        });
      });
    });
  }

  void resolveMetadataAnnotation(MetadataAnnotationX annotation) {
    compiler.withCurrentElement(annotation.annotatedElement, () => measure(() {
      assert(annotation.resolutionState == STATE_NOT_STARTED);
      annotation.resolutionState = STATE_STARTED;

      Node node = annotation.parseNode(compiler);
      Element annotatedElement = annotation.annotatedElement;
      AnalyzableElement context = annotatedElement.analyzableElement;
      ClassElement classElement = annotatedElement.enclosingClass;
      if (classElement != null) {
        // The annotation is resolved in the scope of [classElement].
        classElement.ensureResolved(compiler);
      }
      assert(invariant(node, context != null,
          message: "No context found for metadata annotation "
                   "on $annotatedElement."));
      ResolverVisitor visitor = visitorFor(context, useEnclosingScope: true);
      ResolutionRegistry registry = visitor.registry;
      node.accept(visitor);
      // TODO(johnniwinther): Avoid passing the [TreeElements] to
      // [compileMetadata].
      annotation.constant =
          constantCompiler.compileMetadata(annotation, node, registry.mapping);
      // TODO(johnniwinther): Register the relation between the annotation
      // and the annotated element instead. This will allow the backend to
      // retrieve the backend constant and only register metadata on the
      // elements for which it is needed. (Issue 17732).
      registry.registerMetadataConstant(annotation, annotatedElement);
      annotation.resolutionState = STATE_DONE;
    }));
  }

  error(Spannable node, MessageKind kind, [arguments = const {}]) {
    // TODO(ahe): Make non-fatal.
    compiler.reportFatalError(node, kind, arguments);
  }

  Link<MetadataAnnotation> resolveMetadata(Element element,
                                           VariableDefinitions node) {
    LinkBuilder<MetadataAnnotation> metadata =
        new LinkBuilder<MetadataAnnotation>();
    for (Metadata annotation in node.metadata.nodes) {
      ParameterMetadataAnnotation metadataAnnotation =
          new ParameterMetadataAnnotation(annotation);
      metadataAnnotation.annotatedElement = element;
      metadata.addLast(metadataAnnotation.ensureResolved(compiler));
    }
    return metadata.toLink();
  }
}

class InitializerResolver {
  final ResolverVisitor visitor;
  final Map<Element, Node> initialized;
  Link<Node> initializers;
  bool hasSuper;

  InitializerResolver(this.visitor)
    : initialized = new Map<Element, Node>(), hasSuper = false;

  ResolutionRegistry get registry => visitor.registry;

  error(Node node, MessageKind kind, [arguments = const {}]) {
    visitor.error(node, kind, arguments);
  }

  warning(Node node, MessageKind kind, [arguments = const {}]) {
    visitor.warning(node, kind, arguments);
  }

  bool isFieldInitializer(SendSet node) {
    if (node.selector.asIdentifier() == null) return false;
    if (node.receiver == null) return true;
    if (node.receiver.asIdentifier() == null) return false;
    return node.receiver.asIdentifier().isThis();
  }

  reportDuplicateInitializerError(Element field, Node init, Node existing) {
    visitor.compiler.reportError(
        init,
        MessageKind.DUPLICATE_INITIALIZER, {'fieldName': field.name});
    visitor.compiler.reportInfo(
        existing,
        MessageKind.ALREADY_INITIALIZED, {'fieldName': field.name});
  }

  void checkForDuplicateInitializers(FieldElementX field, Node init) {
    // [field] can be null if it could not be resolved.
    if (field == null) return;
    String name = field.name;
    if (initialized.containsKey(field)) {
      reportDuplicateInitializerError(field, init, initialized[field]);
    } else if (field.isFinal) {
      field.parseNode(visitor.compiler);
      Expression initializer = field.initializer;
      if (initializer != null) {
        reportDuplicateInitializerError(field, init, initializer);
      }
    }
    initialized[field] = init;
  }

  void resolveFieldInitializer(FunctionElement constructor, SendSet init) {
    // init is of the form [this.]field = value.
    final Node selector = init.selector;
    final String name = selector.asIdentifier().source;
    // Lookup target field.
    Element target;
    if (isFieldInitializer(init)) {
      target = constructor.enclosingClass.lookupLocalMember(name);
      if (target == null) {
        error(selector, MessageKind.CANNOT_RESOLVE, {'name': name});
      } else if (target.kind != ElementKind.FIELD) {
        error(selector, MessageKind.NOT_A_FIELD, {'fieldName': name});
      } else if (!target.isInstanceMember) {
        error(selector, MessageKind.INIT_STATIC_FIELD, {'fieldName': name});
      }
    } else {
      error(init, MessageKind.INVALID_RECEIVER_IN_INITIALIZER);
    }
    registry.useElement(init, target);
    registry.registerStaticUse(target);
    checkForDuplicateInitializers(target, init);
    // Resolve initializing value.
    visitor.visitInStaticContext(init.arguments.head);
  }

  ClassElement getSuperOrThisLookupTarget(FunctionElement constructor,
                                          bool isSuperCall,
                                          Node diagnosticNode) {
    ClassElement lookupTarget = constructor.enclosingClass;
    if (isSuperCall) {
      // Calculate correct lookup target and constructor name.
      if (identical(lookupTarget, visitor.compiler.objectClass)) {
        error(diagnosticNode, MessageKind.SUPER_INITIALIZER_IN_OBJECT);
      } else {
        return lookupTarget.supertype.element;
      }
    }
    return lookupTarget;
  }

  Element resolveSuperOrThisForSend(FunctionElement constructor,
                                    FunctionExpression functionNode,
                                    Send call) {
    // Resolve the selector and the arguments.
    ResolverTask resolver = visitor.compiler.resolver;
    visitor.inStaticContext(() {
      visitor.resolveSelector(call, null);
      visitor.resolveArguments(call.argumentsNode);
    });
    Selector selector = registry.getSelector(call);
    bool isSuperCall = Initializers.isSuperConstructorCall(call);

    ClassElement lookupTarget = getSuperOrThisLookupTarget(constructor,
                                                           isSuperCall,
                                                           call);
    Selector constructorSelector =
        visitor.getRedirectingThisOrSuperConstructorSelector(call);
    FunctionElement calledConstructor =
        lookupTarget.lookupConstructor(constructorSelector);

    final bool isImplicitSuperCall = false;
    final String className = lookupTarget.name;
    verifyThatConstructorMatchesCall(constructor,
                                     calledConstructor,
                                     selector,
                                     isImplicitSuperCall,
                                     call,
                                     className,
                                     constructorSelector);

    registry.useElement(call, calledConstructor);
    registry.registerStaticUse(calledConstructor);
    return calledConstructor;
  }

  void resolveImplicitSuperConstructorSend(FunctionElement constructor,
                                           FunctionExpression functionNode) {
    // If the class has a super resolve the implicit super call.
    ClassElement classElement = constructor.enclosingClass;
    ClassElement superClass = classElement.superclass;
    if (classElement != visitor.compiler.objectClass) {
      assert(superClass != null);
      assert(superClass.resolutionState == STATE_DONE);
      String constructorName = '';
      Selector callToMatch = new Selector.call(
          constructorName,
          classElement.library,
          0);

      final bool isSuperCall = true;
      ClassElement lookupTarget = getSuperOrThisLookupTarget(constructor,
                                                             isSuperCall,
                                                             functionNode);
      Selector constructorSelector = new Selector.callDefaultConstructor(
          visitor.enclosingElement.library);
      Element calledConstructor = lookupTarget.lookupConstructor(
          constructorSelector);

      final String className = lookupTarget.name;
      final bool isImplicitSuperCall = true;
      verifyThatConstructorMatchesCall(constructor,
                                       calledConstructor,
                                       callToMatch,
                                       isImplicitSuperCall,
                                       functionNode,
                                       className,
                                       constructorSelector);
      registry.registerImplicitSuperCall(calledConstructor);
      registry.registerStaticUse(calledConstructor);
    }
  }

  void verifyThatConstructorMatchesCall(
      FunctionElement caller,
      FunctionElement lookedupConstructor,
      Selector call,
      bool isImplicitSuperCall,
      Node diagnosticNode,
      String className,
      Selector constructorSelector) {
    if (lookedupConstructor == null
        || !lookedupConstructor.isGenerativeConstructor) {
      String fullConstructorName = Elements.constructorNameForDiagnostics(
              className,
              constructorSelector.name);
      MessageKind kind = isImplicitSuperCall
          ? MessageKind.CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT
          : MessageKind.CANNOT_RESOLVE_CONSTRUCTOR;
      visitor.compiler.reportError(
          diagnosticNode, kind, {'constructorName': fullConstructorName});
    } else {
      lookedupConstructor.computeSignature(visitor.compiler);
      if (!call.applies(lookedupConstructor, visitor.compiler.world)) {
        MessageKind kind = isImplicitSuperCall
                           ? MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT
                           : MessageKind.NO_MATCHING_CONSTRUCTOR;
        visitor.compiler.reportError(diagnosticNode, kind);
      } else if (caller.isConst
                 && !lookedupConstructor.isConst) {
        visitor.compiler.reportError(
            diagnosticNode, MessageKind.CONST_CALLS_NON_CONST);
      }
    }
  }

  /**
   * Resolve all initializers of this constructor. In the case of a redirecting
   * constructor, the resolved constructor's function element is returned.
   */
  FunctionElement resolveInitializers(FunctionElement constructor,
                                      FunctionExpression functionNode) {
    // Keep track of all "this.param" parameters specified for constructor so
    // that we can ensure that fields are initialized only once.
    FunctionSignature functionParameters = constructor.functionSignature;
    functionParameters.forEachParameter((ParameterElement element) {
      if (element.isInitializingFormal) {
        InitializingFormalElement initializingFormal = element;
        checkForDuplicateInitializers(initializingFormal.fieldElement,
                                      element.initializer);
      }
    });

    if (functionNode.initializers == null) {
      initializers = const Link<Node>();
    } else {
      initializers = functionNode.initializers.nodes;
    }
    FunctionElement result;
    bool resolvedSuper = false;
    for (Link<Node> link = initializers; !link.isEmpty; link = link.tail) {
      if (link.head.asSendSet() != null) {
        final SendSet init = link.head.asSendSet();
        resolveFieldInitializer(constructor, init);
      } else if (link.head.asSend() != null) {
        final Send call = link.head.asSend();
        if (call.argumentsNode == null) {
          error(link.head, MessageKind.INVALID_INITIALIZER);
          continue;
        }
        if (Initializers.isSuperConstructorCall(call)) {
          if (resolvedSuper) {
            error(call, MessageKind.DUPLICATE_SUPER_INITIALIZER);
          }
          resolveSuperOrThisForSend(constructor, functionNode, call);
          resolvedSuper = true;
        } else if (Initializers.isConstructorRedirect(call)) {
          // Check that there is no body (Language specification 7.5.1).  If the
          // constructor is also const, we already reported an error in
          // [resolveMethodElement].
          if (functionNode.hasBody() && !constructor.isConst) {
            error(functionNode, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_BODY);
          }
          // Check that there are no other initializers.
          if (!initializers.tail.isEmpty) {
            error(call, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER);
          }
          // Check that there are no field initializing parameters.
          Compiler compiler = visitor.compiler;
          FunctionSignature signature = constructor.functionSignature;
          signature.forEachParameter((ParameterElement parameter) {
            if (parameter.isInitializingFormal) {
              Node node = parameter.node;
              error(node, MessageKind.INITIALIZING_FORMAL_NOT_ALLOWED);
            }
          });
          return resolveSuperOrThisForSend(constructor, functionNode, call);
        } else {
          visitor.error(call, MessageKind.CONSTRUCTOR_CALL_EXPECTED);
          return null;
        }
      } else {
        error(link.head, MessageKind.INVALID_INITIALIZER);
      }
    }
    if (!resolvedSuper) {
      resolveImplicitSuperConstructorSend(constructor, functionNode);
    }
    return null;  // If there was no redirection always return null.
  }
}

class CommonResolverVisitor<R> extends Visitor<R> {
  final Compiler compiler;

  CommonResolverVisitor(Compiler this.compiler);

  R visitNode(Node node) {
    internalError(node,
        'internal error: Unhandled node: ${node.getObjectDescription()}');
    return null;
  }

  R visitEmptyStatement(Node node) => null;

  /** Convenience method for visiting nodes that may be null. */
  R visit(Node node) => (node == null) ? null : node.accept(this);

  void error(Spannable node, MessageKind kind, [Map arguments = const {}]) {
    compiler.reportFatalError(node, kind, arguments);
  }

  void warning(Spannable node, MessageKind kind, [Map arguments = const {}]) {
    compiler.reportWarning(node, kind, arguments);
  }

  void internalError(Spannable node, message) {
    compiler.internalError(node, message);
  }

  void addDeferredAction(Element element, DeferredAction action) {
    compiler.enqueuer.resolution.addDeferredAction(element, action);
  }
}

abstract class LabelScope {
  LabelScope get outer;
  LabelDefinition lookup(String label);
}

class LabeledStatementLabelScope implements LabelScope {
  final LabelScope outer;
  final Map<String, LabelDefinition> labels;
  LabeledStatementLabelScope(this.outer, this.labels);
  LabelDefinition lookup(String labelName) {
    LabelDefinition label = labels[labelName];
    if (label != null) return label;
    return outer.lookup(labelName);
  }
}

class SwitchLabelScope implements LabelScope {
  final LabelScope outer;
  final Map<String, LabelDefinition> caseLabels;

  SwitchLabelScope(this.outer, this.caseLabels);

  LabelDefinition lookup(String labelName) {
    LabelDefinition result = caseLabels[labelName];
    if (result != null) return result;
    return outer.lookup(labelName);
  }
}

class EmptyLabelScope implements LabelScope {
  const EmptyLabelScope();
  LabelDefinition lookup(String label) => null;
  LabelScope get outer {
    throw 'internal error: empty label scope has no outer';
  }
}

class StatementScope {
  LabelScope labels;
  Link<JumpTarget> breakTargetStack;
  Link<JumpTarget> continueTargetStack;
  // Used to provide different numbers to statements if one is inside the other.
  // Can be used to make otherwise duplicate labels unique.
  int nestingLevel = 0;

  StatementScope()
      : labels = const EmptyLabelScope(),
        breakTargetStack = const Link<JumpTarget>(),
        continueTargetStack = const Link<JumpTarget>();

  LabelDefinition lookupLabel(String label) {
    return labels.lookup(label);
  }

  JumpTarget currentBreakTarget() =>
    breakTargetStack.isEmpty ? null : breakTargetStack.head;

  JumpTarget currentContinueTarget() =>
    continueTargetStack.isEmpty ? null : continueTargetStack.head;

  void enterLabelScope(Map<String, LabelDefinition> elements) {
    labels = new LabeledStatementLabelScope(labels, elements);
    nestingLevel++;
  }

  void exitLabelScope() {
    nestingLevel--;
    labels = labels.outer;
  }

  void enterLoop(JumpTarget element) {
    breakTargetStack = breakTargetStack.prepend(element);
    continueTargetStack = continueTargetStack.prepend(element);
    nestingLevel++;
  }

  void exitLoop() {
    nestingLevel--;
    breakTargetStack = breakTargetStack.tail;
    continueTargetStack = continueTargetStack.tail;
  }

  void enterSwitch(JumpTarget breakElement,
                   Map<String, LabelDefinition> continueElements) {
    breakTargetStack = breakTargetStack.prepend(breakElement);
    labels = new SwitchLabelScope(labels, continueElements);
    nestingLevel++;
  }

  void exitSwitch() {
    nestingLevel--;
    breakTargetStack = breakTargetStack.tail;
    labels = labels.outer;
  }
}

class TypeResolver {
  final Compiler compiler;

  TypeResolver(this.compiler);

  /// Tries to resolve the type name as an element.
  Element resolveTypeName(Identifier prefixName,
                          Identifier typeName,
                          Scope scope,
                          {bool deferredIsMalformed: true}) {
    Element element;
    bool deferredTypeAnnotation = false;
    if (prefixName != null) {
      Element prefixElement =
          lookupInScope(compiler, prefixName, scope, prefixName.source);
      if (prefixElement != null && prefixElement.isPrefix) {
        // The receiver is a prefix. Lookup in the imported members.
        PrefixElement prefix = prefixElement;
        element = prefix.lookupLocalMember(typeName.source);
        // TODO(17260, sigurdm): The test for DartBackend is there because
        // dart2dart outputs malformed types with prefix.
        if (element != null &&
            prefix.isDeferred &&
            deferredIsMalformed &&
            compiler.backend is! DartBackend) {
          element = new ErroneousElementX(MessageKind.DEFERRED_TYPE_ANNOTATION,
                                          {'node': typeName},
                                          element.name,
                                          element);
        }
      } else {
        // The caller of this method will create the ErroneousElement for
        // the MalformedType.
        element = null;
      }
    } else {
      String stringValue = typeName.source;
      element = lookupInScope(compiler, typeName, scope, typeName.source);
    }
    return element;
  }

  DartType resolveTypeAnnotation(MappingVisitor visitor, TypeAnnotation node,
                                 {bool malformedIsError: false,
                                  bool deferredIsMalformed: true}) {
    ResolutionRegistry registry = visitor.registry;

    Identifier typeName;
    DartType type;

    DartType checkNoTypeArguments(DartType type) {
      List<DartType> arguments = new List<DartType>();
      bool hasTypeArgumentMismatch = resolveTypeArguments(
          visitor, node, const <DartType>[], arguments);
      if (hasTypeArgumentMismatch) {
        return new MalformedType(
            new ErroneousElementX(MessageKind.TYPE_ARGUMENT_COUNT_MISMATCH,
                {'type': node}, typeName.source, visitor.enclosingElement),
                type, arguments);
      }
      return type;
    }

    Identifier prefixName;
    Send send = node.typeName.asSend();
    if (send != null) {
      // The type name is of the form [: prefix . identifier :].
      prefixName = send.receiver.asIdentifier();
      typeName = send.selector.asIdentifier();
    } else {
      typeName = node.typeName.asIdentifier();
      if (identical(typeName.source, 'void')) {
        type = const VoidType();
        checkNoTypeArguments(type);
        registry.useType(node, type);
        return type;
      } else if (identical(typeName.source, 'dynamic')) {
        type = const DynamicType();
        checkNoTypeArguments(type);
        registry.useType(node, type);
        return type;
      }
    }

    Element element = resolveTypeName(prefixName, typeName, visitor.scope,
                                      deferredIsMalformed: deferredIsMalformed);

    DartType reportFailureAndCreateType(MessageKind messageKind,
                                        Map messageArguments,
                                        {DartType userProvidedBadType,
                                         Element erroneousElement}) {
      if (malformedIsError) {
        visitor.error(node, messageKind, messageArguments);
      } else {
        registry.registerThrowRuntimeError();
        visitor.warning(node, messageKind, messageArguments);
      }
      if (erroneousElement == null) {
         erroneousElement = new ErroneousElementX(
            messageKind, messageArguments, typeName.source,
            visitor.enclosingElement);
      }
      List<DartType> arguments = <DartType>[];
      resolveTypeArguments(visitor, node, const <DartType>[], arguments);
      return new MalformedType(erroneousElement,
              userProvidedBadType, arguments);
    }

    // Try to construct the type from the element.
    if (element == null) {
      type = reportFailureAndCreateType(
          MessageKind.CANNOT_RESOLVE_TYPE, {'typeName': node.typeName});
    } else if (element.isAmbiguous) {
      AmbiguousElement ambiguous = element;
      type = reportFailureAndCreateType(
          ambiguous.messageKind, ambiguous.messageArguments);
      ambiguous.diagnose(registry.mapping.analyzedElement, compiler);
    } else if (element.isErroneous) {
      ErroneousElement erroneousElement = element;
      type = reportFailureAndCreateType(
          erroneousElement.messageKind, erroneousElement.messageArguments,
          erroneousElement: erroneousElement);
    } else if (!element.impliesType) {
      type = reportFailureAndCreateType(
          MessageKind.NOT_A_TYPE, {'node': node.typeName});
    } else {
      bool addTypeVariableBoundsCheck = false;
      if (element.isClass) {
        ClassElement cls = element;
        // TODO(johnniwinther): [_ensureClassWillBeResolved] should imply
        // [computeType].
        compiler.resolver._ensureClassWillBeResolved(cls);
        element.computeType(compiler);
        List<DartType> arguments = <DartType>[];
        bool hasTypeArgumentMismatch = resolveTypeArguments(
            visitor, node, cls.typeVariables, arguments);
        if (hasTypeArgumentMismatch) {
          type = new BadInterfaceType(cls.declaration,
              new InterfaceType.forUserProvidedBadType(cls.declaration,
                                                       arguments));
        } else {
          if (arguments.isEmpty) {
            type = cls.rawType;
          } else {
            type = new InterfaceType(cls.declaration, arguments.toList(growable: false));
            addTypeVariableBoundsCheck = true;
          }
        }
      } else if (element.isTypedef) {
        TypedefElement typdef = element;
        // TODO(johnniwinther): [ensureResolved] should imply [computeType].
        typdef.ensureResolved(compiler);
        element.computeType(compiler);
        List<DartType> arguments = <DartType>[];
        bool hasTypeArgumentMismatch = resolveTypeArguments(
            visitor, node, typdef.typeVariables, arguments);
        if (hasTypeArgumentMismatch) {
          type = new BadTypedefType(typdef,
              new TypedefType.forUserProvidedBadType(typdef, arguments));
        } else {
          if (arguments.isEmpty) {
            type = typdef.rawType;
          } else {
            type = new TypedefType(typdef, arguments.toList(growable: false));
            addTypeVariableBoundsCheck = true;
          }
        }
      } else if (element.isTypeVariable) {
        Element outer =
            visitor.enclosingElement.outermostEnclosingMemberOrTopLevel;
        bool isInFactoryConstructor =
            outer != null && outer.isFactoryConstructor;
        if (!outer.isClass &&
            !outer.isTypedef &&
            !isInFactoryConstructor &&
            Elements.isInStaticContext(visitor.enclosingElement)) {
          registry.registerThrowRuntimeError();
          type = reportFailureAndCreateType(
              MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
              {'typeVariableName': node},
              userProvidedBadType: element.computeType(compiler));
        } else {
          type = element.computeType(compiler);
        }
        type = checkNoTypeArguments(type);
      } else {
        compiler.internalError(node,
            "Unexpected element kind ${element.kind}.");
      }
      if (addTypeVariableBoundsCheck) {
        registry.registerTypeVariableBoundCheck();
        visitor.addDeferredAction(
            visitor.enclosingElement,
            () => checkTypeVariableBounds(node, type));
      }
    }
    registry.useType(node, type);
    return type;
  }

  /// Checks the type arguments of [type] against the type variable bounds.
  void checkTypeVariableBounds(TypeAnnotation node, GenericType type) {
    void checkTypeVariableBound(_, DartType typeArgument,
                                   TypeVariableType typeVariable,
                                   DartType bound) {
      if (!compiler.types.isSubtype(typeArgument, bound)) {
        compiler.reportWarning(node,
            MessageKind.INVALID_TYPE_VARIABLE_BOUND,
            {'typeVariable': typeVariable,
             'bound': bound,
             'typeArgument': typeArgument,
             'thisType': type.element.thisType});
      }
    };

    compiler.types.checkTypeVariableBounds(type, checkTypeVariableBound);
  }

  /**
   * Resolves the type arguments of [node] and adds these to [arguments].
   *
   * Returns [: true :] if the number of type arguments did not match the
   * number of type variables.
   */
  bool resolveTypeArguments(MappingVisitor visitor,
                            TypeAnnotation node,
                            List<DartType> typeVariables,
                            List<DartType> arguments) {
    if (node.typeArguments == null) {
      return false;
    }
    int expectedVariables = typeVariables.length;
    int index = 0;
    bool typeArgumentCountMismatch = false;
    for (Link<Node> typeArguments = node.typeArguments.nodes;
         !typeArguments.isEmpty;
         typeArguments = typeArguments.tail, index++) {
      if (index > expectedVariables - 1) {
        visitor.warning(
            typeArguments.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT);
        typeArgumentCountMismatch = true;
      }
      DartType argType = resolveTypeAnnotation(visitor, typeArguments.head);
      // TODO(karlklose): rewrite to not modify [arguments].
      arguments.add(argType);
    }
    if (index < expectedVariables) {
      visitor.warning(node.typeArguments,
                      MessageKind.MISSING_TYPE_ARGUMENT);
      typeArgumentCountMismatch = true;
    }
    return typeArgumentCountMismatch;
  }
}

/**
 * Common supertype for resolver visitors that record resolutions in a
 * [ResolutionRegistry].
 */
abstract class MappingVisitor<T> extends CommonResolverVisitor<T> {
  final ResolutionRegistry registry;
  final TypeResolver typeResolver;
  /// The current enclosing element for the visited AST nodes.
  Element get enclosingElement;
  /// The current scope of the visitor.
  Scope get scope;

  MappingVisitor(Compiler compiler, ResolutionRegistry this.registry)
      : typeResolver = new TypeResolver(compiler),
        super(compiler);

  AsyncMarker get currentAsyncMarker => AsyncMarker.SYNC;

  /// Add [element] to the current scope and check for duplicate definitions.
  void addToScope(Element element) {
    Element existing = scope.add(element);
    if (existing != element) {
      reportDuplicateDefinition(element.name, element, existing);
    }
  }

  void checkLocalDefinitionName(Node node, Element element) {
    if (currentAsyncMarker != AsyncMarker.SYNC) {
      if (element.name == 'yield' ||
          element.name == 'async' ||
          element.name == 'await') {
        compiler.reportError(
            node, MessageKind.ASYNC_KEYWORD_AS_IDENTIFIER,
            {'keyword': element.name,
             'modifier': currentAsyncMarker});
      }
    }
  }

  /// Register [node] as the definition of [element].
  void defineLocalVariable(Node node, LocalVariableElement element) {
    invariant(node, element != null);
    checkLocalDefinitionName(node, element);
    registry.defineElement(node, element);
  }

  void reportDuplicateDefinition(String name,
                                 Spannable definition,
                                 Spannable existing) {
    compiler.reportError(definition,
        MessageKind.DUPLICATE_DEFINITION, {'name': name});
    compiler.reportInfo(existing,
        MessageKind.EXISTING_DEFINITION, {'name': name});
  }
}

/**
 * Core implementation of resolution.
 *
 * Do not subclass or instantiate this class outside this library
 * except for testing.
 */
class ResolverVisitor extends MappingVisitor<ResolutionResult> {
  /**
   * The current enclosing element for the visited AST nodes.
   *
   * This field is updated when nested closures are visited.
   */
  Element enclosingElement;
  bool inInstanceContext;
  bool inCheckContext;
  bool inCatchBlock;

  Scope scope;
  ClassElement currentClass;
  ExpressionStatement currentExpressionStatement;
  bool sendIsMemberAccess = false;
  StatementScope statementScope;
  int allowedCategory = ElementCategory.VARIABLE | ElementCategory.FUNCTION
      | ElementCategory.IMPLIES_TYPE;

  /**
   * Record of argument nodes to JS_INTERCEPTOR_CONSTANT for deferred
   * processing.
   */
  Set<Node> argumentsToJsInterceptorConstant = null;

  /// When visiting the type declaration of the variable in a [ForIn] loop,
  /// the initializer of the variable is implicit and we should not emit an
  /// error when verifying that all final variables are initialized.
  bool allowFinalWithoutInitializer = false;

  /// The nodes for which variable access and mutation must be registered in
  /// order to determine when the static type of variables types is promoted.
  Link<Node> promotionScope = const Link<Node>();

  bool isPotentiallyMutableTarget(Element target) {
    if (target == null) return false;
    return (target.isVariable || target.isParameter) &&
      !(target.isFinal || target.isConst);
  }

  // TODO(ahe): Find a way to share this with runtime implementation.
  static final RegExp symbolValidationPattern =
      new RegExp(r'^(?:[a-zA-Z$][a-zA-Z$0-9_]*\.)*(?:[a-zA-Z$][a-zA-Z$0-9_]*=?|'
                 r'-|'
                 r'unary-|'
                 r'\[\]=|'
                 r'~|'
                 r'==|'
                 r'\[\]|'
                 r'\*|'
                 r'/|'
                 r'%|'
                 r'~/|'
                 r'\+|'
                 r'<<|'
                 r'>>|'
                 r'>=|'
                 r'>|'
                 r'<=|'
                 r'<|'
                 r'&|'
                 r'\^|'
                 r'\|'
                 r')$');

  ResolverVisitor(Compiler compiler,
                  Element element,
                  ResolutionRegistry registry,
                  {bool useEnclosingScope: false})
    : this.enclosingElement = element,
      // When the element is a field, we are actually resolving its
      // initial value, which should not have access to instance
      // fields.
      inInstanceContext = (element.isInstanceMember && !element.isField)
          || element.isGenerativeConstructor,
      this.currentClass = element.isClassMember ? element.enclosingClass
                                             : null,
      this.statementScope = new StatementScope(),
      scope = useEnclosingScope
          ? Scope.buildEnclosingScope(element) : element.buildScope(),
      // The type annotations on a typedef do not imply type checks.
      // TODO(karlklose): clean this up (dartbug.com/8870).
      inCheckContext = compiler.enableTypeAssertions &&
          !element.isLibrary &&
          !element.isTypedef &&
          !element.enclosingElement.isTypedef,
      inCatchBlock = false,
      super(compiler, registry);

  AsyncMarker get currentAsyncMarker {
    if (enclosingElement is FunctionElement) {
      FunctionElement function = enclosingElement;
      return function.asyncMarker;
    }
    return AsyncMarker.SYNC;
  }

  Element reportLookupErrorIfAny(Element result, Node node, String name) {
    if (!Elements.isUnresolved(result)) {
      if (!inInstanceContext && result.isInstanceMember) {
        compiler.reportError(
            node, MessageKind.NO_INSTANCE_AVAILABLE, {'name': name});
        return new ErroneousElementX(MessageKind.NO_INSTANCE_AVAILABLE,
                                     {'name': name},
                                     name, enclosingElement);
      } else if (result.isAmbiguous) {
        AmbiguousElement ambiguous = result;
        compiler.reportError(
            node, ambiguous.messageKind, ambiguous.messageArguments);
        ambiguous.diagnose(enclosingElement, compiler);
        return new ErroneousElementX(ambiguous.messageKind,
                                     ambiguous.messageArguments,
                                     name, enclosingElement);
      }
    }
    return result;
  }

  // Create, or reuse an already created, target element for a statement.
  JumpTarget getOrDefineTarget(Node statement) {
    JumpTarget element = registry.getTargetDefinition(statement);
    if (element == null) {
      element = new JumpTargetX(statement,
                                   statementScope.nestingLevel,
                                   enclosingElement);
      registry.defineTarget(statement, element);
    }
    return element;
  }

  doInCheckContext(action()) {
    bool wasInCheckContext = inCheckContext;
    inCheckContext = true;
    var result = action();
    inCheckContext = wasInCheckContext;
    return result;
  }

  inStaticContext(action()) {
    bool wasInstanceContext = inInstanceContext;
    inInstanceContext = false;
    var result = action();
    inInstanceContext = wasInstanceContext;
    return result;
  }

  doInPromotionScope(Node node, action()) {
    promotionScope = promotionScope.prepend(node);
    var result = action();
    promotionScope = promotionScope.tail;
    return result;
  }

  visitInStaticContext(Node node) {
    inStaticContext(() => visit(node));
  }

  ErroneousElement warnAndCreateErroneousElement(Node node,
                                                 String name,
                                                 MessageKind kind,
                                                 [Map arguments = const {}]) {
    compiler.reportWarning(node, kind, arguments);
    return new ErroneousElementX(kind, arguments, name, enclosingElement);
  }

  ResolutionResult visitIdentifier(Identifier node) {
    if (node.isThis()) {
      if (!inInstanceContext) {
        error(node, MessageKind.NO_INSTANCE_AVAILABLE, {'name': node});
      }
      return null;
    } else if (node.isSuper()) {
      if (!inInstanceContext) error(node, MessageKind.NO_SUPER_IN_STATIC);
      if ((ElementCategory.SUPER & allowedCategory) == 0) {
        error(node, MessageKind.INVALID_USE_OF_SUPER);
      }
      return null;
    } else {
      String name = node.source;
      Element element = lookupInScope(compiler, node, scope, name);
      if (Elements.isUnresolved(element) && name == 'dynamic') {
        // TODO(johnniwinther): Remove this hack when we can return more complex
        // objects than [Element] from this method.
        element = compiler.typeClass;
        // Set the type to be `dynamic` to mark that this is a type literal.
        registry.setType(node, const DynamicType());
      }
      element = reportLookupErrorIfAny(element, node, node.source);
      if (element == null) {
        if (!inInstanceContext) {
          element = warnAndCreateErroneousElement(
              node, node.source, MessageKind.CANNOT_RESOLVE,
              {'name': node});
          registry.registerThrowNoSuchMethod();
        }
      } else if (element.isErroneous) {
        // Use the erroneous element.
      } else {
        if ((element.kind.category & allowedCategory) == 0) {
          // TODO(ahe): Improve error message. Need UX input.
          error(node, MessageKind.GENERIC,
                {'text': "is not an expression $element"});
        }
      }
      if (!Elements.isUnresolved(element) && element.isClass) {
        ClassElement classElement = element;
        classElement.ensureResolved(compiler);
      }
      return new ElementResult(registry.useElement(node, element));
    }
  }

  ResolutionResult visitTypeAnnotation(TypeAnnotation node) {
    DartType type = resolveTypeAnnotation(node);
    if (inCheckContext) {
      registry.registerIsCheck(type);
    }
    return new TypeResult(type);
  }

  bool isNamedConstructor(Send node) => node.receiver != null;

  Selector getRedirectingThisOrSuperConstructorSelector(Send node) {
    if (isNamedConstructor(node)) {
      String constructorName = node.selector.asIdentifier().source;
      return new Selector.callConstructor(
          constructorName,
          enclosingElement.library);
    } else {
      return new Selector.callDefaultConstructor(
          enclosingElement.library);
    }
  }

  FunctionElement resolveConstructorRedirection(FunctionElementX constructor) {
    FunctionExpression node = constructor.parseNode(compiler);

    // A synthetic constructor does not have a node.
    if (node == null) return null;
    if (node.initializers == null) return null;
    Link<Node> initializers = node.initializers.nodes;
    if (!initializers.isEmpty &&
        Initializers.isConstructorRedirect(initializers.head)) {
      Selector selector =
          getRedirectingThisOrSuperConstructorSelector(initializers.head);
      final ClassElement classElement = constructor.enclosingClass;
      return classElement.lookupConstructor(selector);
    }
    return null;
  }

  void setupFunction(FunctionExpression node, FunctionElement function) {
    Element enclosingElement = function.enclosingElement;
    if (node.modifiers.isStatic &&
        enclosingElement.kind != ElementKind.CLASS) {
      compiler.reportError(node, MessageKind.ILLEGAL_STATIC);
    }

    scope = new MethodScope(scope, function);
    // Put the parameters in scope.
    FunctionSignature functionParameters = function.functionSignature;
    Link<Node> parameterNodes = (node.parameters == null)
        ? const Link<Node>() : node.parameters.nodes;
    functionParameters.forEachParameter((ParameterElement element) {
      // TODO(karlklose): should be a list of [FormalElement]s, but the actual
      // implementation uses [Element].
      Link<Element> optionals = functionParameters.optionalParameters;
      if (!optionals.isEmpty && element == optionals.head) {
        NodeList nodes = parameterNodes.head;
        parameterNodes = nodes.nodes;
      }
      visit(element.initializer);
      VariableDefinitions variableDefinitions = parameterNodes.head;
      Node parameterNode = variableDefinitions.definitions.nodes.head;
      // Field parameters (this.x) are not visible inside the constructor. The
      // fields they reference are visible, but must be resolved independently.
      if (element.isInitializingFormal) {
        registry.useElement(parameterNode, element);
      } else {
        LocalParameterElement parameterElement = element;
        defineLocalVariable(parameterNode, parameterElement);
        addToScope(parameterElement);
      }
      parameterNodes = parameterNodes.tail;
    });
    addDeferredAction(enclosingElement, () {
      functionParameters.forEachOptionalParameter((Element parameter) {
        compiler.resolver.constantCompiler.compileConstant(parameter);
      });
    });
    if (inCheckContext) {
      functionParameters.forEachParameter((ParameterElement element) {
        registry.registerIsCheck(element.type);
      });
    }
  }

  visitCascade(Cascade node) {
    visit(node.expression);
  }

  visitCascadeReceiver(CascadeReceiver node) {
    visit(node.expression);
  }

  visitClassNode(ClassNode node) {
    internalError(node, "shouldn't be called");
  }

  visitIn(Node node, Scope nestedScope) {
    Scope oldScope = scope;
    scope = nestedScope;
    ResolutionResult result = visit(node);
    scope = oldScope;
    return result;
  }

  /**
   * Introduces new default targets for break and continue
   * before visiting the body of the loop
   */
  visitLoopBodyIn(Loop loop, Node body, Scope bodyScope) {
    JumpTarget element = getOrDefineTarget(loop);
    statementScope.enterLoop(element);
    visitIn(body, bodyScope);
    statementScope.exitLoop();
    if (!element.isTarget) {
      registry.undefineTarget(loop);
    }
  }

  visitBlock(Block node) {
    visitIn(node.statements, new BlockScope(scope));
  }

  visitDoWhile(DoWhile node) {
    visitLoopBodyIn(node, node.body, new BlockScope(scope));
    visit(node.condition);
  }

  visitEmptyStatement(EmptyStatement node) { }

  visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement oldExpressionStatement = currentExpressionStatement;
    currentExpressionStatement = node;
    visit(node.expression);
    currentExpressionStatement = oldExpressionStatement;
  }

  visitFor(For node) {
    Scope blockScope = new BlockScope(scope);
    visitIn(node.initializer, blockScope);
    visitIn(node.condition, blockScope);
    visitIn(node.update, blockScope);
    visitLoopBodyIn(node, node.body, blockScope);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    assert(node.function.name != null);
    visitFunctionExpression(node.function, inFunctionDeclaration: true);
  }


  /// Process a local function declaration or an anonymous function expression.
  ///
  /// [inFunctionDeclaration] is `true` when the current node is the immediate
  /// child of a function declaration.
  ///
  /// This is used to distinguish local function declarations from anonymous
  /// function expressions.
  visitFunctionExpression(FunctionExpression node,
                          {bool inFunctionDeclaration: false}) {
    bool doAddToScope = inFunctionDeclaration;
    if (!inFunctionDeclaration && node.name != null) {
      compiler.reportError(
          node.name,
          MessageKind.NAMED_FUNCTION_EXPRESSION,
          {'name': node.name});
    }
    visit(node.returnType);
    String name;
    if (node.name == null) {
      name = "";
    } else {
      name = node.name.asIdentifier().source;
    }
    LocalFunctionElementX function = new LocalFunctionElementX(
        name, node, ElementKind.FUNCTION, Modifiers.EMPTY,
        enclosingElement);
    function.functionSignatureCache =
        SignatureResolver.analyze(compiler, node.parameters, node.returnType,
            function, registry, createRealParameters: true);
    ResolverTask.processAsyncMarker(compiler, function);
    checkLocalDefinitionName(node, function);
    registry.defineFunction(node, function);
    if (doAddToScope) {
      addToScope(function);
    }
    Scope oldScope = scope; // The scope is modified by [setupFunction].
    setupFunction(node, function);

    Element previousEnclosingElement = enclosingElement;
    enclosingElement = function;
    // Run the body in a fresh statement scope.
    StatementScope oldStatementScope = statementScope;
    statementScope = new StatementScope();
    visit(node.body);
    statementScope = oldStatementScope;

    scope = oldScope;
    enclosingElement = previousEnclosingElement;

    registry.registerClosure(function);
    registry.registerInstantiatedClass(compiler.functionClass);
  }

  visitIf(If node) {
    doInPromotionScope(node.condition.expression, () => visit(node.condition));
    doInPromotionScope(node.thenPart,
        () => visitIn(node.thenPart, new BlockScope(scope)));
    visitIn(node.elsePart, new BlockScope(scope));
  }

  ResolutionResult resolveSend(Send node) {
    Selector selector = resolveSelector(node, null);
    if (node.isSuperCall) registry.registerSuperUse(node);

    if (node.receiver == null) {
      // If this send is of the form "assert(expr);", then
      // this is an assertion.
      if (selector.isAssert) {
        if (selector.argumentCount != 1) {
          error(node.selector,
                MessageKind.WRONG_NUMBER_OF_ARGUMENTS_FOR_ASSERT,
                {'argumentCount': selector.argumentCount});
        } else if (selector.namedArgumentCount != 0) {
          error(node.selector,
                MessageKind.ASSERT_IS_GIVEN_NAMED_ARGUMENTS,
                {'argumentCount': selector.namedArgumentCount});
        }
        registry.registerAssert(node);
        return const AssertResult();
      }

      return node.selector.accept(this);
    }

    var oldCategory = allowedCategory;
    allowedCategory |= ElementCategory.PREFIX | ElementCategory.SUPER;
    ResolutionResult resolvedReceiver = visit(node.receiver);
    allowedCategory = oldCategory;

    Element target;
    String name = node.selector.asIdentifier().source;
    if (identical(name, 'this')) {
      // TODO(ahe): Why is this using GENERIC?
      error(node.selector, MessageKind.GENERIC,
            {'text': "expected an identifier"});
    } else if (node.isSuperCall) {
      if (node.isOperator) {
        if (isUserDefinableOperator(name)) {
          name = selector.name;
        } else {
          error(node.selector, MessageKind.ILLEGAL_SUPER_SEND, {'name': name});
        }
      }
      if (!inInstanceContext) {
        error(node.receiver, MessageKind.NO_INSTANCE_AVAILABLE, {'name': name});
        return null;
      }
      if (currentClass.supertype == null) {
        // This is just to guard against internal errors, so no need
        // for a real error message.
        error(node.receiver, MessageKind.GENERIC,
              {'text': "Object has no superclass"});
      }
      // TODO(johnniwinther): Ensure correct behavior if currentClass is a
      // patch.
      target = currentClass.lookupSuperSelector(selector);
      // [target] may be null which means invoking noSuchMethod on
      // super.
      if (target == null) {
        target = warnAndCreateErroneousElement(
            node, name, MessageKind.NO_SUCH_SUPER_MEMBER,
            {'className': currentClass, 'memberName': name});
        // We still need to register the invocation, because we might
        // call [:super.noSuchMethod:] which calls
        // [JSInvocationMirror._invokeOn].
        registry.registerDynamicInvocation(selector);
        registry.registerSuperNoSuchMethod();
      }
    } else if (resolvedReceiver == null ||
               Elements.isUnresolved(resolvedReceiver.element)) {
      return null;
    } else if (resolvedReceiver.element.isClass) {
      ClassElement receiverClass = resolvedReceiver.element;
      receiverClass.ensureResolved(compiler);
      if (node.isOperator) {
        // When the resolved receiver is a class, we can have two cases:
        //  1) a static send: C.foo, or
        //  2) an operator send, where the receiver is a class literal: 'C + 1'.
        // The following code that looks up the selector on the resolved
        // receiver will treat the second as the invocation of a static operator
        // if the resolved receiver is not null.
        return null;
      }
      MembersCreator.computeClassMembersByName(
          compiler, receiverClass.declaration, name);
      target = receiverClass.lookupLocalMember(name);
      if (target == null || target.isInstanceMember) {
        registry.registerThrowNoSuchMethod();
        // TODO(johnniwinther): With the simplified [TreeElements] invariant,
        // try to resolve injected elements if [currentClass] is in the patch
        // library of [receiverClass].

        // TODO(karlklose): this should be reported by the caller of
        // [resolveSend] to select better warning messages for getters and
        // setters.
        MessageKind kind = (target == null)
            ? MessageKind.MEMBER_NOT_FOUND
            : MessageKind.MEMBER_NOT_STATIC;
        return new ElementResult(warnAndCreateErroneousElement(
            node, name, kind,
            {'className': receiverClass.name, 'memberName': name}));
      } else if (isPrivateName(name) &&
                 target.library != enclosingElement.library) {
        registry.registerThrowNoSuchMethod();
        return new ElementResult(warnAndCreateErroneousElement(
            node, name, MessageKind.PRIVATE_ACCESS,
            {'libraryName': target.library.getLibraryOrScriptName(),
             'name': name}));
      }
    } else if (resolvedReceiver.element.isPrefix) {
      PrefixElement prefix = resolvedReceiver.element;
      target = prefix.lookupLocalMember(name);
      if (Elements.isUnresolved(target)) {
        registry.registerThrowNoSuchMethod();
        return new ElementResult(warnAndCreateErroneousElement(
            node, name, MessageKind.NO_SUCH_LIBRARY_MEMBER,
            {'libraryName': prefix.name, 'memberName': name}));
      } else if (target.isAmbiguous) {
        registry.registerThrowNoSuchMethod();
        AmbiguousElement ambiguous = target;
        target = warnAndCreateErroneousElement(node, name,
                                               ambiguous.messageKind,
                                               ambiguous.messageArguments);
        ambiguous.diagnose(enclosingElement, compiler);
        return new ElementResult(target);
      } else if (target.kind == ElementKind.CLASS) {
        ClassElement classElement = target;
        classElement.ensureResolved(compiler);
      }
    }
    return new ElementResult(target);
  }

  static Selector computeSendSelector(Send node,
                                      LibraryElement library,
                                      Element element) {
    // First determine if this is part of an assignment.
    bool isSet = node.asSendSet() != null;

    if (node.isIndex) {
      return isSet ? new Selector.indexSet() : new Selector.index();
    }

    if (node.isOperator) {
      String source = node.selector.asOperator().source;
      String string = source;
      if (identical(string, '!') ||
          identical(string, '&&') || identical(string, '||') ||
          identical(string, 'is') || identical(string, 'as') ||
          identical(string, '?') ||
          identical(string, '>>>')) {
        return null;
      }
      String op = source;
      if (!isUserDefinableOperator(source)) {
        op = Elements.mapToUserOperatorOrNull(source);
      }
      if (op == null) {
        // Unsupported operator. An error has been reported during parsing.
        return new Selector.call(
            source, library, node.argumentsNode.slowLength(), []);
      }
      return node.arguments.isEmpty
          ? new Selector.unaryOperator(op)
          : new Selector.binaryOperator(op);
    }

    Identifier identifier = node.selector.asIdentifier();
    if (node.isPropertyAccess) {
      assert(!isSet);
      return new Selector.getter(identifier.source, library);
    } else if (isSet) {
      return new Selector.setter(identifier.source, library);
    }

    // Compute the arity and the list of named arguments.
    int arity = 0;
    List<String> named = <String>[];
    for (Link<Node> link = node.argumentsNode.nodes;
        !link.isEmpty;
        link = link.tail) {
      Expression argument = link.head;
      NamedArgument namedArgument = argument.asNamedArgument();
      if (namedArgument != null) {
        named.add(namedArgument.name.source);
      }
      arity++;
    }

    if (element != null && element.isConstructor) {
      return new Selector.callConstructor(
          element.name, library, arity, named);
    }

    // If we're invoking a closure, we do not have an identifier.
    return (identifier == null)
        ? new Selector.callClosure(arity, named)
        : new Selector.call(identifier.source, library, arity, named);
  }

  Selector resolveSelector(Send node, Element element) {
    LibraryElement library = enclosingElement.library;
    Selector selector = computeSendSelector(node, library, element);
    if (selector != null) registry.setSelector(node, selector);
    return selector;
  }

  void resolveArguments(NodeList list) {
    if (list == null) return;
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    sendIsMemberAccess = false;
    Map<String, Node> seenNamedArguments = new Map<String, Node>();
    for (Link<Node> link = list.nodes; !link.isEmpty; link = link.tail) {
      Expression argument = link.head;
      visit(argument);
      NamedArgument namedArgument = argument.asNamedArgument();
      if (namedArgument != null) {
        String source = namedArgument.name.source;
        if (seenNamedArguments.containsKey(source)) {
          reportDuplicateDefinition(
              source,
              argument,
              seenNamedArguments[source]);
        } else {
          seenNamedArguments[source] = namedArgument;
        }
      } else if (!seenNamedArguments.isEmpty) {
        error(argument, MessageKind.INVALID_ARGUMENT_AFTER_NAMED);
      }
    }
    sendIsMemberAccess = oldSendIsMemberAccess;
  }

  ResolutionResult visitSend(Send node) {
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    sendIsMemberAccess = node.isPropertyAccess || node.isCall;
    ResolutionResult result;
    if (node.isLogicalAnd) {
      result = doInPromotionScope(node.receiver, () => resolveSend(node));
    } else {
      result = resolveSend(node);
    }
    sendIsMemberAccess = oldSendIsMemberAccess;

    Element target = result != null ? result.element : null;

    if (target != null
        && target == compiler.mirrorSystemGetNameFunction
        && !compiler.mirrorUsageAnalyzerTask.hasMirrorUsage(enclosingElement)) {
      compiler.reportHint(
          node.selector, MessageKind.STATIC_FUNCTION_BLOAT,
          {'class': compiler.mirrorSystemClass.name,
           'name': compiler.mirrorSystemGetNameFunction.name});
    }

    if (target != null) {
      if (target.isErroneous) {
        registry.registerThrowNoSuchMethod();
      } else if (target.isAbstractField) {
        AbstractFieldElement field = target;
        target = field.getter;
        if (target == null && !inInstanceContext) {
          registry.registerThrowNoSuchMethod();
          target =
              warnAndCreateErroneousElement(node.selector, field.name,
                                            MessageKind.CANNOT_RESOLVE_GETTER);
        }
      } else if (target.isTypeVariable) {
        ClassElement cls = target.enclosingClass;
        assert(enclosingElement.enclosingClass == cls);
        registry.registerClassUsingVariableExpression(cls);
        registry.registerTypeVariableExpression();
        // Set the type of the node to [Type] to mark this send as a
        // type variable expression.
        registry.registerTypeLiteral(node, target.computeType(compiler));
      } else if (target.impliesType && (!sendIsMemberAccess || node.isCall)) {
        // Set the type of the node to [Type] to mark this send as a
        // type literal.
        DartType type;

        // TODO(johnniwinther): Remove this hack when we can pass more complex
        // information between methods than resolved elements.
        if (target == compiler.typeClass && node.receiver == null) {
          // Potentially a 'dynamic' type literal.
          type = registry.getType(node.selector);
        }
        if (type == null) {
          type = target.computeType(compiler);
        }
        registry.registerTypeLiteral(node, type);

        // Don't try to make constants of calls to type literals.
        if (!node.isCall) {
          analyzeConstantDeferred(node);
        } else {
          // The node itself is not a constant but we register the selector (the
          // identifier that refers to the class/typedef) as a constant.
          if (node.receiver != null) {
            // This is a hack for the case of prefix.Type, we need to store
            // the element on the selector, so [analyzeConstant] can build
            // the type literal from the selector.
            registry.useElement(node.selector, target);
          }
          analyzeConstantDeferred(node.selector);
        }
      }
      if (isPotentiallyMutableTarget(target)) {
        if (enclosingElement != target.enclosingElement) {
          for (Node scope in promotionScope) {
            registry.setAccessedByClosureIn(scope, target, node);
          }
        }
      }
    }

    bool resolvedArguments = false;
    if (node.isOperator) {
      String operatorString = node.selector.asOperator().source;
      if (identical(operatorString, 'is')) {
        // TODO(johnniwinther): Use seen type tests to avoid registration of
        // mutation/access to unpromoted variables.
        DartType type =
            resolveTypeAnnotation(node.typeAnnotationFromIsCheckOrCast);
        if (type != null) {
          registry.registerIsCheck(type);
        }
        resolvedArguments = true;
      } else if (identical(operatorString, 'as')) {
        DartType type = resolveTypeAnnotation(node.arguments.head);
        if (type != null) {
          registry.registerAsCheck(type);
        }
        resolvedArguments = true;
      } else if (identical(operatorString, '&&')) {
        doInPromotionScope(node.arguments.head,
            () => resolveArguments(node.argumentsNode));
        resolvedArguments = true;
      }
    }

    if (!resolvedArguments) {
      resolveArguments(node.argumentsNode);
    }

    // If the selector is null, it means that we will not be generating
    // code for this as a send.
    Selector selector = registry.getSelector(node);
    if (selector == null) return null;

    if (node.isCall) {
      if (Elements.isUnresolved(target) ||
          target.isGetter ||
          target.isField ||
          Elements.isClosureSend(node, target)) {
        // If we don't know what we're calling or if we are calling a getter,
        // we need to register that fact that we may be calling a closure
        // with the same arguments.
        Selector call = new Selector.callClosureFrom(selector);
        registry.registerDynamicInvocation(call);
      } else if (target.impliesType) {
        // We call 'call()' on a Type instance returned from the reference to a
        // class or typedef literal. We do not need to register this call as a
        // dynamic invocation, because we statically know what the target is.
      } else {
        if (target is FunctionElement) {
          FunctionElement function = target;
          function.computeSignature(compiler);
        }
        if (!selector.applies(target, compiler.world)) {
          registry.registerThrowNoSuchMethod();
          if (node.isSuperCall) {
            // Similar to what we do when we can't find super via selector
            // in [resolveSend] above, we still need to register the invocation,
            // because we might call [:super.noSuchMethod:] which calls
            // [JSInvocationMirror._invokeOn].
            registry.registerDynamicInvocation(selector);
            registry.registerSuperNoSuchMethod();
          }
        }
      }

      if (target != null && target.isForeign(compiler.backend)) {
        if (selector.name == 'JS') {
          registry.registerJsCall(node, this);
        } else if (selector.name == 'JS_EMBEDDED_GLOBAL') {
          registry.registerJsEmbeddedGlobalCall(node, this);
        } else if (selector.name == 'JS_INTERCEPTOR_CONSTANT') {
          if (!node.argumentsNode.isEmpty) {
            Node argument = node.argumentsNode.nodes.head;
            if (argumentsToJsInterceptorConstant == null) {
              argumentsToJsInterceptorConstant = new Set<Node>();
            }
            argumentsToJsInterceptorConstant.add(argument);
          }
        }
      }
    }

    registry.useElement(node, target);
    registerSend(selector, target);
    if (node.isPropertyAccess && Elements.isStaticOrTopLevelFunction(target)) {
      registry.registerGetOfStaticFunction(target.declaration);
    }
    return node.isPropertyAccess ? new ElementResult(target) : null;
  }

  /// Callback for native enqueuer to parse a type.  Returns [:null:] on error.
  DartType resolveTypeFromString(Node node, String typeName) {
    Element element = lookupInScope(compiler, node,
                                    scope, typeName);
    if (element == null) return null;
    if (element is! ClassElement) return null;
    ClassElement cls = element;
    cls.ensureResolved(compiler);
    return cls.computeType(compiler);
  }

  ResolutionResult visitSendSet(SendSet node) {
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    sendIsMemberAccess = node.isPropertyAccess || node.isCall;
    ResolutionResult result = resolveSend(node);
    sendIsMemberAccess = oldSendIsMemberAccess;
    Element target = result != null ? result.element : null;
    Element setter = target;
    Element getter = target;
    String operatorName = node.assignmentOperator.source;
    String source = operatorName;
    bool isComplex = !identical(source, '=');
    if (!(result is AssertResult || Elements.isUnresolved(target))) {
      if (target.isAbstractField) {
        AbstractFieldElement field = target;
        setter = field.setter;
        getter = field.getter;
        if (setter == null && !inInstanceContext) {
          setter = warnAndCreateErroneousElement(
              node.selector, field.name, MessageKind.CANNOT_RESOLVE_SETTER);
          registry.registerThrowNoSuchMethod();
        }
        if (isComplex && getter == null && !inInstanceContext) {
          getter = warnAndCreateErroneousElement(
              node.selector, field.name, MessageKind.CANNOT_RESOLVE_GETTER);
          registry.registerThrowNoSuchMethod();
        }
      } else if (target.impliesType) {
        setter = warnAndCreateErroneousElement(
            node.selector, target.name, MessageKind.ASSIGNING_TYPE);
        registry.registerThrowNoSuchMethod();
      } else if (target.isFinal ||
                 target.isConst ||
                 (target.isFunction &&
                  Elements.isStaticOrTopLevelFunction(target) &&
                  !target.isSetter)) {
        if (target.isFunction) {
          setter = warnAndCreateErroneousElement(
              node.selector, target.name, MessageKind.ASSIGNING_METHOD);
        } else {
          setter = warnAndCreateErroneousElement(
              node.selector, target.name, MessageKind.CANNOT_RESOLVE_SETTER);
        }
        registry.registerThrowNoSuchMethod();
      }
      if (isPotentiallyMutableTarget(target)) {
        registry.registerPotentialMutation(target, node);
        if (enclosingElement != target.enclosingElement) {
          registry.registerPotentialMutationInClosure(target, node);
        }
        for (Node scope in promotionScope) {
          registry.registerPotentialMutationIn(scope, target, node);
        }
      }
    }

    resolveArguments(node.argumentsNode);

    Selector selector = registry.getSelector(node);
    if (isComplex) {
      Selector getterSelector;
      if (selector.isSetter) {
        getterSelector = new Selector.getterFrom(selector);
      } else {
        assert(selector.isIndexSet);
        getterSelector = new Selector.index();
      }
      registerSend(getterSelector, getter);
      registry.setGetterSelectorInComplexSendSet(node, getterSelector);
      if (node.isSuperCall) {
        getter = currentClass.lookupSuperSelector(getterSelector);
        if (getter == null) {
          target = warnAndCreateErroneousElement(
              node, selector.name, MessageKind.NO_SUCH_SUPER_MEMBER,
              {'className': currentClass, 'memberName': selector.name});
          registry.registerSuperNoSuchMethod();
        }
      }
      registry.useElement(node.selector, getter);

      // Make sure we include the + and - operators if we are using
      // the ++ and -- ones.  Also, if op= form is used, include op itself.
      void registerBinaryOperator(String name) {
        Selector binop = new Selector.binaryOperator(name);
        registry.registerDynamicInvocation(binop);
        registry.setOperatorSelectorInComplexSendSet(node, binop);
      }
      if (identical(source, '++')) {
        registerBinaryOperator('+');
        registry.registerInstantiatedClass(compiler.intClass);
      } else if (identical(source, '--')) {
        registerBinaryOperator('-');
        registry.registerInstantiatedClass(compiler.intClass);
      } else if (source.endsWith('=')) {
        registerBinaryOperator(Elements.mapToUserOperator(operatorName));
      }
    }

    registerSend(selector, setter);
    return new ElementResult(registry.useElement(node, setter));
  }

  void registerSend(Selector selector, Element target) {
    if (target == null || target.isInstanceMember) {
      if (selector.isGetter) {
        registry.registerDynamicGetter(selector);
      } else if (selector.isSetter) {
        registry.registerDynamicSetter(selector);
      } else {
        registry.registerDynamicInvocation(selector);
      }
    } else if (Elements.isStaticOrTopLevel(target)) {
      // Avoid registration of type variables since they are not analyzable but
      // instead resolved through their enclosing type declaration.
      if (!target.isTypeVariable) {
        // [target] might be the implementation element and only declaration
        // elements may be registered.
        registry.registerStaticUse(target.declaration);
      }
    }
  }

  visitLiteralInt(LiteralInt node) {
    registry.registerInstantiatedClass(compiler.intClass);
  }

  visitLiteralDouble(LiteralDouble node) {
    registry.registerInstantiatedClass(compiler.doubleClass);
  }

  visitLiteralBool(LiteralBool node) {
    registry.registerInstantiatedClass(compiler.boolClass);
  }

  visitLiteralString(LiteralString node) {
    registry.registerInstantiatedClass(compiler.stringClass);
  }

  visitLiteralNull(LiteralNull node) {
    registry.registerInstantiatedClass(compiler.nullClass);
  }

  visitLiteralSymbol(LiteralSymbol node) {
    registry.registerInstantiatedClass(compiler.symbolClass);
    registry.registerStaticUse(compiler.symbolConstructor.declaration);
    registry.registerConstSymbol(node.slowNameString);
    if (!validateSymbol(node, node.slowNameString, reportError: false)) {
      compiler.reportError(node,
          MessageKind.UNSUPPORTED_LITERAL_SYMBOL,
          {'value': node.slowNameString});
    }
    analyzeConstantDeferred(node);
  }

  visitStringJuxtaposition(StringJuxtaposition node) {
    registry.registerInstantiatedClass(compiler.stringClass);
    node.visitChildren(this);
  }

  visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      visit(link.head);
    }
  }

  visitOperator(Operator node) {
    internalError(node, 'operator');
  }

  visitRethrow(Rethrow node) {
    if (!inCatchBlock) {
      error(node, MessageKind.THROW_WITHOUT_EXPRESSION);
    }
  }

  visitReturn(Return node) {
    Node expression = node.expression;
    if (expression != null &&
        enclosingElement.isGenerativeConstructor) {
      // It is a compile-time error if a return statement of the form
      // `return e;` appears in a generative constructor.  (Dart Language
      // Specification 13.12.)
      compiler.reportError(expression,
                           MessageKind.CANNOT_RETURN_FROM_CONSTRUCTOR);
    }
    visit(node.expression);
  }

  visitYield(Yield node) {
    compiler.streamClass.ensureResolved(compiler);
    compiler.iterableClass.ensureResolved(compiler);
    visit(node.expression);
  }

  visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    final isSymbolConstructor = enclosingElement == compiler.symbolConstructor;
    if (!enclosingElement.isFactoryConstructor) {
      compiler.reportError(
          node, MessageKind.FACTORY_REDIRECTION_IN_NON_FACTORY);
      compiler.reportHint(
          enclosingElement, MessageKind.MISSING_FACTORY_KEYWORD);
    }
    ConstructorElementX constructor = enclosingElement;
    bool isConstConstructor = constructor.isConst;
    ConstructorElement redirectionTarget = resolveRedirectingFactory(
        node, inConstContext: isConstConstructor);
    constructor.immediateRedirectionTarget = redirectionTarget;
    registry.setRedirectingTargetConstructor(node, redirectionTarget);
    if (Elements.isUnresolved(redirectionTarget)) {
      registry.registerThrowNoSuchMethod();
      return;
    } else {
      if (isConstConstructor &&
          !redirectionTarget.isConst) {
        compiler.reportError(node, MessageKind.CONSTRUCTOR_IS_NOT_CONST);
      }
      if (redirectionTarget == constructor) {
        compiler.reportError(node, MessageKind.CYCLIC_REDIRECTING_FACTORY);
        return;
      }
    }

    // Check that the target constructor is type compatible with the
    // redirecting constructor.
    ClassElement targetClass = redirectionTarget.enclosingClass;
    InterfaceType type = registry.getType(node);
    FunctionType targetType = redirectionTarget.computeType(compiler)
        .subst(type.typeArguments, targetClass.typeVariables);
    FunctionType constructorType = constructor.computeType(compiler);
    bool isSubtype = compiler.types.isSubtype(targetType, constructorType);
    if (!isSubtype) {
      warning(node, MessageKind.NOT_ASSIGNABLE,
              {'fromType': targetType, 'toType': constructorType});
    }

    FunctionSignature targetSignature =
        redirectionTarget.computeSignature(compiler);
    FunctionSignature constructorSignature =
        constructor.computeSignature(compiler);
    if (!targetSignature.isCompatibleWith(constructorSignature)) {
      assert(!isSubtype);
      registry.registerThrowNoSuchMethod();
    }

    // Register a post process to check for cycles in the redirection chain and
    // set the actual generative constructor at the end of the chain.
    addDeferredAction(constructor, () {
      compiler.resolver.resolveRedirectionChain(constructor, node);
    });

    registry.registerStaticUse(redirectionTarget);
    // TODO(johnniwinther): Register the effective target type instead.
    registry.registerInstantiatedClass(
        redirectionTarget.enclosingClass.declaration);
    if (isSymbolConstructor) {
      registry.registerSymbolConstructor();
    }
  }

  visitThrow(Throw node) {
    registry.registerThrowExpression();
    visit(node.expression);
  }

  visitAwait(Await node) {
    compiler.futureClass.ensureResolved(compiler);
    visit(node.expression);
  }

  visitVariableDefinitions(VariableDefinitions node) {
    DartType type;
    if (node.type != null) {
      type = resolveTypeAnnotation(node.type);
    } else {
      type = const DynamicType();
    }
    VariableList variables = new VariableList.node(node, type);
    VariableDefinitionsVisitor visitor =
        new VariableDefinitionsVisitor(compiler, node, this, variables);

    Modifiers modifiers = node.modifiers;
    void reportExtraModifier(String modifier) {
      Node modifierNode;
      for (Link<Node> nodes = modifiers.nodes.nodes;
           !nodes.isEmpty;
           nodes = nodes.tail) {
        if (modifier == nodes.head.asIdentifier().source) {
          modifierNode = nodes.head;
          break;
        }
      }
      assert(modifierNode != null);
      compiler.reportError(modifierNode, MessageKind.EXTRANEOUS_MODIFIER,
          {'modifier': modifier});
    }
    if (modifiers.isFinal && (modifiers.isConst || modifiers.isVar)) {
      reportExtraModifier('final');
    }
    if (modifiers.isVar && (modifiers.isConst || node.type != null)) {
      reportExtraModifier('var');
    }
    if (enclosingElement.isFunction) {
      if (modifiers.isAbstract) {
        reportExtraModifier('abstract');
      }
      if (modifiers.isStatic) {
        reportExtraModifier('static');
      }
    }
    if (node.metadata != null) {
      variables.metadata =
          compiler.resolver.resolveMetadata(enclosingElement, node);
    }
    visitor.visit(node.definitions);
  }

  visitWhile(While node) {
    visit(node.condition);
    visitLoopBodyIn(node, node.body, new BlockScope(scope));
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    sendIsMemberAccess = false;
    visit(node.expression);
    sendIsMemberAccess = oldSendIsMemberAccess;
  }

  ResolutionResult visitNewExpression(NewExpression node) {
    Node selector = node.send.selector;
    FunctionElement constructor = resolveConstructor(node);
    final bool isSymbolConstructor = constructor == compiler.symbolConstructor;
    final bool isMirrorsUsedConstant =
        node.isConst && (constructor == compiler.mirrorsUsedConstructor);
    Selector callSelector = resolveSelector(node.send, constructor);
    resolveArguments(node.send.argumentsNode);
    registry.useElement(node.send, constructor);
    if (Elements.isUnresolved(constructor)) {
      return new ElementResult(constructor);
    }
    constructor.computeSignature(compiler);
    if (!callSelector.applies(constructor, compiler.world)) {
      registry.registerThrowNoSuchMethod();
    }

    // [constructor] might be the implementation element
    // and only declaration elements may be registered.
    registry.registerStaticUse(constructor.declaration);
    ClassElement cls = constructor.enclosingClass;
    if (cls.isEnumClass && currentClass != cls) {
      compiler.reportError(node,
                           MessageKind.CANNOT_INSTANTIATE_ENUM,
                           {'enumName': cls.name});
    }

    InterfaceType type = registry.getType(node);
    if (node.isConst && type.containsTypeVariables) {
      compiler.reportError(node.send.selector,
                           MessageKind.TYPE_VARIABLE_IN_CONSTANT);
    }
    // TODO(johniwinther): Avoid registration of `type` in face of redirecting
    // factory constructors.
    registry.registerInstantiatedType(type);
    if (constructor.isFactoryConstructor && !type.typeArguments.isEmpty) {
      registry.registerFactoryWithTypeArguments();
    }
    if (constructor.isGenerativeConstructor && cls.isAbstract) {
      warning(node, MessageKind.ABSTRACT_CLASS_INSTANTIATION);
      registry.registerAbstractClassInstantiation();
    }

    if (isSymbolConstructor) {
      if (node.isConst) {
        Node argumentNode = node.send.arguments.head;
        ConstantExpression constant =
            compiler.resolver.constantCompiler.compileNode(
                argumentNode, registry.mapping);
        ConstantValue name = constant.value;
        if (!name.isString) {
          DartType type = name.computeType(compiler);
          compiler.reportError(argumentNode, MessageKind.STRING_EXPECTED,
                                   {'type': type});
        } else {
          StringConstantValue stringConstant = name;
          String nameString = stringConstant.toDartString().slowToString();
          if (validateSymbol(argumentNode, nameString)) {
            registry.registerConstSymbol(nameString);
          }
        }
      } else {
        if (!compiler.mirrorUsageAnalyzerTask.hasMirrorUsage(
                enclosingElement)) {
          compiler.reportHint(
              node.newToken, MessageKind.NON_CONST_BLOAT,
              {'name': compiler.symbolClass.name});
        }
        registry.registerNewSymbol();
      }
    } else if (isMirrorsUsedConstant) {
      compiler.mirrorUsageAnalyzerTask.validate(node, registry.mapping);
    }
    if (node.isConst) {
      analyzeConstantDeferred(node);
    }

    return null;
  }

  void checkConstMapKeysDontOverrideEquals(Spannable spannable,
                                           MapConstantValue map) {
    for (ConstantValue key in map.keys) {
      if (!key.isObject) continue;
      ObjectConstantValue objectConstant = key;
      DartType keyType = objectConstant.type;
      ClassElement cls = keyType.element;
      if (cls == compiler.stringClass) continue;
      Element equals = cls.lookupMember('==');
      if (equals.enclosingClass != compiler.objectClass) {
        compiler.reportError(spannable,
                             MessageKind.CONST_MAP_KEY_OVERRIDES_EQUALS,
                             {'type': keyType});
      }
    }
  }

  void analyzeConstant(Node node) {
    ConstantExpression constant =
        compiler.resolver.constantCompiler.compileNode(
            node, registry.mapping);

    ConstantValue value = constant.value;
    if (value.isMap) {
      checkConstMapKeysDontOverrideEquals(node, value);
    }

    // The type constant that is an argument to JS_INTERCEPTOR_CONSTANT names
    // a class that will be instantiated outside the program by attaching a
    // native class dispatch record referencing the interceptor.
    if (argumentsToJsInterceptorConstant != null &&
        argumentsToJsInterceptorConstant.contains(node)) {
      if (value.isType) {
        TypeConstantValue typeConstant = value;
        if (typeConstant.representedType is InterfaceType) {
          registry.registerInstantiatedType(typeConstant.representedType);
        } else {
          compiler.reportError(node,
              MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
        }
      } else {
        compiler.reportError(node,
            MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
      }
    }
  }

  void analyzeConstantDeferred(Node node) {
    addDeferredAction(enclosingElement, () {
      analyzeConstant(node);
    });
  }

  bool validateSymbol(Node node, String name, {bool reportError: true}) {
    if (name.isEmpty) return true;
    if (name.startsWith('_')) {
      if (reportError) {
        compiler.reportError(node, MessageKind.PRIVATE_IDENTIFIER,
                             {'value': name});
      }
      return false;
    }
    if (!symbolValidationPattern.hasMatch(name)) {
      if (reportError) {
        compiler.reportError(node, MessageKind.INVALID_SYMBOL,
                             {'value': name});
      }
      return false;
    }
    return true;
  }

  /**
   * Try to resolve the constructor that is referred to by [node].
   * Note: this function may return an ErroneousFunctionElement instead of
   * [:null:], if there is no corresponding constructor, class or library.
   */
  ConstructorElement resolveConstructor(NewExpression node) {
    return node.accept(new ConstructorResolver(compiler, this));
  }

  ConstructorElement resolveRedirectingFactory(RedirectingFactoryBody node,
                                               {bool inConstContext: false}) {
    return node.accept(new ConstructorResolver(compiler, this,
                                               inConstContext: inConstContext));
  }

  DartType resolveTypeAnnotation(TypeAnnotation node,
                                 {bool malformedIsError: false,
                                  bool deferredIsMalformed: true}) {
    DartType type = typeResolver.resolveTypeAnnotation(
        this, node, malformedIsError: malformedIsError,
        deferredIsMalformed: deferredIsMalformed);
    if (inCheckContext) {
      registry.registerIsCheck(type);
      registry.registerRequiredType(type, enclosingElement);
    }
    return type;
  }

  visitModifiers(Modifiers node) {
    internalError(node, 'modifiers');
  }

  visitLiteralList(LiteralList node) {
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    sendIsMemberAccess = false;

    NodeList arguments = node.typeArguments;
    DartType typeArgument;
    if (arguments != null) {
      Link<Node> nodes = arguments.nodes;
      if (nodes.isEmpty) {
        // The syntax [: <>[] :] is not allowed.
        error(arguments, MessageKind.MISSING_TYPE_ARGUMENT);
      } else {
        typeArgument = resolveTypeAnnotation(nodes.head);
        for (nodes = nodes.tail; !nodes.isEmpty; nodes = nodes.tail) {
          warning(nodes.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT);
          resolveTypeAnnotation(nodes.head);
        }
      }
    }
    DartType listType;
    if (typeArgument != null) {
      if (node.isConst && typeArgument.containsTypeVariables) {
        compiler.reportError(arguments.nodes.head,
            MessageKind.TYPE_VARIABLE_IN_CONSTANT);
      }
      listType = new InterfaceType(compiler.listClass, [typeArgument]);
    } else {
      compiler.listClass.computeType(compiler);
      listType = compiler.listClass.rawType;
    }
    registry.setType(node, listType);
    registry.registerInstantiatedType(listType);
    registry.registerRequiredType(listType, enclosingElement);
    visit(node.elements);
    if (node.isConst) {
      analyzeConstantDeferred(node);
    }

    sendIsMemberAccess = false;
  }

  visitConditional(Conditional node) {
    doInPromotionScope(node.condition, () => visit(node.condition));
    doInPromotionScope(node.thenExpression, () => visit(node.thenExpression));
    visit(node.elseExpression);
  }

  visitStringInterpolation(StringInterpolation node) {
    registry.registerInstantiatedClass(compiler.stringClass);
    registry.registerStringInterpolation();
    node.visitChildren(this);
  }

  visitStringInterpolationPart(StringInterpolationPart node) {
    registerImplicitInvocation('toString', 0);
    node.visitChildren(this);
  }

  visitBreakStatement(BreakStatement node) {
    JumpTarget target;
    if (node.target == null) {
      target = statementScope.currentBreakTarget();
      if (target == null) {
        error(node, MessageKind.NO_BREAK_TARGET);
        return;
      }
      target.isBreakTarget = true;
    } else {
      String labelName = node.target.source;
      LabelDefinition label = statementScope.lookupLabel(labelName);
      if (label == null) {
        error(node.target, MessageKind.UNBOUND_LABEL, {'labelName': labelName});
        return;
      }
      target = label.target;
      if (!target.statement.isValidBreakTarget()) {
        error(node.target, MessageKind.INVALID_BREAK);
        return;
      }
      label.setBreakTarget();
      registry.useLabel(node, label);
    }
    registry.registerTargetOf(node, target);
  }

  visitContinueStatement(ContinueStatement node) {
    JumpTarget target;
    if (node.target == null) {
      target = statementScope.currentContinueTarget();
      if (target == null) {
        error(node, MessageKind.NO_CONTINUE_TARGET);
        return;
      }
      target.isContinueTarget = true;
    } else {
      String labelName = node.target.source;
      LabelDefinition label = statementScope.lookupLabel(labelName);
      if (label == null) {
        error(node.target, MessageKind.UNBOUND_LABEL, {'labelName': labelName});
        return;
      }
      target = label.target;
      if (!target.statement.isValidContinueTarget()) {
        error(node.target, MessageKind.INVALID_CONTINUE);
      }
      label.setContinueTarget();
      registry.useLabel(node, label);
    }
    registry.registerTargetOf(node, target);
  }

  registerImplicitInvocation(String name, int arity) {
    Selector selector = new Selector.call(name, null, arity);
    registry.registerDynamicInvocation(selector);
  }

  visitForIn(ForIn node) {
    LibraryElement library = enclosingElement.library;
    registry.setIteratorSelector(node, compiler.iteratorSelector);
    registry.registerDynamicGetter(compiler.iteratorSelector);
    registry.setCurrentSelector(node, compiler.currentSelector);
    registry.registerDynamicGetter(compiler.currentSelector);
    registry.setMoveNextSelector(node, compiler.moveNextSelector);
    registry.registerDynamicInvocation(compiler.moveNextSelector);

    visit(node.expression);
    Scope blockScope = new BlockScope(scope);
    Node declaration = node.declaredIdentifier;

    bool oldAllowFinalWithoutInitializer = allowFinalWithoutInitializer;
    allowFinalWithoutInitializer = true;
    visitIn(declaration, blockScope);
    allowFinalWithoutInitializer = oldAllowFinalWithoutInitializer;

    Send send = declaration.asSend();
    VariableDefinitions variableDefinitions =
        declaration.asVariableDefinitions();
    Element loopVariable;
    Selector loopVariableSelector;
    if (send != null) {
      loopVariable = registry.getDefinition(send);
      Identifier identifier = send.selector.asIdentifier();
      if (identifier == null) {
        compiler.reportError(send.selector, MessageKind.INVALID_FOR_IN);
      } else {
        loopVariableSelector = new Selector.setter(identifier.source, library);
      }
      if (send.receiver != null) {
        compiler.reportError(send.receiver, MessageKind.INVALID_FOR_IN);
      }
    } else if (variableDefinitions != null) {
      Link<Node> nodes = variableDefinitions.definitions.nodes;
      if (!nodes.tail.isEmpty) {
        compiler.reportError(nodes.tail.head, MessageKind.INVALID_FOR_IN);
      }
      Node first = nodes.head;
      Identifier identifier = first.asIdentifier();
      if (identifier == null) {
        compiler.reportError(first, MessageKind.INVALID_FOR_IN);
      } else {
        loopVariableSelector = new Selector.setter(identifier.source, library);
        loopVariable = registry.getDefinition(identifier);
      }
    } else {
      compiler.reportError(declaration, MessageKind.INVALID_FOR_IN);
    }
    if (loopVariableSelector != null) {
      registry.setSelector(declaration, loopVariableSelector);
      registerSend(loopVariableSelector, loopVariable);
    } else {
      // The selector may only be null if we reported an error.
      assert(invariant(declaration, compiler.compilationFailed));
    }
    if (loopVariable != null) {
      // loopVariable may be null if it could not be resolved.
      registry.setForInVariable(node, loopVariable);
    }
    visitLoopBodyIn(node, node.body, blockScope);
  }

  visitLabel(Label node) {
    // Labels are handled by their containing statements/cases.
  }

  visitLabeledStatement(LabeledStatement node) {
    Statement body = node.statement;
    JumpTarget targetElement = getOrDefineTarget(body);
    Map<String, LabelDefinition> labelElements = <String, LabelDefinition>{};
    for (Label label in node.labels) {
      String labelName = label.labelName;
      if (labelElements.containsKey(labelName)) continue;
      LabelDefinition element = targetElement.addLabel(label, labelName);
      labelElements[labelName] = element;
    }
    statementScope.enterLabelScope(labelElements);
    visit(node.statement);
    statementScope.exitLabelScope();
    labelElements.forEach((String labelName, LabelDefinition element) {
      if (element.isTarget) {
        registry.defineLabel(element.label, element);
      } else {
        warning(element.label, MessageKind.UNUSED_LABEL,
                {'labelName': labelName});
      }
    });
    if (!targetElement.isTarget) {
      registry.undefineTarget(body);
    }
  }

  visitLiteralMap(LiteralMap node) {
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    sendIsMemberAccess = false;

    NodeList arguments = node.typeArguments;
    DartType keyTypeArgument;
    DartType valueTypeArgument;
    if (arguments != null) {
      Link<Node> nodes = arguments.nodes;
      if (nodes.isEmpty) {
        // The syntax [: <>{} :] is not allowed.
        error(arguments, MessageKind.MISSING_TYPE_ARGUMENT);
      } else {
        keyTypeArgument = resolveTypeAnnotation(nodes.head);
        nodes = nodes.tail;
        if (nodes.isEmpty) {
          warning(arguments, MessageKind.MISSING_TYPE_ARGUMENT);
        } else {
          valueTypeArgument = resolveTypeAnnotation(nodes.head);
          for (nodes = nodes.tail; !nodes.isEmpty; nodes = nodes.tail) {
            warning(nodes.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT);
            resolveTypeAnnotation(nodes.head);
          }
        }
      }
    }
    DartType mapType;
    if (valueTypeArgument != null) {
      mapType = new InterfaceType(compiler.mapClass,
          [keyTypeArgument, valueTypeArgument]);
    } else {
      compiler.mapClass.computeType(compiler);
      mapType = compiler.mapClass.rawType;
    }
    if (node.isConst && mapType.containsTypeVariables) {
      compiler.reportError(arguments,
          MessageKind.TYPE_VARIABLE_IN_CONSTANT);
    }
    registry.setType(node, mapType);
    registry.registerInstantiatedType(mapType);
    if (node.isConst) {
      registry.registerConstantMap();
    }
    registry.registerRequiredType(mapType, enclosingElement);
    node.visitChildren(this);
    if (node.isConst) {
      analyzeConstantDeferred(node);
    }

    sendIsMemberAccess = false;
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    node.visitChildren(this);
  }

  visitNamedArgument(NamedArgument node) {
    visit(node.expression);
  }

  DartType typeOfConstant(ConstantValue constant) {
    if (constant.isInt) return compiler.intClass.rawType;
    if (constant.isBool) return compiler.boolClass.rawType;
    if (constant.isDouble) return compiler.doubleClass.rawType;
    if (constant.isString) return compiler.stringClass.rawType;
    if (constant.isNull) return compiler.nullClass.rawType;
    if (constant.isFunction) return compiler.functionClass.rawType;
    assert(constant.isObject);
    ObjectConstantValue objectConstant = constant;
    return objectConstant.type;
  }

  bool overridesEquals(DartType type) {
    ClassElement cls = type.element;
    Element equals = cls.lookupMember('==');
    return equals.enclosingClass != compiler.objectClass;
  }

  void checkCaseExpressions(SwitchStatement node) {
    JumpTarget breakElement = getOrDefineTarget(node);
    Map<String, LabelDefinition> continueLabels = <String, LabelDefinition>{};

    Link<Node> cases = node.cases.nodes;
    CaseMatch firstCase = null;
    DartType firstCaseType = null;
    bool hasReportedProblem = false;

    for (Link<Node> cases = node.cases.nodes;
         !cases.isEmpty;
         cases = cases.tail) {
      SwitchCase switchCase = cases.head;

      for (Node labelOrCase in switchCase.labelsAndCases) {
        CaseMatch caseMatch = labelOrCase.asCaseMatch();
        if (caseMatch == null) continue;

        // Analyze the constant.
        ConstantExpression constant =
            registry.getConstant(caseMatch.expression);
        assert(invariant(node, constant != null,
            message: 'No constant computed for $node'));

        DartType caseType = typeOfConstant(constant.value);

        if (firstCaseType == null) {
          firstCase = caseMatch;
          firstCaseType = caseType;

          // We only report the bad type on the first class element. All others
          // get a "type differs" error.
          if (caseType.element == compiler.doubleClass) {
            compiler.reportError(node,
                                 MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS,
                                 {'type': "double"});
          } else if (caseType.element == compiler.functionClass) {
            compiler.reportError(node, MessageKind.SWITCH_CASE_FORBIDDEN,
                                 {'type': "Function"});
          } else if (constant.value.isObject && overridesEquals(caseType)) {
            compiler.reportError(firstCase.expression,
                MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS,
                {'type': caseType});
          }
        } else {
          if (caseType != firstCaseType) {
            if (!hasReportedProblem) {
              compiler.reportError(
                  node,
                  MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL,
                  {'type': firstCaseType});
              compiler.reportInfo(
                  firstCase.expression,
                  MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE,
                  {'type': firstCaseType});
              hasReportedProblem = true;
            }
            compiler.reportInfo(
                caseMatch.expression,
                MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE,
                {'type': caseType});
          }
        }
      }
    }
  }

  visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);

    JumpTarget breakElement = getOrDefineTarget(node);
    Map<String, LabelDefinition> continueLabels = <String, LabelDefinition>{};
    Link<Node> cases = node.cases.nodes;
    while (!cases.isEmpty) {
      SwitchCase switchCase = cases.head;
      for (Node labelOrCase in switchCase.labelsAndCases) {
        CaseMatch caseMatch = labelOrCase.asCaseMatch();
        if (caseMatch != null) {
          analyzeConstantDeferred(caseMatch.expression);
          continue;
        }
        Label label = labelOrCase;
        String labelName = label.labelName;

        LabelDefinition existingElement = continueLabels[labelName];
        if (existingElement != null) {
          // It's an error if the same label occurs twice in the same switch.
          compiler.reportError(
              label,
              MessageKind.DUPLICATE_LABEL, {'labelName': labelName});
          compiler.reportInfo(
              existingElement.label,
              MessageKind.EXISTING_LABEL, {'labelName': labelName});
        } else {
          // It's only a warning if it shadows another label.
          existingElement = statementScope.lookupLabel(labelName);
          if (existingElement != null) {
            compiler.reportWarning(
                label,
                MessageKind.DUPLICATE_LABEL, {'labelName': labelName});
            compiler.reportInfo(
                existingElement.label,
                MessageKind.EXISTING_LABEL, {'labelName': labelName});
          }
        }

        JumpTarget targetElement = getOrDefineTarget(switchCase);
        LabelDefinition labelElement = targetElement.addLabel(label, labelName);
        registry.defineLabel(label, labelElement);
        continueLabels[labelName] = labelElement;
      }
      cases = cases.tail;
      // Test that only the last case, if any, is a default case.
      if (switchCase.defaultKeyword != null && !cases.isEmpty) {
        error(switchCase, MessageKind.INVALID_CASE_DEFAULT);
      }
    }

    addDeferredAction(enclosingElement, () {
      checkCaseExpressions(node);
    });

    statementScope.enterSwitch(breakElement, continueLabels);
    node.cases.accept(this);
    statementScope.exitSwitch();

    // Clean-up unused labels.
    continueLabels.forEach((String key, LabelDefinition label) {
      if (!label.isContinueTarget) {
        JumpTarget targetElement = label.target;
        SwitchCase switchCase = targetElement.statement;
        registry.undefineTarget(switchCase);
        registry.undefineLabel(label.label);
      }
    });
    // TODO(15575): We should warn if we can detect a fall through
    // error.
    registry.registerFallThroughError();
  }

  visitSwitchCase(SwitchCase node) {
    node.labelsAndCases.accept(this);
    visitIn(node.statements, new BlockScope(scope));
  }

  visitCaseMatch(CaseMatch node) {
    visit(node.expression);
  }

  visitTryStatement(TryStatement node) {
    visit(node.tryBlock);
    if (node.catchBlocks.isEmpty && node.finallyBlock == null) {
      error(node.getEndToken().next, MessageKind.NO_CATCH_NOR_FINALLY);
    }
    visit(node.catchBlocks);
    visit(node.finallyBlock);
  }

  visitCatchBlock(CatchBlock node) {
    registry.registerCatchStatement();
    // Check that if catch part is present, then
    // it has one or two formal parameters.
    VariableDefinitions exceptionDefinition;
    VariableDefinitions stackTraceDefinition;
    if (node.formals != null) {
      Link<Node> formalsToProcess = node.formals.nodes;
      if (formalsToProcess.isEmpty) {
        error(node, MessageKind.EMPTY_CATCH_DECLARATION);
      } else {
        exceptionDefinition = formalsToProcess.head.asVariableDefinitions();
        formalsToProcess = formalsToProcess.tail;
        if (!formalsToProcess.isEmpty) {
          stackTraceDefinition = formalsToProcess.head.asVariableDefinitions();
          formalsToProcess = formalsToProcess.tail;
          if (!formalsToProcess.isEmpty) {
            for (Node extra in formalsToProcess) {
              error(extra, MessageKind.EXTRA_CATCH_DECLARATION);
            }
          }
          registry.registerStackTraceInCatch();
        }
      }

      // Check that the formals aren't optional and that they have no
      // modifiers or type.
      for (Link<Node> link = node.formals.nodes;
           !link.isEmpty;
           link = link.tail) {
        // If the formal parameter is a node list, it means that it is a
        // sequence of optional parameters.
        NodeList nodeList = link.head.asNodeList();
        if (nodeList != null) {
          error(nodeList, MessageKind.OPTIONAL_PARAMETER_IN_CATCH);
        } else {
          VariableDefinitions declaration = link.head;
          for (Node modifier in declaration.modifiers.nodes) {
            error(modifier, MessageKind.PARAMETER_WITH_MODIFIER_IN_CATCH);
          }
          TypeAnnotation type = declaration.type;
          if (type != null) {
            error(type, MessageKind.PARAMETER_WITH_TYPE_IN_CATCH);
          }
        }
      }
    }

    Scope blockScope = new BlockScope(scope);
    doInCheckContext(() => visitIn(node.type, blockScope));
    visitIn(node.formals, blockScope);
    var oldInCatchBlock = inCatchBlock;
    inCatchBlock = true;
    visitIn(node.block, blockScope);
    inCatchBlock = oldInCatchBlock;

    if (node.type != null && exceptionDefinition != null) {
      DartType exceptionType = registry.getType(node.type);
      Node exceptionVariable = exceptionDefinition.definitions.nodes.head;
      VariableElementX exceptionElement =
          registry.getDefinition(exceptionVariable);
      exceptionElement.variables.type = exceptionType;
    }
    if (stackTraceDefinition != null) {
      Node stackTraceVariable = stackTraceDefinition.definitions.nodes.head;
      VariableElementX stackTraceElement =
          registry.getDefinition(stackTraceVariable);
      registry.registerInstantiatedClass(compiler.stackTraceClass);
      stackTraceElement.variables.type = compiler.stackTraceClass.rawType;
    }
  }

  visitTypedef(Typedef node) {
    internalError(node, 'typedef');
  }
}

class TypeDefinitionVisitor extends MappingVisitor<DartType> {
  Scope scope;
  final TypeDeclarationElement enclosingElement;
  TypeDeclarationElement get element => enclosingElement;

  TypeDefinitionVisitor(Compiler compiler,
                        TypeDeclarationElement element,
                        ResolutionRegistry registry)
      : this.enclosingElement = element,
        scope = Scope.buildEnclosingScope(element),
        super(compiler, registry);

  DartType get objectType => compiler.objectClass.rawType;

  void resolveTypeVariableBounds(NodeList node) {
    if (node == null) return;

    Setlet<String> nameSet = new Setlet<String>();
    // Resolve the bounds of type variables.
    Iterator<DartType> types = element.typeVariables.iterator;
    Link<Node> nodeLink = node.nodes;
    while (!nodeLink.isEmpty) {
      types.moveNext();
      TypeVariableType typeVariable = types.current;
      String typeName = typeVariable.name;
      TypeVariable typeNode = nodeLink.head;
      registry.useType(typeNode, typeVariable);
      if (nameSet.contains(typeName)) {
        error(typeNode, MessageKind.DUPLICATE_TYPE_VARIABLE_NAME,
              {'typeVariableName': typeName});
      }
      nameSet.add(typeName);

      TypeVariableElementX variableElement = typeVariable.element;
      if (typeNode.bound != null) {
        DartType boundType = typeResolver.resolveTypeAnnotation(
            this, typeNode.bound);
        variableElement.boundCache = boundType;

        void checkTypeVariableBound() {
          Link<TypeVariableElement> seenTypeVariables =
              const Link<TypeVariableElement>();
          seenTypeVariables = seenTypeVariables.prepend(variableElement);
          DartType bound = boundType;
          while (bound.isTypeVariable) {
            TypeVariableElement element = bound.element;
            if (seenTypeVariables.contains(element)) {
              if (identical(element, variableElement)) {
                // Only report an error on the checked type variable to avoid
                // generating multiple errors for the same cyclicity.
                warning(typeNode.name, MessageKind.CYCLIC_TYPE_VARIABLE,
                    {'typeVariableName': variableElement.name});
              }
              break;
            }
            seenTypeVariables = seenTypeVariables.prepend(element);
            bound = element.bound;
          }
        }
        addDeferredAction(element, checkTypeVariableBound);
      } else {
        variableElement.boundCache = objectType;
      }
      nodeLink = nodeLink.tail;
    }
    assert(!types.moveNext());
  }
}

class TypedefResolverVisitor extends TypeDefinitionVisitor {
  TypedefElementX get element => enclosingElement;

  TypedefResolverVisitor(Compiler compiler,
                         TypedefElement typedefElement,
                         ResolutionRegistry registry)
      : super(compiler, typedefElement, registry);

  visitTypedef(Typedef node) {
    TypedefType type = element.computeType(compiler);
    scope = new TypeDeclarationScope(scope, element);
    resolveTypeVariableBounds(node.typeParameters);

    FunctionSignature signature = SignatureResolver.analyze(
        compiler, node.formals, node.returnType, element, registry,
        defaultValuesError: MessageKind.TYPEDEF_FORMAL_WITH_DEFAULT);
    element.functionSignature = signature;

    scope = new MethodScope(scope, element);
    signature.forEachParameter(addToScope);

    element.alias = signature.type;

    void checkCyclicReference() {
      element.checkCyclicReference(compiler);
    }
    addDeferredAction(element, checkCyclicReference);
  }
}

// TODO(johnniwinther): Replace with a traversal on the AST when the type
// annotations in typedef alias are stored in a [TreeElements] mapping.
class TypedefCyclicVisitor extends DartTypeVisitor {
  final Compiler compiler;
  final TypedefElementX element;
  bool hasCyclicReference = false;

  Link<TypedefElement> seenTypedefs = const Link<TypedefElement>();

  int seenTypedefsCount = 0;

  Link<TypeVariableElement> seenTypeVariables =
      const Link<TypeVariableElement>();

  TypedefCyclicVisitor(Compiler this.compiler, TypedefElement this.element);

  visitType(DartType type, _) {
    // Do nothing.
  }

  visitTypedefType(TypedefType type, _) {
    TypedefElementX typedefElement = type.element;
    if (seenTypedefs.contains(typedefElement)) {
      if (!hasCyclicReference && identical(element, typedefElement)) {
        // Only report an error on the checked typedef to avoid generating
        // multiple errors for the same cyclicity.
        hasCyclicReference = true;
        if (seenTypedefsCount == 1) {
          // Direct cyclicity.
          compiler.reportError(element,
              MessageKind.CYCLIC_TYPEDEF,
              {'typedefName': element.name});
        } else if (seenTypedefsCount == 2) {
          // Cyclicity through one other typedef.
          compiler.reportError(element,
              MessageKind.CYCLIC_TYPEDEF_ONE,
              {'typedefName': element.name,
               'otherTypedefName': seenTypedefs.head.name});
        } else {
          // Cyclicity through more than one other typedef.
          for (TypedefElement cycle in seenTypedefs) {
            if (!identical(typedefElement, cycle)) {
              compiler.reportError(element,
                  MessageKind.CYCLIC_TYPEDEF_ONE,
                  {'typedefName': element.name,
                   'otherTypedefName': cycle.name});
            }
          }
        }
        ErroneousElementX erroneousElement = new ErroneousElementX(
              MessageKind.CYCLIC_TYPEDEF,
              {'typedefName': element.name},
              element.name, element);
        element.alias =
            new MalformedType(erroneousElement, typedefElement.alias);
        element.hasBeenCheckedForCycles = true;
      }
    } else {
      seenTypedefs = seenTypedefs.prepend(typedefElement);
      seenTypedefsCount++;
      type.visitChildren(this, null);
      typedefElement.alias.accept(this, null);
      seenTypedefs = seenTypedefs.tail;
      seenTypedefsCount--;
    }
  }

  visitFunctionType(FunctionType type, _) {
    type.visitChildren(this, null);
  }

  visitInterfaceType(InterfaceType type, _) {
    type.visitChildren(this, null);
  }

  visitTypeVariableType(TypeVariableType type, _) {
    TypeVariableElement typeVariableElement = type.element;
    if (seenTypeVariables.contains(typeVariableElement)) {
      // Avoid running in cycles on cyclic type variable bounds.
      // Cyclicity is reported elsewhere.
      return;
    }
    seenTypeVariables = seenTypeVariables.prepend(typeVariableElement);
    typeVariableElement.bound.accept(this, null);
    seenTypeVariables = seenTypeVariables.tail;
  }
}

/**
 * The implementation of [ResolverTask.resolveClass].
 *
 * This visitor has to be extra careful as it is building the basic
 * element information, and cannot safely look at other elements as
 * this may lead to cycles.
 *
 * This visitor can assume that the supertypes have already been
 * resolved, but it cannot call [ResolverTask.resolveClass] directly
 * or indirectly (through [ClassElement.ensureResolved]) for any other
 * types.
 */
class ClassResolverVisitor extends TypeDefinitionVisitor {
  BaseClassElementX get element => enclosingElement;

  ClassResolverVisitor(Compiler compiler,
                       ClassElement classElement,
                       ResolutionRegistry registry)
    : super(compiler, classElement, registry);

  DartType visitClassNode(ClassNode node) {
    invariant(node, element != null);
    invariant(element, element.resolutionState == STATE_STARTED,
        message: () => 'cyclic resolution of class $element');

    InterfaceType type = element.computeType(compiler);
    scope = new TypeDeclarationScope(scope, element);
    // TODO(ahe): It is not safe to call resolveTypeVariableBounds yet.
    // As a side-effect, this may get us back here trying to
    // resolve this class again.
    resolveTypeVariableBounds(node.typeParameters);

    // Setup the supertype for the element (if there is a cycle in the
    // class hierarchy, it has already been set to Object).
    if (element.supertype == null && node.superclass != null) {
      MixinApplication superMixin = node.superclass.asMixinApplication();
      if (superMixin != null) {
        DartType supertype = resolveSupertype(element, superMixin.superclass);
        Link<Node> link = superMixin.mixins.nodes;
        while (!link.isEmpty) {
          supertype = applyMixin(supertype,
                                 checkMixinType(link.head), link.head);
          link = link.tail;
        }
        element.supertype = supertype;
      } else {
        element.supertype = resolveSupertype(element, node.superclass);
      }
    }
    // If the super type isn't specified, we provide a default.  The language
    // specifies [Object] but the backend can pick a specific 'implementation'
    // of Object - the JavaScript backend chooses between Object and
    // Interceptor.
    if (element.supertype == null) {
      ClassElement superElement = registry.defaultSuperclass(element);
      // Avoid making the superclass (usually Object) extend itself.
      if (element != superElement) {
        if (superElement == null) {
          compiler.internalError(node,
              "Cannot resolve default superclass for $element.");
        } else {
          superElement.ensureResolved(compiler);
        }
        element.supertype = superElement.computeType(compiler);
      }
    }

    if (element.interfaces == null) {
      element.interfaces = resolveInterfaces(node.interfaces, node.superclass);
    } else {
      assert(invariant(element, element.hasIncompleteHierarchy));
    }
    calculateAllSupertypes(element);

    if (!element.hasConstructor) {
      Element superMember = element.superclass.localLookup('');
      if (superMember == null || !superMember.isGenerativeConstructor) {
        MessageKind kind = MessageKind.CANNOT_FIND_CONSTRUCTOR;
        Map arguments = {'constructorName': ''};
        // TODO(ahe): Why is this a compile-time error? Or if it is an error,
        // why do we bother to registerThrowNoSuchMethod below?
        compiler.reportError(node, kind, arguments);
        superMember = new ErroneousElementX(
            kind, arguments, '', element);
        registry.registerThrowNoSuchMethod();
      } else {
        ConstructorElement superConstructor = superMember;
        Selector callToMatch = new Selector.call("", element.library, 0);
        superConstructor.computeSignature(compiler);
        if (!callToMatch.applies(superConstructor, compiler.world)) {
          MessageKind kind = MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT;
          compiler.reportError(node, kind);
          superMember = new ErroneousElementX(kind, {}, '', element);
        }
      }
      FunctionElement constructor =
          new SynthesizedConstructorElementX.forDefault(superMember, element);
      element.setDefaultConstructor(constructor, compiler);
    }
    return element.computeType(compiler);
  }

  @override
  DartType visitEnum(Enum node) {
    if (!compiler.enableEnums) {
      compiler.reportError(node, MessageKind.EXPERIMENTAL_ENUMS);
    }

    invariant(node, element != null);
    invariant(element, element.resolutionState == STATE_STARTED,
        message: () => 'cyclic resolution of class $element');

    InterfaceType enumType = element.computeType(compiler);
    element.supertype = compiler.objectClass.computeType(compiler);
    element.interfaces = const Link<DartType>();
    calculateAllSupertypes(element);

    if (node.names.nodes.isEmpty) {
      compiler.reportError(node,
                           MessageKind.EMPTY_ENUM_DECLARATION,
                           {'enumName': element.name});
    }

    EnumCreator creator = new EnumCreator(compiler, element);
    creator.createMembers();
    return enumType;
  }

  /// Resolves the mixed type for [mixinNode] and checks that the the mixin type
  /// is a valid, non-blacklisted interface type. The mixin type is returned.
  DartType checkMixinType(TypeAnnotation mixinNode) {
    DartType mixinType = resolveType(mixinNode);
    if (isBlackListed(mixinType)) {
      compiler.reportError(mixinNode,
          MessageKind.CANNOT_MIXIN, {'type': mixinType});
    } else if (mixinType.isTypeVariable) {
      compiler.reportError(mixinNode, MessageKind.CLASS_NAME_EXPECTED);
    } else if (mixinType.isMalformed) {
      compiler.reportError(mixinNode, MessageKind.CANNOT_MIXIN_MALFORMED,
          {'className': element.name, 'malformedType': mixinType});
    } else if (mixinType.isEnumType) {
      compiler.reportError(mixinNode, MessageKind.CANNOT_MIXIN_ENUM,
          {'className': element.name, 'enumType': mixinType});
    }
    return mixinType;
  }

  DartType visitNamedMixinApplication(NamedMixinApplication node) {
    invariant(node, element != null);
    invariant(element, element.resolutionState == STATE_STARTED,
        message: () => 'cyclic resolution of class $element');

    if (identical(node.classKeyword.stringValue, 'typedef')) {
      // TODO(aprelev@gmail.com): Remove this deprecation diagnostic
      // together with corresponding TODO in parser.dart.
      compiler.reportWarning(node.classKeyword,
          MessageKind.DEPRECATED_TYPEDEF_MIXIN_SYNTAX);
    }

    InterfaceType type = element.computeType(compiler);
    scope = new TypeDeclarationScope(scope, element);
    resolveTypeVariableBounds(node.typeParameters);

    // Generate anonymous mixin application elements for the
    // intermediate mixin applications (excluding the last).
    DartType supertype = resolveSupertype(element, node.superclass);
    Link<Node> link = node.mixins.nodes;
    while (!link.tail.isEmpty) {
      supertype = applyMixin(supertype, checkMixinType(link.head), link.head);
      link = link.tail;
    }
    doApplyMixinTo(element, supertype, checkMixinType(link.head));
    return element.computeType(compiler);
  }

  DartType applyMixin(DartType supertype, DartType mixinType, Node node) {
    String superName = supertype.name;
    String mixinName = mixinType.name;
    MixinApplicationElementX mixinApplication = new MixinApplicationElementX(
        "${superName}+${mixinName}",
        element.compilationUnit,
        compiler.getNextFreeClassId(),
        node,
        new Modifiers.withFlags(new NodeList.empty(), Modifiers.FLAG_ABSTRACT));
    // Create synthetic type variables for the mixin application.
    List<DartType> typeVariables = <DartType>[];
    element.typeVariables.forEach((TypeVariableType type) {
      TypeVariableElementX typeVariableElement = new TypeVariableElementX(
          type.name, mixinApplication, type.element.node);
      TypeVariableType typeVariable = new TypeVariableType(typeVariableElement);
      typeVariables.add(typeVariable);
    });
    // Setup bounds on the synthetic type variables.
    List<DartType> link = typeVariables;
    int index = 0;
    element.typeVariables.forEach((TypeVariableType type) {
      TypeVariableType typeVariable = typeVariables[index++];
      TypeVariableElementX typeVariableElement = typeVariable.element;
      typeVariableElement.typeCache = typeVariable;
      typeVariableElement.boundCache =
          type.element.bound.subst(typeVariables, element.typeVariables);
    });
    // Setup this and raw type for the mixin application.
    mixinApplication.computeThisAndRawType(compiler, typeVariables);
    // Substitute in synthetic type variables in super and mixin types.
    supertype = supertype.subst(typeVariables, element.typeVariables);
    mixinType = mixinType.subst(typeVariables, element.typeVariables);

    doApplyMixinTo(mixinApplication, supertype, mixinType);
    mixinApplication.resolutionState = STATE_DONE;
    mixinApplication.supertypeLoadState = STATE_DONE;
    // Replace the synthetic type variables by the original type variables in
    // the returned type (which should be the type actually extended).
    InterfaceType mixinThisType = mixinApplication.computeType(compiler);
    return mixinThisType.subst(element.typeVariables,
                               mixinThisType.typeArguments);
  }

  bool isDefaultConstructor(FunctionElement constructor) {
    return constructor.name == '' &&
        constructor.computeSignature(compiler).parameterCount == 0;
  }

  FunctionElement createForwardingConstructor(ConstructorElement target,
                                              ClassElement enclosing) {
    return new SynthesizedConstructorElementX(
        target.name, target, enclosing, false);
  }

  void doApplyMixinTo(MixinApplicationElementX mixinApplication,
                      DartType supertype,
                      DartType mixinType) {
    Node node = mixinApplication.parseNode(compiler);

    if (mixinApplication.supertype != null) {
      // [supertype] is not null if there was a cycle.
      assert(invariant(node, compiler.compilationFailed));
      supertype = mixinApplication.supertype;
      assert(invariant(node, supertype.element == compiler.objectClass));
    } else {
      mixinApplication.supertype = supertype;
    }

    // Named mixin application may have an 'implements' clause.
    NamedMixinApplication namedMixinApplication =
        node.asNamedMixinApplication();
    Link<DartType> interfaces = (namedMixinApplication != null)
        ? resolveInterfaces(namedMixinApplication.interfaces,
                            namedMixinApplication.superclass)
        : const Link<DartType>();

    // The class that is the result of a mixin application implements
    // the interface of the class that was mixed in so always prepend
    // that to the interface list.
    if (mixinApplication.interfaces == null) {
      if (mixinType.isInterfaceType) {
        // Avoid malformed types in the interfaces.
        interfaces = interfaces.prepend(mixinType);
      }
      mixinApplication.interfaces = interfaces;
    } else {
      assert(invariant(mixinApplication,
          mixinApplication.hasIncompleteHierarchy));
    }

    ClassElement superclass = supertype.element;
    if (mixinType.kind != TypeKind.INTERFACE) {
      mixinApplication.hasIncompleteHierarchy = true;
      mixinApplication.allSupertypesAndSelf = superclass.allSupertypesAndSelf;
      return;
    }

    assert(mixinApplication.mixinType == null);
    mixinApplication.mixinType = resolveMixinFor(mixinApplication, mixinType);

    // Create forwarding constructors for constructor defined in the superclass
    // because they are now hidden by the mixin application.
    superclass.forEachLocalMember((Element member) {
      if (!member.isGenerativeConstructor) return;
      FunctionElement forwarder =
          createForwardingConstructor(member, mixinApplication);
      if (isPrivateName(member.name) &&
          mixinApplication.library != superclass.library) {
        // Do not create a forwarder to the super constructor, because the mixin
        // application is in a different library than the constructor in the
        // super class and it is not possible to call that constructor from the
        // library using the mixin application.
        return;
      }
      mixinApplication.addConstructor(forwarder);
    });
    calculateAllSupertypes(mixinApplication);
  }

  InterfaceType resolveMixinFor(MixinApplicationElement mixinApplication,
                                DartType mixinType) {
    ClassElement mixin = mixinType.element;
    mixin.ensureResolved(compiler);

    // Check for cycles in the mixin chain.
    ClassElement previous = mixinApplication;  // For better error messages.
    ClassElement current = mixin;
    while (current != null && current.isMixinApplication) {
      MixinApplicationElement currentMixinApplication = current;
      if (currentMixinApplication == mixinApplication) {
        compiler.reportError(
            mixinApplication, MessageKind.ILLEGAL_MIXIN_CYCLE,
            {'mixinName1': current.name, 'mixinName2': previous.name});
        // We have found a cycle in the mixin chain. Return null as
        // the mixin for this application to avoid getting into
        // infinite recursion when traversing members.
        return null;
      }
      previous = current;
      current = currentMixinApplication.mixin;
    }
    registry.registerMixinUse(mixinApplication, mixin);
    return mixinType;
  }

  DartType resolveType(TypeAnnotation node) {
    return typeResolver.resolveTypeAnnotation(this, node);
  }

  DartType resolveSupertype(ClassElement cls, TypeAnnotation superclass) {
    DartType supertype = resolveType(superclass);
    if (supertype != null) {
      if (supertype.isMalformed) {
        compiler.reportError(superclass, MessageKind.CANNOT_EXTEND_MALFORMED,
            {'className': element.name, 'malformedType': supertype});
        return objectType;
      } else if (supertype.isEnumType) {
        compiler.reportError(superclass, MessageKind.CANNOT_EXTEND_ENUM,
            {'className': element.name, 'enumType': supertype});
        return objectType;
      } else if (!supertype.isInterfaceType) {
        compiler.reportError(superclass.typeName,
            MessageKind.CLASS_NAME_EXPECTED);
        return objectType;
      } else if (isBlackListed(supertype)) {
        compiler.reportError(superclass, MessageKind.CANNOT_EXTEND,
            {'type': supertype});
        return objectType;
      }
    }
    return supertype;
  }

  Link<DartType> resolveInterfaces(NodeList interfaces, Node superclass) {
    Link<DartType> result = const Link<DartType>();
    if (interfaces == null) return result;
    for (Link<Node> link = interfaces.nodes; !link.isEmpty; link = link.tail) {
      DartType interfaceType = resolveType(link.head);
      if (interfaceType != null) {
        if (interfaceType.isMalformed) {
          compiler.reportError(superclass,
              MessageKind.CANNOT_IMPLEMENT_MALFORMED,
              {'className': element.name, 'malformedType': interfaceType});
        } else if (interfaceType.isEnumType) {
          compiler.reportError(superclass,
              MessageKind.CANNOT_IMPLEMENT_ENUM,
              {'className': element.name, 'enumType': interfaceType});
        } else if (!interfaceType.isInterfaceType) {
          // TODO(johnniwinther): Handle dynamic.
          TypeAnnotation typeAnnotation = link.head;
          error(typeAnnotation.typeName, MessageKind.CLASS_NAME_EXPECTED);
        } else {
          if (interfaceType == element.supertype) {
            compiler.reportError(
                superclass,
                MessageKind.DUPLICATE_EXTENDS_IMPLEMENTS,
                {'type': interfaceType});
            compiler.reportError(
                link.head,
                MessageKind.DUPLICATE_EXTENDS_IMPLEMENTS,
                {'type': interfaceType});
          }
          if (result.contains(interfaceType)) {
            compiler.reportError(
                link.head,
                MessageKind.DUPLICATE_IMPLEMENTS,
                {'type': interfaceType});
          }
          result = result.prepend(interfaceType);
          if (isBlackListed(interfaceType)) {
            error(link.head, MessageKind.CANNOT_IMPLEMENT,
                  {'type': interfaceType});
          }
        }
      }
    }
    return result;
  }

  /**
   * Compute the list of all supertypes.
   *
   * The elements of this list are ordered as follows: first the supertype that
   * the class extends, then the implemented interfaces, and then the supertypes
   * of these.  The class [Object] appears only once, at the end of the list.
   *
   * For example, for a class `class C extends S implements I1, I2`, we compute
   *   supertypes(C) = [S, I1, I2] ++ supertypes(S) ++ supertypes(I1)
   *                   ++ supertypes(I2),
   * where ++ stands for list concatenation.
   *
   * This order makes sure that if a class implements an interface twice with
   * different type arguments, the type used in the most specific class comes
   * first.
   */
  void calculateAllSupertypes(BaseClassElementX cls) {
    if (cls.allSupertypesAndSelf != null) return;
    final DartType supertype = cls.supertype;
    if (supertype != null) {
      OrderedTypeSetBuilder allSupertypes = new OrderedTypeSetBuilder(cls);
      // TODO(15296): Collapse these iterations to one when the order is not
      // needed.
      allSupertypes.add(compiler, supertype);
      for (Link<DartType> interfaces = cls.interfaces;
           !interfaces.isEmpty;
           interfaces = interfaces.tail) {
        allSupertypes.add(compiler, interfaces.head);
      }

      addAllSupertypes(allSupertypes, supertype);
      for (Link<DartType> interfaces = cls.interfaces;
           !interfaces.isEmpty;
           interfaces = interfaces.tail) {
        addAllSupertypes(allSupertypes, interfaces.head);
      }
      allSupertypes.add(compiler, cls.computeType(compiler));
      cls.allSupertypesAndSelf = allSupertypes.toTypeSet();
    } else {
      assert(identical(cls, compiler.objectClass));
      cls.allSupertypesAndSelf =
          new OrderedTypeSet.singleton(cls.computeType(compiler));
    }
  }

  /**
   * Adds [type] and all supertypes of [type] to [allSupertypes] while
   * substituting type variables.
   */
  void addAllSupertypes(OrderedTypeSetBuilder allSupertypes,
                        InterfaceType type) {
    ClassElement classElement = type.element;
    Link<DartType> supertypes = classElement.allSupertypes;
    assert(invariant(element, supertypes != null,
        message: "Supertypes not computed on $classElement "
                 "during resolution of $element"));
    while (!supertypes.isEmpty) {
      DartType supertype = supertypes.head;
      allSupertypes.add(compiler, supertype.substByContext(type));
      supertypes = supertypes.tail;
    }
  }

  isBlackListed(DartType type) {
    LibraryElement lib = element.library;
    return
      !identical(lib, compiler.coreLibrary) &&
      !compiler.backend.isBackendLibrary(lib) &&
      (type.isDynamic ||
       identical(type.element, compiler.boolClass) ||
       identical(type.element, compiler.numClass) ||
       identical(type.element, compiler.intClass) ||
       identical(type.element, compiler.doubleClass) ||
       identical(type.element, compiler.stringClass) ||
       identical(type.element, compiler.nullClass));
  }
}

class ClassSupertypeResolver extends CommonResolverVisitor {
  Scope context;
  ClassElement classElement;

  ClassSupertypeResolver(Compiler compiler, ClassElement cls)
    : context = Scope.buildEnclosingScope(cls),
      this.classElement = cls,
      super(compiler);

  void loadSupertype(ClassElement element, Node from) {
    compiler.resolver.loadSupertypes(element, from);
    element.ensureResolved(compiler);
  }

  void visitNodeList(NodeList node) {
    if (node != null) {
      for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
        link.head.accept(this);
      }
    }
  }

  void visitClassNode(ClassNode node) {
    if (node.superclass == null) {
      if (!identical(classElement, compiler.objectClass)) {
        loadSupertype(compiler.objectClass, node);
      }
    } else {
      node.superclass.accept(this);
    }
    visitNodeList(node.interfaces);
  }

  void visitEnum(Enum node) {
    loadSupertype(compiler.objectClass, node);
  }

  void visitMixinApplication(MixinApplication node) {
    node.superclass.accept(this);
    visitNodeList(node.mixins);
  }

  void visitNamedMixinApplication(NamedMixinApplication node) {
    node.superclass.accept(this);
    visitNodeList(node.mixins);
    visitNodeList(node.interfaces);
  }

  void visitTypeAnnotation(TypeAnnotation node) {
    node.typeName.accept(this);
  }

  void visitIdentifier(Identifier node) {
    Element element = lookupInScope(compiler, node, context, node.source);
    if (element != null && element.isClass) {
      loadSupertype(element, node);
    }
  }

  void visitSend(Send node) {
    Identifier prefix = node.receiver.asIdentifier();
    if (prefix == null) {
      error(node.receiver, MessageKind.NOT_A_PREFIX, {'node': node.receiver});
      return;
    }
    Element element = lookupInScope(compiler, prefix, context, prefix.source);
    if (element == null || !identical(element.kind, ElementKind.PREFIX)) {
      error(node.receiver, MessageKind.NOT_A_PREFIX, {'node': node.receiver});
      return;
    }
    PrefixElement prefixElement = element;
    Identifier selector = node.selector.asIdentifier();
    var e = prefixElement.lookupLocalMember(selector.source);
    if (e == null || !e.impliesType) {
      error(node.selector, MessageKind.CANNOT_RESOLVE_TYPE,
            {'typeName': node.selector});
      return;
    }
    loadSupertype(e, node);
  }
}

class VariableDefinitionsVisitor extends CommonResolverVisitor<Identifier> {
  VariableDefinitions definitions;
  ResolverVisitor resolver;
  VariableList variables;

  VariableDefinitionsVisitor(Compiler compiler,
                             this.definitions,
                             this.resolver,
                             this.variables)
      : super(compiler) {
  }

  ResolutionRegistry get registry => resolver.registry;

  Identifier visitSendSet(SendSet node) {
    assert(node.arguments.tail.isEmpty); // Sanity check
    Identifier identifier = node.selector;
    String name = identifier.source;
    VariableDefinitionScope scope =
        new VariableDefinitionScope(resolver.scope, name);
    resolver.visitIn(node.arguments.head, scope);
    if (scope.variableReferencedInInitializer) {
      compiler.reportError(
          identifier, MessageKind.REFERENCE_IN_INITIALIZATION,
          {'variableName': name});
    }
    return identifier;
  }

  Identifier visitIdentifier(Identifier node) {
    // The variable is initialized to null.
    registry.registerInstantiatedClass(compiler.nullClass);
    if (definitions.modifiers.isConst) {
      compiler.reportError(node, MessageKind.CONST_WITHOUT_INITIALIZER);
    }
    if (definitions.modifiers.isFinal &&
        !resolver.allowFinalWithoutInitializer) {
      compiler.reportError(node, MessageKind.FINAL_WITHOUT_INITIALIZER);
    }
    return node;
  }

  visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      Identifier name = visit(link.head);
      LocalVariableElement element = new LocalVariableElementX(
          name.source, resolver.enclosingElement,
          variables, name.token);
      resolver.defineLocalVariable(link.head, element);
      resolver.addToScope(element);
      if (definitions.modifiers.isConst) {
        compiler.enqueuer.resolution.addDeferredAction(element, () {
          compiler.resolver.constantCompiler.compileConstant(element);
        });
      }
    }
  }
}

class ConstructorResolver extends CommonResolverVisitor<Element> {
  final ResolverVisitor resolver;
  bool inConstContext;
  DartType type;

  ConstructorResolver(Compiler compiler, this.resolver,
                      {bool this.inConstContext: false})
      : super(compiler);

  ResolutionRegistry get registry => resolver.registry;

  visitNode(Node node) {
    throw 'not supported';
  }

  failOrReturnErroneousElement(Element enclosing, Node diagnosticNode,
                               String targetName, MessageKind kind,
                               Map arguments) {
    if (kind == MessageKind.CANNOT_FIND_CONSTRUCTOR) {
      registry.registerThrowNoSuchMethod();
    } else {
      registry.registerThrowRuntimeError();
    }
    if (inConstContext) {
      compiler.reportError(diagnosticNode, kind, arguments);
    } else {
      compiler.reportWarning(diagnosticNode, kind, arguments);
    }
    return new ErroneousElementX(kind, arguments, targetName, enclosing);
  }

  Selector createConstructorSelector(String constructorName) {
    return constructorName == ''
        ? new Selector.callDefaultConstructor(
            resolver.enclosingElement.library)
        : new Selector.callConstructor(
            constructorName,
            resolver.enclosingElement.library);
  }

  FunctionElement resolveConstructor(ClassElement cls,
                                     Node diagnosticNode,
                                     String constructorName) {
    cls.ensureResolved(compiler);
    Selector selector = createConstructorSelector(constructorName);
    Element result = cls.lookupConstructor(selector);
    if (result == null) {
      String fullConstructorName = Elements.constructorNameForDiagnostics(
              cls.name,
              constructorName);
      return failOrReturnErroneousElement(
          cls,
          diagnosticNode,
          fullConstructorName,
          MessageKind.CANNOT_FIND_CONSTRUCTOR,
          {'constructorName': fullConstructorName});
    } else if (inConstContext && !result.isConst) {
      error(diagnosticNode, MessageKind.CONSTRUCTOR_IS_NOT_CONST);
    }
    return result;
  }

  Element visitNewExpression(NewExpression node) {
    inConstContext = node.isConst;
    Node selector = node.send.selector;
    Element element = visit(selector);
    assert(invariant(selector, element != null,
        message: 'No element return for $selector.'));
    return finishConstructorReference(element, node.send.selector, node);
  }

  /// Finishes resolution of a constructor reference and records the
  /// type of the constructed instance on [expression].
  FunctionElement finishConstructorReference(Element element,
                                             Node diagnosticNode,
                                             Node expression) {
    assert(invariant(diagnosticNode, element != null,
        message: 'No element return for $diagnosticNode.'));
    // Find the unnamed constructor if the reference resolved to a
    // class.
    if (!Elements.isUnresolved(element) && !element.isConstructor) {
      if (element.isClass) {
        ClassElement cls = element;
        cls.ensureResolved(compiler);
        // The unnamed constructor may not exist, so [e] may become unresolved.
        element = resolveConstructor(cls, diagnosticNode, '');
      } else {
        element = failOrReturnErroneousElement(
            element, diagnosticNode, element.name, MessageKind.NOT_A_TYPE,
            {'node': diagnosticNode});
      }
    }
    if (type == null) {
      if (Elements.isUnresolved(element)) {
        type = const DynamicType();
      } else {
        type = element.enclosingClass.rawType;
      }
    }
    resolver.registry.setType(expression, type);
    return element;
  }

  Element visitTypeAnnotation(TypeAnnotation node) {
    assert(invariant(node, type == null));
    // This is not really resolving a type-annotation, but the name of the
    // constructor. Therefore we allow deferred types.
    type = resolver.resolveTypeAnnotation(node,
                                          malformedIsError: inConstContext,
                                          deferredIsMalformed: false);
    registry.registerRequiredType(type, resolver.enclosingElement);
    return type.element;
  }

  Element visitSend(Send node) {
    Element element = visit(node.receiver);
    assert(invariant(node.receiver, element != null,
        message: 'No element return for $node.receiver.'));
    if (Elements.isUnresolved(element)) return element;
    Identifier name = node.selector.asIdentifier();
    if (name == null) internalError(node.selector, 'unexpected node');

    if (element.isClass) {
      ClassElement cls = element;
      cls.ensureResolved(compiler);
      return resolveConstructor(cls, name, name.source);
    } else if (element.isPrefix) {
      PrefixElement prefix = element;
      element = prefix.lookupLocalMember(name.source);
      element = Elements.unwrap(element, compiler, node);
      if (element == null) {
        return failOrReturnErroneousElement(
            resolver.enclosingElement, name,
            name.source,
            MessageKind.CANNOT_RESOLVE,
            {'name': name});
      } else if (!element.isClass) {
        error(node, MessageKind.NOT_A_TYPE, {'node': name});
      }
    } else {
      internalError(node.receiver, 'unexpected element $element');
    }
    return element;
  }

  Element visitIdentifier(Identifier node) {
    String name = node.source;
    Element element = resolver.reportLookupErrorIfAny(
        lookupInScope(compiler, node, resolver.scope, name), node, name);
    registry.useElement(node, element);
    // TODO(johnniwinther): Change errors to warnings, cf. 11.11.1.
    if (element == null) {
      return failOrReturnErroneousElement(resolver.enclosingElement, node, name,
                                          MessageKind.CANNOT_RESOLVE,
                                          {'name': name});
    } else if (element.isErroneous) {
      return element;
    } else if (element.isTypedef) {
      error(node, MessageKind.CANNOT_INSTANTIATE_TYPEDEF,
            {'typedefName': name});
    } else if (element.isTypeVariable) {
      error(node, MessageKind.CANNOT_INSTANTIATE_TYPE_VARIABLE,
            {'typeVariableName': name});
    } else if (!element.isClass && !element.isPrefix) {
      error(node, MessageKind.NOT_A_TYPE, {'node': name});
    }
    return element;
  }

  /// Assumed to be called by [resolveRedirectingFactory].
  Element visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    Node constructorReference = node.constructorReference;
    return finishConstructorReference(visit(constructorReference),
        constructorReference, node);
  }
}

/// Looks up [name] in [scope] and unwraps the result.
Element lookupInScope(Compiler compiler, Node node,
                      Scope scope, String name) {
  return Elements.unwrap(scope.lookup(name), compiler, node);
}

TreeElements _ensureTreeElements(AnalyzableElementX element) {
  if (element._treeElements == null) {
    element._treeElements = new TreeElementMapping(element);
  }
  return element._treeElements;
}

abstract class AnalyzableElementX implements AnalyzableElement {
  TreeElements _treeElements;

  bool get hasTreeElements => _treeElements != null;

  TreeElements get treeElements {
    assert(invariant(this, _treeElements !=null,
        message: "TreeElements have not been computed for $this."));
    return _treeElements;
  }

  void reuseElement() {
    _treeElements = null;
  }
}

/// The result of resolving a node.
abstract class ResolutionResult {
  Element get element;
}

/// The result for the resolution of a node that points to an [Element].
class ElementResult implements ResolutionResult {
  final Element element;

  // TODO(johnniwinther): Remove this factory constructor when `null` is never
  // passed as an element result.
  factory ElementResult(Element element) {
    return element != null ? new ElementResult.internal(element) : null;
  }

  ElementResult.internal(this.element);

  String toString() => 'ElementResult($element)';
}

/// The result for the resolution of a node that points to an [DartType].
class TypeResult implements ResolutionResult {
  final DartType type;

  TypeResult(this.type) {
    assert(type != null);
  }

  Element get element => type.element;

  String toString() => 'TypeResult($type)';
}

/// The result for the resolution of the `assert` method.
class AssertResult implements ResolutionResult {
  const AssertResult();

  Element get element => null;

  String toString() => 'AssertResult()';
}
