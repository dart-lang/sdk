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

class SendVisitor extends ResolvedVisitor {
  final PlaceholderCollector collector;

  SendVisitor(this.collector, TreeElements elements) : super(elements);

  visitSuperSend(Send node) {}
  visitOperatorSend(Send node) {}
  visitForeignSend(Send node) {}

  visitClosureSend(Send node) {
    final element = elements[node];
    if (element !== null) {
      collector.tryMakeLocalPlaceholder(element, node.selector);
    }
  }

  visitDynamicSend(Send node) {
    tryRenamePrivateSelector(node);
  }

  visitGetterSend(Send node) {
    final element = elements[node];
    // element === null means dynamic property access.
    if (element === null || element.isInstanceMember()) {
      tryRenamePrivateSelector(node);
      return;
    }
    // We don't want to rename non top-level element access
    // unless it's a local variable.
    if (element.isPrefix()) {
      // Node is prefix part in case of source 'lib.somesetter = 5;'
      collector.makeNullPlaceholder(node);
      return;
    } else if (!element.isTopLevel()) {
      // May get FunctionExpression here in selector
      // in case of A(int this.f());
      if (node.selector is Identifier) {
        collector.tryMakeLocalPlaceholder(element, node.selector);
      } else {
        assert(node.selector is FunctionExpression);
      }
      return;
    }
    // Unqualified <class> in static invocation, why it's not a type annotation?
    // Another option would be to process in visitStaticSend, NB:
    // those elements are not top-level.
    // OR: unqualified top level.
    collector.makeElementPlaceholder(node.selector, element);
    if (node.receiver !== null) {
      // <lib prefix>.<top level>.
      collector.makeNullPlaceholder(node.receiver);  // Cut library prefix.
    }
  }

  visitStaticSend(Send node) {
    final element = elements[node];
    if (!element.isTopLevel()) return;
    // Another ugly case: <lib prefix>.<top level> is represented as
    // receiver: lib prefix, selector: top level.
    collector.makeElementPlaceholder(node.selector, element);
    if (node.receiver !== null) {
      assert(elements[node.receiver].isPrefix());
      // Hack: putting null into map overrides receiver of original node.
      collector.makeNullPlaceholder(node.receiver);
    }
  }

  internalError(String reason, [Node node]) {
    collector.internalError(reason, node);
  }

  tryRenamePrivateSelector(Send node) {
    collector.tryMakePrivateIdentifier(node.selector.asIdentifier());
  }
}

class PlaceholderCollector extends AbstractVisitor {
  final Compiler compiler;
  final Set<Node> nullNodes;  // Nodes that should not be in output.
  final Set<Identifier> unresolvedNodes;
  final Map<Element, Set<Node>> elementNodes;
  final Map<FunctionElement, Set<LocalPlaceholder>> localPlaceholders;
  final Map<LibraryElement, Set<Identifier>> privateNodes;
  Map<String, LocalPlaceholder> currentLocalPlaceholders;
  Element currentElement;
  TreeElements treeElements;

