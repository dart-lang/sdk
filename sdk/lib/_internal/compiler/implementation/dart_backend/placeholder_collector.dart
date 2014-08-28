// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_backend;

class LocalPlaceholder {
  final String identifier;
  final Set<Node> nodes;
  LocalPlaceholder(this.identifier) : nodes = new Set<Node>();
  int get hashCode => identifier.hashCode;
  String toString() =>
      'local_placeholder[id($identifier), nodes($nodes)]';
}

class FunctionScope {
  final Set<String> parameterIdentifiers;
  final Set<LocalPlaceholder> localPlaceholders;
  FunctionScope()
      : parameterIdentifiers = new Set<String>(),
      localPlaceholders = new Set<LocalPlaceholder>();
  void registerParameter(Identifier node) {
    parameterIdentifiers.add(node.source);
  }
}

class ConstructorPlaceholder {
  final Identifier node;
  final ConstructorElement element;

  ConstructorPlaceholder(this.node, this.element);
}

class DeclarationTypePlaceholder {
  final TypeAnnotation typeNode;
  final bool requiresVar;
  DeclarationTypePlaceholder(this.typeNode, this.requiresVar);
}

class SendVisitor extends ResolvedVisitor {
  final PlaceholderCollector collector;

  SendVisitor(collector, TreeElements elements)
      : this.collector = collector,
        super(elements, collector.compiler);

  visitOperatorSend(Send node) {
  }

  visitForeignSend(Send node) {}

  visitSuperSend(Send node) {
    Element element = elements[node];
    if (element != null && element.isConstructor) {
      collector.tryMakeConstructorPlaceholder(node, element);
    } else {
      collector.tryMakeMemberPlaceholder(node.selector);
    }
  }

  visitDynamicSend(Send node) {
    final element = elements[node];
    if (element == null || !element.isErroneous) {
      collector.tryMakeMemberPlaceholder(node.selector);
    }
  }

  visitClosureSend(Send node) {
    final element = elements[node];
    if (element != null) {
      collector.tryMakeLocalPlaceholder(element, node.selector);
    }
  }

  visitGetterSend(Send node) {
    final element = elements[node];
    // element == null means dynamic property access.
    if (element == null) {
      collector.tryMakeMemberPlaceholder(node.selector);
    } else if (element.isErroneous) {
      collector.makeUnresolvedPlaceholder(node);
      return;
    } else if (element.isPrefix) {
      // Node is prefix part in case of source 'lib.somesetter = 5;'
      collector.makeErasePrefixPlaceholder(node);
    } else if (Elements.isStaticOrTopLevel(element)) {
      // Unqualified or prefixed top level or static.
      collector.makeElementPlaceholder(node.selector, element);
    } else if (!element.isTopLevel) {
      if (element.isInstanceMember) {
        collector.tryMakeMemberPlaceholder(node.selector);
      } else {
        // May get FunctionExpression here in selector
        // in case of A(int this.f());
        if (node.selector is Identifier) {
          collector.tryMakeLocalPlaceholder(element, node.selector);
        } else {
          assert(node.selector is FunctionExpression);
        }
      }
    }
  }

  visitAssert(node) {
    visitStaticSend(node);
  }

  visitStaticSend(Send node) {
    Element element = elements[node];
    collector.backend.registerStaticSend(element, node);

    if (Elements.isUnresolved(element)
        || elements.isAssert(node)
        || element.isDeferredLoaderGetter) {
      return;
    }
    if (element.isConstructor || element.isFactoryConstructor) {
      // Rename named constructor in redirection position:
      // class C { C.named(); C.redirecting() : this.named(); }
      if (node.receiver is Identifier
          && node.receiver.asIdentifier().isThis()) {
        assert(node.selector is Identifier);
        collector.tryMakeConstructorPlaceholder(node, element);
      }
      return;
    }
    collector.makeElementPlaceholder(node.selector, element);
    // Another ugly case: <lib prefix>.<top level> is represented as
    // receiver: lib prefix, selector: top level.
    if (element.isTopLevel && node.receiver != null) {
      assert(elements[node.receiver].isPrefix);
      // Hack: putting null into map overrides receiver of original node.
      collector.makeErasePrefixPlaceholder(node.receiver);
    }
  }

