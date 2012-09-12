// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface TreeElements {
  Element operator[](Node node);
  Selector getSelector(Send send);
  DartType getType(TypeAnnotation annotation);
  bool isParameterChecked(Element element);
}

class TreeElementMapping implements TreeElements {
  final Map<Node, Element> map;
  final Map<Node, Selector> selectors;
  final Map<TypeAnnotation, DartType> types;
  final Set<Element> checkedParameters;

  TreeElementMapping()
      : map = new LinkedHashMap<Node, Element>(),
        selectors = new LinkedHashMap<Node, Selector>(),
        types = new LinkedHashMap<TypeAnnotation, DartType>(),
        checkedParameters = new Set<Element>();

  operator []=(Node node, Element element) => map[node] = element;
  operator [](Node node) => map[node];
  void remove(Node node) { map.remove(node); }

  void setType(TypeAnnotation annotation, DartType type) {
    types[annotation] = type;
  }

  DartType getType(TypeAnnotation annotation) => types[annotation];

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
      if (kind === ElementKind.GENERATIVE_CONSTRUCTOR ||
          kind === ElementKind.FUNCTION ||
          kind === ElementKind.GETTER ||
          kind === ElementKind.SETTER) {
        return resolveMethodElement(element);
      }

      if (kind === ElementKind.FIELD) return resolveField(element);

      if (kind === ElementKind.PARAMETER ||
          kind === ElementKind.FIELD_PARAMETER) {
        return resolveParameter(element);
      }

