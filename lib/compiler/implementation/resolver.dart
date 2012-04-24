// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface TreeElements {
  Element operator[](Node node);
  Selector getSelector(Send send);
  Type getType(TypeAnnotation annotation);
}

class TreeElementMapping implements TreeElements {
  Map<Node, Element> map;
  Map<Send, Selector> selectors;
  Map<TypeAnnotation, Type> types;

  TreeElementMapping()
    : map = new LinkedHashMap<Node, Element>(),
      selectors = new LinkedHashMap<Send, Selector>(),
      types = new LinkedHashMap<TypeAnnotation, Type>();

  operator []=(Node node, Element element) => map[node] = element;
  operator [](Node node) => map[node];
  void remove(Node node) { map.remove(node); }

  void setType(TypeAnnotation annotation, Type type) {
    types[annotation] = type;
  }

  Type getType(TypeAnnotation annotation) => types[annotation];

  void setSelector(Send send, Selector selector) {
    selectors[send] = selector;
  }

  Selector getSelector(Send send) => selectors[send];
}

class ResolverTask extends CompilerTask {
  Queue<ClassElement> toResolve;

  // Caches the elements of analyzed constructors to make them available
  // for inlining in later tasks.
  Map<FunctionElement, TreeElements> constructorElements;

  ResolverTask(Compiler compiler)
    : super(compiler), toResolve = new Queue<ClassElement>(),
      constructorElements = new Map<FunctionElement, TreeElements>();

  String get name() => 'Resolver';