  internalError(String reason, {Node node}) {
    collector.internalError(reason, node: node);
  }

  visitTypePrefixSend(Send node) {
    collector.makeElementPlaceholder(node, elements[node]);
  }

  visitTypeLiteralSend(Send node) {
    DartType type = elements.getTypeLiteralType(node);
    if (!type.isDynamic) {
      if (type is TypeVariableType) {
        collector.makeTypeVariablePlaceholder(node.selector, type);
      } else {
        collector.makeTypePlaceholder(node.selector, type);
      }
    }
  }
}

class PlaceholderCollector extends Visitor {
  final Compiler compiler;
  final Set<String> fixedMemberNames; // member names which cannot be renamed.
  final Map<Element, ElementAst> elementAsts;
  final Set<Node> prefixNodesToErase = new Set<Node>();
  final Set<Node> unresolvedNodes = new Set<Node>();
  final Map<Element, Set<Node>> elementNodes = new Map<Element, Set<Node>>();
  final Map<FunctionElement, FunctionScope> functionScopes
      = new Map<FunctionElement, FunctionScope>();
  final Map<LibraryElement, Set<Identifier>> privateNodes =
      new Map<LibraryElement, Set<Identifier>>();
  final List<DeclarationTypePlaceholder> declarationTypePlaceholders
      = new List<DeclarationTypePlaceholder>();
  final Map<String, Set<Identifier>> memberPlaceholders
      = new Map<String, Set<Identifier>>();
  final List<ConstructorPlaceholder> constructorPlaceholders
      = new List<ConstructorPlaceholder>();
  Map<String, LocalPlaceholder> currentLocalPlaceholders;
  Element currentElement;
  FunctionElement topmostEnclosingFunction;
  TreeElements treeElements;

  LibraryElement get coreLibrary => compiler.coreLibrary;
  FunctionElement get entryFunction => compiler.mainFunction;
  DartBackend get backend => compiler.backend;

  get currentFunctionScope => functionScopes.putIfAbsent(
      topmostEnclosingFunction, () => new FunctionScope());

  PlaceholderCollector(this.compiler, this.fixedMemberNames, this.elementAsts);

  void collectFunctionDeclarationPlaceholders(
      FunctionElement element, FunctionExpression node) {
    if (element.isConstructor) {
      ConstructorElement constructor = element;
      DartType type = element.enclosingClass.thisType.asRaw();
      tryMakeConstructorPlaceholder(node.name, element);
      RedirectingFactoryBody bodyAsRedirectingFactoryBody =
          node.body.asRedirectingFactoryBody();
      if (bodyAsRedirectingFactoryBody != null) {
        // Factory redirection.
        FunctionElement redirectTarget = constructor.immediateRedirectionTarget;
        assert(redirectTarget != null && redirectTarget != element);
        type = redirectTarget.enclosingClass.thisType.asRaw();
        tryMakeConstructorPlaceholder(
            bodyAsRedirectingFactoryBody.constructorReference,
            redirectTarget);
      }
    } else if (Elements.isStaticOrTopLevel(element)) {
      // Note: this code should only rename private identifiers for class'
      // fields/getters/setters/methods.  Top-level identifiers are renamed
      // just to escape conflicts and that should be enough as we shouldn't
      // be able to resolve private identifiers for other libraries.
      makeElementPlaceholder(node.name, element);
    } else if (element.isClassMember) {
      if (node.name is Identifier) {
        tryMakeMemberPlaceholder(node.name);
      } else {
        assert(node.name.asSend().isOperator);
      }
    }
  }

  void collectFieldDeclarationPlaceholders(Element element, Node node) {
    Identifier name = node is Identifier ? node : node.asSend().selector;
    if (Elements.isStaticOrTopLevel(element)) {
      makeElementPlaceholder(name, element);
    } else if (Elements.isInstanceField(element)) {
      tryMakeMemberPlaceholder(name);
    }
  }

