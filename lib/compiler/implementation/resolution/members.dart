// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class TreeElements {
  Element operator[](Node node);
  Selector getSelector(Send send);
  DartType getType(Node node);
  bool isParameterChecked(Element element);
}

class TreeElementMapping implements TreeElements {
  final Element currentElement;
  final Map<Node, Element> map;
  final Map<Node, Selector> selectors;
  final Map<Node, DartType> types;
  final Set<Element> checkedParameters;

  TreeElementMapping([Element this.currentElement])
      : map = new LinkedHashMap<Node, Element>(),
        selectors = new LinkedHashMap<Node, Selector>(),
        types = new LinkedHashMap<Node, DartType>(),
        checkedParameters = new Set<Element>();

  operator []=(Node node, Element element) {
    assert(invariant(node, () {
      if (node is FunctionExpression) {
        return !node.modifiers.isExternal();
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

    map[node] = element;
  }
  operator [](Node node) => map[node];
  void remove(Node node) { map.remove(node); }

  void setType(Node node, DartType type) {
    types[node] = type;
  }

  DartType getType(Node node) => types[node];

  void setSelector(Node node, Selector selector) {
    selectors[node] = selector;
  }

  Selector getSelector(Node node) => selectors[node];

  bool isParameterChecked(Element element) {
    return checkedParameters.contains(element);
  }
}

class ResolverTask extends CompilerTask {
  ResolverTask(Compiler compiler) : super(compiler);

  String get name => 'Resolver';

  TreeElements resolve(Element element) {
    return measure(() {
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

      compiler.unimplemented("resolve($element)",
                             node: element.parseNode(compiler));
    });
  }

  bool isNamedConstructor(Send node) => node.receiver != null;

  SourceString getConstructorName(Send node) {
    return node.selector.asIdentifier().source;
  }

  String constructorNameForDiagnostics(SourceString className,
                                   SourceString constructorName) {
    String classNameString = className.slowToString();
    String constructorNameString = constructorName.slowToString();
    return (identical(constructorName, const SourceString('')))
        ? classNameString
        : "$classNameString.$constructorNameString";
   }

  FunctionElement resolveConstructorRedirection(InitializerResolver resolver,
                                                FunctionElement constructor) {
    if (constructor.isPatched) {
      checkMatchingPatchSignatures(constructor, constructor.patch);
      constructor = constructor.patch;
    }
    FunctionExpression node = constructor.parseNode(compiler);

    // A synthetic constructor does not have a node.
    if (node == null) return null;
    if (node.initializers == null) return null;
    Link<Node> initializers = node.initializers.nodes;
    if (!initializers.isEmpty() &&
        Initializers.isConstructorRedirect(initializers.head)) {
      final ClassElement classElement = constructor.getEnclosingClass();
      Selector selector;
      if (isNamedConstructor(initializers.head)) {
        SourceString constructorName = getConstructorName(initializers.head);
        selector = new Selector.callConstructor(
            constructorName,
            resolver.visitor.enclosingElement.getLibrary());
      } else {
        selector = new Selector.callDefaultConstructor(
            resolver.visitor.enclosingElement.getLibrary());
      }
      return classElement.lookupConstructor(selector);
    }
    return null;
  }

  void resolveRedirectingConstructor(InitializerResolver resolver,
                                     Node node,
                                     FunctionElement constructor,
                                     FunctionElement redirection) {
    Set<FunctionElement> seen = new Set<FunctionElement>();
    seen.add(constructor);
    while (redirection != null) {
      if (seen.contains(redirection)) {
        resolver.visitor.error(node, MessageKind.REDIRECTING_CONSTRUCTOR_CYCLE);
        return;
      }
      seen.add(redirection);
      redirection = resolveConstructorRedirection(resolver, redirection);
    }
  }

  void checkMatchingPatchParameters(FunctionElement origin,
                                    Link<Element> originParameters,
                                    Link<Element> patchParameters) {
    while (!originParameters.isEmpty()) {
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
        error(originParameter.parseNode(compiler),
            MessageKind.PATCH_PARAMETER_MISMATCH,
            [origin.name, originParameterText, patchParameterText]);
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
        error(errorNode, MessageKind.PATCH_RETURN_TYPE_MISMATCH, [origin.name,
              originSignature.returnType, patchSignature.returnType]);
      });
    }
    if (originSignature.requiredParameterCount !=
        patchSignature.requiredParameterCount) {
      compiler.withCurrentElement(patch, () {
        error(patchTree,
              MessageKind.PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH,
              [origin.name, originSignature.requiredParameterCount,
               patchSignature.requiredParameterCount]);
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
              [origin.name]);
        });
      }
    }
    if (originSignature.optionalParameterCount !=
        patchSignature.optionalParameterCount) {
      compiler.withCurrentElement(patch, () {
        error(patchTree,
              MessageKind.PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH,
              [origin.name, originSignature.optionalParameterCount,
               patchSignature.optionalParameterCount]);
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
        assert(isConstructor);
        return elements;
      }
      if (element.isPatched) {
        checkMatchingPatchSignatures(element, element.patch);
        element = element.patch;
      }
      return compiler.withCurrentElement(element, () {
        FunctionExpression tree = element.parseNode(compiler);
        if (isConstructor) {
          if (tree.returnType != null) {
            error(tree, MessageKind.CONSTRUCTOR_WITH_RETURN_TYPE);
          }
          resolveConstructorImplementation(element, tree);
        }
        ResolverVisitor visitor = new ResolverVisitor(compiler, element);
        visitor.useElement(tree, element);
        visitor.setupFunction(tree, element);

        if (isConstructor) {
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
        visitBody(visitor, tree.body);

        return visitor.mapping;
      });
    });
  }

  void visitBody(ResolverVisitor visitor, Statement body) {
    visitor.visit(body);
  }

  void resolveConstructorImplementation(FunctionElement constructor,
                                        FunctionExpression node) {
    if (!identical(constructor.defaultImplementation, constructor)) return;
    ClassElement intrface = constructor.getEnclosingClass();
    if (!intrface.isInterface()) return;
    DartType defaultType = intrface.defaultClass;
    if (defaultType == null) {
      error(node, MessageKind.NO_DEFAULT_CLASS, [intrface.name]);
    }
    ClassElement defaultClass = defaultType.element;
    defaultClass.ensureResolved(compiler);
    assert(defaultClass.resolutionState == STATE_DONE);
    assert(defaultClass.supertypeLoadState == STATE_DONE);
    if (defaultClass.isInterface()) {
      error(node, MessageKind.CANNOT_INSTANTIATE_INTERFACE,
            [defaultClass.name]);
    }
    // We have now established the following:
    // [intrface] is an interface, let's say "MyInterface".
    // [defaultClass] is a class, let's say "MyClass".

    Selector selector;
    // If the default class implements the interface then we must use the
    // default class' name. Otherwise we look for a factory with the name
    // of the interface.
    if (defaultClass.implementsInterface(intrface)) {
      var constructorNameString = constructor.name.slowToString();
      // Create selector based on constructor.name but where interface
      // is replaced with default class name.
      // TODO(ahe): Don't use string manipulations here.
      int classNameSeparatorIndex = constructorNameString.indexOf('\$');
      if (classNameSeparatorIndex < 0) {
        selector = new Selector.callDefaultConstructor(
            defaultClass.getLibrary());
      } else {
        selector = new Selector.callConstructor(
            new SourceString(
                constructorNameString.substring(classNameSeparatorIndex + 1)),
            defaultClass.getLibrary());
      }
      constructor.defaultImplementation =
          defaultClass.lookupConstructor(selector);
    } else {
      selector =
          new Selector.callConstructor(constructor.name,
                                       defaultClass.getLibrary());
      constructor.defaultImplementation =
          defaultClass.lookupFactoryConstructor(selector);
    }
    if (constructor.defaultImplementation == null) {
      // We failed to find a constructor named either
      // "MyInterface.name" or "MyClass.name".
      // TODO(aprelev@gmail.com): Use constructorNameForDiagnostics in
      // the error message below.
      error(node,
            MessageKind.CANNOT_FIND_CONSTRUCTOR2,
            [selector.name, defaultClass.name]);
    }
  }

  TreeElements resolveField(VariableElement element) {
    Node tree = element.parseNode(compiler);
    if(element.modifiers.isStatic() && element.variables.isTopLevel()) {
      error(element.modifiers.getStatic(), MessageKind.TOP_LEVEL_VARIABLE_DECLARED_STATIC);
    }
    ResolverVisitor visitor = new ResolverVisitor(compiler, element);
    initializerDo(tree, visitor.visit);
    return visitor.mapping;
  }

  TreeElements resolveParameter(Element element) {
    Node tree = element.parseNode(compiler);
    ResolverVisitor visitor =
        new ResolverVisitor(compiler, element.enclosingElement);
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
    ResolverVisitor visitor = new ResolverVisitor(compiler, element);
    DartType result = visitor.resolveTypeAnnotation(annotation);
    if (result == null) {
      // TODO(karklose): warning.
      return compiler.types.dynamicType;
    }
    return result;
  }

  /**
   * Load and resolve the supertypes of [cls].
   *
   * Warning: do not call this method directly. It should only be
   * called by [resolveClass] and [ClassSupertypeResolver].
   */
  void loadSupertypes(ClassElement cls, Node from) {
    compiler.withCurrentElement(cls, () => measure(() {
      if (cls.supertypeLoadState == STATE_DONE) return;
      if (cls.supertypeLoadState == STATE_STARTED) {
        compiler.reportMessage(
          compiler.spanFromNode(from),
          MessageKind.CYCLIC_CLASS_HIERARCHY.error([cls.name]),
          Diagnostic.ERROR);
        cls.supertypeLoadState = STATE_DONE;
        cls.allSupertypes = const Link<DartType>().prepend(
            compiler.objectClass.computeType(compiler));
        // TODO(ahe): We should also set cls.supertype here to avoid
        // creating a malformed class hierarchy.
        return;
      }
      cls.supertypeLoadState = STATE_STARTED;
      compiler.withCurrentElement(cls, () {
        // TODO(ahe): Cache the node in cls.
        cls.parseNode(compiler).accept(new ClassSupertypeResolver(compiler,
                                                                  cls));
        if (cls.supertypeLoadState != STATE_DONE) {
          cls.supertypeLoadState = STATE_DONE;
        }
      });
    }));
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
  void resolveClass(ClassElement element) {
    if (!element.isPatch) {
      compiler.withCurrentElement(element, () => measure(() {
        assert(element.resolutionState == STATE_NOT_STARTED);
        element.resolutionState = STATE_STARTED;
        ClassNode tree = element.parseNode(compiler);
        loadSupertypes(element, tree);

        ClassResolverVisitor visitor =
            new ClassResolverVisitor(compiler, element);
        visitor.visit(tree);
        element.resolutionState = STATE_DONE;
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
      element.defaultClass = element.origin.defaultClass;
      element.interfaces = element.origin.interfaces;
      element.allSupertypes = element.origin.allSupertypes;
      // Stepwise assignment to ensure invariant.
      element.supertypeLoadState = STATE_STARTED;
      element.supertypeLoadState = STATE_DONE;
      element.resolutionState = STATE_DONE;
      // TODO(johnniwinther): Check matching type variables and
      // empty extends/implements clauses.
    }
  }

  void checkMembers(ClassElement cls) {
    assert(invariant(cls, cls.isDeclaration));
    if (cls.isObject(compiler)) return;
    // TODO(johnniwinther): Should this be done on the implementation element as
    // well?
    cls.forEachMember((holder, member) {
      // Perform various checks as side effect of "computing" the type.
      member.computeType(compiler);

      // Check modifiers.
      if (member.isFunction() && member.modifiers.isFinal()) {
        compiler.reportMessage(
          compiler.spanFromElement(member),
          MessageKind.ILLEGAL_FINAL_METHOD_MODIFIER.error(),
          Diagnostic.ERROR);
      }
      if (member.isConstructor()) {
        final mismatchedFlagsBits =
          member.modifiers.flags &
          (Modifiers.FLAG_STATIC | Modifiers.FLAG_ABSTRACT);
        if (mismatchedFlagsBits != 0) {
          final mismatchedFlags =
            new Modifiers.withFlags(null, mismatchedFlagsBits);
          compiler.reportMessage(
            compiler.spanFromElement(member),
            MessageKind.ILLEGAL_CONSTRUCTOR_MODIFIERS.error([mismatchedFlags]),
            Diagnostic.ERROR);
        }
      }
      checkAbstractField(member);
      checkValidOverride(member, cls.lookupSuperMember(member.name));
    });
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
      compiler.reportMessage(
          compiler.spanFromElement(field.getter),
          MessageKind.GETTER_MISMATCH.error([mismatchedFlags]),
          Diagnostic.ERROR);
      compiler.reportMessage(
          compiler.spanFromElement(field.setter),
          MessageKind.SETTER_MISMATCH.error([mismatchedFlags]),
          Diagnostic.ERROR);
    }
  }

  reportErrorWithContext(Element errorneousElement,
                         MessageKind errorMessage,
                         Element contextElement,
                         MessageKind contextMessage) {
    compiler.reportMessage(
        compiler.spanFromElement(errorneousElement),
        errorMessage.error([contextElement.name,
                            contextElement.getEnclosingClass().name]),
        Diagnostic.ERROR);
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
    return compiler.withCurrentElement(element, () {
      FunctionExpression node =
          compiler.parser.measure(() => element.parseNode(compiler));
      return measure(() => SignatureResolver.analyze(
          compiler, node.parameters, node.returnType, element));
    });
  }

  FunctionSignature resolveFunctionExpression(Element element,
                                              FunctionExpression node) {
    return measure(() => SignatureResolver.analyze(
      compiler, node.parameters, node.returnType, element));
  }

  void resolveTypedef(TypedefElement element) {
    if (element.isResolved || element.isBeingResolved) return;
    element.isBeingResolved = true;
    return compiler.withCurrentElement(element, () {
      measure(() {
        Typedef node =
          compiler.parser.measure(() => element.parseNode(compiler));
        TypedefResolverVisitor visitor =
          new TypedefResolverVisitor(compiler, element);
        visitor.visit(node);

        element.isBeingResolved = false;
        element.isResolved = true;
      });
    });
  }

  FunctionType computeFunctionType(Element element,
                                   FunctionSignature signature) {
    LinkBuilder<DartType> parameterTypes = new LinkBuilder<DartType>();
    for (Link<Element> link = signature.requiredParameters;
         !link.isEmpty();
         link = link.tail) {
       parameterTypes.addLast(link.head.computeType(compiler));
       // TODO(karlklose): optional parameters.
    }
    return new FunctionType(signature.returnType,
                            parameterTypes.toLink(),
                            element);
  }

  void resolveMetadataAnnotation(PartialMetadataAnnotation annotation) {
    compiler.withCurrentElement(annotation.annotatedElement, () => measure(() {
      assert(annotation.resolutionState == STATE_NOT_STARTED);
      annotation.resolutionState = STATE_STARTED;

      Node node = annotation.parseNode(compiler);
      ResolverVisitor visitor = new ResolverVisitor(
          compiler, annotation.annotatedElement.enclosingElement);
      node.accept(visitor);
      annotation.value = compiler.constantHandler.compileNodeWithDefinitions(
          node, visitor.mapping);

      annotation.resolutionState = STATE_DONE;
    }));
  }

  error(Node node, MessageKind kind, [arguments = const []]) {
    ResolutionError message = new ResolutionError(kind, arguments);
    compiler.reportError(node, message);
  }
}

class InitializerResolver {
  final ResolverVisitor visitor;
  final Map<SourceString, Node> initialized;
  Link<Node> initializers;
  bool hasSuper;

  InitializerResolver(this.visitor)
    : initialized = new Map<SourceString, Node>(), hasSuper = false;

  error(Node node, MessageKind kind, [arguments = const []]) {
    visitor.error(node, kind, arguments);
  }

  warning(Node node, MessageKind kind, [arguments = const []]) {
    visitor.warning(node, kind, arguments);
  }

  bool isFieldInitializer(SendSet node) {
    if (node.selector.asIdentifier() == null) return false;
    if (node.receiver == null) return true;
    if (node.receiver.asIdentifier() == null) return false;
    return node.receiver.asIdentifier().isThis();
  }

  void checkForDuplicateInitializers(SourceString name, Node init) {
    if (initialized.containsKey(name)) {
      error(init, MessageKind.DUPLICATE_INITIALIZER, [name]);
      warning(initialized[name], MessageKind.ALREADY_INITIALIZED, [name]);
    }
    initialized[name] = init;
  }

  void resolveFieldInitializer(FunctionElement constructor, SendSet init) {
    // init is of the form [this.]field = value.
    final Node selector = init.selector;
    final SourceString name = selector.asIdentifier().source;
    // Lookup target field.
    Element target;
    if (isFieldInitializer(init)) {
      target = constructor.getEnclosingClass().lookupLocalMember(name);
      if (target == null) {
        error(selector, MessageKind.CANNOT_RESOLVE, [name]);
      } else if (target.kind != ElementKind.FIELD) {
        error(selector, MessageKind.NOT_A_FIELD, [name]);
      } else if (!target.isInstanceMember()) {
        error(selector, MessageKind.INIT_STATIC_FIELD, [name]);
      }
    } else {
      error(init, MessageKind.INVALID_RECEIVER_IN_INITIALIZER);
    }
    visitor.useElement(init, target);
    visitor.world.registerStaticUse(target);
    checkForDuplicateInitializers(name, init);
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
      visitor.resolveSelector(call);
      visitor.resolveArguments(call.argumentsNode);
    });
    Selector selector = visitor.mapping.getSelector(call);
    bool isSuperCall = Initializers.isSuperConstructorCall(call);

    ClassElement lookupTarget = getSuperOrThisLookupTarget(constructor,
                                                           isSuperCall,
                                                           call);
    final SourceString className = lookupTarget.name;

    SourceString constructorName;
    Selector lookupSelector;
    if (resolver.isNamedConstructor(call)) {
      constructorName = resolver.getConstructorName(call);
      lookupSelector = new Selector.callConstructor(
          constructorName,
          visitor.enclosingElement.getLibrary());
    } else {
      constructorName = const SourceString('');
      lookupSelector = new Selector.callDefaultConstructor(
          visitor.enclosingElement.getLibrary());
    }

    FunctionElement lookedupConstructor =
        lookupTarget.lookupConstructor(lookupSelector);

    final bool isImplicitSuperCall = false;
    verifyThatConstructorMatchesCall(lookedupConstructor,
                                     selector,
                                     isImplicitSuperCall,
                                     call,
                                     constructorName,
                                     className);

    visitor.useElement(call, lookedupConstructor);
    visitor.world.registerStaticUse(lookedupConstructor);
    return lookedupConstructor;
  }

  void resolveImplicitSuperConstructorSend(FunctionElement constructor,
                                           FunctionExpression functionNode) {
    // If the class has a super resolve the implicit super call.
    ClassElement classElement = constructor.getEnclosingClass();
    ClassElement superClass = classElement.superclass;
    if (classElement != visitor.compiler.objectClass) {
      assert(superClass != null);
      assert(superClass.resolutionState == STATE_DONE);
      SourceString constructorName = const SourceString('');
      Selector callToMatch = new Selector.call(
          constructorName,
          classElement.getLibrary(),
          0);

      final bool isSuperCall = true;
      ClassElement lookupTarget = getSuperOrThisLookupTarget(constructor,
                                                             isSuperCall,
                                                             functionNode);
      final SourceString className = lookupTarget.name;
      Element calledConstructor = lookupTarget.lookupConstructor(
          new Selector.callDefaultConstructor(
              visitor.enclosingElement.getLibrary()));

      final bool isImplicitSuperCall = true;
      verifyThatConstructorMatchesCall(calledConstructor,
                                       callToMatch,
                                       isImplicitSuperCall,
                                       functionNode,
                                       className,
                                       const SourceString(''));

      visitor.world.registerStaticUse(calledConstructor);
    }
  }

  void verifyThatConstructorMatchesCall(
      FunctionElement lookedupConstructor,
      Selector call,
      bool isImplicitSuperCall,
      Node diagnosticNode,
      SourceString className,
      SourceString constructorName) {
    if (lookedupConstructor == null
        || !lookedupConstructor.isGenerativeConstructor()) {
      var fullConstructorName =
          visitor.compiler.resolver.constructorNameForDiagnostics(className,
                                                              constructorName);
      MessageKind kind = isImplicitSuperCall
          ? MessageKind.CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT
          : MessageKind.CANNOT_RESOLVE_CONSTRUCTOR;
      error(diagnosticNode, kind, [fullConstructorName]);
    } else {
      if (!call.applies(lookedupConstructor, visitor.compiler)) {
        MessageKind kind = isImplicitSuperCall
                           ? MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT
                           : MessageKind.NO_MATCHING_CONSTRUCTOR;
        error(diagnosticNode, kind);
      }
    }
  }

  FunctionElement resolveRedirection(FunctionElement constructor,
                                     FunctionExpression functionNode) {
    if (functionNode.initializers == null) return null;
    Link<Node> link = functionNode.initializers.nodes;
    if (!link.isEmpty() && Initializers.isConstructorRedirect(link.head)) {
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
        checkForDuplicateInitializers(element.name,
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
         !link.isEmpty();
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
          // Check that there is no body (Language specification 7.5.1).
          if (functionNode.hasBody()) {
            error(functionNode, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_BODY);
          }
          // Check that there are no other initializers.
          if (!initializers.tail.isEmpty()) {
            error(call, MessageKind.REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER);
          }
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

  void error(Node node, MessageKind kind, [arguments = const []]) {
    ResolutionError message  = new ResolutionError(kind, arguments);
    compiler.reportError(node, message);
  }

  void warning(Node node, MessageKind kind, [arguments = const []]) {
    ResolutionWarning message  = new ResolutionWarning(kind, arguments);
    compiler.reportWarning(node, message);
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
    breakTargetStack.isEmpty() ? null : breakTargetStack.head;

  TargetElement currentContinueTarget() =>
    continueTargetStack.isEmpty() ? null : continueTargetStack.head;

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

  Element resolveTypeName(Scope scope, TypeAnnotation node) {
    Identifier typeName = node.typeName.asIdentifier();
    Send send = node.typeName.asSend();
    return resolveTypeNameInternal(scope, typeName, send);
  }

  Element resolveTypeNameInternal(Scope scope, Identifier typeName, Send send) {
    if (send != null) {
      typeName = send.selector;
    }
    if (identical(typeName.source.stringValue, 'void')) {
      return compiler.types.voidType.element;
    } else if (
        // TODO(aprelev@gmail.com): Remove deprecated Dynamic keyword support.
        identical(typeName.source.stringValue, 'Dynamic')
        || identical(typeName.source.stringValue, 'dynamic')) {
      return compiler.dynamicClass;
    } else if (send != null) {
      Element e = scope.lookup(send.receiver.asIdentifier().source);
      if (e != null && identical(e.kind, ElementKind.PREFIX)) {
        // The receiver is a prefix. Lookup in the imported members.
        PrefixElement prefix = e;
        return prefix.lookupLocalMember(typeName.source);
      } else if (e != null && identical(e.kind, ElementKind.CLASS)) {
        // The receiver is the class part of a named constructor.
        return e;
      } else {
        return null;
      }
    } else {
      return scope.lookup(typeName.source);
    }
  }

  // TODO(johnniwinther): Change  [onFailure] and [whenResolved] to use boolean
  // flags instead of closures.
  // TODO(johnniwinther): Should never return [null] but instead an erroneous
  // type.
  DartType resolveTypeAnnotation(TypeAnnotation node,
                                 {Scope inScope, ClassElement inClass,
                                 onFailure(Node, MessageKind, [List arguments]),
                                 whenResolved(Node, Type)}) {
    if (onFailure == null) {
      onFailure = (n, k, [arguments]) {};
    }
    if (whenResolved == null) {
      whenResolved = (n, t) {};
    }
    if (inClass != null) {
      inScope = inClass.buildScope();
    }
    if (inScope == null) {
      compiler.internalError('resolveTypeAnnotation: no scope specified');
    }
    return resolveTypeAnnotationInContext(inScope, node, onFailure,
                                          whenResolved);
  }

  DartType resolveTypeAnnotationInContext(Scope scope, TypeAnnotation node,
                                          onFailure, whenResolved) {
    Element element = resolveTypeName(scope, node);
    DartType type;
    if (element == null) {
      onFailure(node, MessageKind.CANNOT_RESOLVE_TYPE, [node.typeName]);
    } else if (element.isErroneous()) {
      ErroneousElement error = element;
      onFailure(node, error.messageKind, error.messageArguments);
    } else if (!element.impliesType()) {
      onFailure(node, MessageKind.NOT_A_TYPE, [node.typeName]);
    } else {
      if (identical(element, compiler.types.voidType.element) ||
          identical(element, compiler.types.dynamicType.element)) {
        type = element.computeType(compiler);
      } else if (element.isClass()) {
        ClassElement cls = element;
        cls.ensureResolved(compiler);
        Link<DartType> arguments =
            resolveTypeArguments(node, cls.typeVariables, scope,
                                 onFailure, whenResolved);
        if (cls.typeVariables.isEmpty() && arguments.isEmpty()) {
          // Use the canonical type if it has no type parameters.
          type = cls.computeType(compiler);
        } else {
          type = new InterfaceType(cls, arguments);
        }
      } else if (element.isTypedef()) {
        TypedefElement typdef = element;
        // TODO(ahe): Should be [ensureResolved].
        compiler.resolveTypedef(typdef);
        typdef.computeType(compiler);
        Link<DartType> arguments = resolveTypeArguments(
            node, typdef.typeVariables,
            scope, onFailure, whenResolved);
        if (typdef.typeVariables.isEmpty() && arguments.isEmpty()) {
          // Return the canonical type if it has no type parameters.
          type = typdef.computeType(compiler);
        } else {
          type = new TypedefType(typdef, arguments);
        }
      } else if (element.isTypeVariable()) {
        type = element.computeType(compiler);
      } else {
        compiler.cancel("unexpected element kind ${element.kind}",
                        node: node);
      }
    }
    whenResolved(node, type);
    return type;
  }

  Link<DartType> resolveTypeArguments(TypeAnnotation node,
                                      Link<DartType> typeVariables,
                                      Scope scope, onFailure, whenResolved) {
    if (node.typeArguments == null) {
      return const Link<DartType>();
    }
    var arguments = new LinkBuilder<DartType>();
    for (Link<Node> typeArguments = node.typeArguments.nodes;
         !typeArguments.isEmpty();
         typeArguments = typeArguments.tail) {
      if (typeVariables.isEmpty()) {
        onFailure(typeArguments.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT);
      }
      DartType argType = resolveTypeAnnotationInContext(scope,
                                                    typeArguments.head,
                                                    onFailure,
                                                    whenResolved);
      arguments.addLast(argType);
      if (!typeVariables.isEmpty()) {
        typeVariables = typeVariables.tail;
      }
    }
    if (!typeVariables.isEmpty()) {
      onFailure(node.typeArguments, MessageKind.MISSING_TYPE_ARGUMENT);
    }
    return arguments.toLink();
  }
}

class ResolverVisitor extends CommonResolverVisitor<Element> {
  final TreeElementMapping mapping;
  Element enclosingElement;
  final TypeResolver typeResolver;
  bool inInstanceContext;
  bool inCheckContext;
  bool inCatchBlock;
  Scope scope;
  ClassElement currentClass;
  ExpressionStatement currentExpressionStatement;
  bool typeRequired = false;
  StatementScope statementScope;
  int allowedCategory = ElementCategory.VARIABLE | ElementCategory.FUNCTION;

  ResolverVisitor(Compiler compiler, Element element)
    : this.mapping  = new TreeElementMapping(element),
      this.enclosingElement = element,
      // When the element is a field, we are actually resolving its
      // initial value, which should not have access to instance
      // fields.
      inInstanceContext = (element.isInstanceMember() && !element.isField())
          || element.isGenerativeConstructor(),
      this.currentClass = element.isMember() ? element.getEnclosingClass()
                                             : null,
      this.statementScope = new StatementScope(),
      typeResolver = new TypeResolver(compiler),
      scope = element.buildScope(),
      inCheckContext = compiler.enableTypeAssertions,
      inCatchBlock = false,
      super(compiler);

  Enqueuer get world => compiler.enqueuer.resolution;

  Element lookup(Node node, SourceString name) {
    Element result = scope.lookup(name);
    if (!inInstanceContext && result != null && result.isInstanceMember()) {
      error(node, MessageKind.NO_INSTANCE_AVAILABLE, [node]);
    }
    return result;
  }

  // Create, or reuse an already created, statement element for a statement.
  TargetElement getOrCreateTargetElement(Node statement) {
    TargetElement element = mapping[statement];
    if (element == null) {
      element = new TargetElement(statement,
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

  visitInStaticContext(Node node) {
    inStaticContext(() => visit(node));
  }

  ErroneousElement warnAndCreateErroneousElement(Node node,
                                                 SourceString name,
                                                 MessageKind kind,
                                                 List<Node> arguments) {
    return warnOnErroneousElement(node,
        new ErroneousElement(kind, arguments, name, enclosingElement));
  }

  ErroneousElement warnOnErroneousElement(Node node,
                                          ErroneousElement erroneousElement) {
    ResolutionWarning warning =
        new ResolutionWarning(erroneousElement.messageKind,
                              erroneousElement.messageArguments);
    compiler.reportWarning(node, warning);
    return erroneousElement;
  }

  Element visitIdentifier(Identifier node) {
    if (node.isThis()) {
      if (!inInstanceContext) {
        error(node, MessageKind.NO_INSTANCE_AVAILABLE, [node]);
      }
      return null;
    } else if (node.isSuper()) {
      if (!inInstanceContext) error(node, MessageKind.NO_SUPER_IN_STATIC);
      if ((ElementCategory.SUPER & allowedCategory) == 0) {
        error(node, MessageKind.INVALID_USE_OF_SUPER);
      }
      return null;
    } else {
      Element element = lookup(node, node.source);
      if (element == null) {
        if (!inInstanceContext) {
          element = warnAndCreateErroneousElement(node, node.source,
                                                  MessageKind.CANNOT_RESOLVE,
                                                  [node]);
        }
      } else if (element.isErroneous()) {
        element = warnOnErroneousElement(node, element);
      } else {
        if ((element.kind.category & allowedCategory) == 0) {
          // TODO(ahe): Improve error message. Need UX input.
          error(node, MessageKind.GENERIC, ["is not an expression $element"]);
        }
      }
      return useElement(node, element);
    }
  }

  Element visitTypeAnnotation(TypeAnnotation node) {
    DartType type = resolveTypeAnnotation(node);
    if (type != null) {
      if (inCheckContext) {
        compiler.enqueuer.resolution.registerIsCheck(type);
      }
      return type.element;
    }
    return null;
  }

  Element defineElement(Node node, Element element,
                        {bool doAddToScope: true}) {
    compiler.ensure(element != null);
    mapping[node] = element;
    if (doAddToScope) {
      Element existing = scope.add(element);
      if (existing != element) {
        error(node, MessageKind.DUPLICATE_DEFINITION, [node]);
      }
    }
    return element;
  }

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

  void setupFunction(FunctionExpression node, FunctionElement function) {
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
    SourceString name;
    if (node.name == null) {
      name = const SourceString("");
    } else {
      name = node.name.asIdentifier().source;
    }

    FunctionElement function = new FunctionElement.node(
        name, node, ElementKind.FUNCTION, Modifiers.EMPTY,
        enclosingElement);
    Scope oldScope = scope; // The scope is modified by [setupFunction].
    setupFunction(node, function);
    defineElement(node, function, doAddToScope: node.name !== null);

    Element previousEnclosingElement = enclosingElement;
    enclosingElement = function;
    // Run the body in a fresh statement scope.
    StatementScope oldStatementScope = statementScope;
    statementScope = new StatementScope();
    visit(node.body);
    statementScope = oldStatementScope;

    scope = oldScope;
    enclosingElement = previousEnclosingElement;
  }

  visitIf(If node) {
    visit(node.condition);
    visit(node.thenPart);
    visit(node.elsePart);
  }

  static bool isLogicalOperator(Identifier op) {
    String str = op.source.stringValue;
    return (identical(str, '&&') || str == '||' || str == '!');
  }

  Element resolveSend(Send node) {
    Selector selector = resolveSelector(node);

    if (node.receiver == null) {
      // If this send is of the form "assert(expr);", then
      // this is an assertion.
      if (selector.isAssert()) {
        if (selector.argumentCount != 1) {
          error(node.selector,
                MessageKind.WRONG_NUMBER_OF_ARGUMENTS_FOR_ASSERT,
                [selector.argumentCount]);
        } else if (selector.namedArgumentCount != 0) {
          error(node.selector,
                MessageKind.ASSERT_IS_GIVEN_NAMED_ARGUMENTS,
                [selector.namedArgumentCount]);
        }
        return compiler.assertMethod;
      }
      return node.selector.accept(this);
    }

    var oldCategory = allowedCategory;
    allowedCategory |=
      ElementCategory.CLASS | ElementCategory.PREFIX | ElementCategory.SUPER;
    Element resolvedReceiver = visit(node.receiver);
    allowedCategory = oldCategory;

    Element target;
    SourceString name = node.selector.asIdentifier().source;
    if (identical(name.stringValue, 'this')) {
      error(node.selector, MessageKind.GENERIC, ["expected an identifier"]);
    } else if (node.isSuperCall) {
      if (node.isOperator) {
        if (isUserDefinableOperator(name.stringValue)) {
          name = selector.name;
        } else {
          error(node.selector, MessageKind.ILLEGAL_SUPER_SEND, [name]);
        }
      }
      if (!inInstanceContext) {
        error(node.receiver, MessageKind.NO_INSTANCE_AVAILABLE, [name]);
        return null;
      }
      if (currentClass.supertype == null) {
        // This is just to guard against internal errors, so no need
        // for a real error message.
        error(node.receiver, MessageKind.GENERIC, ["Object has no superclass"]);
      }
      // TODO(johnniwinther): Ensure correct behavior if currentClass is a
      // patch.
      target = currentClass.lookupSuperMember(name);
      // [target] may be null which means invoking noSuchMethod on
      // super.
    } else if (Elements.isUnresolved(resolvedReceiver)) {
      return null;
    } else if (identical(resolvedReceiver.kind, ElementKind.CLASS)) {
      ClassElement receiverClass = resolvedReceiver;
      receiverClass.ensureResolved(compiler);
      target = receiverClass.lookupLocalMember(name);
      if (target == null) {
        // TODO(johnniwinther): With the simplified [TreeElements] invariant,
        // try to resolve injected elements if [currentClass] is in the patch
        // library of [receiverClass].

        // TODO(karlklose): this should be reported by the caller of
        // [resolveSend] to select better warning messages for getters and
        // setters.
        return warnAndCreateErroneousElement(node, name,
                                             MessageKind.METHOD_NOT_FOUND,
                                             [receiverClass.name, name]);
      } else if (target.isInstanceMember()) {
        error(node, MessageKind.MEMBER_NOT_STATIC, [receiverClass.name, name]);
      }
    } else if (identical(resolvedReceiver.kind, ElementKind.PREFIX)) {
      PrefixElement prefix = resolvedReceiver;
      target = prefix.lookupLocalMember(name);
      if (target == null) {
        error(node, MessageKind.NO_SUCH_LIBRARY_MEMBER, [prefix.name, name]);
      }
    }
    return target;
  }

  DartType resolveTypeTest(Node argument) {
    TypeAnnotation node = argument.asTypeAnnotation();
    if (node == null) {
      // node is of the form !Type.
      node = argument.asSend().receiver.asTypeAnnotation();
      if (node == null) compiler.cancel("malformed send");
    }
    return resolveTypeRequired(node);
  }

  static Selector computeSendSelector(Send node, LibraryElement library) {
    // First determine if this is part of an assignment.
    bool isSet = node.asSendSet() != null;

    if (node.isIndex) {
      return isSet ? new Selector.indexSet() : new Selector.index();
    }

    if (node.isOperator) {
      SourceString source = node.selector.asOperator().source;
      String string = source.stringValue;
      if (identical(string, '!')   || identical(string, '&&')  || string == '||' ||
          identical(string, 'is')  || identical(string, 'as')  ||
          identical(string, '===') || identical(string, '!==') ||
          identical(string, '>>>')) {
        return null;
      }
      return node.arguments.isEmpty()
          ? new Selector.unaryOperator(source)
          : new Selector.binaryOperator(source);
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
    List<SourceString> named = <SourceString>[];
    for (Link<Node> link = node.argumentsNode.nodes;
        !link.isEmpty();
        link = link.tail) {
      Expression argument = link.head;
      NamedArgument namedArgument = argument.asNamedArgument();
      if (namedArgument != null) {
        named.add(namedArgument.name.source);
      }
      arity++;
    }

    // If we're invoking a closure, we do not have an identifier.
    return (identifier == null)
        ? new Selector.callClosure(arity, named)
        : new Selector.call(identifier.source, library, arity, named);
  }

  Selector resolveSelector(Send node) {
    LibraryElement library = enclosingElement.getLibrary();
    Selector selector = computeSendSelector(node, library);
    if (selector != null) mapping.setSelector(node, selector);
    return selector;
  }

  void resolveArguments(NodeList list) {
    if (list == null) return;
    bool seenNamedArgument = false;
    for (Link<Node> link = list.nodes; !link.isEmpty(); link = link.tail) {
      Expression argument = link.head;
      visit(argument);
      if (argument.asNamedArgument() != null) {
        seenNamedArgument = true;
      } else if (seenNamedArgument) {
        error(argument, MessageKind.INVALID_ARGUMENT_AFTER_NAMED);
      }
    }
  }

  visitSend(Send node) {
    Element target = resolveSend(node);
    if (!Elements.isUnresolved(target)
        && target.kind == ElementKind.ABSTRACT_FIELD) {
      AbstractFieldElement field = target;
      target = field.getter;
      if (target == null && !inInstanceContext) {
        target =
            warnAndCreateErroneousElement(node.selector, field.name,
                                          MessageKind.CANNOT_RESOLVE_GETTER,
                                          [node.selector]);
      }
    }

    bool resolvedArguments = false;
    if (node.isOperator) {
      String operatorString = node.selector.asOperator().source.stringValue;
      if (identical(operatorString, 'is') || identical(operatorString, 'as')) {
        assert(node.arguments.tail.isEmpty());
        DartType type = resolveTypeTest(node.arguments.head);
        if (type != null) {
          compiler.enqueuer.resolution.registerIsCheck(type);
        }
        resolvedArguments = true;
      } else if (identical(operatorString, '?')) {
        Element parameter = mapping[node.receiver];
        if (parameter == null
            || !identical(parameter.kind, ElementKind.PARAMETER)) {
          error(node.receiver, MessageKind.PARAMETER_NAME_EXPECTED);
        } else {
          mapping.checkedParameters.add(parameter);
        }
      }
    }

    if (!resolvedArguments) {
      resolveArguments(node.argumentsNode);
    }

    // If the selector is null, it means that we will not be generating
    // code for this as a send.
    Selector selector = mapping.getSelector(node);
    if (selector == null) return;

    // If we don't know what we're calling or if we are calling a getter,
    // we need to register that fact that we may be calling a closure
    // with the same arguments.
    if (node.isCall &&
        (Elements.isUnresolved(target) ||
         target.isGetter() ||
         Elements.isClosureSend(node, target))) {
      Selector call = new Selector.callClosureFrom(selector);
      world.registerDynamicInvocation(call.name, call);
    }

    // TODO(ngeoffray): Warn if target is null and the send is
    // unqualified.
    useElement(node, target);
    registerSend(selector, target);
    return node.isPropertyAccess ? target : null;
  }

  visitSendSet(SendSet node) {
    Element target = resolveSend(node);
    Element setter = target;
    Element getter = target;
    SourceString operatorName = node.assignmentOperator.source;
    String source = operatorName.stringValue;
    bool isComplex = !identical(source, '=');
    if (!Elements.isUnresolved(target)
        && target.kind == ElementKind.ABSTRACT_FIELD) {
      AbstractFieldElement field = target;
      setter = field.setter;
      getter = field.getter;
      if (setter == null && !inInstanceContext) {
        setter =
            warnAndCreateErroneousElement(node.selector, field.name,
                                          MessageKind.CANNOT_RESOLVE_SETTER,
                                          [node.selector]);
      }
      if (isComplex && getter == null && !inInstanceContext) {
        getter =
            warnAndCreateErroneousElement(node.selector, field.name,
                                          MessageKind.CANNOT_RESOLVE_GETTER,
                                          [node.selector]);
      }
    }

    visit(node.argumentsNode);

    // TODO(ngeoffray): Check if the target can be assigned.
    // TODO(ngeoffray): Warn if target is null and the send is
    // unqualified.

    Selector selector = mapping.getSelector(node);
    if (isComplex) {
      if (selector.isSetter()) {
        // TODO(kasperl): We're registering the getter selector for
        // compound assignments on the AST selector node. In the code
        // generator, we then fetch it from there when generating the
        // getter for a SendSet node.
        Selector getterSelector = new Selector.getterFrom(selector);
        registerSend(getterSelector, getter);
        mapping.setSelector(node.selector, getterSelector);
        useElement(node.selector, getter);
      } else {
        // TODO(kasperl): If [getter] is resolved, it will actually
        // refer to the []= operator which isn't the one we want to
        // register here. We should consider using some notion of
        // abstract indexable element that we can resolve to so we can
        // distinguish the two.
        assert(selector.isIndexSet());
        registerSend(new Selector.index(), null);
      }

      // Make sure we include the + and - operators if we are using
      // the ++ and -- ones.  Also, if op= form is used, include op itself.
      void registerBinaryOperator(SourceString name) {
        Selector binop = new Selector.binaryOperator(name);
        world.registerDynamicInvocation(binop.name, binop);
      }
      if (identical(source, '++')) registerBinaryOperator(const SourceString('+'));
      if (identical(source, '--')) registerBinaryOperator(const SourceString('-'));
      if (source.endsWith('=')) {
        registerBinaryOperator(Elements.mapToUserOperator(operatorName));
      }
    }

    registerSend(selector, setter);
    return useElement(node, setter);
  }

  void registerSend(Selector selector, Element target) {
    if (target == null || target.isInstanceMember()) {
      if (selector.isGetter()) {
        world.registerDynamicGetter(selector.name, selector);
      } else if (selector.isSetter()) {
        world.registerDynamicSetter(selector.name, selector);
      } else {
        world.registerDynamicInvocation(selector.name, selector);
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
    if (target == null) {
      // If we haven't found an element for this send, it might be a
      // dynamic send on a primitive value. Register the selector with
      // the world to add an interceptor, if necessary.
      world.registerUsedSelector(selector);
    }
  }

  visitLiteralInt(LiteralInt node) {
  }

  visitLiteralDouble(LiteralDouble node) {
  }

  visitLiteralBool(LiteralBool node) {
  }

  visitLiteralString(LiteralString node) {
  }

  visitLiteralNull(LiteralNull node) {
  }

  visitStringJuxtaposition(StringJuxtaposition node) {
    node.visitChildren(this);
  }

  visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty(); link = link.tail) {
      visit(link.head);
    }
  }

  visitOperator(Operator node) {
    unimplemented(node, 'operator');
  }

  visitReturn(Return node) {
    if (node.isRedirectingFactoryBody) {
      unimplemented(node, 'redirecting constructors');
    }
    visit(node.expression);
  }

  visitThrow(Throw node) {
    if (!inCatchBlock && node.expression == null) {
      error(node, MessageKind.THROW_WITHOUT_EXPRESSION);
    }
    visit(node.expression);
  }

  visitVariableDefinitions(VariableDefinitions node) {
    visit(node.type);
    VariableDefinitionsVisitor visitor =
        new VariableDefinitionsVisitor(compiler, node, this,
                                       ElementKind.VARIABLE);
    visitor.visit(node.definitions);
  }

  visitWhile(While node) {
    visit(node.condition);
    visitLoopBodyIn(node, node.body, new BlockScope(scope));
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    visit(node.expression);
  }

  visitNewExpression(NewExpression node) {
    Node selector = node.send.selector;
    FunctionElement constructor = resolveConstructor(node);
    resolveSelector(node.send);
    resolveArguments(node.send.argumentsNode);
    useElement(node.send, constructor);
    if (Elements.isUnresolved(constructor)) return constructor;
    // TODO(karlklose): handle optional arguments.
    if (node.send.argumentCount() != constructor.parameterCount(compiler)) {
      // TODO(ngeoffray): resolution error with wrong number of
      // parameters. We cannot do this rigth now because of the
      // List constructor.
    }
    // [constructor] might be the implementation element and only declaration
    // elements may be registered.
    world.registerStaticUse(constructor.declaration);
    compiler.withCurrentElement(constructor, () {
      FunctionExpression tree = constructor.parseNode(compiler);
      compiler.resolver.resolveConstructorImplementation(constructor, tree);
    });
    // [constructor.defaultImplementation] might be the implementation element
    // and only declaration elements may be registered.
    world.registerStaticUse(constructor.defaultImplementation.declaration);
    ClassElement cls = constructor.defaultImplementation.getEnclosingClass();
    // [cls] might be the implementation element and only declaration elements
    // may be registered.
    world.registerInstantiatedClass(cls.declaration);
    // [cls] might be the declaration element and we want to include injected
    // members.
    cls.implementation.forEachInstanceField(
        (ClassElement enclosingClass, Element member) {
          world.addToWorkList(member);
        },
        includeBackendMembers: false,
        includeSuperMembers: true);
    return null;
  }

  /**
   * Try to resolve the constructor that is referred to by [node].
   * Note: this function may return an ErroneousFunctionElement instead of
   * [null], if there is no corresponding constructor, class or library.
   */
  FunctionElement resolveConstructor(NewExpression node) {
    // Resolve the constructor that [node] refers to.
    ConstructorResolver visitor =
        new ConstructorResolver(compiler, this, node.isConst());
    FunctionElement constructor = node.accept(visitor);
    // Try to resolve the type that the new-expression constructs.
    TypeAnnotation annotation = node.send.getTypeAnnotation();
    if (Elements.isUnresolved(constructor)) {
      // Resolve the type arguments. We cannot create a type and check the
      // number of type arguments for this annotation, because we do not know
      // the element.
      Link arguments = const Link<Node>();
      if (annotation.typeArguments != null) {
        arguments = annotation.typeArguments.nodes;
      }
      for (Node argument in arguments) {
        resolveTypeRequired(argument);
      }
    } else {
      // Resolve and store the type this annotation resolves to. The type
      // is used in the backend, e.g., for creating runtime type information.
      // TODO(karlklose): This will resolve the class element again. Refactor
      // so we can use the TypeResolver.
      resolveTypeRequired(annotation);
    }
    return constructor;
  }

  DartType resolveTypeRequired(TypeAnnotation node) {
    bool old = typeRequired;
    typeRequired = true;
    DartType result = resolveTypeAnnotation(node);
    typeRequired = old;
    return result;
  }

  void analyzeTypeArgument(DartType annotation, DartType argument) {
    if (argument == null) return;
    if (argument.element.isTypeVariable()) {
      // Register a dependency between the class where the type
      // variable is, and the annotation. If the annotation requires
      // runtime type information, then the class of the type variable
      // does too.
      compiler.world.registerRtiDependency(
          annotation.element,
          argument.element.enclosingElement);
    } else if (argument is InterfaceType) {
      InterfaceType type = argument;
      type.arguments.forEach((DartType argument) {
        analyzeTypeArgument(type, argument);
      });
    }
  }

  DartType resolveTypeAnnotation(TypeAnnotation node) {
    Function report = typeRequired ? error : warning;
    DartType type = typeResolver.resolveTypeAnnotation(node, inScope: scope,
                                                       onFailure: report,
                                                       whenResolved: useType);
    if (type == null) return null;
    if (inCheckContext) {
      compiler.enqueuer.resolution.registerIsCheck(type);
    }
    if (typeRequired || inCheckContext) {
      if (type is InterfaceType) {
        InterfaceType itf = type;
        itf.arguments.forEach((DartType argument) {
          analyzeTypeArgument(type, argument);
        });
      }
      // TODO(ngeoffray): Also handle cases like:
      // 1) a is T
      // 2) T a (in checked mode).
    }
    return type;
  }

  visitModifiers(Modifiers node) {
    // TODO(ngeoffray): Implement this.
    unimplemented(node, 'modifiers');
  }

  visitLiteralList(LiteralList node) {
    NodeList arguments = node.typeArguments;
    if (arguments != null) {
      Link<Node> nodes = arguments.nodes;
      if (nodes.isEmpty()) {
        error(arguments, MessageKind.MISSING_TYPE_ARGUMENT, []);
      } else {
        resolveTypeRequired(nodes.head);
        for (nodes = nodes.tail; !nodes.isEmpty(); nodes = nodes.tail) {
          error(nodes.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT, []);
          resolveTypeRequired(nodes.head);
        }
      }
    }
    visit(node.elements);
  }

  visitConditional(Conditional node) {
    node.visitChildren(this);
  }

  visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
  }

  visitStringInterpolationPart(StringInterpolationPart node) {
    registerImplicitInvocation(const SourceString('toString'), 0);
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
      String labelName = node.target.source.slowToString();
      LabelElement label = statementScope.lookupLabel(labelName);
      if (label == null) {
        error(node.target, MessageKind.UNBOUND_LABEL, [labelName]);
        return;
      }
      target = label.target;
      if (!target.statement.isValidBreakTarget()) {
        error(node.target, MessageKind.INVALID_BREAK, [labelName]);
        return;
      }
      label.setBreakTarget();
      mapping[node.target] = label;
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
      String labelName = node.target.source.slowToString();
      LabelElement label = statementScope.lookupLabel(labelName);
      if (label == null) {
        error(node.target, MessageKind.UNBOUND_LABEL, [labelName]);
        return;
      }
      target = label.target;
      if (!target.statement.isValidContinueTarget()) {
        error(node.target, MessageKind.INVALID_CONTINUE, [labelName]);
      }
      // TODO(lrn): Handle continues to switch cases.
      if (target.statement is SwitchCase) {
        unimplemented(node, "continue to switch case");
      }
      label.setContinueTarget();
      mapping[node.target] = label;
    }
    mapping[node] = target;
  }

  registerImplicitInvocation(SourceString name, int arity) {
    Selector selector = new Selector.call(name, null, arity);
    world.registerDynamicInvocation(name, selector);
  }

  visitForIn(ForIn node) {
    for (final name in const [
        const SourceString('iterator'),
        const SourceString('next'),
        const SourceString('hasNext')]) {
      registerImplicitInvocation(name, 0);
    }
    visit(node.expression);
    Scope blockScope = new BlockScope(scope);
    Node declaration = node.declaredIdentifier;
    visitIn(declaration, blockScope);
    visitLoopBodyIn(node, node.body, blockScope);

    // TODO(lrn): Also allow a single identifier.
    if ((declaration is !Send || declaration.asSend().selector is !Identifier
        || declaration.asSend().receiver != null)
        && (declaration is !VariableDefinitions ||
        !declaration.asVariableDefinitions().definitions.nodes.tail.isEmpty()))
    {
      // The variable declaration is either not an identifier, not a
      // declaration, or it's declaring more than one variable.
      error(node.declaredIdentifier, MessageKind.INVALID_FOR_IN, []);
    }
  }

  visitLabel(Label node) {
    // Labels are handled by their containing statements/cases.
  }

  visitLabeledStatement(LabeledStatement node) {
    Statement body = node.statement;
    TargetElement targetElement = getOrCreateTargetElement(body);
    Map<String, LabelElement> labelElements = <String, LabelElement>{};
    for (Label label in node.labels) {
      String labelName = label.slowToString();
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
        warning(element.label, MessageKind.UNUSED_LABEL, [labelName]);
      }
    });
    if (!targetElement.isTarget && identical(mapping[body], targetElement)) {
      // If the body is itself a break or continue for another target, it
      // might have updated its mapping to the target it actually does target.
      mapping.remove(body);
    }
  }

  visitLiteralMap(LiteralMap node) {
    node.visitChildren(this);
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
    while (!cases.isEmpty()) {
      SwitchCase switchCase = cases.head;
      for (Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is! Label) continue;
        Label label = labelOrCase;
        String labelName = label.slowToString();

        LabelElement existingElement = continueLabels[labelName];
        if (existingElement != null) {
          // It's an error if the same label occurs twice in the same switch.
          warning(label, MessageKind.DUPLICATE_LABEL, [labelName]);
          error(existingElement.label, MessageKind.EXISTING_LABEL, [labelName]);
        } else {
          // It's only a warning if it shadows another label.
          existingElement = statementScope.lookupLabel(labelName);
          if (existingElement != null) {
            warning(label, MessageKind.DUPLICATE_LABEL, [labelName]);
            warning(existingElement.label,
                    MessageKind.EXISTING_LABEL, [labelName]);
          }
        }

        TargetElement targetElement =
            new TargetElement(switchCase,
                              statementScope.nestingLevel,
                              enclosingElement);
        mapping[switchCase] = targetElement;

        LabelElement labelElement =
            new LabelElement(label, labelName,
                             targetElement, enclosingElement);
        mapping[label] = labelElement;
        continueLabels[labelName] = labelElement;
      }
      cases = cases.tail;
      // Test that only the last case, if any, is a default case.
      if (switchCase.defaultKeyword != null && !cases.isEmpty()) {
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
    if (node.catchBlocks.isEmpty() && node.finallyBlock == null) {
      // TODO(ngeoffray): The precise location is
      // node.getEndtoken.next. Adjust when issue #1581 is fixed.
      error(node, MessageKind.NO_CATCH_NOR_FINALLY);
    }
    visit(node.catchBlocks);
    visit(node.finallyBlock);
  }

  visitCatchBlock(CatchBlock node) {
    // Check that if catch part is present, then
    // it has one or two formal parameters.
    if (node.formals != null) {
      if (node.formals.isEmpty()) {
        error(node, MessageKind.EMPTY_CATCH_DECLARATION);
      }
      if (!node.formals.nodes.tail.isEmpty() &&
          !node.formals.nodes.tail.tail.isEmpty()) {
        for (Node extra in node.formals.nodes.tail.tail) {
          error(extra, MessageKind.EXTRA_CATCH_DECLARATION);
        }
      }

      // Check that the formals aren't optional and that they have no
      // modifiers or type.
      for (Link<Node> link = node.formals.nodes;
           !link.isEmpty();
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
    var wasTypeRequired = typeRequired;
    typeRequired = true;
    doInCheckContext(() => visitIn(node.type, blockScope));
    typeRequired = wasTypeRequired;
    visitIn(node.formals, blockScope);
    var oldInCatchBlock = inCatchBlock;
    inCatchBlock = true;
    visitIn(node.block, blockScope);
    inCatchBlock = oldInCatchBlock;
  }

  visitTypedef(Typedef node) {
    unimplemented(node, 'typedef');
  }
}

class TypeDefinitionVisitor extends CommonResolverVisitor<DartType> {
  Scope scope;
  TypeDeclarationElement element;
  TypeResolver typeResolver;

  TypeDefinitionVisitor(Compiler compiler, TypeDeclarationElement element)
      : this.element = element,
        scope = Scope.buildEnclosingScope(element),
        typeResolver = new TypeResolver(compiler),
        super(compiler);

  void resolveTypeVariableBounds(NodeList node) {
    if (node == null) return;

    var nameSet = new Set<SourceString>();
    // Resolve the bounds of type variables.
    Link<DartType> typeLink = element.typeVariables;
    Link<Node> nodeLink = node.nodes;
    while (!nodeLink.isEmpty()) {
      TypeVariableType typeVariable = typeLink.head;
      SourceString typeName = typeVariable.name;
      TypeVariable typeNode = nodeLink.head;
      if (nameSet.contains(typeName)) {
        error(typeNode, MessageKind.DUPLICATE_TYPE_VARIABLE_NAME, [typeName]);
      }
      nameSet.add(typeName);

      TypeVariableElement variableElement = typeVariable.element;
      if (typeNode.bound != null) {
        DartType boundType = typeResolver.resolveTypeAnnotation(
            typeNode.bound, inScope: scope, onFailure: warning);
        if (boundType != null && boundType.element == variableElement) {
          // TODO(johnniwinther): Check for more general cycles, like
          // [: <A extends B, B extends C, C extends B> :].
          warning(node, MessageKind.CYCLIC_TYPE_VARIABLE,
                  [variableElement.name]);
        } else if (boundType != null) {
          variableElement.bound = boundType;
        } else {
          // TODO(johnniwinther): Should be an erroneous type.
          variableElement.bound = compiler.objectClass.computeType(compiler);
        }
      } else {
        variableElement.bound = compiler.objectClass.computeType(compiler);
      }
      nodeLink = nodeLink.tail;
      typeLink = typeLink.tail;
    }
    assert(typeLink.isEmpty());
  }
}

class TypedefResolverVisitor extends TypeDefinitionVisitor {
  TypedefElement get element => super.element;

  TypedefResolverVisitor(Compiler compiler, TypedefElement typedefElement)
      : super(compiler, typedefElement);

  visitTypedef(Typedef node) {
    TypedefType type = element.computeType(compiler);
    scope = new TypeDeclarationScope(scope, element);
    resolveTypeVariableBounds(node.typeParameters);

    element.functionSignature = SignatureResolver.analyze(
        compiler, node.formals, node.returnType, element);

    element.alias = compiler.computeFunctionType(
        element, element.functionSignature);

    // TODO(johnniwinther): Check for cyclic references in the typedef alias.
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
  ClassElement get element => super.element;

  ClassResolverVisitor(Compiler compiler, ClassElement classElement)
    : super(compiler, classElement);

  DartType visitClassNode(ClassNode node) {
    compiler.ensure(element != null);
    compiler.ensure(element.resolutionState == STATE_STARTED);

    InterfaceType type = element.computeType(compiler);
    scope = new TypeDeclarationScope(scope, element);
    // TODO(ahe): It is not safe to call resolveTypeVariableBounds yet.
    // As a side-effect, this may get us back here trying to
    // resolve this class again.
    resolveTypeVariableBounds(node.typeParameters);

    // Find super type.
    DartType supertype = visit(node.superclass);
    if (supertype != null && supertype.element.isExtendable()) {
      element.supertype = supertype;
      if (isBlackListed(supertype)) {
        error(node.superclass, MessageKind.CANNOT_EXTEND, [supertype]);
      }
    } else if (supertype != null) {
      error(node.superclass, MessageKind.TYPE_NAME_EXPECTED);
    }
    final objectElement = compiler.objectClass;
    if (!identical(element, objectElement) && element.supertype == null) {
      if (objectElement == null) {
        compiler.internalError("Internal error: cannot resolve Object",
                               node: node);
      } else {
        objectElement.ensureResolved(compiler);
      }
      // TODO(ahe): This should be objectElement.computeType(...).
      element.supertype = new InterfaceType(objectElement);
    }
    assert(element.interfaces == null);
    Link<DartType> interfaces = const Link<DartType>();
    for (Link<Node> link = node.interfaces.nodes;
         !link.isEmpty();
         link = link.tail) {
      DartType interfaceType = visit(link.head);
      if (interfaceType != null && interfaceType.element.isExtendable()) {
        interfaces = interfaces.prepend(interfaceType);
        if (isBlackListed(interfaceType)) {
          error(link.head, MessageKind.CANNOT_IMPLEMENT, [interfaceType]);
        }
      } else {
        error(link.head, MessageKind.TYPE_NAME_EXPECTED);
      }
    }
    element.interfaces = interfaces;
    calculateAllSupertypes(element);

    if (node.defaultClause != null) {
      element.defaultClass = visit(node.defaultClause);
    }
    addDefaultConstructorIfNeeded(element);
    return element.computeType(compiler);
  }

  DartType visitTypeAnnotation(TypeAnnotation node) {
    return visit(node.typeName);
  }

  DartType visitIdentifier(Identifier node) {
    Element element = scope.lookup(node.source);
    if (element == null) {
      error(node, MessageKind.CANNOT_RESOLVE_TYPE, [node]);
      return null;
    } else if (!element.impliesType() && !element.isTypeVariable()) {
      error(node, MessageKind.NOT_A_TYPE, [node]);
      return null;
    } else {
      if (element.isTypeVariable()) {
        TypeVariableElement variableElement = element;
        return variableElement.type;
      } else if (element.isTypedef()) {
        compiler.unimplemented('visitIdentifier for typedefs', node: node);
      } else {
        // TODO(ngeoffray): Use type variables.
        return element.computeType(compiler);
      }
    }
    return null;
  }

  DartType visitSend(Send node) {
    Identifier prefix = node.receiver.asIdentifier();
    if (prefix == null) {
      error(node.receiver, MessageKind.NOT_A_PREFIX, [node.receiver]);
      return null;
    }
    Element element = scope.lookup(prefix.source);
    if (element == null || !identical(element.kind, ElementKind.PREFIX)) {
      error(node.receiver, MessageKind.NOT_A_PREFIX, [node.receiver]);
      return null;
    }
    PrefixElement prefixElement = element;
    Identifier selector = node.selector.asIdentifier();
    var e = prefixElement.lookupLocalMember(selector.source);
    if (e == null || !e.impliesType()) {
      error(node.selector, MessageKind.CANNOT_RESOLVE_TYPE, [node.selector]);
      return null;
    }
    return e.computeType(compiler);
  }

  void calculateAllSupertypes(ClassElement cls) {
    // TODO(karlklose): substitute type variables.
    // TODO(karlklose): check if type arguments match, if a classelement occurs
    //                  more than once in the supertypes.
    if (cls.allSupertypes != null) return;
    final DartType supertype = cls.supertype;
    if (supertype != null) {
      ClassElement superElement = supertype.element;
      Link<DartType> superSupertypes = superElement.allSupertypes;
      assert(superSupertypes != null);
      Link<DartType> supertypes = superSupertypes.prepend(supertype);
      for (Link<DartType> interfaces = cls.interfaces;
           !interfaces.isEmpty();
           interfaces = interfaces.tail) {
        ClassElement element = interfaces.head.element;
        Link<DartType> interfaceSupertypes = element.allSupertypes;
        assert(interfaceSupertypes != null);
        supertypes = supertypes.reversePrependAll(interfaceSupertypes);
        supertypes = supertypes.prepend(interfaces.head);
      }
      cls.allSupertypes = supertypes;
    } else {
      assert(identical(cls, compiler.objectClass));
      cls.allSupertypes = const Link<DartType>();
    }
  }

  /**
   * Add a synthetic nullary constructor if there are no other
   * constructors.
   */
  void addDefaultConstructorIfNeeded(ClassElement element) {
    if (element.hasConstructor) return;
    SynthesizedConstructorElement constructor =
      new SynthesizedConstructorElement(element);
    element.addToScope(constructor, compiler);
    DartType returnType = compiler.types.voidType;
    constructor.type = new FunctionType(returnType, const Link<DartType>(),
                                        constructor);
    constructor.cachedNode =
      new FunctionExpression(new Identifier(element.position()),
                             new NodeList.empty(),
                             new Block(new NodeList.empty()),
                             null, Modifiers.EMPTY, null, null);
  }

  isBlackListed(DartType type) {
    LibraryElement lib = element.getLibrary();
    return
      !identical(lib, compiler.coreLibrary) &&
      !identical(lib, compiler.coreImplLibrary) &&
      !identical(lib, compiler.jsHelperLibrary) &&
      (identical(type.element, compiler.dynamicClass) ||
       identical(type.element, compiler.boolClass) ||
       identical(type.element, compiler.numClass) ||
       identical(type.element, compiler.intClass) ||
       identical(type.element, compiler.doubleClass) ||
       identical(type.element, compiler.stringClass) ||
       identical(type.element, compiler.nullClass) ||
       identical(type.element, compiler.functionClass));
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

  void visitClassNode(ClassNode node) {
    if (node.superclass == null) {
      if (!identical(classElement, compiler.objectClass)) {
        loadSupertype(compiler.objectClass, node);
      }
    } else {
      node.superclass.accept(this);
    }
    for (Link<Node> link = node.interfaces.nodes;
         !link.isEmpty();
         link = link.tail) {
      link.head.accept(this);
    }
  }

  void visitTypeAnnotation(TypeAnnotation node) {
    node.typeName.accept(this);
  }

  void visitIdentifier(Identifier node) {
    Element element = context.lookup(node.source);
    if (element == null) {
      error(node, MessageKind.CANNOT_RESOLVE_TYPE, [node]);
    } else if (!element.impliesType()) {
      error(node, MessageKind.NOT_A_TYPE, [node]);
    } else {
      if (element.isClass()) {
        loadSupertype(element, node);
      } else {
        compiler.reportMessage(
          compiler.spanFromNode(node),
          MessageKind.TYPE_NAME_EXPECTED.error([]),
          Diagnostic.ERROR);
      }
    }
  }

  void visitSend(Send node) {
    Identifier prefix = node.receiver.asIdentifier();
    if (prefix == null) {
      error(node.receiver, MessageKind.NOT_A_PREFIX, [node.receiver]);
      return;
    }
    Element element = context.lookup(prefix.source);
    if (element == null || !identical(element.kind, ElementKind.PREFIX)) {
      error(node.receiver, MessageKind.NOT_A_PREFIX, [node.receiver]);
      return;
    }
    PrefixElement prefixElement = element;
    Identifier selector = node.selector.asIdentifier();
    var e = prefixElement.lookupLocalMember(selector.source);
    if (e == null || !e.impliesType()) {
      error(node.selector, MessageKind.CANNOT_RESOLVE_TYPE, [node.selector]);
      return;
    }
    loadSupertype(e, node);
  }
}

class VariableDefinitionsVisitor extends CommonResolverVisitor<SourceString> {
  VariableDefinitions definitions;
  ResolverVisitor resolver;
  ElementKind kind;
  VariableListElement variables;

  VariableDefinitionsVisitor(Compiler compiler,
                             this.definitions, this.resolver, this.kind)
      : super(compiler) {
    variables = new VariableListElement.node(
        definitions, ElementKind.VARIABLE_LIST, resolver.enclosingElement);
  }

  SourceString visitSendSet(SendSet node) {
    assert(node.arguments.tail.isEmpty()); // Sanity check
    resolver.visit(node.arguments.head);
    return visit(node.selector);
  }

  SourceString visitIdentifier(Identifier node) => node.source;

  visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty(); link = link.tail) {
      SourceString name = visit(link.head);
      VariableElement element =
          new VariableElement(name, variables, kind, link.head);
      resolver.defineElement(link.head, element);
    }
  }
}

/**
 * [SignatureResolver] resolves function signatures.
 */
class SignatureResolver extends CommonResolverVisitor<Element> {
  final Element enclosingElement;
  Link<Element> optionalParameters = const Link<Element>();
  int optionalParameterCount = 0;
  bool optionalParametersAreNamed = false;
  VariableDefinitions currentDefinitions;

  SignatureResolver(Compiler compiler, this.enclosingElement) : super(compiler);

  Element visitNodeList(NodeList node) {
    // This must be a list of optional arguments.
    String value = node.beginToken.stringValue;
    if ((!identical(value, '[')) && (!identical(value, '{'))) {
      internalError(node, "expected optional parameters");
    }
    optionalParametersAreNamed = (identical(value, '{'));
    LinkBuilder<Element> elements = analyzeNodes(node.nodes);
    optionalParameterCount = elements.length;
    optionalParameters = elements.toLink();
    return null;
  }

  Element visitVariableDefinitions(VariableDefinitions node) {
    Link<Node> definitions = node.definitions.nodes;
    if (definitions.isEmpty()) {
      cancel(node, 'internal error: no parameter definition');
      return null;
    }
    if (!definitions.tail.isEmpty()) {
      cancel(definitions.tail.head, 'internal error: extra definition');
      return null;
    }
    Node definition = definitions.head;
    if (definition is NodeList) {
      cancel(node, 'optional parameters are not implemented');
    }

    if (currentDefinitions != null) {
      cancel(node, 'function type parameters not supported');
    }
    currentDefinitions = node;
    Element element = definition.accept(this);
    currentDefinitions = null;
    return element;
  }

  Element visitIdentifier(Identifier node) {
    Element variables = new VariableListElement.node(currentDefinitions,
        ElementKind.VARIABLE_LIST, enclosingElement);
    // Ensure a parameter is not typed 'void'.
    variables.computeType(compiler);
    return new VariableElement(node.source, variables,
        ElementKind.PARAMETER, node);
  }

  SourceString getParameterName(Send node) {
    var identifier = node.selector.asIdentifier();
    if (identifier != null) {
      // Normal parameter: [:Type name:].
      return identifier.source;
    } else {
      // Function type parameter: [:void name(DartType arg):].
      var functionExpression = node.selector.asFunctionExpression();
      if (functionExpression != null &&
          functionExpression.name.asIdentifier() != null) {
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
      error(node, MessageKind.INVALID_PARAMETER, []);
    } else if (!identical(enclosingElement.kind, ElementKind.GENERATIVE_CONSTRUCTOR)) {
      error(node, MessageKind.FIELD_PARAMETER_NOT_ALLOWED, []);
    } else {
      SourceString name = getParameterName(node);
      Element fieldElement = currentClass.lookupLocalMember(name);
      if (fieldElement == null || !identical(fieldElement.kind, ElementKind.FIELD)) {
        error(node, MessageKind.NOT_A_FIELD, [name]);
      } else if (!fieldElement.isInstanceMember()) {
        error(node, MessageKind.NOT_INSTANCE_FIELD, [name]);
      }
      Element variables = new VariableListElement.node(currentDefinitions,
          ElementKind.VARIABLE_LIST, enclosingElement);
      element = new FieldParameterElement(name, fieldElement, variables, node);
    }
    return element;
  }

  Element visitSendSet(SendSet node) {
    Element element;
    if (node.receiver != null) {
      element = visitSend(node);
    } else if (node.selector.asIdentifier() != null) {
      Element variables = new VariableListElement.node(currentDefinitions,
          ElementKind.VARIABLE_LIST, enclosingElement);
      element = new VariableElement(node.selector.asIdentifier().source,
          variables, ElementKind.PARAMETER, node);
    }
    // Visit the value. The compile time constant handler will
    // make sure it's a compile time constant.
    resolveExpression(node.arguments.head);
    return element;
  }

  Element visitFunctionExpression(FunctionExpression node) {
    // This is a function typed parameter.
    // TODO(ahe): Resolve the function type.
    return visit(node.name);
  }

  LinkBuilder<Element> analyzeNodes(Link<Node> link) {
    LinkBuilder<Element> elements = new LinkBuilder<Element>();
    for (; !link.isEmpty(); link = link.tail) {
      Element element = link.head.accept(this);
      if (element != null) {
        elements.addLast(element);
      } else {
        // If parameter is null, the current node should be the last,
        // and a list of optional named parameters.
        if (!link.tail.isEmpty() || (link.head is !NodeList)) {
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
                                   Element element) {
    SignatureResolver visitor = new SignatureResolver(compiler, element);
    Link<Element> parameters = const Link<Element>();
    int requiredParameterCount = 0;
    if (formalParameters == null) {
      if (!element.isGetter()) {
        compiler.reportMessage(compiler.spanFromElement(element),
                               MessageKind.MISSING_FORMALS.error([]),
                               Diagnostic.ERROR);
      }
    } else {
      if (element.isGetter()) {
        if (!element.getLibrary().isPlatformLibrary) {
          // TODO(ahe): Remove the isPlatformLibrary check.
          if (!identical(formalParameters.getEndToken().next.stringValue, 'native')) {
            // TODO(ahe): Remove the check for native keyword.
            compiler.reportMessage(compiler.spanFromNode(formalParameters),
                                   MessageKind.EXTRA_FORMALS.error([]),
                                   Diagnostic.WARNING);
          }
        }
      }
      LinkBuilder<Element> parametersBuilder =
        visitor.analyzeNodes(formalParameters.nodes);
      requiredParameterCount  = parametersBuilder.length;
      parameters = parametersBuilder.toLink();
    }
    DartType returnType = compiler.resolveReturnType(element, returnNode);
    return new FunctionSignature(parameters,
                                 visitor.optionalParameters,
                                 requiredParameterCount,
                                 visitor.optionalParameterCount,
                                 visitor.optionalParametersAreNamed,
                                 returnType);
  }

  // TODO(ahe): This is temporary.
  void resolveExpression(Node node) {
    if (node == null) return;
    node.accept(new ResolverVisitor(compiler, enclosingElement));
  }

  // TODO(ahe): This is temporary.
  ClassElement get currentClass {
    return enclosingElement.isMember()
      ? enclosingElement.getEnclosingClass() : null;
  }
}

class ConstructorResolver extends CommonResolverVisitor<Element> {
  final ResolverVisitor resolver;
  // TODO(ngeoffray): have this context at the call site.
  final bool inConstContext;

  ConstructorResolver(Compiler compiler,
                      this.resolver,
                      this.inConstContext)
      : super(compiler);

  visitNode(Node node) {
    throw 'not supported';
  }

  failOrReturnErroneousElement(Element enclosing, Node diagnosticNode,
                               SourceString targetName, MessageKind kind,
                               List arguments) {
    if (inConstContext) {
      error(diagnosticNode, kind, arguments);
    } else {
      ResolutionWarning warning  = new ResolutionWarning(kind, arguments);
      compiler.reportWarning(diagnosticNode, warning);
      return new ErroneousFunctionElement(kind, arguments, targetName,
                                          enclosing);
    }
  }

  Selector createConstructorSelector(SourceString constructorName) {
    return constructorName == const SourceString('')
        ? new Selector.callDefaultConstructor(
            resolver.enclosingElement.getLibrary())
        : new Selector.callConstructor(
            constructorName,
            resolver.enclosingElement.getLibrary());
  }

  // TODO(ngeoffray): method named lookup should not report errors.
  FunctionElement lookupConstructor(ClassElement cls,
                                    Node diagnosticNode,
                                    SourceString constructorName) {
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
          new SourceString(fullConstructorName),
          MessageKind.CANNOT_FIND_CONSTRUCTOR,
          [fullConstructorName]);
    } else if (inConstContext && !result.modifiers.isConst()) {
      error(diagnosticNode, MessageKind.CONSTRUCTOR_IS_NOT_CONST);
    }
    return result;
  }

  visitNewExpression(NewExpression node) {
    Node selector = node.send.selector;
    Element e = visit(selector);
    if (!Elements.isUnresolved(e) && identical(e.kind, ElementKind.CLASS)) {
      ClassElement cls = e;
      cls.ensureResolved(compiler);
      if (cls.isInterface() && (cls.defaultClass == null)) {
        error(selector, MessageKind.CANNOT_INSTANTIATE_INTERFACE, [cls.name]);
      }
      e = lookupConstructor(cls, selector, const SourceString(''));
    }
    return e;
  }

  visitTypeAnnotation(TypeAnnotation node) {
    return visit(node.typeName);
  }

  visitSend(Send node) {
    Element e = visit(node.receiver);
    if (Elements.isUnresolved(e)) return e;
    Identifier name = node.selector.asIdentifier();
    if (name == null) internalError(node.selector, 'unexpected node');

    if (identical(e.kind, ElementKind.CLASS)) {
      ClassElement cls = e;
      cls.ensureResolved(compiler);
      if (cls.isInterface() && (cls.defaultClass == null)) {
        error(node.receiver, MessageKind.CANNOT_INSTANTIATE_INTERFACE,
              [cls.name]);
      }
      return lookupConstructor(cls, name, name.source);
    } else if (identical(e.kind, ElementKind.PREFIX)) {
      PrefixElement prefix = e;
      e = prefix.lookupLocalMember(name.source);
      if (e == null) {
        return failOrReturnErroneousElement(resolver.enclosingElement, name,
                                            name.source,
                                            MessageKind.CANNOT_RESOLVE,
                                            [name]);
      } else if (!identical(e.kind, ElementKind.CLASS)) {
        error(node, MessageKind.NOT_A_TYPE, [name]);
      }
    } else {
      internalError(node.receiver, 'unexpected element $e');
    }
    return e;
  }

  Element visitIdentifier(Identifier node) {
    SourceString name = node.source;
    Element e = resolver.lookup(node, name);
    // TODO(johnniwinther): Change errors to warnings, cf. 11.11.1.
    if (e == null) {
      return failOrReturnErroneousElement(resolver.enclosingElement, node, name,
                                          MessageKind.CANNOT_RESOLVE, [name]);
    } else if (identical(e.kind, ElementKind.TYPEDEF)) {
      error(node, MessageKind.CANNOT_INSTANTIATE_TYPEDEF, [name]);
    } else if (identical(e.kind, ElementKind.TYPE_VARIABLE)) {
      error(node, MessageKind.CANNOT_INSTANTIATE_TYPE_VARIABLE, [name]);
    } else if (!identical(e.kind, ElementKind.CLASS)
        && !identical(e.kind, ElementKind.PREFIX)) {
      error(node, MessageKind.NOT_A_TYPE, [name]);
    }
    return e;
  }
}

abstract class Scope {
  /**
   * Adds [element] to this scope. This operation is only allowed on mutable
   * scopes such as [MethodScope] and [BlockScope].
   */
  abstract Element add(Element element);

  /**
   * Looks up the [Element] for [name] in this scope.
   */
  abstract Element lookup(SourceString name);

  static Scope buildEnclosingScope(Element element) {
    return element.enclosingElement != null
        ? element.enclosingElement.buildScope() : element.buildScope();
  }
}

abstract class NestedScope extends Scope {
  final Scope parent;

  NestedScope(this.parent);

  Element lookup(SourceString name) {
    Element result = localLookup(name);
    if (result != null) return result;
    return parent.lookup(name);
  }

  abstract Element localLookup(SourceString name);

  static Scope buildEnclosingScope(Element element) {
    return element.enclosingElement != null
        ? element.enclosingElement.buildScope() : element.buildScope();
  }
}

/**
 * [TypeDeclarationScope] defines the outer scope of a type declaration in
 * which the declared type variables and the entities in the enclosing scope are
 * available but where declared and inherited members are not available. This
 * scope is only used for class/interface declarations during resolution of the
 * class hierarchy. In all other cases [ClassScope] is used.
 */
class TypeDeclarationScope extends NestedScope {
  final TypeDeclarationElement element;

  TypeDeclarationScope(parent, this.element)
      : super(parent) {
    assert(parent != null);
  }

  Element add(Element newElement) {
    throw "Cannot add element to TypeDeclarationScope";
  }

  Element lookupTypeVariable(SourceString name) {
    Link<DartType> typeVariableLink = element.typeVariables;
    while (!typeVariableLink.isEmpty()) {
      TypeVariableType typeVariable = typeVariableLink.head;
      if (typeVariable.name == name) {
        return typeVariable.element;
      }
      typeVariableLink = typeVariableLink.tail;
    }
    return null;
  }

  Element localLookup(SourceString name) => lookupTypeVariable(name);

  String toString() =>
      'TypeDeclarationScope($element)';
}

abstract class MutableScope extends NestedScope {
  final Map<SourceString, Element> elements;

  MutableScope(Scope parent)
      : super(parent),
        this.elements = new Map<SourceString, Element>() {
    assert(parent != null);
  }

  Element add(Element newElement) {
    if (elements.containsKey(newElement.name)) {
      return elements[newElement.name];
    }
    elements[newElement.name] = newElement;
    return newElement;
  }

  Element localLookup(SourceString name) => elements[name];
}

class MethodScope extends MutableScope {
  final Element element;

  MethodScope(Scope parent, this.element)
      : super(parent);

  String toString() => 'MethodScope($element${elements.getKeys()})';
}

class BlockScope extends MutableScope {
  BlockScope(Scope parent) : super(parent);

  String toString() => 'BlockScope(${elements.getKeys()})';
}

/**
 * [ClassScope] defines the inner scope of a class/interface declaration in
 * which declared members, declared type variables, entities in the enclosing
 * scope and inherited members are available, in the given order.
 */
class ClassScope extends TypeDeclarationScope {
  ClassElement get element => super.element;

  ClassScope(Scope parentScope, ClassElement element)
      : super(parentScope, element)  {
    assert(parent != null);
  }

  Element localLookup(SourceString name) {
    Element result = element.lookupLocalMember(name);
    if (result != null) return result;
    return super.localLookup(name);
  }

  Element lookup(SourceString name) {
    Element result = localLookup(name);
    if (result != null) return result;
    result = parent.lookup(name);
    if (result != null) return result;
    return element.lookupSuperMember(name);
  }

  Element add(Element newElement) {
    throw "Cannot add an element in a class scope";
  }

  String toString() => 'ClassScope($element)';
}

class LibraryScope implements Scope {
  final LibraryElement library;

  LibraryScope(LibraryElement this.library);

  Element localLookup(SourceString name) => library.find(name);
  Element lookup(SourceString name) => localLookup(name);

  Element add(Element newElement) {
    throw "Cannot add an element to a library scope";
  }

  String toString() => 'LibraryScope($library)';
}
