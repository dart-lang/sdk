// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class LocalPlaceholder {
  final String identifier;
  final Set<Node> nodes;
  LocalPlaceholder(this.identifier) : nodes = new Set<Node>();
  int hashCode() => identifier.hashCode();
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
    parameterIdentifiers.add(node.source.slowToString());
  }
}

class DeclarationTypePlaceholder {
  final TypeAnnotation typeNode;
  final bool requiresVar;
  DeclarationTypePlaceholder(this.typeNode, this.requiresVar);
}

class SendVisitor extends ResolvedVisitor {
  final PlaceholderCollector collector;

  get compiler => collector.compiler;

  SendVisitor(this.collector, TreeElements elements) : super(elements);

  visitOperatorSend(Send node) {}
  visitForeignSend(Send node) {}

  visitSuperSend(Send node) {
    collector.tryMakeMemberPlaceholder(node.selector);
  }

  visitDynamicSend(Send node) {
    final element = elements[node];
    if (element == null || !element.isErroneous()) {
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
    // element === null means dynamic property access.
    if (element == null) {
      collector.tryMakeMemberPlaceholder(node.selector);
    } else if (element.isErroneous()) {
      return;
    } else if (element.isPrefix()) {
      // Node is prefix part in case of source 'lib.somesetter = 5;'
      collector.makeNullPlaceholder(node);
    } else if (Elements.isStaticOrTopLevel(element)) {
      // Unqualified or prefixed top level or static.
      collector.makeElementPlaceholder(node.selector, element);
    } else if (!element.isTopLevel()) {
      if (element.isInstanceMember()) {
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

  visitStaticSend(Send node) {
    final element = elements[node];
    if (Elements.isUnresolved(element)
        || identical(element, compiler.assertMethod)) {
      return;
    }
    if (element.isConstructor() || element.isFactoryConstructor()) {
      // Rename named constructor in redirection position:
      // class C { C.named(); C.redirecting() : this.named(); }
      if (node.receiver is Identifier
          && node.receiver.asIdentifier().isThis()) {
        assert(node.selector is Identifier);
        collector.tryMakeMemberPlaceholder(node.selector);
      }
      // Field names can be exposed as names of optional arguments, e.g.
      // class C {
      //   final field;
      //   C([this.field]);
      // }
      // Do not forget to rename them as well.
      FunctionElement functionElement = element;
      Link<Element> optionalParameters =
          functionElement.functionSignature.optionalParameters;
      for (final argument in node.argumentsNode) {
        NamedArgument named = argument.asNamedArgument();
        if (named == null) continue;
        Identifier name = named.name;
        String nameAsString = name.source.slowToString();
        for (final parameter in optionalParameters) {
          if (identical(parameter.kind, ElementKind.FIELD_PARAMETER)) {
            if (parameter.name.slowToString() == nameAsString) {
              collector.tryMakeMemberPlaceholder(name);
              break;
            }
          }
        }
      }
      return;
    }
    collector.makeElementPlaceholder(node.selector, element);
    // Another ugly case: <lib prefix>.<top level> is represented as
    // receiver: lib prefix, selector: top level.
    if (element.isTopLevel() && node.receiver != null) {
      assert(elements[node.receiver].isPrefix());
      // Hack: putting null into map overrides receiver of original node.
      collector.makeNullPlaceholder(node.receiver);
    }
  }

  internalError(String reason, {Node node}) {
    collector.internalError(reason, node);
  }
}

class PlaceholderCollector extends Visitor {
  final Compiler compiler;
  final Set<String> fixedMemberNames; // member names which cannot be renamed.
  final Map<Element, ElementAst> elementAsts;
  final Set<Node> nullNodes;  // Nodes that should not be in output.
  final Set<Identifier> unresolvedNodes;
  final Map<Element, Set<Identifier>> elementNodes;
  final Map<FunctionElement, FunctionScope> functionScopes;
  final Map<LibraryElement, Set<Identifier>> privateNodes;
  final List<DeclarationTypePlaceholder> declarationTypePlaceholders;
  final Map<String, Set<Identifier>> memberPlaceholders;
  Map<String, LocalPlaceholder> currentLocalPlaceholders;
  Element currentElement;
  FunctionElement topmostEnclosingFunction;
  TreeElements treeElements;

  LibraryElement get coreLibrary => compiler.coreLibrary;
  FunctionElement get entryFunction => compiler.mainApp.find(Compiler.MAIN);

  get currentFunctionScope => functionScopes.putIfAbsent(
      topmostEnclosingFunction, () => new FunctionScope());

  PlaceholderCollector(this.compiler, this.fixedMemberNames, this.elementAsts) :
      nullNodes = new Set<Node>(),
      unresolvedNodes = new Set<Identifier>(),
      elementNodes = new Map<Element, Set<Identifier>>(),
      functionScopes = new Map<FunctionElement, FunctionScope>(),
      privateNodes = new Map<LibraryElement, Set<Identifier>>(),
      declarationTypePlaceholders = new List<DeclarationTypePlaceholder>(),
      memberPlaceholders = new Map<String, Set<Identifier>>();

  void tryMakeConstructorNamePlaceholder(
      FunctionExpression constructor, ClassElement element) {
    Node nameNode = constructor.name;
    if (nameNode is Send) nameNode = nameNode.receiver;
    if (nameNode.asIdentifier().token.slowToString()
        == element.name.slowToString()) {
      makeElementPlaceholder(nameNode, element);
    }
  }

  void collectFunctionDeclarationPlaceholders(
      FunctionElement element, FunctionExpression node) {
    if (element.isGenerativeConstructor() || element.isFactoryConstructor()) {
      // Two complicated cases for class/interface renaming:
      // 1) class which implements constructors of other interfaces, but not
      //    implements interfaces themselves:
      //      0.dart: class C { I(); }
      //      1.dart and 2.dart: interface I default C { I(); }
      //    now we have to duplicate our I() constructor in C class with
      //    proper names.
      // 2) (even worse for us):
      //      0.dart: class C { C(); }
      //      1.dart: interface C default p0.C { C(); }
      //    the second case is just a bug now.
      tryMakeConstructorNamePlaceholder(node, element.getEnclosingClass());

      // If we have interface constructor, make sure that we put placeholder
      // for its default factory implementation.
      // Example:
      // interface I default C { I();}
      // class C { factory I() {} }
      // 2 cases:
      // Plain interface name. Rename it unless it is the default
      // constructor for enclosing class.
      // Example:
      // interface I { I(); }
      // class C implements I { C(); }  don't rename this case.
      // OR I.named() inside C, rename first part.
      if (element.defaultImplementation != null
          && !identical(element.defaultImplementation, element)) {
        FunctionElement implementingFactory = element.defaultImplementation;
        if (implementingFactory is !SynthesizedConstructorElement) {
          tryMakeConstructorNamePlaceholder(
              elementAsts[implementingFactory].ast,
              element.getEnclosingClass());
        }
      }
    } else if (Elements.isStaticOrTopLevel(element)) {
      // Note: this code should only rename private identifiers for class'
      // fields/getters/setters/methods.  Top-level identifiers are renamed
      // just to escape conflicts and that should be enough as we shouldn't
      // be able to resolve private identifiers for other libraries.
      makeElementPlaceholder(node.name, element);
    } else if (element.isMember()) {
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
    } else if (element is VariableListElement) {
      VariableDefinitions definitions = elementNode;
      for (Node definition in definitions.definitions) {
        final definitionElement = treeElements[definition];
        // definitionElement === null if variable is actually unused.
        if (definitionElement == null) continue;
        collectFieldDeclarationPlaceholders(definitionElement, definition);
      }
      makeVarDeclarationTypePlaceholder(definitions);
    } else {
      assert(element is ClassElement || element is TypedefElement);
    }
    currentLocalPlaceholders = new Map<String, LocalPlaceholder>();
    compiler.withCurrentElement(element, () {
      elementNode.accept(this);
    });
  }

  void tryMakeLocalPlaceholder(Element element, Identifier node) {
    bool isOptionalParameter() {
      FunctionElement function = element.enclosingElement;
      for (Element parameter in function.functionSignature.optionalParameters) {
        if (identical(parameter, element)) return true;
      }
      return false;
    }

    // TODO(smok): Maybe we should rename privates as well, their privacy
    // should not matter if they are local vars.
    if (node.source.isPrivate()) return;
    if (element.isParameter() && isOptionalParameter()) {
      currentFunctionScope.registerParameter(node);
    } else if (Elements.isLocal(element)) {
      makeLocalPlaceholder(node);
    }
  }

  void tryMakeMemberPlaceholder(Identifier node) {
    assert(node != null);
    if (node.source.isPrivate()) return;
    if (node is Operator) return;
    final identifier = node.source.slowToString();
    if (fixedMemberNames.contains(identifier)) return;
    memberPlaceholders.putIfAbsent(
        identifier, () => new Set<Identifier>()).add(node);
  }

  void makeTypePlaceholder(Node node, DartType type) {
    if (node is Send) {
      // Prefix.
      assert(node.receiver is Identifier);
      assert(node.selector is Identifier);
      makeNullPlaceholder(node.receiver);
      node = node.selector;
    }
    makeElementPlaceholder(node, type.element);
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
    bool requiresVar = !node.modifiers.isFinalOrConst();
    declarationTypePlaceholders.add(
        new DeclarationTypePlaceholder(node.type, requiresVar));
  }

  void makeNullPlaceholder(Node node) {
    assert(node is Identifier || node is Send);
    nullNodes.add(node);
  }

  void makeElementPlaceholder(Identifier node, Element element) {
    assert(element != null);
    if (identical(element, entryFunction)) return;
    if (identical(element.getLibrary(), coreLibrary)) return;
    if (element.getLibrary().isPlatformLibrary && !element.isTopLevel()) {
      return;
    }
    if (element == compiler.types.dynamicType.element) {
      internalError(
          'Should never make element placeholder for dynamic type element',
          node);
    }
    elementNodes.putIfAbsent(element, () => new Set<Identifier>()).add(node);
  }

  void makePrivateIdentifier(Identifier node) {
    assert(node != null);
    privateNodes.putIfAbsent(
        currentElement.getLibrary(), () => new Set<Identifier>()).add(node);
  }

  void makeUnresolvedPlaceholder(Node node) {
    unresolvedNodes.add(node);
  }

  void makeLocalPlaceholder(Identifier identifier) {
    LocalPlaceholder getLocalPlaceholder() {
      String name = identifier.source.slowToString();
      return currentLocalPlaceholders.putIfAbsent(name, () {
        LocalPlaceholder localPlaceholder = new LocalPlaceholder(name);
        currentFunctionScope.localPlaceholders.add(localPlaceholder);
        return localPlaceholder;
      });
    }

    getLocalPlaceholder().nodes.add(identifier);
  }

  void internalError(String reason, {Node node}) {
    compiler.cancel(reason: reason, node: node);
  }

  void unreachable() { internalError('Unreachable case'); }

  visit(Node node) => (node == null) ? null : node.accept(this);

  visitNode(Node node) { node.visitChildren(this); }  // We must go deeper.

  visitSend(Send send) {
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
    if (element == null) {
      if (send.receiver != null) tryMakeMemberPlaceholder(send.selector);
    } else if (!element.isErroneous()) {
      if (Elements.isStaticOrTopLevel(element)) {
        // TODO(smok): Worth investigating why sometimes we get getter/setter
        // here and sometimes abstract field.
        assert(element is VariableElement || element.isAccessor()
            || element.isAbstractField() || element.isFunction());
        makeElementPlaceholder(send.selector, element);
      } else {
        assert(send.selector is Identifier);
        if (Elements.isInstanceField(element)) {
          tryMakeMemberPlaceholder(send.selector);
        } else {
          tryMakeLocalPlaceholder(element, send.selector);
        }
      }
    }
    send.visitChildren(this);
  }

  visitIdentifier(Identifier identifier) {
    if (identifier.source.isPrivate()) makePrivateIdentifier(identifier);
  }

  static bool isPlainTypeName(TypeAnnotation typeAnnotation) {
    if (typeAnnotation.typeName is !Identifier) return false;
    if (typeAnnotation.typeArguments == null) return true;
    if (typeAnnotation.typeArguments.length == 0) return true;
    return false;
  }

  static bool isDynamicType(TypeAnnotation typeAnnotation) {
    if (!isPlainTypeName(typeAnnotation)) return false;
    String name = typeAnnotation.typeName.asIdentifier().source.slowToString();
    // TODO(aprelev@gmail.com): Removed deprecated Dynamic keyword support.
    return name == 'Dynamic' || name == 'dynamic';
  }

  visitTypeAnnotation(TypeAnnotation node) {
    // Poor man generic variables resolution.
    // TODO(antonm): get rid of it once resolver can deal with it.
    TypeDeclarationElement typeDeclarationElement;
    if (currentElement is TypeDeclarationElement) {
      typeDeclarationElement = currentElement;
    } else {
      typeDeclarationElement = currentElement.getEnclosingClass();
    }
    if (typeDeclarationElement != null && isPlainTypeName(node)
        && tryResolveAndCollectTypeVariable(
               typeDeclarationElement, node.typeName)) {
      return;
    }
    // We call [resolveReturnType] to allow having 'void'.
    final type = compiler.resolveReturnType(currentElement, node);
    bool hasPrefix = false;
    if (type is InterfaceType || type is TypedefType) {
      Node target = node.typeName;
      if (node.typeName is Send) {
        final send = node.typeName.asSend();
        Identifier receiver = send.receiver;
        Identifier selector = send.selector;
        Element potentialPrefix =
            currentElement.getLibrary().findLocal(receiver.source);
        if (potentialPrefix != null && potentialPrefix.isPrefix()) {
          // prefix.Class case.
          hasPrefix = true;
        } else {
          // Class.namedContructor case.
          target = receiver;
          // If element is unresolved, mark namedConstructor as unresolved.
          if (treeElements[node] == null) {
            makeUnresolvedPlaceholder(selector);
          }
        }
      }
      // TODO(antonm): is there a better way to detect unresolved types?
      // Corner case: dart:core type with a prefix.
      // Most probably there are some additional problems with
      // coreLibPrefix.topLevels.
      Element typeElement = type.element;
      Element dynamicTypeElement = compiler.types.dynamicType.element;
      if (hasPrefix &&
          (identical(typeElement.getLibrary(), coreLibrary) ||
          identical(typeElement, dynamicTypeElement))) {
        makeNullPlaceholder(node.typeName.asSend().receiver);
      } else {
        if (hasPrefix) {
          assert(node.typeName is Send);
          Send typeName = node.typeName;
          assert(typeName.receiver is Identifier);
          assert(typeName.selector is Identifier);
          makeNullPlaceholder(typeName.receiver);
        }
        if (!identical(typeElement, dynamicTypeElement)) {
          makeTypePlaceholder(target, type);
        } else {
          if (!isDynamicType(node)) makeUnresolvedPlaceholder(target);
        }
      }
    }
    // Trying to differentiate new A.foo() and lib.A cases. In the latter case
    // we don't want to go deeper into typeName.
    if (hasPrefix) {
      // Visit only type arguments, otherwise in case of lib.Class type
      // annotation typeName is Send and we go to visitGetterSend, as a result
      // "Class" is added to member placeholders.
      visit(node.typeArguments);
    } else {
      node.visitChildren(this);
    }
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
      if (definition is Send) {
        // May get FunctionExpression here in definition.selector
        // in case of A(int this.f());
        if (definition.selector is Identifier) {
          if (identical(definitionElement.kind, ElementKind.FIELD_PARAMETER)) {
            tryMakeMemberPlaceholder(definition.selector);
          } else {
            tryMakeLocalPlaceholder(definitionElement, definition.selector);
          }
        } else {
          assert(definition.selector is FunctionExpression);
          if (identical(definitionElement.kind, ElementKind.FIELD_PARAMETER)) {
            tryMakeMemberPlaceholder(
                definition.selector.asFunctionExpression().name);
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
        id != null && Keyword.keywords[id.source.slowToString()] != null;

    Element element = treeElements[node];
    // May get null here in case of A(int this.f());
    if (element != null) {
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
    if (node.defaultClause != null) {
      // Can't just visit class node's default clause because of the bug in the
      // resolver, it just crashes when it meets type variable.
      DartType defaultType = classElement.defaultClass;
      assert(defaultType != null);
      makeTypePlaceholder(node.defaultClause.typeName, defaultType);
      visit(node.defaultClause.typeArguments);
    }
  }

  bool tryResolveAndCollectTypeVariable(
      TypeDeclarationElement typeDeclaration, Identifier name) {
    // Hack for case when interface and default class are in different
    // libraries, try to resolve type variable to default class type arg.
    // Example:
    // lib1: interface I<K> default C<K> {...}
    // lib2: class C<K> {...}
    if (typeDeclaration is ClassElement
        && (typeDeclaration as ClassElement).defaultClass != null) {
      typeDeclaration = (typeDeclaration as ClassElement).defaultClass.element;
    }
    // Another poor man type resolution.
    // Find this variable in enclosing type declaration parameters.
    for (DartType type in typeDeclaration.typeVariables) {
      if (type.name.slowToString() == name.source.slowToString()) {
        makeTypePlaceholder(name, type);
        return true;
      }
    }
    return false;
  }

  visitTypeVariable(TypeVariable node) {
    assert(currentElement is TypedefElement || currentElement is ClassElement);
    tryResolveAndCollectTypeVariable(currentElement, node.name);
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
