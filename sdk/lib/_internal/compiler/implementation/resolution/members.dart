// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

abstract class TreeElements {
  Element get currentElement;
  Setlet<Node> get superUses;

  /// A set of additional dependencies.  See [registerDependency] below.
  Setlet<Element> get otherDependencies;

  Element operator[](Node node);
  Selector getSelector(Send send);
  Selector getGetterSelectorInComplexSendSet(SendSet node);
  Selector getOperatorSelectorInComplexSendSet(SendSet node);
  DartType getType(Node node);
  void setSelector(Node node, Selector selector);
  void setGetterSelectorInComplexSendSet(SendSet node, Selector selector);
  void setOperatorSelectorInComplexSendSet(SendSet node, Selector selector);
  Selector getIteratorSelector(ForIn node);
  Selector getMoveNextSelector(ForIn node);
  Selector getCurrentSelector(ForIn node);
  Selector setIteratorSelector(ForIn node, Selector selector);
  Selector setMoveNextSelector(ForIn node, Selector selector);
  Selector setCurrentSelector(ForIn node, Selector selector);
  void setConstant(Node node, Constant constant);
  Constant getConstant(Node node);

  /**
   * Returns [:true:] if [node] is a type literal.
   *
   * Resolution marks this by setting the type on the node to be the
   * [:Type:] type.
   */
  bool isTypeLiteral(Send node);

  /// Register additional dependencies required by [currentElement].
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
}

class TreeElementMapping implements TreeElements {
  final Element currentElement;
  final Map<Spannable, Selector> selectors = new Map<Spannable, Selector>();
  final Map<Node, DartType> types = new Map<Node, DartType>();
  final Setlet<Node> superUses = new Setlet<Node>();
  final Setlet<Element> otherDependencies = new Setlet<Element>();
  final Map<Node, Constant> constants = new Map<Node, Constant>();
  final Map<VariableElement, List<Node>> potentiallyMutated =
      new Map<VariableElement, List<Node>>();
  final Map<Node, Map<VariableElement, List<Node>>> potentiallyMutatedIn =
      new Map<Node,  Map<VariableElement, List<Node>>>();
  final Map<VariableElement, List<Node>> potentiallyMutatedInClosure =
      new Map<VariableElement, List<Node>>();
  final Map<Node, Map<VariableElement, List<Node>>> accessedByClosureIn =
      new Map<Node, Map<VariableElement, List<Node>>>();

  final int hashCode = ++hashCodeCounter;
  static int hashCodeCounter = 0;

  TreeElementMapping(this.currentElement);

  operator []=(Node node, Element element) {
    assert(invariant(node, () {
      FunctionExpression functionExpression = node.asFunctionExpression();
      if (functionExpression != null) {
        return !functionExpression.modifiers.isExternal();
      }
      return true;
    }));
    // TODO(johnniwinther): Simplify this invariant to use only declarations in
    // [TreeElements].
    assert(invariant(node, () {
      if (!element.isErroneous() && currentElement != null && element.isPatch) {
        return currentElement.getImplementationLibrary().isPatch;
      }
      return true;
    }));
    // TODO(ahe): Investigate why the invariant below doesn't hold.
    // assert(invariant(node,
    //                  getTreeElement(node) == element ||
    //                  getTreeElement(node) == null,
    //                  message: '${getTreeElement(node)}; $element'));

    setTreeElement(node, element);
  }

  operator [](Node node) => getTreeElement(node);

  void remove(Node node) {
    setTreeElement(node, null);
  }

  void setType(Node node, DartType type) {
    types[node] = type;
  }

  DartType getType(Node node) => types[node];

  void setSelector(Node node, Selector selector) {
    selectors[node] = selector;
  }

  Selector getSelector(Node node) {
    return selectors[node];
  }

  void setGetterSelectorInComplexSendSet(SendSet node, Selector selector) {
    selectors[node.selector] = selector;
  }

  Selector getGetterSelectorInComplexSendSet(SendSet node) {
    return selectors[node.selector];
  }

  void setOperatorSelectorInComplexSendSet(SendSet node, Selector selector) {
    selectors[node.assignmentOperator] = selector;
  }

  Selector getOperatorSelectorInComplexSendSet(SendSet node) {
    return selectors[node.assignmentOperator];
  }

  // The following methods set selectors on the "for in" node. Since
  // we're using three selectors, we need to use children of the node,
  // and we arbitrarily choose which ones.

  Selector setIteratorSelector(ForIn node, Selector selector) {
    selectors[node] = selector;
  }

  Selector getIteratorSelector(ForIn node) {
    return selectors[node];
  }

  Selector setMoveNextSelector(ForIn node, Selector selector) {
    selectors[node.forToken] = selector;
  }

  Selector getMoveNextSelector(ForIn node) {
    return selectors[node.forToken];
  }

  Selector setCurrentSelector(ForIn node, Selector selector) {
    selectors[node.inToken] = selector;
  }

  Selector getCurrentSelector(ForIn node) {
    return selectors[node.inToken];
  }

  void setConstant(Node node, Constant constant) {
    constants[node] = constant;
  }

  Constant getConstant(Node node) {
    return constants[node];
  }

  bool isTypeLiteral(Send node) {
    return getType(node) != null;
  }

  void registerDependency(Element element) {
    otherDependencies.add(element.implementation);
  }

  List<Node> getPotentialMutations(VariableElement element) {
    List<Node> mutations = potentiallyMutated[element];
    if (mutations == null) return const <Node>[];
    return mutations;
  }

  void setPotentiallyMutated(VariableElement element, Node mutationNode) {
    potentiallyMutated.putIfAbsent(element, () => <Node>[]).add(mutationNode);
  }

  List<Node> getPotentialMutationsIn(Node node, VariableElement element) {
    Map<VariableElement, List<Node>> mutationsIn = potentiallyMutatedIn[node];
    if (mutationsIn == null) return const <Node>[];
    List<Node> mutations = mutationsIn[element];
    if (mutations == null) return const <Node>[];
    return mutations;
  }

  void registerPotentiallyMutatedIn(Node contextNode, VariableElement element,
                                    Node mutationNode) {
    Map<VariableElement, List<Node>> mutationMap =
      potentiallyMutatedIn.putIfAbsent(contextNode,
          () => new Map<VariableElement, List<Node>>());
    mutationMap.putIfAbsent(element, () => <Node>[]).add(mutationNode);
  }

  List<Node> getPotentialMutationsInClosure(VariableElement element) {
    List<Node> mutations = potentiallyMutatedInClosure[element];
    if (mutations == null) return const <Node>[];
    return mutations;
  }

  void registerPotentiallyMutatedInClosure(VariableElement element,
                                           Node mutationNode) {
    potentiallyMutatedInClosure.putIfAbsent(
        element, () => <Node>[]).add(mutationNode);
  }

  List<Node> getAccessesByClosureIn(Node node, VariableElement element) {
    Map<VariableElement, List<Node>> accessesIn = accessedByClosureIn[node];
    if (accessesIn == null) return const <Node>[];
    List<Node> accesses = accessesIn[element];
    if (accesses == null) return const <Node>[];
    return accesses;
  }

  void setAccessedByClosureIn(Node contextNode, VariableElement element,
                              Node accessNode) {
    Map<VariableElement, List<Node>> accessMap =
        accessedByClosureIn.putIfAbsent(contextNode,
          () => new Map<VariableElement, List<Node>>());
    accessMap.putIfAbsent(element, () => <Node>[]).add(accessNode);
  }

  String toString() => 'TreeElementMapping($currentElement)';
}

class ResolverTask extends CompilerTask {
  ResolverTask(Compiler compiler) : super(compiler);

  String get name => 'Resolver';

  TreeElements resolve(Element element) {
    return measure(() {
      if (Elements.isErroneousElement(element)) return null;

      for (MetadataAnnotation metadata in element.metadata) {
        metadata.ensureResolved(compiler);
      }

      ElementKind kind = element.kind;
      if (identical(kind, ElementKind.GENERATIVE_CONSTRUCTOR) ||
          identical(kind, ElementKind.FUNCTION) ||
          identical(kind, ElementKind.GETTER) ||
          identical(kind, ElementKind.SETTER)) {
        return resolveMethodElement(element);
      }

      if (identical(kind, ElementKind.FIELD)) return resolveField(element);

      if (identical(kind, ElementKind.PARAMETER) ||
          identical(kind, ElementKind.FIELD_PARAMETER)) {
        return resolveParameter(element);
      }
      if (element.isClass()) {
        ClassElement cls = element;
        cls.ensureResolved(compiler);
        return null;
      } else if (element.isTypedef()) {
        TypedefElement typdef = element;
        return resolveTypedef(typdef);
      } else if (element.isTypeVariable()) {
        element.computeType(compiler);
        return null;
      }

      compiler.unimplemented("resolve($element)",
                             node: element.parseNode(compiler));
    });
  }

  String constructorNameForDiagnostics(String className,
                                       String constructorName) {
    String classNameString = className;
    String constructorNameString = constructorName;
    return (constructorName == '')
        ? classNameString
        : "$classNameString.$constructorNameString";
   }

  void resolveRedirectingConstructor(InitializerResolver resolver,
                                     Node node,
                                     FunctionElement constructor,
                                     FunctionElement redirection) {
    Setlet<FunctionElement> seen = new Setlet<FunctionElement>();
    seen.add(constructor);
    while (redirection != null) {
      if (seen.contains(redirection)) {
        resolver.visitor.error(node, MessageKind.REDIRECTING_CONSTRUCTOR_CYCLE);
        return;
      }
      seen.add(redirection);

      if (redirection.isPatched) {
        checkMatchingPatchSignatures(constructor, redirection.patch);
        redirection = redirection.patch;
      }
      redirection = resolver.visitor.resolveConstructorRedirection(redirection);
    }
  }

  void checkMatchingPatchParameters(FunctionElement origin,
                                    Link<Element> originParameters,
                                    Link<Element> patchParameters) {
    while (!originParameters.isEmpty) {
      Element originParameter = originParameters.head;
      Element patchParameter = patchParameters.head;
      // Hack: Use unparser to test parameter equality. This only works because
      // we are restricting patch uses and the approach cannot be used
      // elsewhere.
      String originParameterText =
          originParameter.parseNode(compiler).toString();
      String patchParameterText =
          patchParameter.parseNode(compiler).toString();
      if (originParameterText != patchParameterText) {
        compiler.reportError(
            originParameter.parseNode(compiler),
            MessageKind.PATCH_PARAMETER_MISMATCH,
            {'methodName': origin.name,
             'originParameter': originParameterText,
             'patchParameter': patchParameterText});
        compiler.reportMessage(
            compiler.spanFromSpannable(patchParameter),
            MessageKind.PATCH_POINT_TO_PARAMETER.error(
                {'parameterName': patchParameter.name}),
            Diagnostic.INFO);
      }
      DartType originParameterType = originParameter.computeType(compiler);
      DartType patchParameterType = patchParameter.computeType(compiler);
      if (originParameterType != patchParameterType) {
        compiler.reportError(
            originParameter.parseNode(compiler),
            MessageKind.PATCH_PARAMETER_TYPE_MISMATCH,
            {'methodName': origin.name,
             'parameterName': originParameter.name,
             'originParameterType': originParameterType,
             'patchParameterType': patchParameterType});
        compiler.reportMessage(
            compiler.spanFromSpannable(patchParameter),
            MessageKind.PATCH_POINT_TO_PARAMETER.error(
                {'parameterName': patchParameter.name}),
            Diagnostic.INFO);
      }

      originParameters = originParameters.tail;
      patchParameters = patchParameters.tail;
    }
  }

  void checkMatchingPatchSignatures(FunctionElement origin,
                                    FunctionElement patch) {
    // TODO(johnniwinther): Show both origin and patch locations on errors.
    FunctionExpression originTree = compiler.withCurrentElement(origin, () {
      return origin.parseNode(compiler);
    });
    FunctionSignature originSignature = compiler.withCurrentElement(origin, () {
      return origin.computeSignature(compiler);
    });
    FunctionExpression patchTree = compiler.withCurrentElement(patch, () {
      return patch.parseNode(compiler);
    });
    FunctionSignature patchSignature = compiler.withCurrentElement(patch, () {
      return patch.computeSignature(compiler);
    });

    if (originSignature.returnType != patchSignature.returnType) {
      compiler.withCurrentElement(patch, () {
        Node errorNode =
            patchTree.returnType != null ? patchTree.returnType : patchTree;
        error(errorNode, MessageKind.PATCH_RETURN_TYPE_MISMATCH,
              {'methodName': origin.name,
               'originReturnType': originSignature.returnType,
               'patchReturnType': patchSignature.returnType});
      });
    }
    if (originSignature.requiredParameterCount !=
        patchSignature.requiredParameterCount) {
      compiler.withCurrentElement(patch, () {
        error(patchTree,
              MessageKind.PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH,
              {'methodName': origin.name,
               'originParameterCount': originSignature.requiredParameterCount,
               'patchParameterCount': patchSignature.requiredParameterCount});
      });
    } else {
      checkMatchingPatchParameters(origin,
                                   originSignature.requiredParameters,
                                   patchSignature.requiredParameters);
    }
    if (originSignature.optionalParameterCount != 0 &&
        patchSignature.optionalParameterCount != 0) {
      if (originSignature.optionalParametersAreNamed !=
          patchSignature.optionalParametersAreNamed) {
        compiler.withCurrentElement(patch, () {
          error(patchTree,
                MessageKind.PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH,
                {'methodName': origin.name});
        });
      }
    }
    if (originSignature.optionalParameterCount !=
        patchSignature.optionalParameterCount) {
      compiler.withCurrentElement(patch, () {
        error(patchTree,
              MessageKind.PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH,
              {'methodName': origin.name,
               'originParameterCount': originSignature.optionalParameterCount,
               'patchParameterCount': patchSignature.optionalParameterCount});
      });
    } else {
      checkMatchingPatchParameters(origin,
                                   originSignature.optionalParameters,
                                   patchSignature.optionalParameters);
    }
  }