  void collect(Element element) {
    this.currentElement = element;
    this.topmostEnclosingFunction = null;
    final ElementAst elementAst = elementAsts[element];
    this.treeElements = elementAst.treeElements;
    Node elementNode = elementAst.ast;
    if (element is FunctionElement) {
      collectFunctionDeclarationPlaceholders(element, elementNode);
    } else if (element is VariableElement) {
      VariableDefinitions definitions = elementNode;
      Node definition = definitions.definitions.nodes.head;
      collectFieldDeclarationPlaceholders(element, definition);
      makeVarDeclarationTypePlaceholder(definitions);
    } else {
      assert(element is ClassElement || element is TypedefElement);
    }
    currentLocalPlaceholders = new Map<String, LocalPlaceholder>();
    if (!(element is ConstructorElement && element.isRedirectingFactory)) {
      // Do not visit the body of redirecting factories.
      compiler.withCurrentElement(element, () {
        elementNode.accept(this);
      });
    }
    if (element == backend.mirrorHelperSymbolsMap) {
      backend.registerMirrorHelperElement(element, elementNode);
    }
  }

  // TODO(karlklose): should we create placeholders for these?
  bool isTypedefParameter(Element element) {
    return element != null &&
        element.enclosingElement != null &&
        element.enclosingElement.isTypedef;
  }

  void tryMakeLocalPlaceholder(Element element, Identifier node) {
    bool isNamedOptionalParameter() {
      FunctionTypedElement function = element.enclosingElement;
      FunctionSignature signature = function.functionSignature;
      if (!signature.optionalParametersAreNamed) return false;
      for (Element parameter in signature.optionalParameters) {
        if (identical(parameter, element)) return true;
      }
      return false;
    }
    if (element.isParameter && !isTypedefParameter(element) &&
        isNamedOptionalParameter()) {
      currentFunctionScope.registerParameter(node);
    } else if (Elements.isLocal(element) && !isTypedefParameter(element)) {
      makeLocalPlaceholder(node);
    }
  }

  void tryMakeMemberPlaceholder(Identifier node) {
    assert(node != null);
    if (node is Operator) return;
    final identifier = node.source;
    if (fixedMemberNames.contains(identifier)) return;
    memberPlaceholders.putIfAbsent(
        identifier, () => new Set<Identifier>()).add(node);
  }

  void makeTypePlaceholder(Node node, DartType type) {
    Send send = node.asSend();
    if (send != null) {
      // Prefix.
      assert(send.receiver is Identifier);
      assert(send.selector is Identifier);
      makeErasePrefixPlaceholder(send.receiver);
      node = send.selector;
    }
    makeElementPlaceholder(node, type.element);
  }

  void makeTypeVariablePlaceholder(Node node, TypeVariableType type) {
    Send send = node.asSend();
    if (send != null) {
      // Prefix.
      assert(send.receiver is Identifier);
      assert(send.selector is Identifier);
      makeErasePrefixPlaceholder(send.receiver);
      node = send.selector;
    }
    tryMakeMemberPlaceholder(node);
  }

  void makeOmitDeclarationTypePlaceholder(TypeAnnotation type) {
    if (type == null) return;
    declarationTypePlaceholders.add(
        new DeclarationTypePlaceholder(type, false));
  }

  void makeVarDeclarationTypePlaceholder(VariableDefinitions node) {
    // TODO(smok): Maybe instead of calling this method and
    // makeDeclaratioTypePlaceholder have type declaration placeholder
    // collector logic in visitVariableDefinitions when resolver becomes better
    // and/or catch syntax changes.
    if (node.type == null) return;
    Element definitionElement = treeElements[node.definitions.nodes.head];
    bool requiresVar = !node.modifiers.isFinalOrConst;
    declarationTypePlaceholders.add(
        new DeclarationTypePlaceholder(node.type, requiresVar));
  }

  /// Marks [node] to be erased in the output.
  /// This is done for library prefixes because they are not used in the output
  /// because all imports are flattened and conflicts are renamed away.
  void makeErasePrefixPlaceholder(Node node) {
    assert(node is Identifier || node is Send);
    prefixNodesToErase.add(node);
  }

