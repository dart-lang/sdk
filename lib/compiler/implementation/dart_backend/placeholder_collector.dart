// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class LocalPlaceholder implements Hashable {
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

class SendVisitor extends ResolvedVisitor {
  final PlaceholderCollector collector;

  SendVisitor(this.collector, TreeElements elements) : super(elements);

  visitDynamicSend(Send node) {}
  visitSuperSend(Send node) {}
  visitOperatorSend(Send node) {}
  visitForeignSend(Send node) {}

  visitClosureSend(Send node) {
    final element = elements[node];
    if (element !== null) {
      collector.tryMakeLocalPlaceholder(element, node.selector);
    }
  }

  visitGetterSend(Send node) {
    final element = elements[node];
    // element === null means dynamic property access.
    if (element === null) return;
    if (element.isPrefix()) {
      // Node is prefix part in case of source 'lib.somesetter = 5;'
      collector.makeNullPlaceholder(node);
    } else if (Elements.isStaticOrTopLevel(element)) {
      // Unqualified or prefixed top level or static.
      collector.makeElementPlaceholder(node.selector, element);
    } else if (!element.isTopLevel()) {
      // May get FunctionExpression here in selector
      // in case of A(int this.f());
      if (node.selector is Identifier) {
        collector.tryMakeLocalPlaceholder(element, node.selector);
      } else {
        assert(node.selector is FunctionExpression);
      }
    }
  }

  visitStaticSend(Send node) {
    final element = elements[node];
    if (element.isConstructor() || element.isFactoryConstructor()) return;
    collector.makeElementPlaceholder(node.selector, element);
    // Another ugly case: <lib prefix>.<top level> is represented as
    // receiver: lib prefix, selector: top level.
    if (element.isTopLevel() && node.receiver !== null) {
      assert(elements[node.receiver].isPrefix());
      // Hack: putting null into map overrides receiver of original node.
      collector.makeNullPlaceholder(node.receiver);
    }
  }

  internalError(String reason, [Node node]) {
    collector.internalError(reason, node);
  }
}

class PlaceholderCollector extends AbstractVisitor {
  final Compiler compiler;
  final Set<Node> nullNodes;  // Nodes that should not be in output.
  final Set<Identifier> unresolvedNodes;
  final Map<Element, Set<Node>> elementNodes;
  final Map<FunctionElement, FunctionScope> functionScopes;
  final Map<LibraryElement, Set<Identifier>> privateNodes;
  Map<String, LocalPlaceholder> currentLocalPlaceholders;
  Element currentElement;
  TreeElements treeElements;

  LibraryElement get coreLibrary => compiler.coreLibrary;
  FunctionElement get entryFunction => compiler.mainApp.find(Compiler.MAIN);