  TreeElements resolveMethodElement(FunctionElement element) {
    assert(invariant(element, element.isDeclaration));
    return compiler.withCurrentElement(element, () {
      bool isConstructor =
          identical(element.kind, ElementKind.GENERATIVE_CONSTRUCTOR);
      TreeElements elements =
          compiler.enqueuer.resolution.getCachedElements(element);
      if (elements != null) {
        // TODO(karlklose): Remove the check for [isConstructor]. [elememts]
        // should never be non-null, not even for constructors.
        assert(invariant(element, isConstructor,
            message: 'Non-constructor element $element '
                     'has already been analyzed.'));
        return elements;
      }
      if (element.isSynthesized) {
        Element target = element.targetConstructor;
        // Ensure the signature of the synthesized element is
        // resolved. This is the only place where the resolver is
        // seeing this element.
        element.computeSignature(compiler);
        if (!target.isErroneous()) {
          compiler.enqueuer.resolution.registerStaticUse(
              element.targetConstructor);
        }
        return new TreeElementMapping(element);
      }
      if (element.isPatched) {
        checkMatchingPatchSignatures(element, element.patch);
        element = element.patch;
      }
      return compiler.withCurrentElement(element, () {
        FunctionExpression tree = element.parseNode(compiler);
        if (tree.modifiers.isExternal()) {
          error(tree, MessageKind.PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION);
          return null;
        }
        if (isConstructor || element.isFactoryConstructor()) {
          if (tree.returnType != null) {
            error(tree, MessageKind.CONSTRUCTOR_WITH_RETURN_TYPE);
          }
          if (element.modifiers.isConst() &&
              tree.hasBody() &&
              !tree.isRedirectingFactory) {
            compiler.reportError(tree, MessageKind.CONST_CONSTRUCTOR_HAS_BODY);
          }
        }

        ResolverVisitor visitor = visitorFor(element);
        visitor.useElement(tree, element);
        visitor.setupFunction(tree, element);

        if (isConstructor && !element.isForwardingConstructor) {
          // Even if there is no initializer list we still have to do the
          // resolution in case there is an implicit super constructor call.
          InitializerResolver resolver = new InitializerResolver(visitor);
          FunctionElement redirection =
              resolver.resolveInitializers(element, tree);
          if (redirection != null) {
            resolveRedirectingConstructor(resolver, tree, element, redirection);
          }
        } else if (element.isForwardingConstructor) {
          // Initializers will be checked on the original constructor.
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
        TreeElements resolutionTree = visitor.mapping;
        ClassElement enclosingClass = element.getEnclosingClass();
        if (enclosingClass != null) {
          Set<MixinApplicationElement> mixinUses =
              compiler.world.mixinUses[enclosingClass];
          if (mixinUses != null) {
            ClassElement mixin = enclosingClass;
            for (MixinApplicationElement mixinApplication in mixinUses) {
              checkMixinSuperUses(resolutionTree, mixinApplication, mixin);
            }
          }
        }
        return resolutionTree;
      });
    });
  }

  /// This method should only be used by this library (or tests of
  /// this library).
  ResolverVisitor visitorFor(Element element) {
    var mapping = new TreeElementMapping(element);
    return new ResolverVisitor(compiler, element, mapping);
  }

  void visitBody(ResolverVisitor visitor, Statement body) {
    if (!compiler.analyzeSignaturesOnly) {
      visitor.visit(body);
    }
  }

  TreeElements resolveField(VariableElement element) {
    Node tree = element.parseNode(compiler);
    if(element.modifiers.isStatic() && element.variables.isTopLevel()) {
      error(element.modifiers.getStatic(),
            MessageKind.TOP_LEVEL_VARIABLE_DECLARED_STATIC);
    }
    ResolverVisitor visitor = visitorFor(element);
    visitor.useElement(tree, element);

    SendSet send = tree.asSendSet();
    Modifiers modifiers = element.modifiers;
    if (send != null) {
      // TODO(johnniwinther): Avoid analyzing initializers if
      // [Compiler.analyzeSignaturesOnly] is set.
      visitor.visit(send.arguments.head);
    } else if (modifiers.isConst()) {
      compiler.reportError(element, MessageKind.CONST_WITHOUT_INITIALIZER);
    } else if (modifiers.isFinal() && !element.isInstanceMember()) {
      compiler.reportError(element, MessageKind.FINAL_WITHOUT_INITIALIZER);
    }

    if (Elements.isStaticOrTopLevelField(element)) {
      visitor.addDeferredAction(element, () {
        compiler.constantHandler.compileVariable(
            element, isConst: element.modifiers.isConst());
      });
      if (tree.asSendSet() != null) {
        if (!element.modifiers.isConst()) {
          // TODO(johnniwinther): Determine the const-ness eagerly to avoid
          // unnecessary registrations.
          compiler.backend.registerLazyField(visitor.mapping);
        }
      } else {
        compiler.enqueuer.resolution.registerInstantiatedClass(
            compiler.nullClass, visitor.mapping);
      }
    }

    // Perform various checks as side effect of "computing" the type.
    element.computeType(compiler);

    return visitor.mapping;
  }

  TreeElements resolveParameter(Element element) {
    Node tree = element.parseNode(compiler);
    ResolverVisitor visitor = visitorFor(element.enclosingElement);
    initializerDo(tree, visitor.visit);
    return visitor.mapping;
  }

  DartType resolveTypeAnnotation(Element element, TypeAnnotation annotation) {
    DartType type = resolveReturnType(element, annotation);
    if (type == compiler.types.voidType) {
      error(annotation, MessageKind.VOID_NOT_ALLOWED);
    }
    return type;
  }

  DartType resolveReturnType(Element element, TypeAnnotation annotation) {
    if (annotation == null) return compiler.types.dynamicType;
    DartType result = visitorFor(element).resolveTypeAnnotation(annotation);
    if (result == null) {
      // TODO(karklose): warning.
      return compiler.types.dynamicType;
    }
    return result;
  }

  void resolveRedirectionChain(FunctionElement constructor, Spannable node) {
    FunctionElementX current = constructor;
    List<Element> seen = new List<Element>();
    // Follow the chain of redirections and check for cycles.
    while (current != current.defaultImplementation) {
      if (current.internalRedirectionTarget != null) {
        // We found a constructor that already has been processed.
        current = current.internalRedirectionTarget;
        break;
      }
      Element target = current.defaultImplementation;
      if (seen.contains(target)) {
        error(node, MessageKind.CYCLIC_REDIRECTING_FACTORY);
        break;
      }
      seen.add(current);
      current = target;
    }
    // [current] is now the actual target of the redirections.  Run through
    // the constructors again and set their [redirectionTarget], so that we
    // do not have to run the loop for these constructors again.
    while (!seen.isEmpty) {
      FunctionElementX factory = seen.removeLast();
      factory.redirectionTarget = current;
    }
  }

  /**
   * Load and resolve the supertypes of [cls].
   *
   * Warning: do not call this method directly. It should only be
   * called by [resolveClass] and [ClassSupertypeResolver].
   */
  void loadSupertypes(ClassElement cls, Spannable from) {
    compiler.withCurrentElement(cls, () => measure(() {
      if (cls.supertypeLoadState == STATE_DONE) return;
      if (cls.supertypeLoadState == STATE_STARTED) {
        compiler.reportError(from, MessageKind.CYCLIC_CLASS_HIERARCHY,
                                 {'className': cls.name});
        cls.supertypeLoadState = STATE_DONE;
        cls.allSupertypes = const Link<DartType>().prepend(
            compiler.objectClass.computeType(compiler));
        cls.supertype = cls.allSupertypes.head;
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
  ClassElement currentlyResolvedClass;
  Queue<ClassElement> pendingClassesToBeResolved = new Queue<ClassElement>();

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
  void resolveClass(ClassElement element) {
    ClassElement previousResolvedClass = currentlyResolvedClass;
    currentlyResolvedClass = element;
    // TODO(johnniwinther): Store the mapping in the resolution enqueuer.
    TreeElementMapping mapping = new TreeElementMapping(element);
    resolveClassInternal(element, mapping);
    if (previousResolvedClass == null) {
      while (!pendingClassesToBeResolved.isEmpty) {
        pendingClassesToBeResolved.removeFirst().ensureResolved(compiler);
      }
    }
    currentlyResolvedClass = previousResolvedClass;
  }

  void _ensureClassWillBeResolved(ClassElement element) {
    if (currentlyResolvedClass == null) {
      element.ensureResolved(compiler);
    } else {
      pendingClassesToBeResolved.add(element);
    }
  }

  void resolveClassInternal(ClassElement element, TreeElementMapping mapping) {
    if (!element.isPatch) {
      compiler.withCurrentElement(element, () => measure(() {
        assert(element.resolutionState == STATE_NOT_STARTED);
        element.resolutionState = STATE_STARTED;
        Node tree = element.parseNode(compiler);
        loadSupertypes(element, tree);

        ClassResolverVisitor visitor =
            new ClassResolverVisitor(compiler, element, mapping);
        visitor.visit(tree);
        element.resolutionState = STATE_DONE;
        compiler.onClassResolved(element);
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
      // Copy class hiearchy from origin.
      element.supertype = element.origin.supertype;
      element.interfaces = element.origin.interfaces;
      element.allSupertypes = element.origin.allSupertypes;
      // Stepwise assignment to ensure invariant.
      element.supertypeLoadState = STATE_STARTED;
      element.supertypeLoadState = STATE_DONE;
      element.resolutionState = STATE_DONE;
      // TODO(johnniwinther): Check matching type variables and
      // empty extends/implements clauses.
    }
    for (MetadataAnnotation metadata in element.metadata) {
      metadata.ensureResolved(compiler);
    }

    // Force resolution of metadata on non-instance members since they may be
    // inspected by the backend while emitting. Metadata on instance members is
    // handled as a result of processing instantiated class members in the
    // enqueuer.
    // TODO(ahe): Avoid this eager resolution.
    element.forEachMember((_, Element member) {
      if (!member.isInstanceMember()) {
        compiler.withCurrentElement(member, () {
          for (MetadataAnnotation metadata in member.metadata) {
            metadata.ensureResolved(compiler);
          }
        });
      }
    });
  }

  void checkClass(ClassElement element) {
    if (element.isMixinApplication) {
      checkMixinApplication(element);
    } else {
      checkClassMembers(element);
    }
  }

  void checkMixinApplication(MixinApplicationElement mixinApplication) {
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

    // Check that the mixed in class has Object as its superclass.
    if (!mixin.superclass.isObject(compiler)) {
      compiler.reportError(mixin, MessageKind.ILLEGAL_MIXIN_SUPERCLASS);
    }

    // Check that the mixed in class doesn't have any constructors and
    // make sure we aren't mixing in methods that use 'super'.
    mixin.forEachLocalMember((Element member) {
      if (member.isGenerativeConstructor() && !member.isSynthesized) {
        compiler.reportError(member, MessageKind.ILLEGAL_MIXIN_CONSTRUCTOR);
      } else {
        // Get the resolution tree and check that the resolved member
        // doesn't use 'super'. This is the part of the 'super' mixin
        // check that happens when a function is resolved before the
        // mixin application has been performed.
        checkMixinSuperUses(
            compiler.enqueuer.resolution.resolvedElements[member],
            mixinApplication,
            mixin);
      }
    });
  }

  void checkMixinSuperUses(TreeElements resolutionTree,
                           MixinApplicationElement mixinApplication,
                           ClassElement mixin) {
    if (resolutionTree == null) return;
    Setlet<Node> superUses = resolutionTree.superUses;
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
    if (cls.isObject(compiler)) return;
    // TODO(johnniwinther): Should this be done on the implementation element as
    // well?
    List<Element> constConstructors = <Element>[];
    List<Element> nonFinalInstanceFields = <Element>[];
    cls.forEachMember((holder, member) {
      compiler.withCurrentElement(member, () {
        // Perform various checks as side effect of "computing" the type.
        member.computeType(compiler);

        // Check modifiers.
        if (member.isFunction() && member.modifiers.isFinal()) {
          compiler.reportError(
              member, MessageKind.ILLEGAL_FINAL_METHOD_MODIFIER);
        }
        if (member.isConstructor()) {
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
          if (member.modifiers.isConst()) {
            constConstructors.add(member);
          }
        }
        if (member.isField()) {
          if (!member.modifiers.isStatic() &&
              !member.modifiers.isFinal()) {
            nonFinalInstanceFields.add(member);
          }
        }
        checkAbstractField(member);
        checkValidOverride(member, cls.lookupSuperMember(member.name));
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
    if (!member.isGetter()) return;

    // Find the associated abstract field.
    ClassElement classElement = member.getEnclosingClass();
    Element lookupElement = classElement.lookupLocalMember(member.name);
    if (lookupElement == null) {
      compiler.internalErrorOnElement(member,
                                      "No abstract field for accessor");
    } else if (!identical(lookupElement.kind, ElementKind.ABSTRACT_FIELD)) {
       compiler.internalErrorOnElement(
           member, "Inaccessible abstract field for accessor");
    }
    AbstractFieldElement field = lookupElement;

    if (field.getter == null) return;
    if (field.setter == null) return;
    int getterFlags = field.getter.modifiers.flags | Modifiers.FLAG_ABSTRACT;
    int setterFlags = field.setter.modifiers.flags | Modifiers.FLAG_ABSTRACT;
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
    FunctionSignature signature = function.computeSignature(compiler);
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
      compiler.internalErrorOnElement(function,
          'Unexpected user defined operator $value');
    }
    checkArity(function, requiredParameterCount, messageKind, isMinus);
  }

  void checkOverrideHashCode(FunctionElement operatorEquals) {
    if (operatorEquals.isAbstract(compiler)) return;
    ClassElement cls = operatorEquals.getEnclosingClass();
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
    FunctionExpression node = function.parseNode(compiler);
    FunctionSignature signature = function.computeSignature(compiler);
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
         'className': contextElement.getEnclosingClass().name});
    compiler.reportMessage(
        compiler.spanFromElement(contextElement),
        contextMessage.error(),
        Diagnostic.INFO);
  }

  void checkValidOverride(Element member, Element superMember) {
    if (superMember == null) return;
    if (member.modifiers.isStatic()) {
      reportErrorWithContext(
          member, MessageKind.NO_STATIC_OVERRIDE,
          superMember, MessageKind.NO_STATIC_OVERRIDE_CONT);
    } else {
      FunctionElement superFunction = superMember.asFunctionElement();
      FunctionElement function = member.asFunctionElement();
      if (superFunction == null || superFunction.isAccessor()) {
        // Field or accessor in super.
        if (function != null && !function.isAccessor()) {
          // But a plain method in this class.
          reportErrorWithContext(
              member, MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD,
              superMember, MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD_CONT);
        }
      } else {
        // Instance method in super.
        if (function == null || function.isAccessor()) {
          // But a field (or accessor) in this class.
          reportErrorWithContext(
              member, MessageKind.CANNOT_OVERRIDE_METHOD_WITH_FIELD,
              superMember, MessageKind.CANNOT_OVERRIDE_METHOD_WITH_FIELD_CONT);
        } else {
          // Both are plain instance methods.
          if (superFunction.requiredParameterCount(compiler) !=
              function.requiredParameterCount(compiler)) {
          reportErrorWithContext(
              member,
              MessageKind.BAD_ARITY_OVERRIDE,
              superMember,
              MessageKind.BAD_ARITY_OVERRIDE_CONT);
          }
          // TODO(ahe): Check optional parameters.
        }
      }
    }
  }

  FunctionSignature resolveSignature(FunctionElement element) {
    MessageKind defaultValuesError = null;
    if (element.isFactoryConstructor()) {
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
          defaultValuesError: defaultValuesError));
    });
  }

  FunctionSignature resolveFunctionExpression(Element element,
                                              FunctionExpression node) {
    return measure(() => SignatureResolver.analyze(
      compiler, node.parameters, node.returnType, element));
  }

  TreeElements resolveTypedef(TypedefElementX element) {
    if (element.isResolved) return element.mapping;
    TreeElementMapping mapping = new TreeElementMapping(element);
    // TODO(johnniwinther): Store the mapping in the resolution enqueuer.
    element.mapping = mapping;
    return compiler.withCurrentElement(element, () {
      return measure(() {
        Typedef node =
          compiler.parser.measure(() => element.parseNode(compiler));
        TypedefResolverVisitor visitor =
          new TypedefResolverVisitor(compiler, element, mapping);
        visitor.visit(node);

        return mapping;
      });
    });
  }

  FunctionType computeFunctionType(Element element,
                                   FunctionSignature signature) {
    var parameterTypes = new LinkBuilder<DartType>();
    for (Element parameter in signature.requiredParameters) {
       parameterTypes.addLast(parameter.computeType(compiler));
    }
    var optionalParameterTypes = const Link<DartType>();
    var namedParameters = const Link<String>();
    var namedParameterTypes = const Link<DartType>();
    if (signature.optionalParametersAreNamed) {
      var namedParametersBuilder = new LinkBuilder<String>();
      var namedParameterTypesBuilder = new LinkBuilder<DartType>();
      for (Element parameter in signature.orderedOptionalParameters) {
        namedParametersBuilder.addLast(parameter.name);
        namedParameterTypesBuilder.addLast(parameter.computeType(compiler));
      }
      namedParameters = namedParametersBuilder.toLink();
      namedParameterTypes = namedParameterTypesBuilder.toLink();
    } else {
      var optionalParameterTypesBuilder = new LinkBuilder<DartType>();
      for (Element parameter in signature.optionalParameters) {
        optionalParameterTypesBuilder.addLast(parameter.computeType(compiler));
      }
      optionalParameterTypes = optionalParameterTypesBuilder.toLink();
    }
    return new FunctionType(element,
        signature.returnType,
        parameterTypes.toLink(),
        optionalParameterTypes,
        namedParameters,
        namedParameterTypes);
  }

  void resolveMetadataAnnotation(PartialMetadataAnnotation annotation) {
    compiler.withCurrentElement(annotation.annotatedElement, () => measure(() {
      assert(annotation.resolutionState == STATE_NOT_STARTED);
      annotation.resolutionState = STATE_STARTED;

      Node node = annotation.parseNode(compiler);
      Element annotatedElement = annotation.annotatedElement;
      Element context = annotatedElement.enclosingElement;
      if (context == null) {
        context = annotatedElement;
      }
      ResolverVisitor visitor = visitorFor(context);
      node.accept(visitor);
      annotation.value = compiler.constantHandler.compileNodeWithDefinitions(
          node, visitor.mapping, isConst: true);
      compiler.backend.registerMetadataConstant(annotation.value,
                                                visitor.mapping);

      annotation.resolutionState = STATE_DONE;
    }));
  }

  error(Spannable node, MessageKind kind, [arguments = const {}]) {
    // TODO(ahe): Make non-fatal.
    compiler.reportFatalError(node, kind, arguments);
  }
}

class ConstantMapper extends Visitor {
  final Map<Constant, Node> constantToNodeMap = new Map<Constant, Node>();
  final CompileTimeConstantEvaluator evaluator;

  ConstantMapper(ConstantHandler handler,
                 TreeElements elements,
                 Compiler compiler)
      : evaluator = new CompileTimeConstantEvaluator(
          handler, elements, compiler, isConst: false);

  visitNode(Node node) {
    Constant constant = evaluator.evaluate(node);
    if (constant != null) constantToNodeMap[constant] = node;
    node.visitChildren(this);
  }
}

class InitializerResolver {
  final ResolverVisitor visitor;
  final Map<Element, Node> initialized;
  Link<Node> initializers;
  bool hasSuper;

  InitializerResolver(this.visitor)
    : initialized = new Map<Element, Node>(), hasSuper = false;

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

  void checkForDuplicateInitializers(Element field, Node init) {
    // [field] can be null if it could not be resolved.
    if (field == null) return;
    String name = field.name;
    if (initialized.containsKey(field)) {
      reportDuplicateInitializerError(field, init, initialized[field]);
    } else if (field.modifiers.isFinal()) {
      Node fieldNode = field.parseNode(visitor.compiler).asSendSet();
      if (fieldNode != null) {
        reportDuplicateInitializerError(field, init, fieldNode);
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
      target = constructor.getEnclosingClass().lookupLocalMember(name);
      if (target == null) {
        error(selector, MessageKind.CANNOT_RESOLVE.error, {'name': name});
      } else if (target.kind != ElementKind.FIELD) {
        error(selector, MessageKind.NOT_A_FIELD, {'fieldName': name});
      } else if (!target.isInstanceMember()) {
        error(selector, MessageKind.INIT_STATIC_FIELD, {'fieldName': name});
      }
    } else {
      error(init, MessageKind.INVALID_RECEIVER_IN_INITIALIZER);
    }
    visitor.useElement(init, target);
    visitor.world.registerStaticUse(target);
    checkForDuplicateInitializers(target, init);
    // Resolve initializing value.
    visitor.visitInStaticContext(init.arguments.head);
  }

  ClassElement getSuperOrThisLookupTarget(FunctionElement constructor,
                                          bool isSuperCall,
                                          Node diagnosticNode) {
    ClassElement lookupTarget = constructor.getEnclosingClass();
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
    Selector selector = visitor.mapping.getSelector(call);
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

    visitor.useElement(call, calledConstructor);
    visitor.world.registerStaticUse(calledConstructor);
    return calledConstructor;
  }

  void resolveImplicitSuperConstructorSend(FunctionElement constructor,
                                           FunctionExpression functionNode) {
    // If the class has a super resolve the implicit super call.
    ClassElement classElement = constructor.getEnclosingClass();
    ClassElement superClass = classElement.superclass;
    if (classElement != visitor.compiler.objectClass) {
      assert(superClass != null);
      assert(superClass.resolutionState == STATE_DONE);
      String constructorName = '';
      Selector callToMatch = new Selector.call(
          constructorName,
          classElement.getLibrary(),
          0);

      final bool isSuperCall = true;
      ClassElement lookupTarget = getSuperOrThisLookupTarget(constructor,
                                                             isSuperCall,
                                                             functionNode);
      Selector constructorSelector = new Selector.callDefaultConstructor(
          visitor.enclosingElement.getLibrary());
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

      visitor.world.registerStaticUse(calledConstructor);
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
        || !lookedupConstructor.isGenerativeConstructor()) {
      var fullConstructorName =
          visitor.compiler.resolver.constructorNameForDiagnostics(
              className,
              constructorSelector.name);
      MessageKind kind = isImplicitSuperCall
          ? MessageKind.CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT
          : MessageKind.CANNOT_RESOLVE_CONSTRUCTOR;
      visitor.compiler.reportError(
          diagnosticNode, kind, {'constructorName': fullConstructorName});
    } else {
      if (!call.applies(lookedupConstructor, visitor.compiler)) {
        MessageKind kind = isImplicitSuperCall
                           ? MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT
                           : MessageKind.NO_MATCHING_CONSTRUCTOR;
        visitor.compiler.reportError(diagnosticNode, kind);
      } else if (caller.modifiers.isConst()
                 && !lookedupConstructor.modifiers.isConst()) {
        visitor.compiler.reportError(
            diagnosticNode, MessageKind.CONST_CALLS_NON_CONST);
      }
    }
  }

  FunctionElement resolveRedirection(FunctionElement constructor,
                                     FunctionExpression functionNode) {
    if (functionNode.initializers == null) return null;
    Link<Node> link = functionNode.initializers.nodes;
    if (!link.isEmpty && Initializers.isConstructorRedirect(link.head)) {
      return resolveSuperOrThisForSend(constructor, functionNode, link.head);
    }
    return null;
  }

  /**
   * Resolve all initializers of this constructor. In the case of a redirecting
   * constructor, the resolved constructor's function element is returned.
   */
  FunctionElement resolveInitializers(FunctionElement constructor,
                                      FunctionExpression functionNode) {
    // Keep track of all "this.param" parameters specified for constructor so
    // that we can ensure that fields are initialized only once.
    FunctionSignature functionParameters =
        constructor.computeSignature(visitor.compiler);
    functionParameters.forEachParameter((Element element) {
      if (identical(element.kind, ElementKind.FIELD_PARAMETER)) {
        FieldParameterElement fieldParameter = element;
        checkForDuplicateInitializers(fieldParameter.fieldElement,
                                      element.parseNode(visitor.compiler));
      }
    });

    if (functionNode.initializers == null) {
      initializers = const Link<Node>();
    } else {
      initializers = functionNode.initializers.nodes;
    }
    FunctionElement result;
    bool resolvedSuper = false;
    for (Link<Node> link = initializers;
         !link.isEmpty;
         link = link.tail) {
      if (link.head.asSendSet() != null) {
        final SendSet init = link.head.asSendSet();
        resolveFieldInitializer(constructor, init);
      } else if (link.head.asSend() != null) {
        final Send call = link.head.asSend();
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
          if (functionNode.hasBody() && !constructor.modifiers.isConst()) {
            error(functionNode, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_BODY);
          }
          // Check that there are no other initializers.
          if (!initializers.tail.isEmpty) {
            error(call, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER);
          }
          // Check that there are no field initializing parameters.
          Compiler compiler = visitor.compiler;
          FunctionSignature signature = constructor.computeSignature(compiler);
          signature.forEachParameter((Element parameter) {
            if (parameter.isFieldParameter()) {
              Node node = parameter.parseNode(compiler);
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
    cancel(node,
           'internal error: Unhandled node: ${node.getObjectDescription()}');
  }

  R visitEmptyStatement(Node node) => null;

  /** Convenience method for visiting nodes that may be null. */
  R visit(Node node) => (node == null) ? null : node.accept(this);

  void error(Node node, MessageKind kind, [Map arguments = const {}]) {
    compiler.reportFatalError(node, kind, arguments);
  }

  void dualError(Node node, DualKind kind, [Map arguments = const {}]) {
    error(node, kind.error, arguments);
  }

  void warning(Node node, MessageKind kind, [Map arguments = const {}]) {
    ResolutionWarning message =
        new ResolutionWarning(kind, arguments, compiler.terseDiagnostics);
    compiler.reportWarning(node, message);
  }

  void dualWarning(Node node, DualKind kind, [Map arguments = const {}]) {
    warning(node, kind.warning, arguments);
  }

  void cancel(Node node, String message) {
    compiler.cancel(message, node: node);
  }

  void internalError(Node node, String message) {
    compiler.internalError(message, node: node);
  }

  void unimplemented(Node node, String message) {
    compiler.unimplemented(message, node: node);
  }

  void addDeferredAction(Element element, DeferredAction action) {
    compiler.enqueuer.resolution.addDeferredAction(element, action);
  }
}

abstract class LabelScope {
  LabelScope get outer;
  LabelElement lookup(String label);
}

class LabeledStatementLabelScope implements LabelScope {
  final LabelScope outer;
  final Map<String, LabelElement> labels;
  LabeledStatementLabelScope(this.outer, this.labels);
  LabelElement lookup(String labelName) {
    LabelElement label = labels[labelName];
    if (label != null) return label;
    return outer.lookup(labelName);
  }
}

class SwitchLabelScope implements LabelScope {
  final LabelScope outer;
  final Map<String, LabelElement> caseLabels;

  SwitchLabelScope(this.outer, this.caseLabels);

  LabelElement lookup(String labelName) {
    LabelElement result = caseLabels[labelName];
    if (result != null) return result;
    return outer.lookup(labelName);
  }
}

class EmptyLabelScope implements LabelScope {
  const EmptyLabelScope();
  LabelElement lookup(String label) => null;
  LabelScope get outer {
    throw 'internal error: empty label scope has no outer';
  }
}

class StatementScope {
  LabelScope labels;
  Link<TargetElement> breakTargetStack;
  Link<TargetElement> continueTargetStack;
  // Used to provide different numbers to statements if one is inside the other.
  // Can be used to make otherwise duplicate labels unique.
  int nestingLevel = 0;

  StatementScope()
      : labels = const EmptyLabelScope(),
        breakTargetStack = const Link<TargetElement>(),
        continueTargetStack = const Link<TargetElement>();

  LabelElement lookupLabel(String label) {
    return labels.lookup(label);
  }

  TargetElement currentBreakTarget() =>
    breakTargetStack.isEmpty ? null : breakTargetStack.head;

  TargetElement currentContinueTarget() =>
    continueTargetStack.isEmpty ? null : continueTargetStack.head;

  void enterLabelScope(Map<String, LabelElement> elements) {
    labels = new LabeledStatementLabelScope(labels, elements);
    nestingLevel++;
  }

  void exitLabelScope() {
    nestingLevel--;
    labels = labels.outer;
  }

  void enterLoop(TargetElement element) {
    breakTargetStack = breakTargetStack.prepend(element);
    continueTargetStack = continueTargetStack.prepend(element);
    nestingLevel++;
  }

  void exitLoop() {
    nestingLevel--;
    breakTargetStack = breakTargetStack.tail;
    continueTargetStack = continueTargetStack.tail;
  }

  void enterSwitch(TargetElement breakElement,
                   Map<String, LabelElement> continueElements) {
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

  Element resolveTypeName(Scope scope,
                          Identifier prefixName,
                          Identifier typeName) {
    if (prefixName != null) {
      Element element =
          lookupInScope(compiler, prefixName, scope, prefixName.source);
      if (element != null && element.isPrefix()) {
        // The receiver is a prefix. Lookup in the imported members.
        PrefixElement prefix = element;
        return prefix.lookupLocalMember(typeName.source);
      }
      // The caller of this method will create the ErroneousElement for
      // the MalformedType.
      return null;
    } else {
      String stringValue = typeName.source;
      if (identical(stringValue, 'void')) {
        return compiler.types.voidType.element;
      } else if (identical(stringValue, 'dynamic')) {
        return compiler.dynamicClass;
      } else {
        return lookupInScope(compiler, typeName, scope, typeName.source);
      }
    }
  }

  DartType resolveTypeAnnotation(MappingVisitor visitor, TypeAnnotation node,
                                 {bool malformedIsError: false}) {
    Identifier typeName;
    Identifier prefixName;
    Send send = node.typeName.asSend();
    if (send != null) {
      // The type name is of the form [: prefix . identifier :].
      prefixName = send.receiver.asIdentifier();
      typeName = send.selector.asIdentifier();
    } else {
      typeName = node.typeName.asIdentifier();
    }

    Element element = resolveTypeName(visitor.scope, prefixName, typeName);

    DartType reportFailureAndCreateType(DualKind messageKind,
                                        Map messageArguments,
                                        {DartType userProvidedBadType}) {
      if (malformedIsError) {
        visitor.error(node, messageKind.error, messageArguments);
      } else {
        compiler.backend.registerThrowRuntimeError(visitor.mapping);
        visitor.warning(node, messageKind.warning, messageArguments);
      }
      Element erroneousElement = new ErroneousElementX(
          messageKind.error, messageArguments, typeName.source,
          visitor.enclosingElement);
      LinkBuilder<DartType> arguments = new LinkBuilder<DartType>();
      resolveTypeArguments(visitor, node, null, arguments);
      return new MalformedType(erroneousElement,
              userProvidedBadType, arguments.toLink());
    }

    DartType checkNoTypeArguments(DartType type) {
      LinkBuilder<DartType> arguments = new LinkBuilder<DartType>();
      bool hasTypeArgumentMismatch = resolveTypeArguments(
          visitor, node, const Link<DartType>(), arguments);
      if (hasTypeArgumentMismatch) {
        return new MalformedType(
            new ErroneousElementX(MessageKind.TYPE_ARGUMENT_COUNT_MISMATCH,
                {'type': node}, typeName.source, visitor.enclosingElement),
                type, arguments.toLink());
      }
      return type;
    }

    DartType type;
    if (element == null) {
      type = reportFailureAndCreateType(
          MessageKind.CANNOT_RESOLVE_TYPE, {'typeName': node.typeName});
    } else if (element.isAmbiguous()) {
      AmbiguousElement ambiguous = element;
      type = reportFailureAndCreateType(
          ambiguous.messageKind, ambiguous.messageArguments);
      ambiguous.diagnose(visitor.mapping.currentElement, compiler);
    } else if (!element.impliesType()) {
      type = reportFailureAndCreateType(
          MessageKind.NOT_A_TYPE, {'node': node.typeName});
    } else {
      bool addTypeVariableBoundsCheck = false;
      if (identical(element, compiler.types.voidType.element) ||
          identical(element, compiler.dynamicClass)) {
        type = checkNoTypeArguments(element.computeType(compiler));
      } else if (element.isClass()) {
        ClassElement cls = element;
        compiler.resolver._ensureClassWillBeResolved(cls);
        element.computeType(compiler);
        var arguments = new LinkBuilder<DartType>();
        bool hasTypeArgumentMismatch = resolveTypeArguments(
            visitor, node, cls.typeVariables, arguments);
        if (hasTypeArgumentMismatch) {
          type = new BadInterfaceType(cls.declaration,
              new InterfaceType.forUserProvidedBadType(cls.declaration,
                                                       arguments.toLink()));
        } else {
          if (arguments.isEmpty) {
            type = cls.rawType;
          } else {
            type = new InterfaceType(cls.declaration, arguments.toLink());
            addTypeVariableBoundsCheck = true;
          }
        }
      } else if (element.isTypedef()) {
        TypedefElement typdef = element;
        // TODO(ahe): Should be [ensureResolved].
        compiler.resolveTypedef(typdef);
        var arguments = new LinkBuilder<DartType>();
        bool hasTypeArgumentMismatch = resolveTypeArguments(
            visitor, node, typdef.typeVariables, arguments);
        if (hasTypeArgumentMismatch) {
          type = new BadTypedefType(typdef,
              new TypedefType.forUserProvidedBadType(typdef,
                                                     arguments.toLink()));
        } else {
          if (arguments.isEmpty) {
            type = typdef.rawType;
          } else {
            type = new TypedefType(typdef, arguments.toLink());
            addTypeVariableBoundsCheck = true;
          }
        }
      } else if (element.isTypeVariable()) {
        Element outer =
            visitor.enclosingElement.getOutermostEnclosingMemberOrTopLevel();
        bool isInFactoryConstructor =
            outer != null && outer.isFactoryConstructor();
        if (!outer.isClass() &&
            !outer.isTypedef() &&
            !isInFactoryConstructor &&
            Elements.isInStaticContext(visitor.enclosingElement)) {
          compiler.backend.registerThrowRuntimeError(visitor.mapping);
          type = reportFailureAndCreateType(
              MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
              {'typeVariableName': node},
              userProvidedBadType: element.computeType(compiler));
        } else {
          type = element.computeType(compiler);
        }
        type = checkNoTypeArguments(type);
      } else {
        compiler.cancel("unexpected element kind ${element.kind}",
                        node: node);
      }
      // TODO(johnniwinther): We should not resolve type annotations after the
      // resolution queue has been closed. Currently the dart backend does so.
      // Remove the guarded when this is fixed.
      if (!compiler.enqueuer.resolution.queueIsClosed &&
          addTypeVariableBoundsCheck) {
        visitor.addDeferredAction(
            visitor.enclosingElement,
            () => checkTypeVariableBounds(visitor.mapping, node, type));
      }
    }
    visitor.useType(node, type);
    return type;
  }

  /// Checks the type arguments of [type] against the type variable bounds.
  void checkTypeVariableBounds(TreeElements elements,
                               TypeAnnotation node, GenericType type) {
    void checkTypeVariableBound(_, DartType typeArgument,
                                   TypeVariableType typeVariable,
                                   DartType bound) {
      compiler.backend.registerTypeVariableBoundCheck(elements);
      if (!compiler.types.isSubtype(typeArgument, bound)) {
        compiler.reportWarningCode(node,
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
  bool resolveTypeArguments(
      MappingVisitor visitor,
      TypeAnnotation node,
      Link<DartType> typeVariables,
      LinkBuilder<DartType> arguments) {
    if (node.typeArguments == null) {
      return false;
    }
    bool typeArgumentCountMismatch = false;
    for (Link<Node> typeArguments = node.typeArguments.nodes;
         !typeArguments.isEmpty;
         typeArguments = typeArguments.tail) {
      if (typeVariables != null && typeVariables.isEmpty) {
        visitor.warning(
            typeArguments.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT.warning);
        typeArgumentCountMismatch = true;
      }
      DartType argType = resolveTypeAnnotation(visitor, typeArguments.head);
      arguments.addLast(argType);
      if (typeVariables != null && !typeVariables.isEmpty) {
        typeVariables = typeVariables.tail;
      }
    }
    if (typeVariables != null && !typeVariables.isEmpty) {
      visitor.warning(node.typeArguments,
                      MessageKind.MISSING_TYPE_ARGUMENT.warning);
      typeArgumentCountMismatch = true;
    }
    return typeArgumentCountMismatch;
  }
}

/**
 * Common supertype for resolver visitors that record resolutions in a
 * [TreeElements] mapping.
 */
abstract class MappingVisitor<T> extends CommonResolverVisitor<T> {
  final TreeElementMapping mapping;
  final TypeResolver typeResolver;
  /// The current enclosing element for the visited AST nodes.
  Element get enclosingElement;
  /// The current scope of the visitor.
  Scope get scope;

  MappingVisitor(Compiler compiler, TreeElementMapping this.mapping)
      : typeResolver = new TypeResolver(compiler),
        super(compiler);

  Element useElement(Node node, Element element) {
    if (element == null) return null;
    return mapping[node] = element;
  }

  DartType useType(TypeAnnotation annotation, DartType type) {
    if (type != null) {
      mapping.setType(annotation, type);
      useElement(annotation, type.element);
    }
    return type;
  }

  Element defineElement(Node node, Element element,
                        {bool doAddToScope: true}) {
    compiler.ensure(element != null);
    mapping[node] = element;
    if (doAddToScope) {
      Element existing = scope.add(element);
      if (existing != element) {
        reportDuplicateDefinition(node, element, existing);
      }
    }
    return element;
  }

  void reportDuplicateDefinition(/*Node|String*/ name,
                                 Spannable definition,
                                 Spannable existing) {
    compiler.reportError(
        definition,
        MessageKind.DUPLICATE_DEFINITION, {'name': name});
    compiler.reportMessage(
        compiler.spanFromSpannable(existing),
        MessageKind.EXISTING_DEFINITION.error({'name': name}),
        Diagnostic.INFO);
  }
}

/**
 * Core implementation of resolution.
 *
 * Do not subclass or instantiate this class outside this library
 * except for testing.
 */
class ResolverVisitor extends MappingVisitor<Element> {
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
    return (target.isVariable() || target.isParameter()) &&
      !(target.modifiers.isFinal() || target.modifiers.isConst());
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
                  TreeElementMapping mapping)
    : this.enclosingElement = element,
      // When the element is a field, we are actually resolving its
      // initial value, which should not have access to instance
      // fields.
      inInstanceContext = (element.isInstanceMember() && !element.isField())
          || element.isGenerativeConstructor(),
      this.currentClass = element.isMember() ? element.getEnclosingClass()
                                             : null,
      this.statementScope = new StatementScope(),
      scope = element.buildScope(),
      // The type annotations on a typedef do not imply type checks.
      // TODO(karlklose): clean this up (dartbug.com/8870).
      inCheckContext = compiler.enableTypeAssertions &&
          !element.isLibrary() &&
          !element.isTypedef() &&
          !element.enclosingElement.isTypedef(),
      inCatchBlock = false,
      super(compiler, mapping);

  ResolutionEnqueuer get world => compiler.enqueuer.resolution;

  Element reportLookupErrorIfAny(Element result, Node node, String name) {
    if (!Elements.isUnresolved(result)) {
      if (!inInstanceContext && result.isInstanceMember()) {
        compiler.reportError(
            node, MessageKind.NO_INSTANCE_AVAILABLE, {'name': name});
        return new ErroneousElementX(MessageKind.NO_INSTANCE_AVAILABLE,
                                     {'name': name},
                                     name, enclosingElement);
      } else if (result.isAmbiguous()) {
        AmbiguousElement ambiguous = result;
        compiler.reportError(
            node, ambiguous.messageKind.error, ambiguous.messageArguments);
        ambiguous.diagnose(enclosingElement, compiler);
        return new ErroneousElementX(ambiguous.messageKind.error,
                                     ambiguous.messageArguments,
                                     name, enclosingElement);
      }
    }
    return result;
  }

  // Create, or reuse an already created, statement element for a statement.
  TargetElement getOrCreateTargetElement(Node statement) {
    TargetElement element = mapping[statement];
    if (element == null) {
      element = new TargetElementX(statement,
                                   statementScope.nestingLevel,
                                   enclosingElement);
      mapping[statement] = element;
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
                                                 DualKind kind,
                                                 [Map arguments = const {}]) {
    ResolutionWarning warning = new ResolutionWarning(
        kind.warning, arguments, compiler.terseDiagnostics);
    compiler.reportWarning(node, warning);
    return new ErroneousElementX(kind.error, arguments, name, enclosingElement);
  }

  Element visitIdentifier(Identifier node) {
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
        element = compiler.dynamicClass;
      }
      element = reportLookupErrorIfAny(element, node, node.source);
      if (element == null) {
        if (!inInstanceContext) {
          element = warnAndCreateErroneousElement(
              node, node.source, MessageKind.CANNOT_RESOLVE,
              {'name': node});
          compiler.backend.registerThrowNoSuchMethod(mapping);
        }
      } else if (element.isErroneous()) {
        // Use the erroneous element.
      } else {
        if ((element.kind.category & allowedCategory) == 0) {
          // TODO(ahe): Improve error message. Need UX input.
          error(node, MessageKind.GENERIC,
                {'text': "is not an expression $element"});
        }
      }
      if (!Elements.isUnresolved(element) && element.isClass()) {
        ClassElement classElement = element;
        classElement.ensureResolved(compiler);
      }
      return useElement(node, element);
    }
  }

  Element visitTypeAnnotation(TypeAnnotation node) {
    DartType type = resolveTypeAnnotation(node);
    if (type != null) {
      if (inCheckContext) {
        compiler.enqueuer.resolution.registerIsCheck(type, mapping);
      }
      return type.element;
    }
    return null;
  }

  bool isNamedConstructor(Send node) => node.receiver != null;

  Selector getRedirectingThisOrSuperConstructorSelector(Send node) {
    if (isNamedConstructor(node)) {
      String constructorName = node.selector.asIdentifier().source;
      return new Selector.callConstructor(
          constructorName,
          enclosingElement.getLibrary());
    } else {
      return new Selector.callDefaultConstructor(
          enclosingElement.getLibrary());
    }
  }

  FunctionElement resolveConstructorRedirection(FunctionElement constructor) {
    FunctionExpression node = constructor.parseNode(compiler);

    // A synthetic constructor does not have a node.
    if (node == null) return null;
    if (node.initializers == null) return null;
    Link<Node> initializers = node.initializers.nodes;
    if (!initializers.isEmpty &&
        Initializers.isConstructorRedirect(initializers.head)) {
      Selector selector =
          getRedirectingThisOrSuperConstructorSelector(initializers.head);
      final ClassElement classElement = constructor.getEnclosingClass();
      return classElement.lookupConstructor(selector);
    }
    return null;
  }

  void setupFunction(FunctionExpression node, FunctionElement function) {
    Element enclosingElement = function.enclosingElement;
    if (node.modifiers.isStatic() &&
        enclosingElement.kind != ElementKind.CLASS) {
      compiler.reportError(node, MessageKind.ILLEGAL_STATIC);
    }

    scope = new MethodScope(scope, function);
    // Put the parameters in scope.
    FunctionSignature functionParameters =
        function.computeSignature(compiler);
    Link<Node> parameterNodes = (node.parameters == null)
        ? const Link<Node>() : node.parameters.nodes;
    functionParameters.forEachParameter((Element element) {
      if (element == functionParameters.optionalParameters.head) {
        NodeList nodes = parameterNodes.head;
        parameterNodes = nodes.nodes;
      }
      VariableDefinitions variableDefinitions = parameterNodes.head;
      Node parameterNode = variableDefinitions.definitions.nodes.head;
      initializerDo(parameterNode, (n) => n.accept(this));
      // Field parameters (this.x) are not visible inside the constructor. The
      // fields they reference are visible, but must be resolved independently.
      if (element.kind == ElementKind.FIELD_PARAMETER) {
        useElement(parameterNode, element);
      } else {
        defineElement(variableDefinitions.definitions.nodes.head, element);
      }
      parameterNodes = parameterNodes.tail;
    });
    addDeferredAction(enclosingElement, () {
      functionParameters.forEachOptionalParameter((Element parameter) {
        compiler.constantHandler.compileConstant(parameter);
      });
    });
    if (inCheckContext) {
      functionParameters.forEachParameter((Element element) {
        compiler.enqueuer.resolution.registerIsCheck(
            element.computeType(compiler), mapping);
      });
    }
  }

  visitCascade(Cascade node) {
    visit(node.expression);
  }

  visitCascadeReceiver(CascadeReceiver node) {
    visit(node.expression);
  }

  Element visitClassNode(ClassNode node) {
    cancel(node, "shouldn't be called");
  }

  visitIn(Node node, Scope nestedScope) {
    Scope oldScope = scope;
    scope = nestedScope;
    Element element = visit(node);
    scope = oldScope;
    return element;
  }

  /**
   * Introduces new default targets for break and continue
   * before visiting the body of the loop
   */
  visitLoopBodyIn(Node loop, Node body, Scope bodyScope) {
    TargetElement element = getOrCreateTargetElement(loop);
    statementScope.enterLoop(element);
    visitIn(body, bodyScope);
    statementScope.exitLoop();
    if (!element.isTarget) {
      mapping.remove(loop);
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
    visit(node.function);
    FunctionElement functionElement = mapping[node.function];
    // TODO(floitsch): this might lead to two errors complaining about
    // shadowing.
    defineElement(node, functionElement);
  }

  visitFunctionExpression(FunctionExpression node) {
    visit(node.returnType);
    String name;
    if (node.name == null) {
      name = "";
    } else {
      name = node.name.asIdentifier().source;
    }
    FunctionElement function = new FunctionElementX.node(
        name, node, ElementKind.FUNCTION, Modifiers.EMPTY,
        enclosingElement);
    Scope oldScope = scope; // The scope is modified by [setupFunction].
    setupFunction(node, function);
    defineElement(node, function, doAddToScope: node.name != null);

    Element previousEnclosingElement = enclosingElement;
    enclosingElement = function;
    // Run the body in a fresh statement scope.
    StatementScope oldStatementScope = statementScope;
    statementScope = new StatementScope();
    visit(node.body);
    statementScope = oldStatementScope;

    scope = oldScope;
    enclosingElement = previousEnclosingElement;

    world.registerClosure(function, mapping);
    world.registerInstantiatedClass(compiler.functionClass, mapping);
  }

  visitIf(If node) {
    doInPromotionScope(node.condition.expression, () => visit(node.condition));
    doInPromotionScope(node.thenPart,
        () => visitIn(node.thenPart, new BlockScope(scope)));
    visitIn(node.elsePart, new BlockScope(scope));
  }

  static bool isLogicalOperator(Identifier op) {
    String str = op.source;
    return (identical(str, '&&') || str == '||' || str == '!');
  }

  Element resolveSend(Send node) {
    Selector selector = resolveSelector(node, null);
    if (node.isSuperCall) mapping.superUses.add(node);

    if (node.receiver == null) {
      // If this send is of the form "assert(expr);", then
      // this is an assertion.
      if (selector.isAssert()) {
        if (selector.argumentCount != 1) {
          error(node.selector,
                MessageKind.WRONG_NUMBER_OF_ARGUMENTS_FOR_ASSERT,
                {'argumentCount': selector.argumentCount});
        } else if (selector.namedArgumentCount != 0) {
          error(node.selector,
                MessageKind.ASSERT_IS_GIVEN_NAMED_ARGUMENTS,
                {'argumentCount': selector.namedArgumentCount});
        }
        return compiler.assertMethod;
      }

      return node.selector.accept(this);
    }

    var oldCategory = allowedCategory;
    allowedCategory |= ElementCategory.PREFIX | ElementCategory.SUPER;
    Element resolvedReceiver = visit(node.receiver);
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
      target = currentClass.lookupSuperSelector(selector, compiler);
      // [target] may be null which means invoking noSuchMethod on
      // super.
      if (target == null) {
        target = warnAndCreateErroneousElement(
            node, name, MessageKind.NO_SUCH_SUPER_MEMBER,
            {'className': currentClass, 'memberName': name});
        // We still need to register the invocation, because we might
        // call [:super.noSuchMethod:] which calls
        // [JSInvocationMirror._invokeOn].
        world.registerDynamicInvocation(selector);
        compiler.backend.registerSuperNoSuchMethod(mapping);
      }
    } else if (Elements.isUnresolved(resolvedReceiver)) {
      return null;
    } else if (resolvedReceiver.isClass()) {
      ClassElement receiverClass = resolvedReceiver;
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
      target = receiverClass.lookupLocalMember(name);
      if (target == null || target.isInstanceMember()) {
        compiler.backend.registerThrowNoSuchMethod(mapping);
        // TODO(johnniwinther): With the simplified [TreeElements] invariant,
        // try to resolve injected elements if [currentClass] is in the patch
        // library of [receiverClass].

        // TODO(karlklose): this should be reported by the caller of
        // [resolveSend] to select better warning messages for getters and
        // setters.
        DualKind kind = (target == null)
            ? MessageKind.MEMBER_NOT_FOUND
            : MessageKind.MEMBER_NOT_STATIC;
        return warnAndCreateErroneousElement(node, name, kind,
                                             {'className': receiverClass.name,
                                              'memberName': name});
      }
    } else if (identical(resolvedReceiver.kind, ElementKind.PREFIX)) {
      PrefixElement prefix = resolvedReceiver;
      target = prefix.lookupLocalMember(name);
      if (Elements.isUnresolved(target)) {
        compiler.backend.registerThrowNoSuchMethod(mapping);
        return warnAndCreateErroneousElement(
            node, name, MessageKind.NO_SUCH_LIBRARY_MEMBER,
            {'libraryName': prefix.name, 'memberName': name});
      } else if (target.kind == ElementKind.CLASS) {
        ClassElement classElement = target;
        classElement.ensureResolved(compiler);
      }
    }
    return target;
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

    if (element != null && element.isConstructor()) {
      return new Selector.callConstructor(
          element.name, library, arity, named);
    }

    // If we're invoking a closure, we do not have an identifier.
    return (identifier == null)
        ? new Selector.callClosure(arity, named)
        : new Selector.call(identifier.source, library, arity, named);
  }

  Selector resolveSelector(Send node, Element element) {
    LibraryElement library = enclosingElement.getLibrary();
    Selector selector = computeSendSelector(node, library, element);
    if (selector != null) mapping.setSelector(node, selector);
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

  visitSend(Send node) {
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    sendIsMemberAccess = node.isPropertyAccess || node.isCall;
    Element target;
    if (node.isLogicalAnd) {
      target = doInPromotionScope(node.receiver, () => resolveSend(node));
    } else {
      target = resolveSend(node);
    }
    sendIsMemberAccess = oldSendIsMemberAccess;

    if (target != null
        && target == compiler.mirrorSystemGetNameFunction
        && !compiler.mirrorUsageAnalyzerTask.hasMirrorUsage(enclosingElement)) {
      compiler.reportHint(
          node.selector, MessageKind.STATIC_FUNCTION_BLOAT,
          {'class': compiler.mirrorSystemClass.name,
           'name': compiler.mirrorSystemGetNameFunction.name});
    }

    if (!Elements.isUnresolved(target)) {
      if (target.isAbstractField()) {
        AbstractFieldElement field = target;
        target = field.getter;
        if (target == null && !inInstanceContext) {
          compiler.backend.registerThrowNoSuchMethod(mapping);
          target =
              warnAndCreateErroneousElement(node.selector, field.name,
                                            MessageKind.CANNOT_RESOLVE_GETTER);
        }
      } else if (target.isTypeVariable()) {
        ClassElement cls = target.getEnclosingClass();
        assert(enclosingElement.getEnclosingClass() == cls);
        compiler.backend.registerClassUsingVariableExpression(cls);
        compiler.backend.registerTypeVariableExpression(mapping);
        // Set the type of the node to [Type] to mark this send as a
        // type variable expression.
        mapping.setType(node, compiler.typeClass.computeType(compiler));
        world.registerTypeLiteral(target, mapping);
      } else if (target.impliesType() && !sendIsMemberAccess) {
        // Set the type of the node to [Type] to mark this send as a
        // type literal.
        mapping.setType(node, compiler.typeClass.computeType(compiler));
        world.registerTypeLiteral(target, mapping);

        // Don't try to make constants of calls to type literals.
        analyzeConstant(node, isConst: !node.isCall);
      }
      if (isPotentiallyMutableTarget(target)) {
        if (enclosingElement != target.enclosingElement) {
          for (Node scope in promotionScope) {
            mapping.setAccessedByClosureIn(scope, target, node);
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
          compiler.enqueuer.resolution.registerIsCheck(type, mapping);
        }
        resolvedArguments = true;
      } else if (identical(operatorString, 'as')) {
        DartType type = resolveTypeAnnotation(node.arguments.head);
        if (type != null) {
          compiler.enqueuer.resolution.registerAsCheck(type, mapping);
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
    Selector selector = mapping.getSelector(node);
    if (selector == null) return null;

    if (node.isCall) {
      if (Elements.isUnresolved(target) ||
          target.isGetter() ||
          target.isField() ||
          Elements.isClosureSend(node, target)) {
        // If we don't know what we're calling or if we are calling a getter,
        // we need to register that fact that we may be calling a closure
        // with the same arguments.
        Selector call = new Selector.callClosureFrom(selector);
        world.registerDynamicInvocation(call);
      } else if (target.impliesType()) {
        // We call 'call()' on a Type instance returned from the reference to a
        // class or typedef literal. We do not need to register this call as a
        // dynamic invocation, because we statically know what the target is.
      } else if (!selector.applies(target, compiler)) {
        warnArgumentMismatch(node, target);
      }

      if (target != null && target.isForeign(compiler)) {
        if (selector.name == 'JS') {
          world.registerJsCall(node, this);
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

    // TODO(ngeoffray): Warn if target is null and the send is
    // unqualified.
    useElement(node, target);
    registerSend(selector, target);
    if (node.isPropertyAccess && Elements.isStaticOrTopLevelFunction(target)) {
      world.registerGetOfStaticFunction(target.declaration);
    }
    return node.isPropertyAccess ? target : null;
  }

  void warnArgumentMismatch(Send node, Element target) {
    compiler.backend.registerThrowNoSuchMethod(mapping);
    // TODO(karlklose): we can be more precise about the reason of the
    // mismatch.
    warning(node.argumentsNode, MessageKind.INVALID_ARGUMENTS.warning,
            {'methodName': target.name});
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

  visitSendSet(SendSet node) {
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    sendIsMemberAccess = node.isPropertyAccess || node.isCall;
    Element target = resolveSend(node);
    sendIsMemberAccess = oldSendIsMemberAccess;
    Element setter = target;
    Element getter = target;
    String operatorName = node.assignmentOperator.source;
    String source = operatorName;
    bool isComplex = !identical(source, '=');
    if (!Elements.isUnresolved(target)) {
      if (target.isAbstractField()) {
        AbstractFieldElement field = target;
        setter = field.setter;
        getter = field.getter;
        if (setter == null && !inInstanceContext) {
          setter = warnAndCreateErroneousElement(
              node.selector, field.name, MessageKind.CANNOT_RESOLVE_SETTER);
          compiler.backend.registerThrowNoSuchMethod(mapping);
        }
        if (isComplex && getter == null && !inInstanceContext) {
          getter = warnAndCreateErroneousElement(
              node.selector, field.name, MessageKind.CANNOT_RESOLVE_GETTER);
          compiler.backend.registerThrowNoSuchMethod(mapping);
        }
      } else if (target.impliesType()) {
        compiler.backend.registerThrowNoSuchMethod(mapping);
      } else if (target.modifiers.isFinal() ||
                 target.modifiers.isConst() ||
                 (target.isFunction() &&
                     Elements.isStaticOrTopLevelFunction(target) &&
                     !target.isSetter())) {
        setter = warnAndCreateErroneousElement(
            node.selector, target.name, MessageKind.CANNOT_RESOLVE_SETTER);
        compiler.backend.registerThrowNoSuchMethod(mapping);
      }
      if (isPotentiallyMutableTarget(target)) {
        mapping.setPotentiallyMutated(target, node);
        if (enclosingElement != target.enclosingElement) {
          mapping.registerPotentiallyMutatedInClosure(target, node);
        }
        for (Node scope in promotionScope) {
          mapping.registerPotentiallyMutatedIn(scope, target, node);
        }
      }
    }

    resolveArguments(node.argumentsNode);

    // TODO(ngeoffray): Check if the target can be assigned.
    // TODO(ngeoffray): Warn if target is null and the send is
    // unqualified.

    Selector selector = mapping.getSelector(node);
    if (isComplex) {
      Selector getterSelector;
      if (selector.isSetter()) {
        getterSelector = new Selector.getterFrom(selector);
      } else {
        assert(selector.isIndexSet());
        getterSelector = new Selector.index();
      }
      registerSend(getterSelector, getter);
      mapping.setGetterSelectorInComplexSendSet(node, getterSelector);
      if (node.isSuperCall) {
        getter = currentClass.lookupSuperSelector(getterSelector, compiler);
        if (getter == null) {
          target = warnAndCreateErroneousElement(
              node, selector.name, MessageKind.NO_SUCH_SUPER_MEMBER,
              {'className': currentClass, 'memberName': selector.name});
          compiler.backend.registerSuperNoSuchMethod(mapping);
        }
      }
      useElement(node.selector, getter);

      // Make sure we include the + and - operators if we are using
      // the ++ and -- ones.  Also, if op= form is used, include op itself.
      void registerBinaryOperator(String name) {
        Selector binop = new Selector.binaryOperator(name);
        world.registerDynamicInvocation(binop);
        mapping.setOperatorSelectorInComplexSendSet(node, binop);
      }
      if (identical(source, '++')) {
        registerBinaryOperator('+');
        world.registerInstantiatedClass(compiler.intClass, mapping);
      } else if (identical(source, '--')) {
        registerBinaryOperator('-');
        world.registerInstantiatedClass(compiler.intClass, mapping);
      } else if (source.endsWith('=')) {
        registerBinaryOperator(Elements.mapToUserOperator(operatorName));
      }
    }

    registerSend(selector, setter);
    return useElement(node, setter);
  }

  void registerSend(Selector selector, Element target) {
    if (target == null || target.isInstanceMember()) {
      if (selector.isGetter()) {
        world.registerDynamicGetter(selector);
      } else if (selector.isSetter()) {
        world.registerDynamicSetter(selector);
      } else {
        world.registerDynamicInvocation(selector);
      }
    } else if (Elements.isStaticOrTopLevel(target)) {
      // TODO(kasperl): It seems like we're not supposed to register
      // the use of classes. Wouldn't it be simpler if we just did?
      if (!target.isClass()) {
        // [target] might be the implementation element and only declaration
        // elements may be registered.
        world.registerStaticUse(target.declaration);
      }
    }
  }

  visitLiteralInt(LiteralInt node) {
    world.registerInstantiatedClass(compiler.intClass, mapping);
  }

  visitLiteralDouble(LiteralDouble node) {
    world.registerInstantiatedClass(compiler.doubleClass, mapping);
  }

  visitLiteralBool(LiteralBool node) {
    world.registerInstantiatedClass(compiler.boolClass, mapping);
  }

  visitLiteralString(LiteralString node) {
    world.registerInstantiatedClass(compiler.stringClass, mapping);
  }

  visitLiteralNull(LiteralNull node) {
    world.registerInstantiatedClass(compiler.nullClass, mapping);
  }

  visitLiteralSymbol(LiteralSymbol node) {
    world.registerInstantiatedClass(compiler.symbolClass, mapping);
    world.registerStaticUse(compiler.symbolConstructor.declaration);
    world.registerConstSymbol(node.slowNameString, mapping);
    if (!validateSymbol(node, node.slowNameString, reportError: false)) {
      compiler.reportError(node, MessageKind.UNSUPPORTED_LITERAL_SYMBOL,
                           {'value': node.slowNameString});
    }
    analyzeConstant(node);
  }

  visitStringJuxtaposition(StringJuxtaposition node) {
    world.registerInstantiatedClass(compiler.stringClass, mapping);
    node.visitChildren(this);
  }

  visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      visit(link.head);
    }
  }

  visitOperator(Operator node) {
    unimplemented(node, 'operator');
  }

  visitRethrow(Rethrow node) {
    if (!inCatchBlock) {
      error(node, MessageKind.THROW_WITHOUT_EXPRESSION);
    }
  }

  visitReturn(Return node) {
    if (node.isRedirectingFactoryBody) {
      handleRedirectingFactoryBody(node);
    } else {
      Node expression = node.expression;
      if (expression != null &&
          enclosingElement.isGenerativeConstructor()) {
        // It is a compile-time error if a return statement of the form
        // `return e;` appears in a generative constructor.  (Dart Language
        // Specification 13.12.)
        compiler.reportError(expression,
                             MessageKind.CANNOT_RETURN_FROM_CONSTRUCTOR);
      }
      visit(node.expression);
    }
  }

  void handleRedirectingFactoryBody(Return node) {
    final isSymbolConstructor = enclosingElement == compiler.symbolConstructor;
    if (!enclosingElement.isFactoryConstructor()) {
      compiler.reportError(
          node, MessageKind.FACTORY_REDIRECTION_IN_NON_FACTORY);
      compiler.reportHint(
          enclosingElement, MessageKind.MISSING_FACTORY_KEYWORD);
    }
    FunctionElement constructor = enclosingElement;
    bool isConstConstructor = constructor.modifiers.isConst();
    FunctionElement redirectionTarget = resolveRedirectingFactory(
        node, inConstContext: isConstConstructor);
    constructor.defaultImplementation = redirectionTarget;
    useElement(node.expression, redirectionTarget);
    if (Elements.isUnresolved(redirectionTarget)) {
      compiler.backend.registerThrowNoSuchMethod(mapping);
      return;
    } else {
      if (isConstConstructor &&
          !redirectionTarget.modifiers.isConst()) {
        compiler.reportError(node, MessageKind.CONSTRUCTOR_IS_NOT_CONST);
      }
      if (redirectionTarget == constructor) {
        compiler.reportError(node, MessageKind.CYCLIC_REDIRECTING_FACTORY);
        return;
      }
    }

    // Check that the target constructor is type compatible with the
    // redirecting constructor.
    ClassElement targetClass = redirectionTarget.getEnclosingClass();
    InterfaceType type = mapping.getType(node.expression);
    FunctionType targetType = redirectionTarget.computeType(compiler)
        .subst(type.typeArguments, targetClass.typeVariables);
    FunctionType constructorType = constructor.computeType(compiler);
    bool isSubtype = compiler.types.isSubtype(targetType, constructorType);
    if (!isSubtype) {
      warning(node, MessageKind.NOT_ASSIGNABLE.warning,
              {'fromType': targetType, 'toType': constructorType});
    }

    FunctionSignature targetSignature =
        redirectionTarget.computeSignature(compiler);
    FunctionSignature constructorSignature =
        constructor.computeSignature(compiler);
    if (!targetSignature.isCompatibleWith(constructorSignature)) {
      assert(!isSubtype);
      compiler.backend.registerThrowNoSuchMethod(mapping);
    }

    // Register a post process to check for cycles in the redirection chain and
    // set the actual generative constructor at the end of the chain.
    addDeferredAction(constructor, () {
      compiler.resolver.resolveRedirectionChain(constructor, node);
    });

    world.registerStaticUse(redirectionTarget);
    world.registerInstantiatedClass(
        redirectionTarget.enclosingElement.declaration, mapping);
    if (isSymbolConstructor) {
      compiler.backend.registerSymbolConstructor(mapping);
    }
  }

  visitThrow(Throw node) {
    compiler.backend.registerThrowExpression(mapping);
    visit(node.expression);
  }

  visitVariableDefinitions(VariableDefinitions node) {
    VariableDefinitionsVisitor visitor =
        new VariableDefinitionsVisitor(compiler, node, this,
                                       ElementKind.VARIABLE);
    // Ensure that we set the type of the [VariableListElement] since it depends
    // on the current scope. If the current scope is a [MethodScope] or
    // [BlockScope] it will not be available for the
    // [VariableListElement.computeType] method.
    if (node.type != null) {
      visitor.variables.type = resolveTypeAnnotation(node.type);
    } else {
      visitor.variables.type = compiler.types.dynamicType;
    }

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
    if (modifiers.isFinal() && (modifiers.isConst() || modifiers.isVar())) {
      reportExtraModifier('final');
    }
    if (modifiers.isVar() && (modifiers.isConst() || node.type != null)) {
      reportExtraModifier('var');
    }
    if (enclosingElement.isFunction()) {
      if (modifiers.isAbstract()) {
        reportExtraModifier('abstract');
      }
      if (modifiers.isStatic()) {
        reportExtraModifier('static');
      }
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

  visitNewExpression(NewExpression node) {
    Node selector = node.send.selector;
    FunctionElement constructor = resolveConstructor(node);
    final bool isSymbolConstructor = constructor == compiler.symbolConstructor;
    final bool isMirrorsUsedConstant =
        node.isConst() && (constructor == compiler.mirrorsUsedConstructor);
    resolveSelector(node.send, constructor);
    resolveArguments(node.send.argumentsNode);
    useElement(node.send, constructor);
    if (Elements.isUnresolved(constructor)) return constructor;
    Selector callSelector = mapping.getSelector(node.send);
    if (!callSelector.applies(constructor, compiler)) {
      warnArgumentMismatch(node.send, constructor);
      compiler.backend.registerThrowNoSuchMethod(mapping);
    }

    // [constructor] might be the implementation element
    // and only declaration elements may be registered.
    world.registerStaticUse(constructor.declaration);
    ClassElement cls = constructor.getEnclosingClass();
    InterfaceType type = mapping.getType(node);
    if (node.isConst() && type.containsTypeVariables) {
      compiler.reportError(node.send.selector,
                           MessageKind.TYPE_VARIABLE_IN_CONSTANT);
    }
    world.registerInstantiatedType(type, mapping);
    if (constructor.isFactoryConstructor() && !type.typeArguments.isEmpty) {
      world.registerFactoryWithTypeArguments(mapping);
    }
    if (constructor.isGenerativeConstructor() && cls.isAbstract(compiler)) {
      warning(node, MessageKind.ABSTRACT_CLASS_INSTANTIATION);
      compiler.backend.registerAbstractClassInstantiation(mapping);
    }

    if (isSymbolConstructor) {
      if (node.isConst()) {
        Node argumentNode = node.send.arguments.head;
        Constant name = compiler.constantHandler.compileNodeWithDefinitions(
            argumentNode, mapping, isConst: true);
        if (!name.isString()) {
          DartType type = name.computeType(compiler);
          compiler.reportError(argumentNode, MessageKind.STRING_EXPECTED,
                                   {'type': type});
        } else {
          StringConstant stringConstant = name;
          String nameString = stringConstant.toDartString().slowToString();
          if (validateSymbol(argumentNode, nameString)) {
            world.registerConstSymbol(nameString, mapping);
          }
        }
      } else {
        if (!compiler.mirrorUsageAnalyzerTask.hasMirrorUsage(
                enclosingElement)) {
          compiler.reportHint(
              node.newToken, MessageKind.NON_CONST_BLOAT,
              {'name': compiler.symbolClass.name});
        }
        world.registerNewSymbol(mapping);
      }
    } else if (isMirrorsUsedConstant) {
      compiler.mirrorUsageAnalyzerTask.validate(node, mapping);
    }
    if (node.isConst()) {
      analyzeConstant(node);
    }

    return null;
  }

  void analyzeConstant(Node node, {bool isConst: true}) {
    addDeferredAction(enclosingElement, () {
       Constant constant = compiler.constantHandler.compileNodeWithDefinitions(
           node, mapping, isConst: isConst);

       // The type constant that is an argument to JS_INTERCEPTOR_CONSTANT names
       // a class that will be instantiated outside the program by attaching a
       // native class dispatch record referencing the interceptor.
       if (argumentsToJsInterceptorConstant != null &&
           argumentsToJsInterceptorConstant.contains(node)) {
         if (constant.isType()) {
           TypeConstant typeConstant = constant;
           if (typeConstant.representedType is InterfaceType) {
             world.registerInstantiatedType(typeConstant.representedType,
                 mapping);
           } else {
             compiler.reportError(node,
                 MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
           }
         } else {
           compiler.reportError(node,
               MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
         }
       }
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
   * [null], if there is no corresponding constructor, class or library.
   */
  FunctionElement resolveConstructor(NewExpression node) {
    return node.accept(new ConstructorResolver(compiler, this));
  }

  FunctionElement resolveRedirectingFactory(Return node,
                                            {bool inConstContext: false}) {
    return node.accept(new ConstructorResolver(compiler, this,
                                               inConstContext: inConstContext));
  }

  DartType resolveTypeAnnotation(TypeAnnotation node,
                                 {bool malformedIsError: false}) {
    DartType type = typeResolver.resolveTypeAnnotation(
        this, node, malformedIsError: malformedIsError);
    if (type == null) return null;
    if (inCheckContext) {
      compiler.enqueuer.resolution.registerIsCheck(type, mapping);
      compiler.backend.registerRequiredType(type, enclosingElement);
    }
    return type;
  }

  visitModifiers(Modifiers node) {
    // TODO(ngeoffray): Implement this.
    unimplemented(node, 'modifiers');
  }

  visitLiteralList(LiteralList node) {
    NodeList arguments = node.typeArguments;
    DartType typeArgument;
    if (arguments != null) {
      Link<Node> nodes = arguments.nodes;
      if (nodes.isEmpty) {
        // The syntax [: <>[] :] is not allowed.
        error(arguments, MessageKind.MISSING_TYPE_ARGUMENT.error);
      } else {
        typeArgument = resolveTypeAnnotation(nodes.head);
        for (nodes = nodes.tail; !nodes.isEmpty; nodes = nodes.tail) {
          warning(nodes.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT.warning);
          resolveTypeAnnotation(nodes.head);
        }
      }
    }
    DartType listType;
    if (typeArgument != null) {
      if (node.isConst() && typeArgument.containsTypeVariables) {
        compiler.reportError(arguments.nodes.head,
            MessageKind.TYPE_VARIABLE_IN_CONSTANT);
      }
      listType = new InterfaceType(compiler.listClass,
                                   new Link<DartType>.fromList([typeArgument]));
    } else {
      compiler.listClass.computeType(compiler);
      listType = compiler.listClass.rawType;
    }
    mapping.setType(node, listType);
    world.registerInstantiatedType(listType, mapping);
    compiler.backend.registerRequiredType(listType, enclosingElement);
    visit(node.elements);
    if (node.isConst()) {
      analyzeConstant(node);
    }
  }

  visitConditional(Conditional node) {
    doInPromotionScope(node.condition, () => visit(node.condition));
    doInPromotionScope(node.thenExpression, () => visit(node.thenExpression));
    visit(node.elseExpression);
  }

  visitStringInterpolation(StringInterpolation node) {
    world.registerInstantiatedClass(compiler.stringClass, mapping);
    compiler.backend.registerStringInterpolation(mapping);
    node.visitChildren(this);
  }

  visitStringInterpolationPart(StringInterpolationPart node) {
    registerImplicitInvocation('toString', 0);
    node.visitChildren(this);
  }

  visitBreakStatement(BreakStatement node) {
    TargetElement target;
    if (node.target == null) {
      target = statementScope.currentBreakTarget();
      if (target == null) {
        error(node, MessageKind.NO_BREAK_TARGET);
        return;
      }
      target.isBreakTarget = true;
    } else {
      String labelName = node.target.source;
      LabelElement label = statementScope.lookupLabel(labelName);
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
      mapping[node.target] = label;
    }
    if (mapping[node] != null) {
      // TODO(ahe): I'm not sure why this node already has an element
      // that is different from target.  I will talk to Lasse and
      // figure out what is going on.
      mapping.remove(node);
    }
    mapping[node] = target;
  }

  visitContinueStatement(ContinueStatement node) {
    TargetElement target;
    if (node.target == null) {
      target = statementScope.currentContinueTarget();
      if (target == null) {
        error(node, MessageKind.NO_CONTINUE_TARGET);
        return;
      }
      target.isContinueTarget = true;
    } else {
      String labelName = node.target.source;
      LabelElement label = statementScope.lookupLabel(labelName);
      if (label == null) {
        error(node.target, MessageKind.UNBOUND_LABEL, {'labelName': labelName});
        return;
      }
      target = label.target;
      if (!target.statement.isValidContinueTarget()) {
        error(node.target, MessageKind.INVALID_CONTINUE);
      }
      label.setContinueTarget();
      mapping[node.target] = label;
    }
    mapping[node] = target;
  }

  registerImplicitInvocation(String name, int arity) {
    Selector selector = new Selector.call(name, null, arity);
    world.registerDynamicInvocation(selector);
  }

  visitForIn(ForIn node) {
    LibraryElement library = enclosingElement.getLibrary();
    mapping.setIteratorSelector(node, compiler.iteratorSelector);
    world.registerDynamicGetter(compiler.iteratorSelector);
    mapping.setCurrentSelector(node, compiler.currentSelector);
    world.registerDynamicGetter(compiler.currentSelector);
    mapping.setMoveNextSelector(node, compiler.moveNextSelector);
    world.registerDynamicInvocation(compiler.moveNextSelector);

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
      loopVariable = mapping[send];
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
        loopVariable = mapping[identifier];
      }
    } else {
      compiler.reportError(declaration, MessageKind.INVALID_FOR_IN);
    }
    if (loopVariableSelector != null) {
      mapping.setSelector(declaration, loopVariableSelector);
      registerSend(loopVariableSelector, loopVariable);
    } else {
      // The selector may only be null if we reported an error.
      assert(invariant(declaration, compiler.compilationFailed));
    }
    if (loopVariable != null) {
      // loopVariable may be null if it could not be resolved.
      mapping[declaration] = loopVariable;
    }
    visitLoopBodyIn(node, node.body, blockScope);
  }

  visitLabel(Label node) {
    // Labels are handled by their containing statements/cases.
  }

  visitLabeledStatement(LabeledStatement node) {
    Statement body = node.statement;
    TargetElement targetElement = getOrCreateTargetElement(body);
    Map<String, LabelElement> labelElements = <String, LabelElement>{};
    for (Label label in node.labels) {
      String labelName = label.labelName;
      if (labelElements.containsKey(labelName)) continue;
      LabelElement element = targetElement.addLabel(label, labelName);
      labelElements[labelName] = element;
    }
    statementScope.enterLabelScope(labelElements);
    visit(node.statement);
    statementScope.exitLabelScope();
    labelElements.forEach((String labelName, LabelElement element) {
      if (element.isTarget) {
        mapping[element.label] = element;
      } else {
        warning(element.label, MessageKind.UNUSED_LABEL,
                {'labelName': labelName});
      }
    });
    if (!targetElement.isTarget && identical(mapping[body], targetElement)) {
      // If the body is itself a break or continue for another target, it
      // might have updated its mapping to the target it actually does target.
      mapping.remove(body);
    }
  }

  visitLiteralMap(LiteralMap node) {
    NodeList arguments = node.typeArguments;
    DartType keyTypeArgument;
    DartType valueTypeArgument;
    if (arguments != null) {
      Link<Node> nodes = arguments.nodes;
      if (nodes.isEmpty) {
        // The syntax [: <>{} :] is not allowed.
        error(arguments, MessageKind.MISSING_TYPE_ARGUMENT.error);
      } else {
        keyTypeArgument = resolveTypeAnnotation(nodes.head);
        nodes = nodes.tail;
        if (nodes.isEmpty) {
          warning(arguments, MessageKind.MISSING_TYPE_ARGUMENT.warning);
        } else {
          valueTypeArgument = resolveTypeAnnotation(nodes.head);
          for (nodes = nodes.tail; !nodes.isEmpty; nodes = nodes.tail) {
            warning(nodes.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT.warning);
            resolveTypeAnnotation(nodes.head);
          }
        }
      }
    }
    DartType mapType;
    if (valueTypeArgument != null) {
      mapType = new InterfaceType(compiler.mapClass,
          new Link<DartType>.fromList([keyTypeArgument, valueTypeArgument]));
    } else {
      compiler.mapClass.computeType(compiler);
      mapType = compiler.mapClass.rawType;
    }
    if (node.isConst() && mapType.containsTypeVariables) {
      compiler.reportError(arguments,
          MessageKind.TYPE_VARIABLE_IN_CONSTANT);
    }
    mapping.setType(node, mapType);
    world.registerInstantiatedClass(compiler.mapClass, mapping);
    if (node.isConst()) {
      compiler.backend.registerConstantMap(mapping);
    }
    compiler.backend.registerRequiredType(mapType, enclosingElement);
    node.visitChildren(this);
    if (node.isConst()) {
      analyzeConstant(node);
    }
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    node.visitChildren(this);
  }

  visitNamedArgument(NamedArgument node) {
    visit(node.expression);
  }

  visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);

    TargetElement breakElement = getOrCreateTargetElement(node);
    Map<String, LabelElement> continueLabels = <String, LabelElement>{};
    Link<Node> cases = node.cases.nodes;
    while (!cases.isEmpty) {
      SwitchCase switchCase = cases.head;
      for (Node labelOrCase in switchCase.labelsAndCases) {
        CaseMatch caseMatch = labelOrCase.asCaseMatch();
        if (caseMatch != null) {
          analyzeConstant(caseMatch.expression);
          continue;
        }
        Label label = labelOrCase;
        String labelName = label.labelName;

        LabelElement existingElement = continueLabels[labelName];
        if (existingElement != null) {
          // It's an error if the same label occurs twice in the same switch.
          compiler.reportError(
              label,
              MessageKind.DUPLICATE_LABEL.error, {'labelName': labelName});
          compiler.reportInfo(
              existingElement.label,
              MessageKind.EXISTING_LABEL, {'labelName': labelName});
        } else {
          // It's only a warning if it shadows another label.
          existingElement = statementScope.lookupLabel(labelName);
          if (existingElement != null) {
            compiler.reportWarningCode(
                label,
                MessageKind.DUPLICATE_LABEL.warning, {'labelName': labelName});
            compiler.reportInfo(
                existingElement.label,
                MessageKind.EXISTING_LABEL, {'labelName': labelName});
          }
        }

        TargetElement targetElement = getOrCreateTargetElement(switchCase);
        LabelElement labelElement = targetElement.addLabel(label, labelName);
        mapping[label] = labelElement;
        continueLabels[labelName] = labelElement;
      }
      cases = cases.tail;
      // Test that only the last case, if any, is a default case.
      if (switchCase.defaultKeyword != null && !cases.isEmpty) {
        error(switchCase, MessageKind.INVALID_CASE_DEFAULT);
      }
    }

    statementScope.enterSwitch(breakElement, continueLabels);
    node.cases.accept(this);
    statementScope.exitSwitch();

    // Clean-up unused labels.
    continueLabels.forEach((String key, LabelElement label) {
      if (!label.isContinueTarget) {
        TargetElement targetElement = label.target;
        SwitchCase switchCase = targetElement.statement;
        mapping.remove(switchCase);
        mapping.remove(label.label);
      }
    });
    // TODO(ngeoffray): We should check here instead of the SSA backend if
    // there might be an error.
    compiler.backend.registerFallThroughError(mapping);
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
      // TODO(ngeoffray): The precise location is
      // node.getEndtoken.next. Adjust when issue #1581 is fixed.
      error(node, MessageKind.NO_CATCH_NOR_FINALLY);
    }
    visit(node.catchBlocks);
    visit(node.finallyBlock);
  }

  visitCatchBlock(CatchBlock node) {
    compiler.backend.registerCatchStatement(world, mapping);
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
          compiler.backend.registerStackTraceInCatch(mapping);
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
      DartType exceptionType = mapping.getType(node.type);
      Node exceptionVariable = exceptionDefinition.definitions.nodes.head;
      VariableElementX exceptionElement = mapping[exceptionVariable];
      exceptionElement.variables.type = exceptionType;
    }
    if (stackTraceDefinition != null) {
      Node stackTraceVariable = stackTraceDefinition.definitions.nodes.head;
      VariableElementX stackTraceElement = mapping[stackTraceVariable];
      world.registerInstantiatedClass(compiler.stackTraceClass, mapping);
      stackTraceElement.variables.type = compiler.stackTraceClass.rawType;
    }
  }

  visitTypedef(Typedef node) {
    unimplemented(node, 'typedef');
  }
}

class TypeDefinitionVisitor extends MappingVisitor<DartType> {
  Scope scope;
  final TypeDeclarationElement enclosingElement;
  TypeDeclarationElement get element => enclosingElement;

  TypeDefinitionVisitor(Compiler compiler,
                        TypeDeclarationElement element,
                        TreeElementMapping mapping)
      : this.enclosingElement = element,
        scope = Scope.buildEnclosingScope(element),
        super(compiler, mapping);

  void resolveTypeVariableBounds(NodeList node) {
    if (node == null) return;

    var nameSet = new Setlet<String>();
    // Resolve the bounds of type variables.
    Link<DartType> typeLink = element.typeVariables;
    Link<Node> nodeLink = node.nodes;
    while (!nodeLink.isEmpty) {
      TypeVariableType typeVariable = typeLink.head;
      String typeName = typeVariable.name;
      TypeVariable typeNode = nodeLink.head;
      if (nameSet.contains(typeName)) {
        error(typeNode, MessageKind.DUPLICATE_TYPE_VARIABLE_NAME,
              {'typeVariableName': typeName});
      }
      nameSet.add(typeName);

      TypeVariableElement variableElement = typeVariable.element;
      if (typeNode.bound != null) {
        DartType boundType = typeResolver.resolveTypeAnnotation(
            this, typeNode.bound);
        variableElement.bound = boundType;

        void checkTypeVariableBound() {
          Link<TypeVariableElement> seenTypeVariables =
              const Link<TypeVariableElement>();
          seenTypeVariables = seenTypeVariables.prepend(variableElement);
          DartType bound = boundType;
          while (bound.element.isTypeVariable()) {
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
        variableElement.bound = compiler.objectClass.computeType(compiler);
      }
      nodeLink = nodeLink.tail;
      typeLink = typeLink.tail;
    }
    assert(typeLink.isEmpty);
  }
}

class TypedefResolverVisitor extends TypeDefinitionVisitor {
  TypedefElement get element => enclosingElement;

  TypedefResolverVisitor(Compiler compiler,
                         TypedefElement typedefElement,
                         TreeElementMapping mapping)
      : super(compiler, typedefElement, mapping);

  visitTypedef(Typedef node) {
    TypedefType type = element.computeType(compiler);
    scope = new TypeDeclarationScope(scope, element);
    resolveTypeVariableBounds(node.typeParameters);

    FunctionSignature signature = SignatureResolver.analyze(
        compiler, node.formals, node.returnType, element,
        defaultValuesError: MessageKind.TYPEDEF_FORMAL_WITH_DEFAULT);
    element.functionSignature = signature;

    scope = new MethodScope(scope, element);
    signature.forEachParameter((Element element) {
      defineElement(element.parseNode(compiler), element);
    });

    element.alias = compiler.computeFunctionType(element, signature);

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
    TypedefElement typedefElement = type.element;
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
  ClassElement get element => enclosingElement;

  ClassResolverVisitor(Compiler compiler,
                       ClassElement classElement,
                       TreeElementMapping mapping)
    : super(compiler, classElement, mapping);

  DartType visitClassNode(ClassNode node) {
    compiler.ensure(element != null);
    compiler.ensure(element.resolutionState == STATE_STARTED);

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
          supertype = applyMixin(
              supertype, checkMixinType(link.head), link.head);
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
      ClassElement superElement = compiler.backend.defaultSuperclass(element);
      // Avoid making the superclass (usually Object) extend itself.
      if (element != superElement) {
        if (superElement == null) {
          compiler.internalError(
              "Cannot resolve default superclass for $element",
              node: node);
        } else {
          superElement.ensureResolved(compiler);
        }
        element.supertype = superElement.computeType(compiler);
      }
    }

    assert(element.interfaces == null);
    element.interfaces = resolveInterfaces(node.interfaces, node.superclass);
    calculateAllSupertypes(element);

    if (!element.hasConstructor) {
      Element superMember =
          element.superclass.localLookup('');
      if (superMember == null || !superMember.isGenerativeConstructor()) {
        DualKind kind = MessageKind.CANNOT_FIND_CONSTRUCTOR;
        Map arguments = {'constructorName': ''};
        // TODO(ahe): Why is this a compile-time error? Or if it is an error,
        // why do we bother to registerThrowNoSuchMethod below?
        compiler.reportError(node, kind.error, arguments);
        superMember = new ErroneousElementX(
            kind.error, arguments, '', element);
        compiler.backend.registerThrowNoSuchMethod(mapping);
      }
      FunctionElement constructor =
          new SynthesizedConstructorElementX.forDefault(superMember, element);
      element.setDefaultConstructor(constructor, compiler);
    }
    return element.computeType(compiler);
  }

  /// Resolves the mixed type for [mixinNode] and checks that the the mixin type
  /// is a valid, non-blacklisted interface type. The mixin type is returned.
  DartType checkMixinType(TypeAnnotation mixinNode) {
    DartType mixinType = resolveType(mixinNode);
    if (isBlackListed(mixinType)) {
      compiler.reportError(mixinNode,
          MessageKind.CANNOT_MIXIN, {'type': mixinType});
    } else if (mixinType.kind == TypeKind.TYPE_VARIABLE) {
      compiler.reportError(mixinNode, MessageKind.CLASS_NAME_EXPECTED);
    } else if (mixinType.kind == TypeKind.MALFORMED_TYPE) {
      compiler.reportError(mixinNode, MessageKind.CANNOT_MIXIN_MALFORMED);
    }
    return mixinType;
  }

  DartType visitNamedMixinApplication(NamedMixinApplication node) {
    compiler.ensure(element != null);
    compiler.ensure(element.resolutionState == STATE_STARTED);

    if (identical(node.classKeyword.stringValue, 'typedef')) {
      // TODO(aprelev@gmail.com): Remove this deprecation diagnostic
      // together with corresponding TODO in parser.dart.
      compiler.reportWarningCode(node.classKeyword,
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
    ClassElement mixinApplication = new MixinApplicationElementX(
        "${superName}+${mixinName}",
        element.getCompilationUnit(),
        compiler.getNextFreeClassId(),
        node,
        Modifiers.EMPTY);  // TODO(kasperl): Should this be abstract?
    doApplyMixinTo(mixinApplication, supertype, mixinType);
    mixinApplication.resolutionState = STATE_DONE;
    mixinApplication.supertypeLoadState = STATE_DONE;
    return mixinApplication.computeType(compiler);
  }

  bool isDefaultConstructor(FunctionElement constructor) {
    return constructor.name == '' &&
        constructor.computeSignature(compiler).parameterCount == 0;
  }

  FunctionElement createForwardingConstructor(FunctionElement target,
                                              ClassElement enclosing) {
    return new SynthesizedConstructorElementX(
        target.name, target, enclosing, false);
  }

  void doApplyMixinTo(MixinApplicationElement mixinApplication,
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
    interfaces = interfaces.prepend(mixinType);
    assert(mixinApplication.interfaces == null);
    mixinApplication.interfaces = interfaces;

    if (mixinType.kind != TypeKind.INTERFACE) {
      mixinApplication.allSupertypes = const Link<DartType>();
      return;
    }

    assert(mixinApplication.mixinType == null);
    mixinApplication.mixinType = resolveMixinFor(mixinApplication, mixinType);

    // Create forwarding constructors for constructor defined in the superclass
    // because they are now hidden by the mixin application.
    ClassElement superclass = supertype.element;
    superclass.forEachLocalMember((Element member) {
      if (!member.isGenerativeConstructor()) return;
      FunctionElement forwarder =
          createForwardingConstructor(member, mixinApplication);
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
    compiler.world.registerMixinUse(mixinApplication, mixin);
    return mixinType;
  }

  DartType resolveType(TypeAnnotation node) {
    return typeResolver.resolveTypeAnnotation(this, node);
  }

  DartType resolveSupertype(ClassElement cls, TypeAnnotation superclass) {
    DartType supertype = resolveType(superclass);
    if (supertype != null) {
      if (identical(supertype.kind, TypeKind.MALFORMED_TYPE)) {
        compiler.reportError(superclass, MessageKind.CANNOT_EXTEND_MALFORMED);
        return null;
      } else if (!identical(supertype.kind, TypeKind.INTERFACE)) {
        compiler.reportError(superclass.typeName,
            MessageKind.CLASS_NAME_EXPECTED);
        return null;
      } else if (isBlackListed(supertype)) {
        compiler.reportError(superclass, MessageKind.CANNOT_EXTEND,
            {'type': supertype});
        return null;
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
        if (identical(interfaceType.kind, TypeKind.MALFORMED_TYPE)) {
          compiler.reportError(superclass,
              MessageKind.CANNOT_IMPLEMENT_MALFORMED);
        } else if (!identical(interfaceType.kind, TypeKind.INTERFACE)) {
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
  void calculateAllSupertypes(ClassElement cls) {
    if (cls.allSupertypes != null) return;
    final DartType supertype = cls.supertype;
    if (supertype != null) {
      Map<Element, DartType> instantiations = new Map<Element, DartType>();
      LinkBuilder<DartType> allSupertypes = new LinkBuilder<DartType>();

      void addSupertype(DartType type) {
        DartType existing =
            instantiations.putIfAbsent(type.element, () => type);
        if (existing != null && existing != type) {
          compiler.reportError(cls,
              MessageKind.MULTI_INHERITANCE,
              {'thisType': cls.computeType(compiler),
               'firstType': existing,
               'secondType': type});
        }
        if (type.element != compiler.objectClass) {
          allSupertypes.addLast(type);
        }
      }

      addSupertype(supertype);
      for (Link<DartType> interfaces = cls.interfaces;
          !interfaces.isEmpty;
          interfaces = interfaces.tail) {
        addSupertype(interfaces.head);
      }
      addAllSupertypes(addSupertype, supertype);
      for (Link<DartType> interfaces = cls.interfaces;
           !interfaces.isEmpty;
           interfaces = interfaces.tail) {
        addAllSupertypes(addSupertype, interfaces.head);
      }

      allSupertypes.addLast(compiler.objectClass.rawType);
      cls.allSupertypes = allSupertypes.toLink();
    } else {
      assert(identical(cls, compiler.objectClass));
      cls.allSupertypes = const Link<DartType>();
    }
  }

  /**
   * Adds [type] and all supertypes of [type] to [allSupertypes] while
   * substituting type variables.
   */
  void addAllSupertypes(void addSupertype(DartType supertype),
                        InterfaceType type) {
    Link<DartType> typeArguments = type.typeArguments;
    ClassElement classElement = type.element;
    Link<DartType> typeVariables = classElement.typeVariables;
    Link<DartType> supertypes = classElement.allSupertypes;
    assert(invariant(element, supertypes != null,
        message: "Supertypes not computed on $classElement "
                 "during resolution of $element"));
    while (!supertypes.isEmpty) {
      DartType supertype = supertypes.head;
      if (supertype.element != compiler.objectClass) {
        DartType substituted = supertype.subst(typeArguments, typeVariables);
        addSupertype(substituted);
      }
      supertypes = supertypes.tail;
    }
  }

  isBlackListed(DartType type) {
    LibraryElement lib = element.getLibrary();
    return
      !identical(lib, compiler.coreLibrary) &&
      !identical(lib, compiler.jsHelperLibrary) &&
      !identical(lib, compiler.interceptorsLibrary) &&
      (identical(type, compiler.types.dynamicType) ||
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
    if (element != null && element.isClass()) {
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
    if (e == null || !e.impliesType()) {
      error(node.selector, MessageKind.CANNOT_RESOLVE_TYPE.error,
            {'typeName': node.selector});
      return;
    }
    loadSupertype(e, node);
  }
}

class VariableDefinitionsVisitor extends CommonResolverVisitor<String> {
  VariableDefinitions definitions;
  ResolverVisitor resolver;
  ElementKind kind;
  VariableListElement variables;

  VariableDefinitionsVisitor(Compiler compiler,
                             this.definitions, this.resolver, this.kind)
      : super(compiler) {
    variables = new VariableListElementX.node(
        definitions, ElementKind.VARIABLE_LIST, resolver.enclosingElement);
  }

  String visitSendSet(SendSet node) {
    assert(node.arguments.tail.isEmpty); // Sanity check
    Identifier identifier = node.selector;
    String name = identifier.source;
    VariableDefinitionScope scope =
        new VariableDefinitionScope(resolver.scope, name);
    resolver.visitIn(node.arguments.head, scope);
    if (scope.variableReferencedInInitializer) {
      resolver.error(identifier, MessageKind.REFERENCE_IN_INITIALIZATION,
                     {'variableName': name.toString()});
    }
    return name;
  }

  String visitIdentifier(Identifier node) {
    // The variable is initialized to null.
    resolver.world.registerInstantiatedClass(compiler.nullClass,
                                             resolver.mapping);
    if (definitions.modifiers.isConst()) {
      compiler.reportError(node, MessageKind.CONST_WITHOUT_INITIALIZER);
    }
    if (definitions.modifiers.isFinal() &&
        !resolver.allowFinalWithoutInitializer) {
      compiler.reportError(node, MessageKind.FINAL_WITHOUT_INITIALIZER);
    }
    return node.source;
  }

  visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      String name = visit(link.head);
      VariableElement element =
          new VariableElementX(name, variables, kind, link.head);
      resolver.defineElement(link.head, element);
      if (definitions.modifiers.isConst()) {
        compiler.enqueuer.resolution.addDeferredAction(element, () {
          compiler.constantHandler.compileVariable(element, isConst: true);
        });
      }
    }
  }
}

/**
 * [SignatureResolver] resolves function signatures.
 */
class SignatureResolver extends CommonResolverVisitor<Element> {
  final Element enclosingElement;
  final MessageKind defaultValuesError;
  Link<Element> optionalParameters = const Link<Element>();
  int optionalParameterCount = 0;
  bool isOptionalParameter = false;
  bool optionalParametersAreNamed = false;
  VariableDefinitions currentDefinitions;

  SignatureResolver(Compiler compiler,
                    this.enclosingElement,
                    {this.defaultValuesError})
      : super(compiler);

  bool get defaultValuesAllowed => defaultValuesError == null;

  Element visitNodeList(NodeList node) {
    // This must be a list of optional arguments.
    String value = node.beginToken.stringValue;
    if ((!identical(value, '[')) && (!identical(value, '{'))) {
      internalError(node, "expected optional parameters");
    }
    optionalParametersAreNamed = (identical(value, '{'));
    isOptionalParameter = true;
    LinkBuilder<Element> elements = analyzeNodes(node.nodes);
    optionalParameterCount = elements.length;
    optionalParameters = elements.toLink();
    return null;
  }

  Element visitVariableDefinitions(VariableDefinitions node) {
    Link<Node> definitions = node.definitions.nodes;
    if (definitions.isEmpty) {
      cancel(node, 'internal error: no parameter definition');
      return null;
    }
    if (!definitions.tail.isEmpty) {
      cancel(definitions.tail.head, 'internal error: extra definition');
      return null;
    }
    Node definition = definitions.head;
    if (definition is NodeList) {
      cancel(node, 'optional parameters are not implemented');
    }
    if (node.modifiers.isConst()) {
      error(node, MessageKind.FORMAL_DECLARED_CONST);
    }
    if (node.modifiers.isStatic()) {
      error(node, MessageKind.FORMAL_DECLARED_STATIC);
    }

    if (currentDefinitions != null) {
      cancel(node, 'function type parameters not supported');
    }
    currentDefinitions = node;
    Element element = definition.accept(this);
    currentDefinitions = null;
    return element;
  }

  void validateName(Identifier node) {
    String name = node.source;
    if (isOptionalParameter &&
        optionalParametersAreNamed &&
        isPrivateName(node.source)) {
      compiler.reportError(node, MessageKind.PRIVATE_NAMED_PARAMETER);
    }
  }

  Element visitIdentifier(Identifier node) {
    validateName(node);
    Element variables = new VariableListElementX.node(currentDefinitions,
        ElementKind.VARIABLE_LIST, enclosingElement);
    // Ensure a parameter is not typed 'void'.
    variables.computeType(compiler);
    return new VariableElementX(node.source, variables,
        ElementKind.PARAMETER, node);
  }

  String getParameterName(Send node) {
    var identifier = node.selector.asIdentifier();
    if (identifier != null) {
      // Normal parameter: [:Type name:].
      validateName(identifier);
      return identifier.source;
    } else {
      // Function type parameter: [:void name(DartType arg):].
      var functionExpression = node.selector.asFunctionExpression();
      if (functionExpression != null &&
          functionExpression.name.asIdentifier() != null) {
        validateName(functionExpression.name);
        return functionExpression.name.asIdentifier().source;
      } else {
        cancel(node,
            'internal error: unimplemented receiver on parameter send');
      }
    }
  }

  // The only valid [Send] can be in constructors and must be of the form
  // [:this.x:] (where [:x:] represents an instance field).
  FieldParameterElement visitSend(Send node) {
    FieldParameterElement element;
    if (node.receiver.asIdentifier() == null ||
        !node.receiver.asIdentifier().isThis()) {
      error(node, MessageKind.INVALID_PARAMETER);
    } else if (!identical(enclosingElement.kind,
                          ElementKind.GENERATIVE_CONSTRUCTOR)) {
      error(node, MessageKind.INITIALIZING_FORMAL_NOT_ALLOWED);
    } else {
      String name = getParameterName(node);
      Element fieldElement = currentClass.lookupLocalMember(name);
      if (fieldElement == null ||
          !identical(fieldElement.kind, ElementKind.FIELD)) {
        error(node, MessageKind.NOT_A_FIELD, {'fieldName': name});
      } else if (!fieldElement.isInstanceMember()) {
        error(node, MessageKind.NOT_INSTANCE_FIELD, {'fieldName': name});
      }
      Element variables = new VariableListElementX.node(currentDefinitions,
          ElementKind.VARIABLE_LIST, enclosingElement);
      element = new FieldParameterElementX(name, fieldElement, variables, node);
    }
    return element;
  }

  /// A [SendSet] node is an optional parameter with a default value.
  Element visitSendSet(SendSet node) {
    Element element;
    if (node.receiver != null) {
      element = visitSend(node);
    } else if (node.selector.asIdentifier() != null ||
               node.selector.asFunctionExpression() != null) {
      Element variables = new VariableListElementX.node(currentDefinitions,
          ElementKind.VARIABLE_LIST, enclosingElement);
      Identifier identifier = node.selector.asIdentifier() != null ?
          node.selector.asIdentifier() :
          node.selector.asFunctionExpression().name.asIdentifier();
      validateName(identifier);
      String source = identifier.source;
      element = new VariableElementX(source, variables,
          ElementKind.PARAMETER, node);
    }
    Node defaultValue = node.arguments.head;
    if (!defaultValuesAllowed) {
      error(defaultValue, defaultValuesError);
    }
    // Visit the value. The compile time constant handler will
    // make sure it's a compile time constant.
    resolveExpression(defaultValue);
    return element;
  }

  Element visitFunctionExpression(FunctionExpression node) {
    // This is a function typed parameter.
    Modifiers modifiers = currentDefinitions.modifiers;
    if (modifiers.isFinal()) {
      compiler.reportError(modifiers,
          MessageKind.FINAL_FUNCTION_TYPE_PARAMETER);
    }
    if (modifiers.isVar()) {
      compiler.reportError(modifiers, MessageKind.VAR_FUNCTION_TYPE_PARAMETER);
    }

    Element variable = visit(node.name);
    SignatureResolver.analyze(compiler, node.parameters, node.returnType,
        variable,
        defaultValuesError: MessageKind.FUNCTION_TYPE_FORMAL_WITH_DEFAULT);
    // TODO(ahe): Resolve and record the function type in the correct
    // [TreeElements].
    return variable;
  }

  LinkBuilder<Element> analyzeNodes(Link<Node> link) {
    LinkBuilder<Element> elements = new LinkBuilder<Element>();
    for (; !link.isEmpty; link = link.tail) {
      Element element = link.head.accept(this);
      if (element != null) {
        elements.addLast(element);
      } else {
        // If parameter is null, the current node should be the last,
        // and a list of optional named parameters.
        if (!link.tail.isEmpty || (link.head is !NodeList)) {
          internalError(link.head, "expected optional parameters");
        }
      }
    }
    return elements;
  }

  /**
   * Resolves formal parameters and return type to a [FunctionSignature].
   */
  static FunctionSignature analyze(Compiler compiler,
                                   NodeList formalParameters,
                                   Node returnNode,
                                   Element element,
                                   {MessageKind defaultValuesError}) {
    SignatureResolver visitor = new SignatureResolver(compiler, element,
        defaultValuesError: defaultValuesError);
    Link<Element> parameters = const Link<Element>();
    int requiredParameterCount = 0;
    if (formalParameters == null) {
      if (!element.isGetter()) {
        compiler.reportError(element, MessageKind.MISSING_FORMALS);
      }
    } else {
      if (element.isGetter()) {
        if (!identical(formalParameters.getEndToken().next.stringValue,
                       // TODO(ahe): Remove the check for native keyword.
                       'native')) {
          compiler.reportError(formalParameters,
                               MessageKind.EXTRA_FORMALS);
        }
      }
      LinkBuilder<Element> parametersBuilder =
        visitor.analyzeNodes(formalParameters.nodes);
      requiredParameterCount  = parametersBuilder.length;
      parameters = parametersBuilder.toLink();
    }
    DartType returnType;
    if (element.isFactoryConstructor()) {
      returnType = element.getEnclosingClass().computeType(compiler);
      // Because there is no type annotation for the return type of
      // this element, we explicitly add one.
      if (compiler.enableTypeAssertions) {
        compiler.enqueuer.resolution.registerIsCheck(
            returnType, new TreeElementMapping(element));
      }
    } else {
      returnType = compiler.resolveReturnType(element, returnNode);
    }

    if (element.isSetter() && (requiredParameterCount != 1 ||
                               visitor.optionalParameterCount != 0)) {
      // If there are no formal parameters, we already reported an error above.
      if (formalParameters != null) {
        compiler.reportError(formalParameters,
                                 MessageKind.ILLEGAL_SETTER_FORMALS);
      }
    }
    return new FunctionSignatureX(parameters,
                                  visitor.optionalParameters,
                                  requiredParameterCount,
                                  visitor.optionalParameterCount,
                                  visitor.optionalParametersAreNamed,
                                  returnType);
  }

  // TODO(ahe): This is temporary.
  void resolveExpression(Node node) {
    if (node == null) return;
    node.accept(new ResolverVisitor(compiler, enclosingElement,
                                    new TreeElementMapping(enclosingElement)));
  }

  // TODO(ahe): This is temporary.
  ClassElement get currentClass {
    return enclosingElement.isMember()
      ? enclosingElement.getEnclosingClass() : null;
  }
}

class ConstructorResolver extends CommonResolverVisitor<Element> {
  final ResolverVisitor resolver;
  bool inConstContext;
  DartType type;

  ConstructorResolver(Compiler compiler, this.resolver,
                      {bool this.inConstContext: false})
      : super(compiler);

  visitNode(Node node) {
    throw 'not supported';
  }

  failOrReturnErroneousElement(Element enclosing, Node diagnosticNode,
                               String targetName, DualKind kind,
                               Map arguments) {
    if (kind == MessageKind.CANNOT_FIND_CONSTRUCTOR) {
      compiler.backend.registerThrowNoSuchMethod(resolver.mapping);
    } else {
      compiler.backend.registerThrowRuntimeError(resolver.mapping);
    }
    if (inConstContext) {
      compiler.reportError(diagnosticNode, kind.error, arguments);
    } else {
      ResolutionWarning warning  =
          new ResolutionWarning(
              kind.warning, arguments, compiler.terseDiagnostics);
      compiler.reportWarning(diagnosticNode, warning);
    }
    return new ErroneousElementX(
        kind.error, arguments, targetName, enclosing);
  }

  Selector createConstructorSelector(String constructorName) {
    return constructorName == ''
        ? new Selector.callDefaultConstructor(
            resolver.enclosingElement.getLibrary())
        : new Selector.callConstructor(
            constructorName,
            resolver.enclosingElement.getLibrary());
  }

  // TODO(ngeoffray): method named lookup should not report errors.
  FunctionElement lookupConstructor(ClassElement cls,
                                    Node diagnosticNode,
                                    String constructorName) {
    cls.ensureResolved(compiler);
    Selector selector = createConstructorSelector(constructorName);
    Element result = cls.lookupConstructor(selector);
    if (result == null) {
      String fullConstructorName =
          resolver.compiler.resolver.constructorNameForDiagnostics(
              cls.name,
              constructorName);
      return failOrReturnErroneousElement(
          cls,
          diagnosticNode,
          fullConstructorName,
          MessageKind.CANNOT_FIND_CONSTRUCTOR,
          {'constructorName': fullConstructorName});
    } else if (inConstContext && !result.modifiers.isConst()) {
      error(diagnosticNode, MessageKind.CONSTRUCTOR_IS_NOT_CONST);
    }
    return result;
  }

  Element visitNewExpression(NewExpression node) {
    inConstContext = node.isConst();
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
    if (!Elements.isUnresolved(element) && !element.isConstructor()) {
      if (element.isClass()) {
        ClassElement cls = element;
        cls.ensureResolved(compiler);
        // The unnamed constructor may not exist, so [e] may become unresolved.
        element = lookupConstructor(cls, diagnosticNode, '');
      } else {
        element = failOrReturnErroneousElement(
            element, diagnosticNode, element.name, MessageKind.NOT_A_TYPE,
            {'node': diagnosticNode});
      }
    }
    if (type == null) {
      if (Elements.isUnresolved(element)) {
        type = compiler.types.dynamicType;
      } else {
        type = element.getEnclosingClass().computeType(compiler).asRaw();
      }
    }
    resolver.mapping.setType(expression, type);
    return element;
  }

  Element visitTypeAnnotation(TypeAnnotation node) {
    assert(invariant(node, type == null));
    type = resolver.resolveTypeAnnotation(node,
                                          malformedIsError: inConstContext);
    compiler.backend.registerRequiredType(type, resolver.enclosingElement);
    return type.element;
  }

  Element visitSend(Send node) {
    Element element = visit(node.receiver);
    assert(invariant(node.receiver, element != null,
        message: 'No element return for $node.receiver.'));
    if (Elements.isUnresolved(element)) return element;
    Identifier name = node.selector.asIdentifier();
    if (name == null) internalError(node.selector, 'unexpected node');

    if (element.isClass()) {
      ClassElement cls = element;
      cls.ensureResolved(compiler);
      return lookupConstructor(cls, name, name.source);
    } else if (element.isPrefix()) {
      PrefixElement prefix = element;
      element = prefix.lookupLocalMember(name.source);
      element = Elements.unwrap(element, compiler, node);
      if (element == null) {
        return failOrReturnErroneousElement(
            resolver.enclosingElement, name,
            name.source,
            MessageKind.CANNOT_RESOLVE,
            {'name': name});
      } else if (!element.isClass()) {
        error(node, MessageKind.NOT_A_TYPE.error, {'node': name});
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
    // TODO(johnniwinther): Change errors to warnings, cf. 11.11.1.
    if (element == null) {
      return failOrReturnErroneousElement(resolver.enclosingElement, node, name,
                                          MessageKind.CANNOT_RESOLVE,
                                          {'name': name});
    } else if (element.isErroneous()) {
      return element;
    } else if (element.isTypedef()) {
      error(node, MessageKind.CANNOT_INSTANTIATE_TYPEDEF,
            {'typedefName': name});
    } else if (element.isTypeVariable()) {
      error(node, MessageKind.CANNOT_INSTANTIATE_TYPE_VARIABLE,
            {'typeVariableName': name});
    } else if (!element.isClass() && !element.isPrefix()) {
      error(node, MessageKind.NOT_A_TYPE.error, {'node': name});
    }
    return element;
  }

  /// Assumed to be called by [resolveRedirectingFactory].
  Element visitReturn(Return node) {
    Node expression = node.expression;
    return finishConstructorReference(visit(expression),
                                      expression, expression);
  }
}

/// Looks up [name] in [scope] and unwraps the result.
Element lookupInScope(Compiler compiler, Node node,
                      Scope scope, String name) {
  return Elements.unwrap(scope.lookup(name), compiler, node);
}