  TreeElements resolve(Element element) {
    return measure(() {
      switch (element.kind) {
        case ElementKind.GENERATIVE_CONSTRUCTOR:
        case ElementKind.FUNCTION:
        case ElementKind.GETTER:
        case ElementKind.SETTER:
          return resolveMethodElement(element);

        case ElementKind.FIELD:
          return resolveField(element);

        case ElementKind.PARAMETER:
        case ElementKind.FIELD_PARAMETER:
          return resolveParameter(element);

        default:
          compiler.unimplemented(
              "resolver", node: element.parseNode(compiler));
      }
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
      final ClassElement classElement = constructor.enclosingElement;
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
      if (constructorElements.containsKey(element)) {
        assert(isConstructor);
        TreeElements elements = constructorElements[element];
        if (elements !== null) return elements;
      }
      FunctionExpression tree = element.parseNode(compiler);
      if (isConstructor) {
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
      visitor.visit(tree.body);

      // Resolve the type annotations encountered in the method.
      while (!toResolve.isEmpty()) {
        ClassElement classElement = toResolve.removeFirst();
        classElement.ensureResolved(compiler);
      }
      if (isConstructor) {
        constructorElements[element] = visitor.mapping;
      }
      return visitor.mapping;
    });
  }

  void resolveConstructorImplementation(FunctionElement constructor,
                                        FunctionExpression node) {
    assert(constructor.defaultImplementation === constructor);
    ClassElement intrface = constructor.enclosingElement;
    if (!intrface.isInterface()) return;
    Type defaultType = intrface.defaultClass;
    if (defaultType === null) {
      error(node, MessageKind.NO_DEFAULT_CLASS, [intrface.name]);
    }
    ClassElement defaultClass = defaultType.element;
    defaultClass.ensureResolved(compiler);
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

  void resolveClass(ClassElement element) {
    if (element.isResolved) return;
    measure(() {
      ClassNode tree = element.parseNode(compiler);
      ClassResolverVisitor visitor =
        new ClassResolverVisitor(compiler, element.getLibrary(), element);
      visitor.visit(tree);
      element.isResolved = true;
    });
  }

  FunctionParameters resolveSignature(FunctionElement element) {
    return measure(() => SignatureResolver.analyze(compiler, element));
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

  void resolveFieldInitializer(FunctionElement constructor, SendSet init) {
    // init is of the form [this.]field = value.
    final Node selector = init.selector;
    final SourceString name = selector.asIdentifier().source;
    // Lookup target field.
    Element target;
    if (isFieldInitializer(init)) {
      final ClassElement classElement = constructor.enclosingElement;
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
    // Check for duplicate initializers.
    if (initialized.containsKey(name)) {
      error(init, MessageKind.DUPLICATE_INITIALIZER, [name]);
      warning(initialized[name], MessageKind.ALREADY_INITIALIZED, [name]);
    }
    initialized[name] = init;
    // Resolve initializing value.
    visitor.visitInStaticContext(init.arguments.head);
  }

  Element resolveSuperOrThisForSend(FunctionElement constructor,
                                    FunctionExpression functionNode,
                                    Send call) {
    // Resolve the arguments, and make sure the call gets a selector
    // by calling handleArguments.
    ResolverTask resolver = visitor.compiler.resolver;
    visitor.inStaticContext( () => visitor.handleArguments(call) );
    Selector selector = visitor.mapping.getSelector(call);
    bool isSuperCall = Initializers.isSuperConstructorCall(call);
    SourceString constructorName = resolver.getConstructorName(call);
    Element result = resolveSuperOrThis(
        constructor, isSuperCall, false, constructorName, selector, call);
    visitor.useElement(call, result);
    return result;
  }

  void resolveImplicitSuperConstructorSend(FunctionElement constructor,
                                           FunctionExpression functionNode) {
    // If the class has a super resolve the implicit super call.
    ClassElement classElement = constructor.enclosingElement;
    ClassElement superClass = classElement.superclass;
    if (classElement != visitor.compiler.objectClass) {
      assert(superClass !== null);
      assert(superClass.isResolved);
      resolveSuperOrThis(constructor, true, true, const SourceString(''),
                         Selector.INVOCATION_0, functionNode);
    }
  }

  Element resolveSuperOrThis(FunctionElement constructor,
                             bool isSuperCall,
                             bool isImplicitSuperCall,
                             SourceString constructorName,
                             Selector selector,
                             Node diagnosticNode) {
    ClassElement lookupTarget = constructor.enclosingElement;
    bool validTarget = true;
    FunctionElement result;
    if (isSuperCall) {
      // Calculate correct lookup target and constructor name.
      if (lookupTarget.name == Types.OBJECT) {
        error(diagnosticNode, MessageKind.SUPER_INITIALIZER_IN_OBJECT);
      } else {
        lookupTarget = lookupTarget.supertype.element;
      }
    }

    // Lookup constructor and try to match it to the selector.
    ResolverTask resolver = visitor.compiler.resolver;
    final SourceString className = lookupTarget.name;
    result = lookupTarget.lookupConstructor(className, constructorName);
    if (result === null) {
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
    cancel(node, 'internal error');
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
  LabelScope get outer();
  LabelElement lookup(String label);
}

class LabeledStatementLabelScope implements LabelScope {
  final LabelScope outer;
  final LabelElement label;
  LabeledStatementLabelScope(this.outer, this.label);
  LabelElement lookup(String labelName) {
    if (this.label.labelName == labelName) return label;
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
  LabelScope get outer() {
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

  void enterLabelScope(LabelElement element) {
    labels = new LabeledStatementLabelScope(labels, element);
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

class ResolverVisitor extends CommonResolverVisitor<Element> {
  final TreeElementMapping mapping;
  final Element enclosingElement;
  bool inInstanceContext;
  Scope context;
  ClassElement currentClass;
  bool typeRequired = false;
  StatementScope statementScope;
  int allowedCategory = ElementCategory.VARIABLE | ElementCategory.FUNCTION;

  ResolverVisitor(Compiler compiler, Element element)
    : this.mapping  = new TreeElementMapping(),
      this.enclosingElement = element,
      inInstanceContext = element.isInstanceMember()
          || element.isGenerativeConstructor(),
      this.context  = element.isMember()
        ? new ClassScope(element.enclosingElement, element.getLibrary())
        : new TopScope(element.getLibrary()),
      this.currentClass = element.isMember() ? element.enclosingElement : null,
      this.statementScope = new StatementScope(),
      super(compiler);

  Element lookup(Node node, SourceString name) {
    Element result = context.lookup(name);
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
    Type type = resolveTypeAnnotation(node);
    if (type !== null) return type.element;
    return null;
  }

  Element defineElement(Node node, Element element,
                        [bool doAddToScope = true]) {
    compiler.ensure(element !== null);
    mapping[node] = element;
    if (doAddToScope) {
      Element existing = context.add(element);
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

  Type useType(TypeAnnotation annotation, Type type) {
    if (type !== null) {
      mapping.setType(annotation, type);
      useElement(annotation, type.element);
    }
    return type;
  }

  void setupFunction(FunctionExpression node, FunctionElement function) {
    context = new MethodScope(context, function);
    // Put the parameters in scope.
    FunctionParameters functionParameters =
        function.computeParameters(compiler);
    Link<Node> parameterNodes = node.parameters.nodes;
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

  visitIn(Node node, Scope scope) {
    context = scope;
    Element element = visit(node);
    context = context.parent;
    return element;
  }

  /**
   * Introduces new default targets for break and continue
   * before visiting the body of the loop
   */
  visitLoopBodyIn(Node loop, Node body, Scope scope) {
    TargetElement element = getOrCreateTargetElement(loop);
    statementScope.enterLoop(element);
    visitIn(body, scope);
    statementScope.exitLoop();
    if (!element.isTarget) {
      mapping.remove(loop);
    }
  }

  visitBlock(Block node) {
    visitIn(node.statements, new BlockScope(context));
  }

  visitDoWhile(DoWhile node) {
    visitLoopBodyIn(node, node.body, new BlockScope(context));
    visit(node.condition);
  }

  visitEmptyStatement(EmptyStatement node) { }

  visitExpressionStatement(ExpressionStatement node) {
    visit(node.expression);
  }

  visitFor(For node) {
    Scope scope = new BlockScope(context);
    visitIn(node.initializer, scope);
    visitIn(node.condition, scope);
    visitIn(node.update, scope);
    visitLoopBodyIn(node, node.body, scope);
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
        context.element);
    setupFunction(node, enclosing);
    defineElement(node, enclosing, doAddToScope: node.name !== null);

    // Run the body in a fresh statement scope.
    StatementScope oldScope = statementScope;
    statementScope = new StatementScope();
    visit(node.body);
    statementScope = oldScope;

    context = context.parent;
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

  Element resolveSend(Send node) {
    if (node.receiver === null) {
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
          name = Elements.constructOperatorName(const SourceString('operator'),
                                                name);
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
    } else if (resolvedReceiver === null) {
      return null;
    } else if (resolvedReceiver.kind === ElementKind.CLASS) {
      ClassElement receiverClass = resolvedReceiver;
      target = receiverClass.ensureResolved(compiler).lookupLocalMember(name);
      if (target === null) {
        error(node, MessageKind.METHOD_NOT_FOUND, [receiverClass.name, name]);
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

  Type resolveTypeTest(Node argument) {
    TypeAnnotation node = argument.asTypeAnnotation();
    if (node === null) {
      // node is of the form !Type.
      node = argument.asSend().receiver.asTypeAnnotation();
      if (node === null) compiler.cancel("malformed send");
    }
    return resolveTypeRequired(node);
  }

  void handleArguments(Send node) {
    int count = 0;
    List<SourceString> namedArguments = <SourceString>[];
    bool seenNamedArgument = false;
    for (Link<Node> link = node.argumentsNode.nodes;
         !link.isEmpty();
         link = link.tail) {
      count++;
      Expression argument = link.head;
      visit(argument);
      if (argument.asNamedArgument() != null) {
        seenNamedArgument = true;
        NamedArgument named = argument;
        namedArguments.add(named.name.source);
      } else if (seenNamedArgument) {
        error(argument, MessageKind.INVALID_ARGUMENT_AFTER_NAMED);
      }
    }
    mapping.setSelector(node, new Invocation(count, namedArguments));
  }

  visitSend(Send node) {
    Element target = resolveSend(node);
    if (node.isOperator) {
      Operator op = node.selector.asOperator();
      if (op.source.stringValue === 'is') {
        resolveTypeTest(node.arguments.head);
        assert(node.arguments.tail.isEmpty());
        mapping.setSelector(node, Selector.BINARY_OPERATOR);
      } else if (node.arguments.isEmpty()) {
        assert(op.token.kind !== PLUS_TOKEN);
        mapping.setSelector(node, Selector.UNARY_OPERATOR);
      } else {
        visit(node.argumentsNode);
        mapping.setSelector(node, Selector.BINARY_OPERATOR);
      }
    } else if (node.isIndex) {
      visit(node.argumentsNode);
      assert(node.arguments.tail.isEmpty());
      mapping.setSelector(node, Selector.INDEX);
    } else if (node.isPropertyAccess) {
      mapping.setSelector(node, Selector.GETTER);
    } else {
      handleArguments(node);
    }
    if (target != null && target.kind == ElementKind.ABSTRACT_FIELD) {
      AbstractFieldElement field = target;
      target = field.getter;
    }
    // TODO(ngeoffray): Warn if target is null and the send is
    // unqualified.
    useElement(node, target);
    if (node.isPropertyAccess) return target;
  }

  visitSendSet(SendSet node) {
    Element target = resolveSend(node);
    Element setter = null;
    Element getter = null;
    if (target != null && target.kind == ElementKind.ABSTRACT_FIELD) {
      AbstractFieldElement field = target;
      setter = field.setter;
      getter = field.getter;
    } else {
      setter = target;
      getter = target;
    }
    // TODO(ngeoffray): Check if the target can be assigned.
    Identifier op = node.assignmentOperator;
    bool needsGetter = op.source.stringValue !== '=';
    Selector selector;
    if (needsGetter) {
      if (node.isIndex) {
        selector = Selector.INDEX_AND_INDEX_SET;
      } else {
        selector = Selector.GETTER_AND_SETTER;
      }
      useElement(node.selector, getter);
    } else if (node.isIndex) {
      selector = Selector.INDEX_SET;
    } else {
      selector = Selector.SETTER;
    }
    visit(node.argumentsNode);
    mapping.setSelector(node, selector);
    // TODO(ngeoffray): Warn if target is null and the send is
    // unqualified.
    return useElement(node, setter);
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
    visitLoopBodyIn(node, node.body, new BlockScope(context));
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    visit(node.expression);
  }

  visitNewExpression(NewExpression node) {
    Node selector = node.send.selector;

    FunctionElement constructor = resolveConstructor(node);
    handleArguments(node.send);
    if (constructor === null) return null;
    // TODO(karlklose): handle optional arguments.
    if (node.send.argumentCount() != constructor.parameterCount(compiler)) {
      // TODO(ngeoffray): resolution error with wrong number of
      // parameters. We cannot do this rigth now because of the
      // List constructor.
    }
    useElement(node.send, constructor);
    return null;
  }

  TypeAnnotation getTypeAnnotationFromSend(Send send) {
    if (send.selector.asTypeAnnotation() !== null) {
      return send.selector;
    } else if (send.selector.asSend() !== null) {
      Send selector = send.selector;
      if (selector.receiver.asTypeAnnotation() !== null) {
        return selector.receiver;
      }
    } else {
      compiler.internalError("malformed send in new expression");
    }
  }

  FunctionElement resolveConstructor(NewExpression node) {
    FunctionElement constructor =
        node.accept(new ConstructorResolver(compiler, this));
    TypeAnnotation annotation = getTypeAnnotationFromSend(node.send);
    Type type = resolveTypeRequired(annotation);
    if (constructor === null) {
      Element resolved = (type != null) ? type.element : null;
      if (resolved !== null && resolved.kind === ElementKind.TYPE_VARIABLE) {
        error(node, MessageKind.TYPE_VARIABLE_AS_CONSTRUCTOR);
        return null;
      } else {
        error(node.send, MessageKind.CANNOT_FIND_CONSTRUCTOR, [node.send]);
        return null;
      }
    }
    return constructor;
  }

  Type resolveTypeRequired(TypeAnnotation node) {
    bool old = typeRequired;
    typeRequired = true;
    Type result = resolveTypeAnnotation(node);
    typeRequired = old;
    return result;
  }

  Element resolveTypeName(TypeAnnotation node) {
    Identifier typeName = node.typeName.asIdentifier();
    Send send = node.typeName.asSend();
    if (send !== null) {
      typeName = send.selector;
    }
    if (typeName.source == Types.VOID) return compiler.types.voidType.element;
    if (send !== null) {
      Element e = context.lookup(send.receiver.asIdentifier().source);
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
      return context.lookup(typeName.source);
    }
  }

  Type resolveTypeAnnotation(TypeAnnotation node) {
    Function report = typeRequired ? error : warning;
    Element element = resolveTypeName(node);
    Type type;
    if (element === null) {
      report(node, MessageKind.CANNOT_RESOLVE_TYPE, [node.typeName]);
    } else if (!element.impliesType()) {
      report(node, MessageKind.NOT_A_TYPE, [node.typeName]);
    } else {
      if (element === compiler.types.voidType.element ||
          element === compiler.types.dynamicType.element) {
        type = element.computeType(compiler);
      } else if (element.isClass()) {
        ClassElement cls = element;
        if (!cls.isResolved) compiler.resolveClass(cls);
        LinkBuilder<Type> arguments = new LinkBuilder<Type>();
        if (node.typeArguments !== null) {
          int index = 0;
          for (Link<Node> typeArguments = node.typeArguments.nodes;
               !typeArguments.isEmpty();
               typeArguments = typeArguments.tail) {
            if (++index > cls.typeParameters.length) {
              report(typeArguments.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT);
            }
            arguments.addLast(resolveTypeAnnotation(typeArguments.head));
          }
          if (index < cls.typeParameters.length) {
            report(node.typeArguments, MessageKind.MISSING_TYPE_ARGUMENT);
          }
        }
        type = new InterfaceType(cls.name, cls, arguments.toLink());
      } else if (element.isTypedef()) {
        // TODO(karlklose): implement typedefs. We return a fake type that the
        // code generator can use to detect typedefs in is-checks.
        type = new InterfaceType(element.name, element);
      } else {
        type = element.computeType(compiler);
      }
    }
    return useType(node, type);
  }

  visitModifiers(Modifiers node) {
    // TODO(ngeoffray): Implement this.
    unimplemented(node, 'modifiers');
  }

  visitLiteralList(LiteralList node) {
    visit(node.elements);
  }

  visitConditional(Conditional node) {
    node.visitChildren(this);
  }

  visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
  }

  visitStringInterpolationPart(StringInterpolationPart node) {
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
      label.setContinueTarget();
      mapping[node.target] = label;
    }
    mapping[node] = target;
  }

  visitForIn(ForIn node) {
    visit(node.expression);
    Scope scope = new BlockScope(context);
    Node declaration = node.declaredIdentifier;
    visitIn(declaration, scope);
    visitLoopBodyIn(node, node.body, scope);

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

  visitLabeledStatement(LabeledStatement node) {
    String labelName = node.label.source.slowToString();
    LabelElement existingElement = statementScope.lookupLabel(labelName);
    if (existingElement !== null) {
      warning(node.label, MessageKind.DUPLICATE_LABEL, [labelName]);
      warning(existingElement.label, MessageKind.EXISTING_LABEL, [labelName]);
    }
    Node body = node.getBody();
    TargetElement targetElement = getOrCreateTargetElement(body);

    LabelElement element = targetElement.addLabel(node.label, labelName);
    statementScope.enterLabelScope(element);
    visit(node.statement);
    statementScope.exitLabelScope();
    if (element.isTarget) {
      mapping[node.label] = element;
    } else {
      warning(node.label, MessageKind.UNUSED_LABEL, [labelName]);
    }
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
    Map<String, LabelElement> continueLabels = <LabelElement>{};
    Link<Node> cases = node.cases.nodes;
    while (!cases.isEmpty()) {
      SwitchCase switchCase = cases.head;
      if (switchCase.label !== null) {
        Identifier labelIdentifier = switchCase.label;
        String labelName = labelIdentifier.source.slowToString();

        LabelElement existingElement = continueLabels[labelName];
        if (existingElement !== null) {
          // It's an error if the same label occurs twice in the same switch.
          warning(labelIdentifier, MessageKind.DUPLICATE_LABEL, [labelName]);
          error(existingElement.label, MessageKind.EXISTING_LABEL, [labelName]);
        } else {
          // It's only a warning if it shadows another label.
          existingElement = statementScope.lookupLabel(labelName);
          if (existingElement !== null) {
            warning(labelIdentifier, MessageKind.DUPLICATE_LABEL, [labelName]);
            warning(existingElement.label,
                    MessageKind.EXISTING_LABEL, [labelName]);
          }
        }

        TargetElement targetElement =
            new TargetElement(switchCase,
                              statementScope.nestingLevel,
                              enclosingElement);
        mapping[switchCase] = targetElement;

        LabelElement label =
            new LabelElement(labelIdentifier, labelName,
                             targetElement, enclosingElement);
        mapping[labelIdentifier] = label;
        continueLabels[labelName] = label;
      }
      cases = cases.tail;
      if (switchCase.defaultKeyword !== null && !cases.isEmpty()) {
        error(switchCase, MessageKind.INVALID_CASE_DEFAULT);
      }
    }
    statementScope.enterSwitch(breakElement, continueLabels);
    node.cases.accept(this);
    statementScope.exitSwitch();

    // Clean-up unused labels
    continueLabels.forEach((String key, LabelElement label) {
      TargetElement targetElement = label.target;
      SwitchCase switchCase = targetElement.statement;
      if (!label.isContinueTarget) {
        mapping.remove(switchCase);
        mapping.remove(label.label);
      }
    });
  }

  visitSwitchCase(SwitchCase node) {
    // The label was handled in [visitSwitchStatement(SwitchStatement)].
    node.expressions.accept(this);
    visitIn(node.statements, new BlockScope(context));
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
    Scope scope = new BlockScope(context);
    if (node.formals.isEmpty()) {
      error(node, MessageKind.EMPTY_CATCH_DECLARATION);
    } else if (!node.formals.nodes.tail.isEmpty()
               && !node.formals.nodes.tail.tail.isEmpty()) {
      for (Node extra in node.formals.nodes.tail.tail) {
        error(extra, MessageKind.EXTRA_CATCH_DECLARATION);
      }
    }
    visitIn(node.formals, scope);
    visitIn(node.block, scope);
  }

  visitTypedef(Typedef node) {
    unimplemented(node, 'typedef');
  }
}

class ClassResolverVisitor extends CommonResolverVisitor<Type> {
  Scope context;
  ClassElement classElement;

  ClassResolverVisitor(Compiler compiler, LibraryElement library,
                       ClassElement this.classElement)
    : context = new TopScope(library),
      super(compiler);

  Type visitClassNode(ClassNode node) {
    compiler.ensure(classElement !== null);
    compiler.ensure(!classElement.isResolved);
    final Link<Node> parameters =
        node.typeParameters !== null ? node.typeParameters.nodes
                                     : const EmptyLink<TypeVariable>();
    // Create types and elements for type variable.
    for (Link<Node> link = parameters; !link.isEmpty(); link = link.tail) {
      TypeVariable typeNode = link.head;
      SourceString variableName = typeNode.name.source;
      TypeVariableType variableType = new TypeVariableType(variableName);
      TypeVariableElement variableElement =
          new TypeVariableElement(variableName, classElement, node,
                                  variableType);
      variableType.element = variableElement;
      classElement.typeParameters[variableName] = variableElement;
      context = new TypeVariablesScope(context, classElement);
    }
    // Resolve the bounds of type variables.
    for (Link<Node> link = parameters; !link.isEmpty(); link = link.tail) {
      TypeVariable typeNode = link.head;
      SourceString variableName = typeNode.name.source;
      TypeVariableElement variableElement =
          classElement.typeParameters[variableName];
      if (typeNode.bound !== null) {
        Type boundType = visit(typeNode.bound);
        if (boundType !== null && boundType.element == variableElement) {
          warning(node, MessageKind.CYCLIC_TYPE_VARIABLE,
                  [variableElement.name]);
        } else if (boundType !== null) {
          variableElement.bound = boundType;
        } else {
          variableElement.bound = compiler.objectClass.computeType(compiler);
        }
      }
    }
    // Find super type.
    Type supertype = visit(node.superclass);
    if (supertype !== null && supertype.element.isExtendable()) {
      classElement.supertype = supertype;
      if (isBlackListed(supertype)) {
        error(node.superclass, MessageKind.CANNOT_EXTEND, [supertype]);
      }
    } else if (supertype !== null) {
      error(node.superclass, MessageKind.TYPE_NAME_EXPECTED);
    }
    if (classElement.name != Types.OBJECT && classElement.supertype === null) {
      ClassElement objectElement = context.lookup(Types.OBJECT);
      if (objectElement !== null && !objectElement.isResolved) {
        compiler.resolver.toResolve.add(objectElement);
      } else if (objectElement === null){
        error(node, MessageKind.CANNOT_RESOLVE_TYPE, [Types.OBJECT]);
      }
      classElement.supertype = new InterfaceType(Types.OBJECT, objectElement);
    }
    if (node.defaultClause !== null) {
      classElement.defaultClass = visit(node.defaultClause);
    }
    for (Link<Node> link = node.interfaces.nodes;
         !link.isEmpty();
         link = link.tail) {
      Type interfaceType = visit(link.head);
      if (interfaceType !== null && interfaceType.element.isExtendable()) {
        classElement.interfaces =
            classElement.interfaces.prepend(interfaceType);
        if (isBlackListed(interfaceType)) {
          error(link.head, MessageKind.CANNOT_IMPLEMENT, [interfaceType]);
        }
      } else {
        error(link.head, MessageKind.TYPE_NAME_EXPECTED);
      }
    }
    calculateAllSupertypes(classElement, new Set<ClassElement>());
    addDefaultConstructorIfNeeded(classElement);
    return classElement.computeType(compiler);
  }

  Type visitTypeAnnotation(TypeAnnotation node) {
    return visit(node.typeName);
  }

  Type visitIdentifier(Identifier node) {
    Element element = context.lookup(node.source);
    if (element === null) {
      error(node, MessageKind.CANNOT_RESOLVE_TYPE, [node]);
      return null;
    } else if (!element.impliesType() && !element.isTypeVariable()) {
      error(node, MessageKind.NOT_A_TYPE, [node]);
      return null;
    } else {
      if (element.isClass()) {
        compiler.resolver.toResolve.add(element);
      }
      if (element.isTypeVariable()) {
        TypeVariableElement variableElement = element;
        return variableElement.type;
      } else if (element.isTypedef()) {
        compiler.unimplemented('visitIdentifier for typedefs');
      } else {
        // TODO(ngeoffray): Use type variables.
        return element.computeType(compiler);
      }
    }
    return null;
  }

  Type visitSend(Send node) {
    Identifier prefix = node.receiver.asIdentifier();
    if (prefix === null) {
      error(node.receiver, MessageKind.NOT_A_PREFIX, [node.receiver]);
      return null;
    }
    Element element = context.lookup(prefix.source);
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

  Link<Type> getOrCalculateAllSupertypes(ClassElement cls,
                                         [Set<ClassElement> seen]) {
    Link<Type> allSupertypes = cls.allSupertypes;
    if (allSupertypes !== null) return allSupertypes;
    if (seen === null) {
      seen = new Set<ClassElement>();
    }
    if (seen.contains(cls)) {
      error(cls.parseNode(compiler),
            MessageKind.CYCLIC_CLASS_HIERARCHY,
            [cls.name]);
      cls.allSupertypes = const EmptyLink<Type>();
    } else {
      cls.ensureResolved(compiler);
      calculateAllSupertypes(cls, seen);
    }
    return cls.allSupertypes;
  }

  void calculateAllSupertypes(ClassElement cls, Set<ClassElement> seen) {
    // TODO(karlklose): substitute type variables.
    // TODO(karlklose): check if type arguments match, if a classelement occurs
    //                  more than once in the supertypes.
    if (cls.allSupertypes !== null) return;
    final Type supertype = cls.supertype;
    if (seen.contains(cls)) {
      error(cls.parseNode(compiler),
            MessageKind.CYCLIC_CLASS_HIERARCHY,
            [cls.name]);
      cls.allSupertypes = const EmptyLink<Type>();
    } else if (supertype != null) {
      seen.add(cls);
      Link<Type> superSupertypes =
          getOrCalculateAllSupertypes(supertype.element, seen);
      Link<Type> supertypes = new Link<Type>(supertype, superSupertypes);
      for (Link<Type> interfaces = cls.interfaces;
           !interfaces.isEmpty();
           interfaces = interfaces.tail) {
        Element element = interfaces.head.element;
        Link<Type> interfaceSupertypes =
            getOrCalculateAllSupertypes(element, seen);
        supertypes = supertypes.reversePrependAll(interfaceSupertypes);
        supertypes = supertypes.prepend(interfaces.head);
      }
      seen.remove(cls);
      cls.allSupertypes = supertypes;
    } else {
      cls.allSupertypes = const EmptyLink<Type>();
    }
  }

  /**
   * Add a synthetic nullary constructor if there are no other
   * constructors.
   */
  void addDefaultConstructorIfNeeded(ClassElement element) {
    if (element.constructors.length != 0) return;
    SynthesizedConstructorElement constructor =
      new SynthesizedConstructorElement(element);
    element.constructors[element.name] = constructor;
    Type returnType = compiler.types.voidType;
    constructor.type = new FunctionType(returnType, const EmptyLink<Type>(),
                                        constructor);
    constructor.cachedNode =
      new FunctionExpression(new Identifier(element.position()),
                             new NodeList.empty(),
                             new Block(new NodeList.empty()),
                             null, null, null, null);
  }

  isBlackListed(Type type) {
    LibraryElement lib = classElement.getLibrary();
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

class VariableDefinitionsVisitor extends CommonResolverVisitor<SourceString> {
  VariableDefinitions definitions;
  ResolverVisitor resolver;
  ElementKind kind;
  VariableListElement variables;

  VariableDefinitionsVisitor(Compiler compiler,
                             this.definitions, this.resolver, this.kind)
    : super(compiler)
  {
    variables = new VariableListElement.node(
        definitions, ElementKind.VARIABLE_LIST, resolver.context.element);
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
          name, variables, kind, resolver.context.element, node: link.head);
      resolver.defineElement(link.head, element);
    }
  }
}

class SignatureResolver extends CommonResolverVisitor<Element> {
  final Element enclosingElement;
  Link<Element> optionalParameters = const EmptyLink<Element>();
  int optionalParameterCount = 0;
  Node currentDefinitions;

  SignatureResolver(Compiler compiler, this.enclosingElement) : super(compiler);

  Element visitNodeList(NodeList node) {
    // This must be a list of optional arguments.
    if (node.beginToken.stringValue !== '[') {
      internalError(node, "expected optional parameters");
    }
    LinkBuilder<Element> elements = analyzeNodes(node.nodes);
    optionalParameterCount = elements.length;
    optionalParameters = elements.toLink();
    return null;
  }

  Element visitVariableDefinitions(VariableDefinitions node) {
    resolveType(node.type);

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
      if (node.selector.asIdentifier() == null) {
        cancel(node,
               'internal error: unimplemented receiver on parameter send');
      }
      SourceString name = node.selector.asIdentifier().source;
      Element fieldElement = currentClass.lookupLocalMember(name);
      if (fieldElement === null || fieldElement.kind !== ElementKind.FIELD) {
        error(node, MessageKind.NOT_A_FIELD, [name]);
      } else if (!fieldElement.isInstanceMember()) {
        error(node, MessageKind.NOT_INSTANCE_FIELD, [name]);
      }
      Element variables = new VariableListElement.node(currentDefinitions,
          ElementKind.VARIABLE_LIST, enclosingElement);
      element = new FieldParameterElement(node.selector.asIdentifier().source,
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
    compiler.enqueue(new WorkItem.toCompile(element));
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

  static FunctionParameters analyze(Compiler compiler,
                                    FunctionElement element) {
    FunctionExpression node = element.parseNode(compiler);
    SignatureResolver visitor = new SignatureResolver(compiler, element);
    Link<Node> nodes = node.parameters.nodes;
    LinkBuilder<Element> parameters = visitor.analyzeNodes(nodes);
    return new FunctionParameters(parameters.toLink(),
                                  visitor.optionalParameters,
                                  parameters.length,
                                  visitor.optionalParameterCount);
  }

  // TODO(ahe): This is temporary.
  void resolveExpression(Node node) {
    if (node == null) return;
    node.accept(new ResolverVisitor(compiler, enclosingElement));
  }

  // TODO(ahe): This is temporary.
  void resolveType(Node node) {
    if (node == null) return;
    // Find the correct member context to perform the lookup in.
    Element outer = enclosingElement;
    Element context = outer;
    while (outer !== null) {
      if (outer.isMember()) {
        context = outer;
        break;
      }
      outer = outer.enclosingElement;
    }
    node.accept(new ResolverVisitor(compiler, context));
  }

  // TODO(ahe): This is temporary.
  ClassElement get currentClass() {
    return enclosingElement.isMember()
      ? enclosingElement.enclosingElement : null;
  }
}

class ConstructorResolver extends CommonResolverVisitor<Element> {
  final ResolverVisitor resolver;
  ConstructorResolver(Compiler compiler, this.resolver) : super(compiler);

  visitNode(Node node) {
    throw 'not supported';
  }

  visitNewExpression(NewExpression node) {
    Node selector = node.send.selector;
    Element e = visit(selector);
    if (e !== null && e.kind === ElementKind.CLASS) {
      ClassElement cls = e;
      cls.ensureResolved(compiler);
      compiler.resolver.toResolve.add(cls);
      if (cls.isInterface() && (cls.defaultClass === null)) {
        error(selector, MessageKind.CANNOT_INSTANTIATE_INTERFACE, [cls.name]);
      }
      e = cls.lookupConstructor(cls.name);
    }
    return e;
  }

  visitTypeAnnotation(TypeAnnotation node) {
    // TODO(ahe): Do not ignore type arguments.
    return visit(node.typeName);
  }

  visitSend(Send node) {
    Element e = visit(node.receiver);
    if (e === null) return null; // TODO(ahe): Return erroneous element.

    Identifier name = node.selector.asIdentifier();
    if (name === null) internalError(node.selector, 'unexpected node');

    if (e.kind === ElementKind.CLASS) {
      ClassElement cls = e;
      cls.ensureResolved(compiler);
      compiler.resolver.toResolve.add(cls);
      if (cls.isInterface() && (cls.defaultClass === null)) {
        error(node.receiver, MessageKind.CANNOT_INSTANTIATE_INTERFACE,
              [cls.name]);
      }
      SourceString constructorName =
        Elements.constructConstructorName(cls.name, name.source);
      FunctionElement constructor = cls.lookupConstructor(constructorName);
      if (constructor === null) {
        error(name, MessageKind.CANNOT_FIND_CONSTRUCTOR, [name]);
      }
      e = constructor;
    } else if (e.kind === ElementKind.PREFIX) {
      PrefixElement prefix = e;
      e = prefix.lookupLocalMember(name.source);
      if (e === null) {
        error(name, MessageKind.CANNOT_RESOLVE, [name]);
        // TODO(ahe): Return erroneous element.
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
      error(node, MessageKind.CANNOT_RESOLVE, [name]);
      // TODO(ahe): Return erroneous element.
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
  abstract Element lookup(SourceString name);
}

class TypeVariablesScope extends Scope {
  TypeVariablesScope(parent, ClassElement element) : super(parent, element);
  Element add(Element newElement) {
    throw "Cannot add element to TypeVariableScope";
  }
  Element lookup(SourceString name) {
    ClassElement cls = element;
    Element result = cls.lookupTypeParameter(name);
    if (result !== null) return result;
    if (parent !== null) return parent.lookup(name);
  }
}

class MethodScope extends Scope {
  final Map<SourceString, Element> elements;

  MethodScope(Scope parent, Element element)
    : super(parent, element), this.elements = new Map<SourceString, Element>();

  Element lookup(SourceString name) {
    Element found = elements[name];
    if (found !== null) return found;
    return parent.lookup(name);
  }

  Element add(Element newElement) {
    if (elements.containsKey(newElement.name)) {
      return elements[newElement.name];
    }
    elements[newElement.name] = newElement;
    return newElement;
  }
}

class BlockScope extends MethodScope {
  BlockScope(Scope parent) : super(parent, parent.element);
}

class ClassScope extends Scope {
  ClassScope(ClassElement element, LibraryElement library)
    : super(new TopScope(library), element);

  Element lookup(SourceString name) {
    ClassElement cls = element;
    Element result = cls.lookupLocalMember(name);
    if (result !== null) return result;
    result = cls.lookupTypeParameter(name);
    if (result !== null) return result;
    result = parent.lookup(name);
    if (result != null) return result;
    return cls.lookupSuperMember(name);
  }

  Element add(Element newElement) {
    throw "Cannot add an element in a class scope";
  }
}

class TopScope extends Scope {
  LibraryElement get library() => element;

  TopScope(LibraryElement library) : super(null, library);
  Element lookup(SourceString name) {
    return library.find(name);
  }

  Element add(Element newElement) {
    throw "Cannot add an element in the top scope";
  }
}