      compiler.unimplemented("resolve($element)",
                             node: element.parseNode(compiler));
    });
  }

  SourceString getConstructorName(Send node) {
    if (node.receiver !== null) {
      return node.selector.asIdentifier().source;
    } else {
      return const SourceString('');
    }
  }

  FunctionElement resolveConstructorRedirection(FunctionElement constructor) {
    FunctionExpression node = constructor.parseNode(compiler);
    // A synthetic constructor does not have a node.
    if (node === null) return null;
    if (node.initializers === null) return null;
    Link<Node> initializers = node.initializers.nodes;
    if (!initializers.isEmpty() &&
        Initializers.isConstructorRedirect(initializers.head)) {
      final ClassElement classElement = constructor.getEnclosingClass();
      final SourceString constructorName =
          getConstructorName(initializers.head);
      final SourceString className = classElement.name;
      return classElement.lookupConstructor(className, constructorName);
    }
    return null;
  }

  void resolveRedirectingConstructor(InitializerResolver resolver,
                                     Node node,
                                     FunctionElement constructor,
                                     FunctionElement redirection) {
    Set<FunctionElement> seen = new Set<FunctionElement>();
    seen.add(constructor);
    while (redirection !== null) {
      if (seen.contains(redirection)) {
        resolver.visitor.error(node, MessageKind.REDIRECTING_CONSTRUCTOR_CYCLE);
        return;
      }
      seen.add(redirection);
      redirection = resolveConstructorRedirection(redirection);
    }
  }

  TreeElements resolveMethodElement(FunctionElement element) {
    return compiler.withCurrentElement(element, () {
      bool isConstructor = element.kind === ElementKind.GENERATIVE_CONSTRUCTOR;
      TreeElements elements =
          compiler.enqueuer.resolution.getCachedElements(element);
      if (elements !== null) {
        assert(isConstructor);
        return elements;
      }
      FunctionExpression tree = element.parseNode(compiler);
      if (isConstructor) {
        if (tree.returnType !== null) {
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
        if (redirection !== null) {
          resolveRedirectingConstructor(resolver, tree, element, redirection);
        }
      } else if (tree.initializers != null) {
        error(tree, MessageKind.FUNCTION_WITH_INITIALIZER);
      }
      visitBody(visitor, tree.body);

      return visitor.mapping;
    });
  }

  void visitBody(ResolverVisitor visitor, Statement body) {
    visitor.visit(body);
  }

  void resolveConstructorImplementation(FunctionElement constructor,
                                        FunctionExpression node) {
    if (constructor.defaultImplementation !== constructor) return;
    ClassElement intrface = constructor.getEnclosingClass();
    if (!intrface.isInterface()) return;
    DartType defaultType = intrface.defaultClass;
    if (defaultType === null) {
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

    // If the default class implements the interface then we must use the
    // default class' name. Otherwise we look for a factory with the name
    // of the interface.
    SourceString name;
    if (defaultClass.implementsInterface(intrface)) {
      // TODO(ahe): Don't use string replacement here.
      name = new SourceString(constructor.name.slowToString().replaceFirst(
                 intrface.name.slowToString(),
                 defaultClass.name.slowToString()));
    } else {
      name = constructor.name;
    }
    constructor.defaultImplementation = defaultClass.lookupConstructor(name);

    if (constructor.defaultImplementation === null) {
      // We failed to find a constructor named either
      // "MyInterface.name" or "MyClass.name".
      error(node,
            MessageKind.CANNOT_FIND_CONSTRUCTOR2,
            [name, defaultClass.name]);
    }
  }

  TreeElements resolveField(Element element) {
    Node tree = element.parseNode(compiler);
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
    if (annotation === null) return compiler.types.dynamicType;
    ResolverVisitor visitor = new ResolverVisitor(compiler, element);
    DartType result = visitor.resolveTypeAnnotation(annotation);
    if (result === null) {
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
          api.Diagnostic.ERROR);
        cls.supertypeLoadState = STATE_DONE;
        cls.allSupertypes = const EmptyLink<DartType>().prepend(
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
  }

  void checkMembers(ClassElement cls) {
    if (cls === compiler.objectClass) return;
    cls.forEachMember((holder, member) {
      // Perform various checks as side effect of "computing" the type.
      member.computeType(compiler);

      // Check modifiers.
      if (member.isFunction() && member.modifiers.isFinal()) {
        compiler.reportMessage(
          compiler.spanFromElement(member),
          MessageKind.ILLEGAL_FINAL_METHOD_MODIFIER.error(),
          api.Diagnostic.ERROR);
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
            api.Diagnostic.ERROR);
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
    if (lookupElement === null) {
      compiler.internalErrorOnElement(member,
                                      "No abstract field for accessor");
    } else if (lookupElement.kind !== ElementKind.ABSTRACT_FIELD) {
       compiler.internalErrorOnElement(
           member, "Inaccessible abstract field for accessor");
    }
    AbstractFieldElement field = lookupElement;

    if (field.getter === null) return;
    if (field.setter === null) return;
    int getterFlags = field.getter.modifiers.flags | Modifiers.FLAG_ABSTRACT;
    int setterFlags = field.setter.modifiers.flags | Modifiers.FLAG_ABSTRACT;
    if (getterFlags !== setterFlags) {
      final mismatchedFlags =
        new Modifiers.withFlags(null, getterFlags ^ setterFlags);
      compiler.reportMessage(
          compiler.spanFromElement(field.getter),
          MessageKind.GETTER_MISMATCH.error([mismatchedFlags]),
          api.Diagnostic.ERROR);
      compiler.reportMessage(
          compiler.spanFromElement(field.setter),
          MessageKind.SETTER_MISMATCH.error([mismatchedFlags]),
          api.Diagnostic.ERROR);
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
        api.Diagnostic.ERROR);
    compiler.reportMessage(
        compiler.spanFromElement(contextElement),
        contextMessage.error(),
        api.Diagnostic.INFO);
  }

  void checkValidOverride(Element member, Element superMember) {
    if (superMember === null) return;
    if (member.modifiers.isStatic()) {
      reportErrorWithContext(
          member, MessageKind.NO_STATIC_OVERRIDE,
          superMember, MessageKind.NO_STATIC_OVERRIDE_CONT);
    } else {
      FunctionElement superFunction = superMember.asFunctionElement();
      FunctionElement function = member.asFunctionElement();
      if (superFunction === null || superFunction.isAccessor()) {
        // Field or accessor in super.
        if (function !== null && !function.isAccessor()) {
          // But a plain method in this class.
          reportErrorWithContext(
              member, MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD,
              superMember, MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD_CONT);
        }
      } else {
        // Instance method in super.
        if (function === null || function.isAccessor()) {
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
      final ClassElement classElement = constructor.getEnclosingClass();
      target = classElement.lookupLocalMember(name);
      if (target === null) {
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
    SourceString constructorName = resolver.getConstructorName(call);
    Element result = resolveSuperOrThis(
        constructor, isSuperCall, false, constructorName, selector, call);
    visitor.useElement(call, result);
    visitor.world.registerStaticUse(result);
    return result;
  }

  void resolveImplicitSuperConstructorSend(FunctionElement constructor,
                                           FunctionExpression functionNode) {
    // If the class has a super resolve the implicit super call.
    ClassElement classElement = constructor.getEnclosingClass();
    ClassElement superClass = classElement.superclass;
    if (classElement != visitor.compiler.objectClass) {
      assert(superClass !== null);
      assert(superClass.resolutionState == STATE_DONE);
      SourceString name = const SourceString('');
      Selector call = new Selector.call(name, classElement.getLibrary(), 0);
      var element = resolveSuperOrThis(constructor, true, true,
                                       name, call, functionNode);
      visitor.world.registerStaticUse(element);
    }
  }

  Element resolveSuperOrThis(FunctionElement constructor,
                             bool isSuperCall,
                             bool isImplicitSuperCall,
                             SourceString constructorName,
                             Selector selector,
                             Node diagnosticNode) {
    ClassElement lookupTarget = constructor.getEnclosingClass();
    bool validTarget = true;
    FunctionElement result;
    if (isSuperCall) {
      // Calculate correct lookup target and constructor name.
      if (lookupTarget === visitor.compiler.objectClass) {
        error(diagnosticNode, MessageKind.SUPER_INITIALIZER_IN_OBJECT);
      } else {
        lookupTarget = lookupTarget.supertype.element;
      }
    }

    // Lookup constructor and try to match it to the selector.
    ResolverTask resolver = visitor.compiler.resolver;
    final SourceString className = lookupTarget.name;
    result = lookupTarget.lookupConstructor(className, constructorName);
    if (result === null || !result.isGenerativeConstructor()) {
      String classNameString = className.slowToString();
      String constructorNameString = constructorName.slowToString();
      String name = (constructorName === const SourceString(''))
                        ? classNameString
                        : "$classNameString.$constructorNameString";
      MessageKind kind = isImplicitSuperCall
                         ? MessageKind.CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT
                         : MessageKind.CANNOT_RESOLVE_CONSTRUCTOR;
      error(diagnosticNode, kind, [name]);
    } else {
      if (!selector.applies(result, visitor.compiler)) {
        MessageKind kind = isImplicitSuperCall
                           ? MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT
                           : MessageKind.NO_MATCHING_CONSTRUCTOR;
        error(diagnosticNode, kind);
      }
    }
    return result;
  }

  FunctionElement resolveRedirection(FunctionElement constructor,
                                     FunctionExpression functionNode) {
    if (functionNode.initializers === null) return null;
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
      if (element.kind === ElementKind.FIELD_PARAMETER) {
        checkForDuplicateInitializers(element.name,
                                      element.parseNode(visitor.compiler));
      }
    });

    if (functionNode.initializers === null) {
      initializers = const EmptyLink<Node>();
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
      } else if (link.head.asSend() !== null) {
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

class CommonResolverVisitor<R> extends AbstractVisitor<R> {
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

interface LabelScope {
  LabelScope get outer;
  LabelElement lookup(String label);
}

class LabeledStatementLabelScope implements LabelScope {
  final LabelScope outer;
  final Map<String, LabelElement> labels;
  LabeledStatementLabelScope(this.outer, this.labels);
  LabelElement lookup(String labelName) {
    LabelElement label = labels[labelName];
    if (label !== null) return label;
    return outer.lookup(labelName);
  }
}

class SwitchLabelScope implements LabelScope {
  final LabelScope outer;
  final Map<String, LabelElement> caseLabels;

  SwitchLabelScope(this.outer, this.caseLabels);

  LabelElement lookup(String labelName) {
    LabelElement result = caseLabels[labelName];
    if (result !== null) return result;
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
        breakTargetStack = const EmptyLink<TargetElement>(),
        continueTargetStack = const EmptyLink<TargetElement>();

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
    if (send !== null) {
      typeName = send.selector;
    }
    if (typeName.source.stringValue === 'void') {
      return compiler.types.voidType.element;
    } else if (typeName.source.stringValue === 'Dynamic') {
      return compiler.dynamicClass;
    } else if (send !== null) {
      Element e = scope.lookup(send.receiver.asIdentifier().source);
      if (e !== null && e.kind === ElementKind.PREFIX) {
        // The receiver is a prefix. Lookup in the imported members.
        PrefixElement prefix = e;
        return prefix.lookupLocalMember(typeName.source);
      } else if (e !== null && e.kind === ElementKind.CLASS) {
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
                                 [Scope inScope, ClassElement inClass,
                                 onFailure(Node, MessageKind, [List arguments]),
                                 whenResolved(Node, Type)]) {
    if (onFailure === null) {
      onFailure = (n, k, [arguments]) {};
    }
    if (whenResolved === null) {
      whenResolved = (n, t) {};
    }
    if (inClass !== null) {
      inScope = inClass.buildScope();
    }
    if (inScope === null) {
      compiler.internalError('resolveTypeAnnotation: no scope specified');
    }
    return resolveTypeAnnotationInContext(inScope, node, onFailure,
                                          whenResolved);
  }

  DartType resolveTypeAnnotationInContext(Scope scope, TypeAnnotation node,
                                          onFailure, whenResolved) {
    Element element = resolveTypeName(scope, node);
    DartType type;
    if (element === null) {
      onFailure(node, MessageKind.CANNOT_RESOLVE_TYPE, [node.typeName]);
    } else if (!element.impliesType()) {
      onFailure(node, MessageKind.NOT_A_TYPE, [node.typeName]);
    } else {
      if (element === compiler.types.voidType.element ||
          element === compiler.types.dynamicType.element) {
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
      return const EmptyLink<DartType>();
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
  final Element enclosingElement;
  final TypeResolver typeResolver;
  bool inInstanceContext;
  bool inCheckContext;
  Scope scope;
  ClassElement currentClass;
  ExpressionStatement currentExpressionStatement;
  bool typeRequired = false;
  StatementScope statementScope;
  int allowedCategory = ElementCategory.VARIABLE | ElementCategory.FUNCTION;

  ResolverVisitor(Compiler compiler, Element element)
    : this.mapping  = new TreeElementMapping(),
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
    if (element === null) {
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
    ResolutionWarning warning = new ResolutionWarning(kind, arguments);
    compiler.reportWarning(node, warning);
    return new ErroneousElement(warning.message, name, enclosingElement);
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
      if (element === null) {
        if (!inInstanceContext) error(node, MessageKind.CANNOT_RESOLVE, [node]);
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
    if (type !== null) {
      if (inCheckContext) {
        compiler.enqueuer.resolution.registerIsCheck(type);
      }
      return type.element;
    }
    return null;
  }

  Element defineElement(Node node, Element element,
                        [bool doAddToScope = true]) {
    compiler.ensure(element !== null);
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
    if (element === null) return null;
    return mapping[node] = element;
  }

  DartType useType(TypeAnnotation annotation, DartType type) {
    if (type !== null) {
      mapping.setType(annotation, type);
      useElement(annotation, type.element);
    }
    return type;
  }

  void setupFunction(FunctionExpression node, FunctionElement function) {
    // If [function] is the [enclosingElement], the [scope] has
    // already been set in the constructor of [ResolverVisitor].
    if (function != enclosingElement) scope = new MethodScope(scope, function);

    // Put the parameters in scope.
    FunctionSignature functionParameters =
        function.computeSignature(compiler);
    Link<Node> parameterNodes = (node.parameters === null)
        ? const EmptyLink<Node>() : node.parameters.nodes;
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
    scope = nestedScope;
    Element element = visit(node);
    scope = scope.parent;
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
    assert(node.function.name !== null);
    visit(node.function);
    FunctionElement functionElement = mapping[node.function];
    // TODO(floitsch): this might lead to two errors complaining about
    // shadowing.
    defineElement(node, functionElement);
  }

  visitFunctionExpression(FunctionExpression node) {
    visit(node.returnType);
    SourceString name;
    if (node.name === null) {
      name = const SourceString("");
    } else {
      name = node.name.asIdentifier().source;
    }
    FunctionElement enclosing = new FunctionElement.node(
        name, node, ElementKind.FUNCTION, new Modifiers.empty(),
        scope.element);
    setupFunction(node, enclosing);
    defineElement(node, enclosing, doAddToScope: node.name !== null);

    // Run the body in a fresh statement scope.
    StatementScope oldScope = statementScope;
    statementScope = new StatementScope();
    visit(node.body);
    statementScope = oldScope;

    scope = scope.parent;
  }

  visitIf(If node) {
    visit(node.condition);
    visit(node.thenPart);
    visit(node.elsePart);
  }

  static bool isLogicalOperator(Identifier op) {
    String str = op.source.stringValue;
    return (str === '&&' || str == '||' || str == '!');
  }

  /**
   * Check the lexical scope chain for a declaration with the name "assert".
   *
   * This is used to detect whether "assert(x)" is actually an assertion or
   * just a call expression.
   * It does not check fields inherited from a superclass.
   */
  bool isAssertInLexicalScope() {
    return scope.lexicalLookup(const SourceString("assert")) !== null;
  }

  /** Check if [node] is the expression of the current expression statement. */
  bool isExpressionStatementExpression(Node node) {
    return currentExpressionStatement !== null &&
        currentExpressionStatement.expression === node;
  }

  Element resolveSend(Send node) {
    Selector selector = resolveSelector(node);

    if (node.receiver === null) {
      // If this send is the expression of an expression statement, and is on
      // the form "assert(expr);", and there is no declaration with name
      // "assert" in the lexical scope, then this is actually an assertion.
      if (isExpressionStatementExpression(node) &&
          selector.isAssertSyntax() &&
          !isAssertInLexicalScope()) {
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
    if (name.stringValue === 'this') {
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
      if (currentClass.supertype === null) {
        // This is just to guard against internal errors, so no need
        // for a real error message.
        error(node.receiver, MessageKind.GENERIC, ["Object has no superclass"]);
      }
      target = currentClass.lookupSuperMember(name);
      // [target] may be null which means invoking noSuchMethod on
      // super.
    } else if (Elements.isUnresolved(resolvedReceiver)) {
      return null;
    } else if (resolvedReceiver.kind === ElementKind.CLASS) {
      ClassElement receiverClass = resolvedReceiver;
      target = receiverClass.ensureResolved(compiler).lookupLocalMember(name);
      if (target === null) {
        return warnAndCreateErroneousElement(node, name,
                                             MessageKind.METHOD_NOT_FOUND,
                                             [receiverClass.name, name]);
      } else if (target.isInstanceMember()) {
        error(node, MessageKind.MEMBER_NOT_STATIC, [receiverClass.name, name]);
      }
    } else if (resolvedReceiver.kind === ElementKind.PREFIX) {
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
    if (node === null) {
      // node is of the form !Type.
      node = argument.asSend().receiver.asTypeAnnotation();
      if (node === null) compiler.cancel("malformed send");
    }
    return resolveTypeRequired(node);
  }

  static Selector computeSendSelector(Send node, LibraryElement library) {
    // First determine if this is part of an assignment.
    bool isSet = node.asSendSet() !== null;

    if (node.isIndex) {
      return isSet ? new Selector.indexSet() : new Selector.index();
    }

    if (node.isOperator) {
      SourceString source = node.selector.asOperator().source;
      String string = source.stringValue;
      if (string === '!'   || string === '&&'  || string == '||' ||
          string === 'is'  || string === 'as'  ||
          string === '===' || string === '!==' ||
          string === '>>>') {
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
      if (namedArgument !== null) {
        named.add(namedArgument.name.source);
      }
      arity++;
    }

    // If we're invoking a closure, we do not have an identifier.
    return (identifier === null)
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
    if (list === null) return;
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
      if (Elements.isUnresolved(target) && !inInstanceContext) {
        error(node.selector, MessageKind.CANNOT_RESOLVE_GETTER);
      }
    }

    bool resolvedArguments = false;
    if (node.isOperator) {
      String operatorString = node.selector.asOperator().source.stringValue;
      if (operatorString === 'is' || operatorString === 'as') {
        assert(node.arguments.tail.isEmpty());
        DartType type = resolveTypeTest(node.arguments.head);
        if (type != null) {
          compiler.enqueuer.resolution.registerIsCheck(type);
        }
        resolvedArguments = true;
      } else if (operatorString === '?') {
        Element parameter = mapping[node.receiver];
        if (parameter === null || parameter.kind !== ElementKind.PARAMETER) {
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
    if (selector === null) return;

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
    String source = node.assignmentOperator.source.stringValue;
    bool isComplex = source !== '=';
    if (!Elements.isUnresolved(target)
        && target.kind == ElementKind.ABSTRACT_FIELD) {
      AbstractFieldElement field = target;
      setter = field.setter;
      getter = field.getter;
      if (setter == null && !inInstanceContext) {
        error(node.selector, MessageKind.CANNOT_RESOLVE_SETTER);
      }
      if (isComplex && getter == null && !inInstanceContext) {
        error(node.selector, MessageKind.CANNOT_RESOLVE_GETTER);
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
      // the ++ and -- ones.
      void registerBinaryOperator(SourceString name) {
        Selector binop = new Selector.binaryOperator(name);
        world.registerDynamicInvocation(binop.name, binop);
      }
      if (source === '++') registerBinaryOperator(const SourceString('+'));
      if (source === '--') registerBinaryOperator(const SourceString('-'));
    }

    registerSend(selector, setter);
    return useElement(node, setter);
  }

  void registerSend(Selector selector, Element target) {
    if (target === null || target.isInstanceMember()) {
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
      if (!target.isClass()) world.registerStaticUse(target);
    }

    // TODO(kasperl): Pass the selector directly.
    var interceptor = new Interceptors(compiler).getStaticInterceptor(
        selector.name,
        selector.argumentCount);
    if (interceptor !== null) {
      world.registerStaticUse(interceptor);
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
    visit(node.expression);
  }

  visitThrow(Throw node) {
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
    world.registerStaticUse(constructor);
    compiler.withCurrentElement(constructor, () {
      FunctionExpression tree = constructor.parseNode(compiler);
      compiler.resolver.resolveConstructorImplementation(constructor, tree);
    });
    world.registerStaticUse(constructor.defaultImplementation);
    ClassElement cls = constructor.defaultImplementation.getEnclosingClass();
    world.registerInstantiatedClass(cls);
    cls.forEachInstanceField(
        includeBackendMembers: false,
        includeSuperMembers: true,
        f: (ClassElement enclosingClass, Element member) {
          world.addToWorkList(member);
        });
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
      Link arguments = const EmptyLink<Node>();
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

  DartType resolveTypeAnnotation(TypeAnnotation node) {
    Function report = typeRequired ? error : warning;
    DartType type = typeResolver.resolveTypeAnnotation(node, inScope: scope,
                                                       onFailure: report,
                                                       whenResolved: useType);
    if (inCheckContext && type != null) {
      compiler.enqueuer.resolution.registerIsCheck(type);
    }
    return type;
  }

  visitModifiers(Modifiers node) {
    // TODO(ngeoffray): Implement this.
    unimplemented(node, 'modifiers');
  }

  visitLiteralList(LiteralList node) {
    NodeList arguments = node.typeArguments;
    if (arguments !== null) {
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
    SourceString name = const SourceString('toString');
    LibraryElement library = enclosingElement.getLibrary();
    Selector selector = new Selector.call(name, library, 0);
    world.registerDynamicInvocation(name, selector);
    node.visitChildren(this);
  }

  visitBreakStatement(BreakStatement node) {
    TargetElement target;
    if (node.target === null) {
      target = statementScope.currentBreakTarget();
      if (target === null) {
        error(node, MessageKind.NO_BREAK_TARGET);
        return;
      }
      target.isBreakTarget = true;
    } else {
      String labelName = node.target.source.slowToString();
      LabelElement label = statementScope.lookupLabel(labelName);
      if (label === null) {
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
    if (node.target === null) {
      target = statementScope.currentContinueTarget();
      if (target === null) {
        error(node, MessageKind.NO_CONTINUE_TARGET);
        return;
      }
      target.isContinueTarget = true;
    } else {
      String labelName = node.target.source.slowToString();
      LabelElement label = statementScope.lookupLabel(labelName);
      if (label === null) {
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

  visitForIn(ForIn node) {
    visit(node.expression);
    Scope blockScope = new BlockScope(scope);
    Node declaration = node.declaredIdentifier;
    visitIn(declaration, blockScope);
    visitLoopBodyIn(node, node.body, blockScope);

    // TODO(lrn): Also allow a single identifier.
    if ((declaration is !Send || declaration.asSend().selector is !Identifier)
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
    if (!targetElement.isTarget && mapping[body] === targetElement) {
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
        if (existingElement !== null) {
          // It's an error if the same label occurs twice in the same switch.
          warning(label, MessageKind.DUPLICATE_LABEL, [labelName]);
          error(existingElement.label, MessageKind.EXISTING_LABEL, [labelName]);
        } else {
          // It's only a warning if it shadows another label.
          existingElement = statementScope.lookupLabel(labelName);
          if (existingElement !== null) {
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
      if (switchCase.defaultKeyword !== null && !cases.isEmpty()) {
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
    if (node.formals !== null) {
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
        if (nodeList !== null) {
          error(nodeList, MessageKind.OPTIONAL_PARAMETER_IN_CATCH);
        } else {
        VariableDefinitions declaration = link.head;
          for (Node modifier in declaration.modifiers.nodes) {
            error(modifier, MessageKind.PARAMETER_WITH_MODIFIER_IN_CATCH);
          }
          TypeAnnotation type = declaration.type;
          if (type !== null) {
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
    visitIn(node.block, blockScope);
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
        scope = element.buildEnclosingScope(),
        typeResolver = new TypeResolver(compiler),
        super(compiler);

  void resolveTypeVariableBounds(NodeList node) {
    if (node === null) return;

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
      if (typeNode.bound !== null) {
        DartType boundType = typeResolver.resolveTypeAnnotation(
            typeNode.bound, inScope: scope, onFailure: warning);
        if (boundType !== null && boundType.element == variableElement) {
          // TODO(johnniwinther): Check for more general cycles, like
          // [: <A extends B, B extends C, C extends B> :].
          warning(node, MessageKind.CYCLIC_TYPE_VARIABLE,
                  [variableElement.name]);
        } else if (boundType !== null) {
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
    compiler.ensure(element !== null);
    compiler.ensure(element.resolutionState == STATE_STARTED);

    InterfaceType type = element.computeType(compiler);
    scope = new TypeDeclarationScope(scope, element);
    // TODO(ahe): It is not safe to call resolveTypeVariableBounds yet.
    // As a side-effect, this may get us back here trying to
    // resolve this class again.
    resolveTypeVariableBounds(node.typeParameters);

    // Find super type.
    DartType supertype = visit(node.superclass);
    if (supertype !== null && supertype.element.isExtendable()) {
      element.supertype = supertype;
      if (isBlackListed(supertype)) {
        error(node.superclass, MessageKind.CANNOT_EXTEND, [supertype]);
      }
    } else if (supertype !== null) {
      error(node.superclass, MessageKind.TYPE_NAME_EXPECTED);
    }
    final objectElement = compiler.objectClass;
    if (element !== objectElement && element.supertype === null) {
      if (objectElement === null) {
        compiler.internalError("Internal error: cannot resolve Object",
                               node: node);
      } else {
        objectElement.ensureResolved(compiler);
      }
      // TODO(ahe): This should be objectElement.computeType(...).
      element.supertype = new InterfaceType(objectElement);
    }
    assert(element.interfaces === null);
    Link<DartType> interfaces = const EmptyLink<DartType>();
    for (Link<Node> link = node.interfaces.nodes;
         !link.isEmpty();
         link = link.tail) {
      DartType interfaceType = visit(link.head);
      if (interfaceType !== null && interfaceType.element.isExtendable()) {
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

    if (node.defaultClause !== null) {
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
    if (element === null) {
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
    if (prefix === null) {
      error(node.receiver, MessageKind.NOT_A_PREFIX, [node.receiver]);
      return null;
    }
    Element element = scope.lookup(prefix.source);
    if (element === null || element.kind !== ElementKind.PREFIX) {
      error(node.receiver, MessageKind.NOT_A_PREFIX, [node.receiver]);
      return null;
    }
    PrefixElement prefixElement = element;
    Identifier selector = node.selector.asIdentifier();
    var e = prefixElement.lookupLocalMember(selector.source);
    if (e === null || !e.impliesType()) {
      error(node.selector, MessageKind.CANNOT_RESOLVE_TYPE, [node.selector]);
      return null;
    }
    return e.computeType(compiler);
  }

  void calculateAllSupertypes(ClassElement cls) {
    // TODO(karlklose): substitute type variables.
    // TODO(karlklose): check if type arguments match, if a classelement occurs
    //                  more than once in the supertypes.
    if (cls.allSupertypes !== null) return;
    final DartType supertype = cls.supertype;
    if (supertype != null) {
      ClassElement superElement = supertype.element;
      Link<DartType> superSupertypes = superElement.allSupertypes;
      assert(superSupertypes !== null);
      Link<DartType> supertypes =
          new Link<DartType>(supertype, superSupertypes);
      for (Link<DartType> interfaces = cls.interfaces;
           !interfaces.isEmpty();
           interfaces = interfaces.tail) {
        ClassElement element = interfaces.head.element;
        Link<DartType> interfaceSupertypes = element.allSupertypes;
        assert(interfaceSupertypes !== null);
        supertypes = supertypes.reversePrependAll(interfaceSupertypes);
        supertypes = supertypes.prepend(interfaces.head);
      }
      cls.allSupertypes = supertypes;
    } else {
      assert(cls === compiler.objectClass);
      cls.allSupertypes = const EmptyLink<DartType>();
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
    constructor.type = new FunctionType(returnType, const EmptyLink<DartType>(),
                                        constructor);
    constructor.cachedNode =
      new FunctionExpression(new Identifier(element.position()),
                             new NodeList.empty(),
                             new Block(new NodeList.empty()),
                             null, null, null, null);
  }

  isBlackListed(DartType type) {
    LibraryElement lib = element.getLibrary();
    return
      lib !== compiler.coreLibrary &&
      lib !== compiler.coreImplLibrary &&
      lib !== compiler.jsHelperLibrary &&
      (type.element === compiler.dynamicClass ||
       type.element === compiler.boolClass ||
       type.element === compiler.numClass ||
       type.element === compiler.intClass ||
       type.element === compiler.doubleClass ||
       type.element === compiler.stringClass ||
       type.element === compiler.nullClass ||
       type.element === compiler.functionClass);
  }
}

class ClassSupertypeResolver extends CommonResolverVisitor {
  Scope context;
  ClassElement classElement;

  ClassSupertypeResolver(Compiler compiler, ClassElement cls)
    : context = new TopScope(cls.getLibrary()),
      this.classElement = cls,
      super(compiler);

  void loadSupertype(ClassElement element, Node from) {
    compiler.resolver.loadSupertypes(element, from);
    element.ensureResolved(compiler);
  }

  void visitClassNode(ClassNode node) {
    if (node.superclass === null) {
      if (classElement !== compiler.objectClass) {
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
    if (element === null) {
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
          api.Diagnostic.ERROR);
      }
    }
  }

  void visitSend(Send node) {
    Identifier prefix = node.receiver.asIdentifier();
    if (prefix === null) {
      error(node.receiver, MessageKind.NOT_A_PREFIX, [node.receiver]);
      return;
    }
    Element element = context.lookup(prefix.source);
    if (element === null || element.kind !== ElementKind.PREFIX) {
      error(node.receiver, MessageKind.NOT_A_PREFIX, [node.receiver]);
      return;
    }
    PrefixElement prefixElement = element;
    Identifier selector = node.selector.asIdentifier();
    var e = prefixElement.lookupLocalMember(selector.source);
    if (e === null || !e.impliesType()) {
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
        definitions, ElementKind.VARIABLE_LIST, resolver.scope.element);
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
      VariableElement element = new VariableElement(
          name, variables, kind, resolver.scope.element, node: link.head);
      resolver.defineElement(link.head, element);
    }
  }
}

/**
 * [SignatureResolver] resolves function signatures.
 */
class SignatureResolver extends CommonResolverVisitor<Element> {
  final Element enclosingElement;
  Link<Element> optionalParameters = const EmptyLink<Element>();
  int optionalParameterCount = 0;
  VariableDefinitions currentDefinitions;

  SignatureResolver(Compiler compiler, this.enclosingElement) : super(compiler);

  Element visitNodeList(NodeList node) {
    // This must be a list of optional arguments.
    String value = node.beginToken.stringValue;
    if ((value !== '[') && (value !== '{')) {
      internalError(node, "expected optional parameters");
    }
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
    return new VariableElement(node.source, variables,
        ElementKind.PARAMETER, enclosingElement, node: node);
  }

  SourceString getParameterName(Send node) {
    var identifier = node.selector.asIdentifier();
    if (identifier !== null) {
      // Normal parameter: [:Type name:].
      return identifier.source;
    } else {
      // Function type parameter: [:void name(DartType arg):].
      var functionExpression = node.selector.asFunctionExpression();
      if (functionExpression !== null &&
          functionExpression.name.asIdentifier() !== null) {
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
    if (node.receiver.asIdentifier() === null ||
        !node.receiver.asIdentifier().isThis()) {
      error(node, MessageKind.INVALID_PARAMETER, []);
    } else if (enclosingElement.kind !== ElementKind.GENERATIVE_CONSTRUCTOR) {
      error(node, MessageKind.FIELD_PARAMETER_NOT_ALLOWED, []);
    } else {
      SourceString name = getParameterName(node);
      Element fieldElement = currentClass.lookupLocalMember(name);
      if (fieldElement === null || fieldElement.kind !== ElementKind.FIELD) {
        error(node, MessageKind.NOT_A_FIELD, [name]);
      } else if (!fieldElement.isInstanceMember()) {
        error(node, MessageKind.NOT_INSTANCE_FIELD, [name]);
      }
      Element variables = new VariableListElement.node(currentDefinitions,
          ElementKind.VARIABLE_LIST, enclosingElement);
      element = new FieldParameterElement(name,
          fieldElement, variables, enclosingElement, node);
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
          variables, ElementKind.PARAMETER, enclosingElement, node: node);
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
    Link<Element> parameters = const EmptyLink<Element>();
    int requiredParameterCount = 0;
    if (formalParameters === null) {
      if (!element.isGetter()) {
        compiler.reportMessage(compiler.spanFromElement(element),
                               MessageKind.MISSING_FORMALS.error([]),
                               api.Diagnostic.ERROR);
      }
    } else {
      if (element.isGetter()) {
        if (!element.getLibrary().isPlatformLibrary) {
          // TODO(ahe): Remove the isPlatformLibrary check.
          if (formalParameters.getEndToken().next.stringValue !== 'native') {
            // TODO(ahe): Remove the check for native keyword.
            compiler.reportMessage(compiler.spanFromNode(formalParameters),
                                   MessageKind.EXTRA_FORMALS.error([]),
                                   api.Diagnostic.WARNING);
          }
        }
      }
      LinkBuilder<Element> parametersBuilder =
        visitor.analyzeNodes(formalParameters.nodes);
      requiredParameterCount  = parametersBuilder.length;
      parameters = parametersBuilder.toLink();
    }
    DartType returnType = compiler.resolveTypeAnnotation(element, returnNode);
    return new FunctionSignature(parameters,
                                 visitor.optionalParameters,
                                 requiredParameterCount,
                                 visitor.optionalParameterCount,
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
  final bool inConstContext;

  ConstructorResolver(Compiler compiler, this.resolver,
                      [bool this.inConstContext = false])
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
      return new ErroneousFunctionElement(warning.message, targetName,
                                          enclosing);
    }
  }

  FunctionElement lookupConstructor(ClassElement cls,
                                    Node diagnosticNode,
                                    SourceString constructorName) {
    cls.ensureResolved(compiler);
    Element result = cls.lookupConstructor(cls.name, constructorName);
    if (result === null) {
      String fullConstructorName = cls.name.slowToString();
      if (constructorName !== const SourceString('')) {
        fullConstructorName = '$fullConstructorName'
                              '.${constructorName.slowToString()}';
      }
      return failOrReturnErroneousElement(cls, diagnosticNode,
                                          new SourceString(fullConstructorName),
                                          MessageKind.CANNOT_FIND_CONSTRUCTOR,
                                          [fullConstructorName]);
    }
    return result;
  }

  visitNewExpression(NewExpression node) {
    Node selector = node.send.selector;
    Element e = visit(selector);
    if (!Elements.isUnresolved(e) && e.kind === ElementKind.CLASS) {
      ClassElement cls = e;
      cls.ensureResolved(compiler);
      if (cls.isInterface() && (cls.defaultClass === null)) {
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
    if (name === null) internalError(node.selector, 'unexpected node');

    if (e.kind === ElementKind.CLASS) {
      ClassElement cls = e;
      cls.ensureResolved(compiler);
      if (cls.isInterface() && (cls.defaultClass === null)) {
        error(node.receiver, MessageKind.CANNOT_INSTANTIATE_INTERFACE,
              [cls.name]);
      }
      return lookupConstructor(cls, name, name.source);
    } else if (e.kind === ElementKind.PREFIX) {
      PrefixElement prefix = e;
      e = prefix.lookupLocalMember(name.source);
      if (e === null) {
        return failOrReturnErroneousElement(resolver.enclosingElement, name,
                                            name.source,
                                            MessageKind.CANNOT_RESOLVE,
                                            [name]);
      } else if (e.kind !== ElementKind.CLASS) {
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
    if (e === null) {
      return failOrReturnErroneousElement(resolver.enclosingElement, node, name,
                                          MessageKind.CANNOT_RESOLVE, [name]);
    } else if (e.kind === ElementKind.TYPEDEF) {
      error(node, MessageKind.CANNOT_INSTANTIATE_TYPEDEF, [name]);
    } else if (e.kind !== ElementKind.CLASS && e.kind !== ElementKind.PREFIX) {
      error(node, MessageKind.NOT_A_TYPE, [name]);
    }
    return e;
  }
}

class Scope {
  final Element element;
  final Scope parent;

  Scope(this.parent, this.element);
  abstract Element add(Element element);

  Element lookup(SourceString name) {
    Element result = localLookup(name);
    if (result != null) return result;
    return parent.lookup(name);
  }

  Element lexicalLookup(SourceString name) {
    Element result = localLookup(name);
    if (result != null) return result;
    return parent.lexicalLookup(name);
  }

  abstract Element localLookup(SourceString name);
}

class VariableScope extends Scope {
  VariableScope(parent, element) : super(parent, element);

  Element add(Element newElement) {
    throw "Cannot add element to VariableScope";
  }

  Element lookup(SourceString name) => parent.lookup(name);

  String toString() => '$element > $parent';
}

/**
 * [TypeDeclarationScope] defines the outer scope of a type declaration in
 * which the declared type variables and the entities in the enclosing scope are
 * available but where declared and inherited members are not available. This
 * scope is only used for class/interface declarations during resolution of the
 * class hierarchy. In all other cases [ClassScope] is used.
 */
class TypeDeclarationScope extends Scope {
  TypeDeclarationElement get element => super.element;

  TypeDeclarationScope(parent, TypeDeclarationElement element)
      : super(parent, element) {
    assert(parent !== null);
  }

  Element add(Element newElement) {
    throw "Cannot add element to TypeDeclarationScope";
  }

  Element localLookup(SourceString name) {
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

  String toString() =>
      '$element${element.typeVariables} > $parent';
}

class MethodScope extends Scope {
  final Map<SourceString, Element> elements;

  MethodScope(Scope parent, Element element)
      : super(parent, element),
        this.elements = new Map<SourceString, Element>() {
    assert(parent !== null);
  }

  Element localLookup(SourceString name) => elements[name];

  Element add(Element newElement) {
    if (elements.containsKey(newElement.name)) {
      return elements[newElement.name];
    }
    elements[newElement.name] = newElement;
    return newElement;
  }

  String toString() => '$element${elements.getKeys()} > $parent';
}

class BlockScope extends MethodScope {
  BlockScope(Scope parent) : super(parent, parent.element);

  String toString() => 'block${elements.getKeys()} > $parent';
}

/**
 * [ClassScope] defines the inner scope of a class/interface declaration in
 * which declared members, declared type variables, entities in the enclosing
 * scope and inherited members are available, in the given order.
 */
class ClassScope extends TypeDeclarationScope {
  bool inStaticContext = false;

  ClassScope(Scope parentScope, ClassElement element)
      : super(parentScope, element);

  Element localLookup(SourceString name) {
    ClassElement cls = element;
    Element result = cls.lookupLocalMember(name);
    if (result !== null) return result;
    if (!inStaticContext) {
      // If not in a static context, we can lookup in the
      // TypeDeclaration scope, which contains the type variables of
      // the class.
      return super.localLookup(name);
    }
    return null;
  }

  Element lookup(SourceString name) {
    Element result = super.lookup(name);
    if (result !== null) return result;
    ClassElement cls = element;
    return cls.lookupSuperMember(name);
  }

  Element add(Element newElement) {
    throw "Cannot add an element in a class scope";
  }

  String toString() => '$element > $parent';
}

class TopScope extends Scope {
  LibraryElement get library => element;

  TopScope(LibraryElement library) : super(null, library);

  Element localLookup(SourceString name) => library.find(name);
  Element lookup(SourceString name) => localLookup(name);
  Element lexicalLookup(SourceString name) => localLookup(name);

  Element add(Element newElement) {
    throw "Cannot add an element in the top scope";
  }
  String toString() => '$element';
}