  PlaceholderCollector(this.compiler) :
      nullNodes = new Set<Node>(),
      unresolvedNodes = new Set<Identifier>(),
      elementNodes = new Map<Element, Set<Node>>(),
      localPlaceholders = new Map<FunctionElement, Set<LocalPlaceholder>>(),
      privateNodes = new Map<LibraryElement, Set<Identifier>>();

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
      final enclosingClass = element.getEnclosingClass();
      Node nameNode = node.name;
      if (nameNode is Send) nameNode = nameNode.receiver;
      // For cases like class C implements I { I(); }
      if (nameNode.asIdentifier().token.slowToString()
          == enclosingClass.name.slowToString()) {
        makeTypePlaceholder(nameNode, enclosingClass.type);
      }
      // Process Ctor(this._field) correctly.
      for (Node parameter in node.parameters) {
        VariableDefinitions definitions = parameter.asVariableDefinitions();
        if (definitions !== null) {
          for (Node definition in definitions.definitions) {
            Send send = definition.asSend();
            if (send !== null) {
              assert(send.receiver is Identifier);
              assert(send.receiver.asIdentifier().isThis());
              if (send.selector is Identifier) {
                tryMakePrivateIdentifier(send.selector.asIdentifier());
              } else if (send.selector is FunctionExpression) {
                // C(int this.f()) case where f is field of function type.
                tryMakePrivateIdentifier(
                    send.selector.asFunctionExpression().name.asIdentifier());
              } else {
                internalError('Unreachable case');
              }
            } else {
              assert(definition is Identifier
                  || definition is FunctionExpression);
            }
          }
        } else {
          assert(parameter is NodeList);
          // We don't have to rename privates in optionals.
        }
      }
    } else if (element.isTopLevel()) {
      // Note: this code should only rename private identifiers for class'
      // fields/getters/setters/methods.  Top-level identifiers are renamed
      // just to escape conflicts and that should be enough as we shouldn't
      // be able to resolve private identifiers for other libraries.
      makeElementPlaceholder(node.name, element);
    } else {
      if (node.name !== null) {
        Identifier identifier = node.name.asIdentifier();
        // operator <blah> names shouldn't be renamed.
        if (identifier !== null) tryMakePrivateIdentifier(identifier);
      }
    }
  }

  void collectFieldDeclarationPlaceholders(
      Element element, VariableDefinitions node) {
    if (element.isInstanceMember()) {
      for (Node definition in node.definitions) {
        if (definition is Identifier) {
          tryMakePrivateIdentifier(definition.asIdentifier());
        } else if (definition is SendSet) {
          tryMakePrivateIdentifier(
              definition.asSendSet().selector.asIdentifier());
        } else {
          internalError('Unreachable case');
        }
      }
    } else if (element.isTopLevel()) {
      Node fieldNode = element.parseNode(compiler);
      if (fieldNode is Identifier) {
        makeElementPlaceholder(fieldNode, element);
      } else if (fieldNode is SendSet) {
        makeElementPlaceholder(fieldNode.selector, element);
      } else {
        internalError('Unreachable case');
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
      assert(false); // Unreachable.
    }
    currentLocalPlaceholders = new Map<String, LocalPlaceholder>();
    compiler.withCurrentElement(element, () {
      elementNode.accept(this);
    });
  }

  Type resolveType(TypeAnnotation typeAnnotation) {
    if (treeElements === null) return null;
    var result = treeElements.getType(typeAnnotation);
    // TODO: Have better type resolution.
    if (result === null) {
      result = compiler.resolveTypeAnnotation(currentElement, typeAnnotation);
    }
    return result;
  }

  void tryMakePrivateIdentifier(Identifier identifier) {
    if (identifier.source.isPrivate()) makePrivateIdentifier(identifier);
  }

  void tryMakeLocalPlaceholder(Element element, Identifier node) {
    // TODO(smok): Maybe we should rename privates as well, their privacy
    // should not matter if they are local vars.
    if (node.source.isPrivate()) return;
    if (element.isVariable()
        || (element.isFunction() && !Elements.isStaticOrTopLevel(element))) {
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

  void makeLocalPlaceholder(Node node) {
    assert(currentElement is FunctionElement);
    assert(node is Identifier);
    String identifier = node.asIdentifier().source.slowToString();
    LocalPlaceholder localPlaceholder =
        currentLocalPlaceholders.putIfAbsent(identifier,
            () {
              LocalPlaceholder localPlaceholder =
                  new LocalPlaceholder(identifier);
              localPlaceholders.putIfAbsent(currentElement,
                  () => new Set<LocalPlaceholder>()).add(localPlaceholder);
              return localPlaceholder;
            });
  }

  void internalError(String reason, [Node node]) {
    compiler.cancel(reason: reason, node: node);
  }

  visit(Node node) => (node === null) ? null : node.accept(this);

  visitNode(Node node) { node.visitChildren(this); }  // We must go deeper.

  visitSend(Send send) {
    new SendVisitor(this, treeElements).visitSend(send);
    send.visitChildren(this);
  }

  visitSendSet(SendSet send) {
    final element = treeElements[send];
    if (element !== null) {
      if (element.isInstanceMember()) {
        tryMakePrivateIdentifier(send.selector.asIdentifier());
      } else if (element.isTopLevel()) {
        assert(element is VariableElement || element.isSetter());
        makeElementPlaceholder(send.selector, element);
      } else {
        assert(send.selector is Identifier);
        tryMakeLocalPlaceholder(element, send.selector);
      }
    }
    send.visitChildren(this);
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
    if (isPlainTypeName(node) && currentElement is TypeDeclarationElement) {
      SourceString name = node.typeName.asIdentifier().source;
      TypeDeclarationElement typeElement = currentElement;
      for (TypeVariableType parameter in typeElement.typeVariables) {
        if (parameter.name == name) {
          // type annotation matches one of parameters, shouldn't be renamed.
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
      if (type !== compiler.types.dynamicType) {
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
    assert(currentElement is ClassElement);
    makeElementPlaceholder(node.name, currentElement);
    node.visitChildren(this);
  }

  visitTypedef(Typedef node) {
    assert(currentElement is TypedefElement);
    makeElementPlaceholder(node.name, currentElement);
    node.visitChildren(this);
  }
}
