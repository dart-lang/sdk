// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of resolution;

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
        target = new ErroneousFieldElementX(
            selector.asIdentifier(), constructor.enclosingClass);
      } else if (target.kind != ElementKind.FIELD) {
        error(selector, MessageKind.NOT_A_FIELD, {'fieldName': name});
        target = new ErroneousFieldElementX(
            selector.asIdentifier(), constructor.enclosingClass);
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
        lookupTarget.lookupConstructor(constructorSelector.name);

    final bool isImplicitSuperCall = false;
    final String className = lookupTarget.name;
    verifyThatConstructorMatchesCall(constructor,
                                     calledConstructor,
                                     selector.callStructure,
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
      assert(superClass.isResolved);

      final bool isSuperCall = true;
      ClassElement lookupTarget = getSuperOrThisLookupTarget(constructor,
                                                             isSuperCall,
                                                             functionNode);
      Selector constructorSelector = new Selector.callDefaultConstructor();
      Element calledConstructor = lookupTarget.lookupConstructor(
          constructorSelector.name);

      final String className = lookupTarget.name;
      final bool isImplicitSuperCall = true;
      verifyThatConstructorMatchesCall(constructor,
                                       calledConstructor,
                                       CallStructure.NO_ARGS,
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
      ConstructorElementX lookedupConstructor,
      CallStructure call,
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
      if (!call.signatureApplies(lookedupConstructor)) {
        MessageKind kind = isImplicitSuperCall
                           ? MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT
                           : MessageKind.NO_MATCHING_CONSTRUCTOR;
        visitor.compiler.reportError(diagnosticNode, kind);
      } else if (caller.isConst
                 && !lookedupConstructor.isConst) {
        MessageKind kind = isImplicitSuperCall
                           ? MessageKind.CONST_CALLS_NON_CONST_FOR_IMPLICIT
                           : MessageKind.CONST_CALLS_NON_CONST;
        visitor.compiler.reportError(diagnosticNode, kind);
      }
    }
  }

  /**
   * Resolve all initializers of this constructor. In the case of a redirecting
   * constructor, the resolved constructor's function element is returned.
   */
  ConstructorElement resolveInitializers(ConstructorElementX constructor,
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
          } else {
            constructor.isRedirectingGenerative = true;
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

  ErroneousConstructorElementX failOrReturnErroneousConstructorElement(
      Spannable diagnosticNode,
      Element enclosing,
      String name,
      MessageKind kind,
      Map arguments,
      {bool isError: false,
       bool missingConstructor: false}) {
    if (missingConstructor) {
      registry.registerThrowNoSuchMethod();
    } else {
      registry.registerThrowRuntimeError();
    }
    if (isError || inConstContext) {
      compiler.reportError(diagnosticNode, kind, arguments);
    } else {
      compiler.reportWarning(diagnosticNode, kind, arguments);
    }
    return new ErroneousConstructorElementX(
        kind, arguments, name, enclosing);
  }

  FunctionElement resolveConstructor(ClassElement cls,
                                     Node diagnosticNode,
                                     String constructorName) {
    cls.ensureResolved(compiler);
    Element result = cls.lookupConstructor(constructorName);
    // TODO(johnniwinther): Use [Name] for lookup.
    if (isPrivateName(constructorName) &&
        resolver.enclosingElement.library != cls.library) {
      result = null;
    }
    if (result == null) {
      String fullConstructorName = Elements.constructorNameForDiagnostics(
              cls.name,
              constructorName);
      return failOrReturnErroneousConstructorElement(
          diagnosticNode,
          cls, constructorName,
          MessageKind.CANNOT_FIND_CONSTRUCTOR,
          {'constructorName': fullConstructorName},
          missingConstructor: true);
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
        element = failOrReturnErroneousConstructorElement(
            diagnosticNode,
            element, element.name,
            MessageKind.NOT_A_TYPE, {'node': diagnosticNode});
      }
    } else if (element.isErroneous && element is! ErroneousElementX) {
      // Parser error. The error has already been reported.
      element = new ErroneousConstructorElementX(
          MessageKind.NOT_A_TYPE, {'node': diagnosticNode},
          element.name, element);
      registry.registerThrowRuntimeError();
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
        return failOrReturnErroneousConstructorElement(
            name,
            resolver.enclosingElement, name.source,
            MessageKind.CANNOT_RESOLVE, {'name': name});
      } else if (!element.isClass) {
        return failOrReturnErroneousConstructorElement(
            name,
            resolver.enclosingElement, name.source,
            MessageKind.NOT_A_TYPE, {'node': name},
            isError: true);
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
      return failOrReturnErroneousConstructorElement(
          node,
          resolver.enclosingElement, name,
          MessageKind.CANNOT_RESOLVE,
          {'name': name});
    } else if (element.isErroneous) {
      return element;
    } else if (element.isTypedef) {
      element = failOrReturnErroneousConstructorElement(
          node,
          resolver.enclosingElement, name,
          MessageKind.CANNOT_INSTANTIATE_TYPEDEF, {'typedefName': name},
          isError: true);
    } else if (element.isTypeVariable) {
      element = failOrReturnErroneousConstructorElement(
          node,
          resolver.enclosingElement, name,
          MessageKind.CANNOT_INSTANTIATE_TYPE_VARIABLE,
          {'typeVariableName': name},
          isError: true);
    } else if (!element.isClass && !element.isPrefix) {
      element = failOrReturnErroneousConstructorElement(
          node,
          resolver.enclosingElement, name,
          MessageKind.NOT_A_TYPE, {'node': name},
          isError: true);
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