  void makeElementPlaceholder(Node node, Element element) {
    assert(node != null);
    assert(element != null);
    LibraryElement library = element.library;
    if (identical(element, entryFunction)) return;
    if (identical(library, coreLibrary)) return;

    if (library.isPlatformLibrary && !element.isTopLevel) {
      return;
    }
    if (element.isGetter || element.isSetter) {
      element = (element as FunctionElement).abstractField;
    }
    elementNodes.putIfAbsent(element, () => new Set<Node>()).add(node);
  }

  /// Marks [node] to be renamed per-library if it names an instance member
  /// and has a private name.
  void tryMakePrivateIdentifier(Node node, Element element) {
    if (node is Identifier &&
        !Elements.isStaticOrTopLevel(element) &&
        !Elements.isLocal(element) &&
        isPrivateName(node.source)) {
      privateNodes.putIfAbsent(
          currentElement.library, () => new Set<Identifier>()).add(node);
    }
  }

  void makeUnresolvedPlaceholder(Node node) {
    unresolvedNodes.add(node);
  }

  void makeLocalPlaceholder(Identifier identifier) {
    LocalPlaceholder getLocalPlaceholder() {
      String name = identifier.source;
      return currentLocalPlaceholders.putIfAbsent(name, () {
        LocalPlaceholder localPlaceholder = new LocalPlaceholder(name);
        currentFunctionScope.localPlaceholders.add(localPlaceholder);
        return localPlaceholder;
      });
    }
    getLocalPlaceholder().nodes.add(identifier);
  }

  /// Finds the first constructor on the chain of definingConstructor from
  /// [element] that is not in a synthetic class.
  Element findDefiningConstructor(ConstructorElement element) {
    while (element.definingConstructor != null) {
      element = element.definingConstructor;
    }
    return element;
  }

  void tryMakeConstructorPlaceholder(Node node, ConstructorElement element) {
    if (Elements.isUnresolved(element)) {
      makeUnresolvedPlaceholder(node);
      return;
    }
    // A library prefix.
    Node prefix;
    // The name of the class with the constructor.
    Node className;
    // Will be null for unnamed constructors.
    Identifier constructorName;
    // First deconstruct the constructor, there are 4 possibilities:
    //  ClassName()
    //  prefix.ClassName()
    //  ClassName.constructorName()
    //  prefix.ClassName.constructorName()
    if (node is Send) {
      if (node.receiver is Send) {
        Send receiver = node.receiver;
        // prefix.ClassName.constructorName()
        assert(treeElements[receiver.receiver] != null &&
               treeElements[receiver.receiver].isPrefix);
        prefix = receiver.receiver;
        className = receiver.selector;
        constructorName = node.selector;
      } else {
        Element receiverElement = treeElements[node.receiver];
        if (receiverElement != null && receiverElement.isPrefix) {
          // prefix.ClassName()
          prefix = node.receiver;
          className = node.selector;
        } else {
          // ClassName.constructorName()
          className = node.receiver;
          constructorName = node.selector;
        }
      }
    } else {
      // ClassName()
      className = node;
    }

    if (prefix != null) {
      makeErasePrefixPlaceholder(prefix);
    }

    if (className is TypeAnnotation) {
      visitTypeAnnotation(className);
    } else if (Elements.isUnresolved(element)) {
      // We handle unresolved nodes elsewhere.
    } else if (className.isThis() || className.isSuper()) {
      // Do not rename super and this.
    } else if (className is Identifier) {
      makeElementPlaceholder(className, element.contextClass);
    } else {
      throw "Bad type of constructor name $className";
    }

    if (constructorName != null) {
      Element definingConstructor = findDefiningConstructor(element);
      constructorPlaceholders.add(new ConstructorPlaceholder(constructorName,
          definingConstructor));
      tryMakePrivateIdentifier(constructorName, element);
    }
  }

  void internalError(String reason, {Node node}) {
    compiler.internalError(node, reason);
  }

  visit(Node node) => (node == null) ? null : node.accept(this);