  PlaceholderCollector(this.compiler) :
      nullNodes = new Set<Node>(),
      unresolvedNodes = new Set<Identifier>(),
      elementNodes = new Map<Element, Set<Node>>(),
      functionScopes = new Map<FunctionElement, FunctionScope>(),
      privateNodes = new Map<LibraryElement, Set<Identifier>>();

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
      if (element.defaultImplementation !== null
          && element.defaultImplementation !== element) {
        FunctionElement implementingFactory = element.defaultImplementation;
        tryMakeConstructorNamePlaceholder(implementingFactory.cachedNode,
            element.getEnclosingClass());
      }
    } else if (Elements.isStaticOrTopLevel(element)) {
      // Note: this code should only rename private identifiers for class'
      // fields/getters/setters/methods.  Top-level identifiers are renamed
      // just to escape conflicts and that should be enough as we shouldn't
      // be able to resolve private identifiers for other libraries.
      makeElementPlaceholder(node.name, element);
    }
  }

  void collectFieldDeclarationPlaceholders(
      Element element, VariableDefinitions node) {
    if (Elements.isStaticOrTopLevel(element)) {
      Node fieldNode = element.parseNode(compiler);
      if (fieldNode is Identifier) {
        makeElementPlaceholder(fieldNode, element);
      } else if (fieldNode is SendSet) {
        makeElementPlaceholder(fieldNode.selector, element);
      } else {
        unreachable();
      }
    }
  }

  void collect(Element element, TreeElements elements) {
    treeElements = elements;
    Node elementNode;
    if (element is FunctionElement) {
      currentElement = element;
      elementNode = currentElement.parseNode(compiler);
      collectFunctionDeclarationPlaceholders(element, elementNode);
    } else if (element.isField()) {
      // TODO(smok): In the future make sure we don't process same
      // variable list element twice, better merge this with emitter logic.
      currentElement = (element as VariableElement).variables;
      elementNode = currentElement.parseNode(compiler);
      // We don't collect other elements from the same variable lists
      // if they are not used. http://dartbug.com/4536
      collectFieldDeclarationPlaceholders(element, elementNode);
    } else if (element is ClassElement || element is TypedefElement) {
      currentElement = element;
      elementNode = currentElement.parseNode(compiler);
    } else {
      unreachable();
    }
    currentLocalPlaceholders = new Map<String, LocalPlaceholder>();
    compiler.withCurrentElement(element, () {
      elementNode.accept(this);
    });
  }

  void tryMakeLocalPlaceholder(Element element, Identifier node) {
    // TODO(smok): Maybe we should rename privates as well, their privacy
    // should not matter if they are local vars.
    if (node.source.isPrivate()) return;
    if (element.isParameter()) {
      functionScopes.putIfAbsent(currentElement, () => new FunctionScope())
          .registerParameter(node);
      return;
    }
    if (!element.isMember() && !Elements.isStaticOrTopLevel(element)
        && (element.isVariable() || element.isFunction())) {
      makeLocalPlaceholder(node);
    }
  }

  void makeTypePlaceholder(Node node, Type type) {
    makeElementPlaceholder(node, type.element);
  }

  void makeNullPlaceholder(Node node) {
    assert(node is Identifier || node is Send);
    nullNodes.add(node);
  }

  void makeElementPlaceholder(Node node, Element element) {
    assert(element !== null);
    if (element === entryFunction) return;
    if (element.getLibrary() === coreLibrary) return;
    if (isDartCoreLib(compiler, element.getLibrary())
        && !element.isTopLevel()) {
      return;
    }
    if (element == compiler.types.dynamicType.element) {
      internalError(
          'Should never make element placeholder for dynamic type element',
          node);
    }
    elementNodes.putIfAbsent(element, () => new Set<Node>()).add(node);
  }

  void makePrivateIdentifier(Identifier node) {
    assert(node !== null);
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
        functionScopes.putIfAbsent(currentElement, () => new FunctionScope())
            .localPlaceholders.add(localPlaceholder);
        return localPlaceholder;
      });
    }

    assert(currentElement is FunctionElement);
    getLocalPlaceholder().nodes.add(identifier);
  }

  void internalError(String reason, [Node node]) {
    compiler.cancel(reason: reason, node: node);
  }

  void unreachable() { internalError('Unreachable case'); }

  visit(Node node) => (node === null) ? null : node.accept(this);

  visitNode(Node node) { node.visitChildren(this); }  // We must go deeper.

  visitSend(Send send) {
    new SendVisitor(this, treeElements).visitSend(send);
    send.visitChildren(this);
  }

  visitSendSet(SendSet send) {
    final element = treeElements[send];
    if (element !== null) {
      if (Elements.isStaticOrTopLevel(element)) {
        assert(element is VariableElement || element.isSetter());
        makeElementPlaceholder(send.selector, element);
      } else {
        assert(send.selector is Identifier);
        tryMakeLocalPlaceholder(element, send.selector);
      }
    }
    send.visitChildren(this);
  }

  visitIdentifier(Identifier identifier) {
    if (identifier.source.isPrivate()) makePrivateIdentifier(identifier);
  }

  static bool isPlainTypeName(TypeAnnotation typeAnnotation) {
    if (typeAnnotation.typeName is !Identifier) return false;
    if (typeAnnotation.typeArguments === null) return true;
    if (typeAnnotation.typeArguments.length === 0) return true;
    return false;
  }

  static bool isDynamicType(TypeAnnotation typeAnnotation) {
    if (!isPlainTypeName(typeAnnotation)) return false;
    String name = typeAnnotation.typeName.asIdentifier().source.slowToString();
    return name == 'Dynamic';
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
    if (typeDeclarationElement !== null && isPlainTypeName(node)) {
      SourceString name = node.typeName.asIdentifier().source;
      for (TypeVariableType parameter in typeDeclarationElement.typeVariables) {
        if (parameter.name == name) {
          makeTypePlaceholder(node, parameter);
          return;
        }
      }
    }
    final type = compiler.resolveTypeAnnotation(currentElement, node);
    if (type is InterfaceType || type is TypedefType) {
      var target = node.typeName;
      if (node.typeName is Send) {
        final element = treeElements[node];
        if (element !== null) {
          final send = node.typeName.asSend();
          Identifier receiver = send.receiver;
          Identifier selector = send.selector;
          final hasPrefix = element is TypedefElement ||
              element.lookupConstructor(receiver.source, selector.source)
                  === null;
          if (!hasPrefix) target = send.receiver;
        }
      }
      // TODO(antonm): is there a better way to detect unresolved types?
      if (type.element !== compiler.types.dynamicType.element) {
        makeTypePlaceholder(target, type);
      } else {
        if (!isDynamicType(node)) makeUnresolvedPlaceholder(target);
      }
    }
    node.visitChildren(this);
  }

  visitVariableDefinitions(VariableDefinitions node) {
    // Collect only local placeholders.
    if (currentElement is FunctionElement) {
      for (Node definition in node.definitions.nodes) {
        Element definitionElement = treeElements[definition];
        // definitionElement may be null if we're inside variable definitions
        // of a function that is a parameter of another function.
        // TODO(smok): Fix this when resolver correctly deals with
        // such cases.
        if (definitionElement === null) continue;
        if (definition is Send) {
          // May get FunctionExpression here in definition.selector
          // in case of A(int this.f());
          if (definition.selector is Identifier) {
            tryMakeLocalPlaceholder(definitionElement, definition.selector);
          } else {
            assert(definition.selector is FunctionExpression);
          }
        } else if (definition is Identifier) {
          tryMakeLocalPlaceholder(definitionElement, definition);
        } else if (definition is FunctionExpression) {
          // Skip, it will be processed in visitFunctionExpression.
        } else {
          internalError('Unexpected definition structure $definition');
        }
      }
    }
    node.visitChildren(this);
  }

  visitFunctionExpression(FunctionExpression node) {
    Element element = treeElements[node];
    // May get null here in case of A(int this.f());
    if (element !== null) {
      // Rename only local functions.
      if (element is FunctionElement && element !== currentElement) {
        if (node.name !== null) {
          assert(node.name is Identifier);
          tryMakeLocalPlaceholder(element, node.name);
        }
      }
    }
    node.visitChildren(this);
  }

  visitClassNode(ClassNode node) {
    ClassElement classElement = currentElement;
    makeElementPlaceholder(node.name, classElement);
    node.visitChildren(this);
    if (node.defaultClause !== null) {
      // Can't just visit class node's default clause because of the bug in the
      // resolver, it just crashes when it meets type variable.
      Type defaultType = classElement.defaultClass;
      assert(defaultType !== null);
      makeTypePlaceholder(node.defaultClause.typeName, defaultType);
      visit(node.defaultClause.typeArguments);
    }
  }

  visitTypeVariable(TypeVariable node) {
    assert(currentElement is TypedefElement || currentElement is ClassElement);
    // Hack for case when interface and default class are in different
    // libraries, try to resolve type variable to default class type arg.
    // Example:
    // lib1: interface I<K> default C<K> {...}
    // lib2: class C<K> {...}
    if (currentElement is ClassElement
        && (currentElement as ClassElement).defaultClass !== null) {
      currentElement = (currentElement as ClassElement).defaultClass.element;
    }
    // Another poor man type resolution.
    // Find this variable in current element type parameters.
    for (Type type in currentElement.typeVariables) {
      if (type.name.slowToString() == node.name.source.slowToString()) {
        makeTypePlaceholder(node.name, type);
        break;
      }
    }
    node.visitChildren(this);
  }

  visitTypedef(Typedef node) {
    assert(currentElement is TypedefElement);
    makeElementPlaceholder(node.name, currentElement);
    node.visitChildren(this);
  }
}