  visitNode(Node node) { node.visitChildren(this); }  // We must go deeper.

  visitNewExpression(NewExpression node) {
    Send send = node.send;
    DartType type = treeElements.getType(node);
    assert(type != null);
    Element constructor = treeElements[send];
    assert(constructor != null);
    assert(send.receiver == null);
    if (!Elements.isErroneousElement(constructor)) {
      tryMakeConstructorPlaceholder(node.send.selector, constructor);
      // TODO(smok): Should this be in visitNamedArgument?
      // Field names can be exposed as names of optional arguments, e.g.
      // class C {
      //   final field;
      //   C([this.field]);
      // }
      // Do not forget to rename them as well.
      FunctionElement constructorFunction = constructor;
      Link<Element> optionalParameters =
          constructorFunction.functionSignature.optionalParameters;
      for (final argument in send.argumentsNode) {
        NamedArgument named = argument.asNamedArgument();
        if (named == null) continue;
        Identifier name = named.name;
        String nameAsString = name.source;
        for (final parameter in optionalParameters) {
          if (parameter.isInitializingFormal) {
            if (parameter.name == nameAsString) {
              tryMakeMemberPlaceholder(name);
              break;
            }
          }
        }
      }
    } else {
      makeUnresolvedPlaceholder(node.send.selector);
    }
    visit(node.send.argumentsNode);
  }

  visitSend(Send send) {
    Element element = treeElements[send];
    tryMakePrivateIdentifier(send.selector, element);
    new SendVisitor(this, treeElements).visitSend(send);
    send.visitChildren(this);
  }

  visitSendSet(SendSet send) {
    Element element = treeElements[send];
    if (Elements.isErroneousElement(element)) {
      // Complicated case: constructs like receiver.selector++ can resolve
      // to ErroneousElement.  Fortunately, receiver.selector still
      // can be resoved via treeElements[send.selector], that's all
      // that is needed to rename the construct properly.
      element = treeElements[send.selector];
    }
    tryMakePrivateIdentifier(send.selector, element);
    if (element == null) {
      if (send.receiver != null) tryMakeMemberPlaceholder(send.selector);
    } else if (!element.isErroneous) {
      if (Elements.isStaticOrTopLevel(element)) {
        // TODO(smok): Worth investigating why sometimes we get getter/setter
        // here and sometimes abstract field.
        assert(element.isClass || element is VariableElement ||
               element.isAccessor || element.isAbstractField ||
               element.isFunction || element.isTypedef ||
               element is TypeVariableElement);
        makeElementPlaceholder(send.selector, element);
      } else {
        Identifier identifier = send.selector.asIdentifier();
        if (identifier == null) {
          // Handle optional function expression parameters with default values.
          identifier = send.selector.asFunctionExpression().name;
        }
        if (Elements.isInstanceField(element)) {
          tryMakeMemberPlaceholder(identifier);
        } else {
          tryMakeLocalPlaceholder(element, identifier);
        }
      }
    }
    send.visitChildren(this);
  }

  visitTypeAnnotation(TypeAnnotation node) {
    final type = treeElements.getType(node);
    assert(invariant(node, type != null,
        message: "Missing type for type annotation: $treeElements"));
    if (!type.isVoid) {
      if (!type.treatAsDynamic) {
        if (type is TypeVariableType) {
          makeTypeVariablePlaceholder(node.typeName, type);
        } else {
          makeTypePlaceholder(node.typeName, type);
        }
      } else if (!type.isDynamic) {
        makeUnresolvedPlaceholder(node.typeName);
      }
    }
    // Visit only type arguments, otherwise in case of lib.Class type
    // annotation typeName is Send and we go to visitGetterSend, as a result
    // "Class" is added to member placeholders.
    visit(node.typeArguments);
  }

  visitVariableDefinitions(VariableDefinitions node) {
    // Collect only local placeholders.
    for (Node definition in node.definitions.nodes) {
      Element definitionElement = treeElements[definition];
      // definitionElement may be null if we're inside variable definitions
      // of a function that is a parameter of another function.
      // TODO(smok): Fix this when resolver correctly deals with
      // such cases.
      if (definitionElement == null) continue;

      Send send = definition.asSend();
      Identifier identifier = definition is Identifier
          ? definition
          : definition is Send
              ? (send.selector is Identifier
                  ? send.selector
                  : null)
              : null;

      tryMakePrivateIdentifier(identifier, definitionElement);

      if (send != null) {
        // May get FunctionExpression here in definition.selector
        // in case of A(int this.f());
        if (send.selector is Identifier) {
          if (definitionElement.isInitializingFormal) {
            tryMakeMemberPlaceholder(send.selector);
          } else {
            tryMakeLocalPlaceholder(definitionElement, send.selector);
          }
        } else {
          assert(send.selector is FunctionExpression);
          if (definitionElement.isInitializingFormal) {
            tryMakeMemberPlaceholder(
                send.selector.asFunctionExpression().name);
          }
        }
      } else if (definition is Identifier) {
        tryMakeLocalPlaceholder(definitionElement, definition);
      } else if (definition is FunctionExpression) {
        // Skip, it will be processed in visitFunctionExpression.
      } else {
        internalError('Unexpected definition structure $definition');
      }
    }
    node.visitChildren(this);
  }

  visitFunctionExpression(FunctionExpression node) {
    bool isKeyword(Identifier id) =>
        id != null && Keyword.keywords[id.source] != null;

    Element element = treeElements[node];
    // May get null here in case of A(int this.f());
    if (element != null) {
      tryMakePrivateIdentifier(node.name, element);

      if (element == backend.mirrorHelperGetNameFunction) {
        backend.registerMirrorHelperElement(element, node);
      }
      // Rename only local functions.
      if (topmostEnclosingFunction == null) {
        topmostEnclosingFunction = element;
      }
      if (!identical(element, currentElement)) {
        if (node.name != null) {
          assert(node.name is Identifier);
          tryMakeLocalPlaceholder(element, node.name);
        }
      }
    }

    node.visitChildren(this);

    // Make sure we don't omit return type of methods which names are
    // identifiers, because the following works fine:
    // int interface() => 1;
    // But omitting 'int' makes VM unhappy.
    // TODO(smok): Remove it when http://dartbug.com/5278 is fixed.
    if (node.name == null || !isKeyword(node.name.asIdentifier())) {
      makeOmitDeclarationTypePlaceholder(node.returnType);
    }
    collectFunctionParameters(node.parameters);
  }

  void collectFunctionParameters(NodeList parameters) {
    if (parameters == null) return;
    for (Node parameter in parameters.nodes) {
      if (parameter is NodeList) {
        // Optional parameter list.
        collectFunctionParameters(parameter);
      } else {
        assert(parameter is VariableDefinitions);
        makeOmitDeclarationTypePlaceholder(
            parameter.asVariableDefinitions().type);
      }
    }
  }

  visitClassNode(ClassNode node) {
    ClassElement classElement = currentElement;
    makeElementPlaceholder(node.name, classElement);
    node.visitChildren(this);
  }

  visitNamedMixinApplication(NamedMixinApplication node) {
    ClassElement classElement = currentElement;
    makeElementPlaceholder(node.name, classElement);
    node.visitChildren(this);
  }

  visitTypeVariable(TypeVariable node) {
    DartType type = treeElements.getType(node);
    assert(invariant(node, type != null,
        message: "Missing type for type variable: $treeElements"));
    makeTypeVariablePlaceholder(node.name, type);
    node.visitChildren(this);
  }

  visitTypedef(Typedef node) {
    assert(currentElement is TypedefElement);
    makeElementPlaceholder(node.name, currentElement);
    node.visitChildren(this);
    makeOmitDeclarationTypePlaceholder(node.returnType);
    collectFunctionParameters(node.formals);
  }

  visitBlock(Block node) {
    for (Node statement in node.statements.nodes) {
      if (statement is VariableDefinitions) {
        makeVarDeclarationTypePlaceholder(statement);
      }
    }
    node.visitChildren(this);
  }
}
