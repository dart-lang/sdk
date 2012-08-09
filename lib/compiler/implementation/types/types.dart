// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('types');

#import('../leg.dart');
#import('../tree/tree.dart');
#import('../elements/elements.dart');
#import('../util/util.dart');

/**
 * The types task infers guaranteed types globally.
 */
class TypesTask extends CompilerTask {
  final String name = 'Type inference';
  final Set<Element> untypedElements;
  final Map<Element, Link<Element>> typedSends;

  TypesTask(Compiler compiler)
    : untypedElements = new Set<Element>(),
      typedSends = new Map<Element, Link<Element>>(),
      super(compiler);

  /**
   * Called once for each method during the resolution phase of the
   * compiler.
   */
  void analyze(Node node, TreeElements elements) {
    measure(() {
      node.accept(new ConcreteTypeInferencer(this, elements));
    });
  }

  /**
   * Called when resolution is complete.
   */
  void onResolutionComplete() {
    measure(() {
      // TODO(ahe): Do something here.
    });
  }

  /**
   * Return the (inferred) guaranteed type of [element].
   */
  Element getGuaranteedTypeOfElement(Element element) {
    return measure(() {
      if (!element.isParameter()) return null;
      Element holder = element.enclosingElement;
      Link<Element> types = typedSends[holder];
      if (types === null) return null;
      if (!holder.isFunction()) return null;
      if (untypedElements.contains(holder)) return null;
      FunctionElement function = holder;
      FunctionSignature signature = function.computeSignature(compiler);
      for (Element parameter in signature.requiredParameters) {
        if (types.isEmpty()) return null;
        if (element === parameter) return types.head;
        types = types.tail;
      }
      return null;
    });
  }

  /**
   * Return the (inferred) guaranteed type of [node].
   * [node] must be an AST node of [owner].
   */
  Element getGuaranteedTypeOfNode(Node node, Element owner) {
    return measure(() {
      // TODO(ahe): Do something real here.
      return null;
    });
  }
}

/**
 * Infers concrete types for a single method or expression.
 */
class ConcreteTypeInferencer extends AbstractVisitor {
  final TypesTask task;
  final TreeElements elements;
  final ClassElement boolClass;
  final ClassElement doubleClass;
  final ClassElement intClass;
  final ClassElement listClass;
  final ClassElement nullClass;
  final ClassElement stringClass;

  final Map<Node, ClassElement> concreteTypes;

  ConcreteTypeInferencer(TypesTask task, this.elements)
    : this.task = task,
      this.boolClass = task.compiler.boolClass,
      this.doubleClass = task.compiler.doubleClass,
      this.intClass = task.compiler.intClass,
      this.listClass = task.compiler.listClass,
      this.nullClass = task.compiler.nullClass,
      this.stringClass = task.compiler.stringClass,
      this.concreteTypes = new Map<Node, ClassElement>();

  visitNode(Node node) => node.visitChildren(this);

  visitLiteralString(LiteralString node) {
    recordConcreteType(node, stringClass);
  }

  visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    recordConcreteType(node, stringClass);
  }

  visitStringJuxtaposition(StringJuxtaposition node) {
    node.visitChildren(this);
    recordConcreteType(node, stringClass);
  }

  recordConcreteType(Node node, ClassElement cls) {
    concreteTypes[node] = cls;
  }

  visitLiteralBool(LiteralBool node) {
    recordConcreteType(node, boolClass);
  }

  visitLiteralDouble(LiteralDouble node) {
    recordConcreteType(node, doubleClass);
  }

  visitLiteralInt(LiteralInt node) {
    recordConcreteType(node, intClass);
  }

  visitLiteralList(LiteralList node) {
    node.visitChildren(this);
    recordConcreteType(node, listClass);
  }

  visitLiteralMap(LiteralMap node) {
    node.visitChildren(this);
    // TODO(ahe): map class?
  }

  visitLiteralNull(LiteralNull node) {
    recordConcreteType(node, nullClass);
  }

  Link<Element> computeConcreteSendArguments(Send node) {
    if (node.argumentsNode === null) return null;
    if (node.arguments.isEmpty()) return const EmptyLink<Element>();
    if (node.receiver !== null && concreteTypes[node.receiver] === null) {
      return null;
    }
    LinkBuilder<Element> types = new LinkBuilder<Element>();
    for (Node argument in node.arguments) {
      Element type = concreteTypes[argument];
      if (type === null) return null;
      types.addLast(type);
    }
    return types.toLink();
  }

  visitSend(Send node) {
    node.visitChildren(this);
    Element element = elements[node.selector];
    if (element === null) return;
    if (!Elements.isStaticOrTopLevelFunction(element)) return;
    if (node.argumentsNode === null) {
      // interest(node, 'closurized method');
      task.untypedElements.add(element);
      return;
    }
    Link<Element> types = computeConcreteSendArguments(node);
    if (types !== null) {
      Link<Element> existing = task.typedSends[element];
      if (existing === null) {
        task.typedSends[element] = types;
      } else {
        // interest(node, 'multiple invocations');
        Link<Element> lub = computeLubs(existing, types);
        if (lub === null) {
          task.untypedElements.add(element);
        } else {
          task.typedSends[element] = lub;
        }
      }
    } else {
      // interest(node, 'dynamically typed invocation');
      task.untypedElements.add(element);
    }
  }

  visitSendSet(SendSet node) {
    // TODO(ahe): Implement this. For now, overridden to avoid calling
    // visitSend through super.
    node.visitChildren(this);
  }

  void interest(Node node, String note) {
    var message = MessageKind.GENERIC.message([note]);
    task.compiler.reportWarning(node, message);
  }

  /**
   * Computes the pairwise Least Upper Bound (LUB) of the elements of
   * [a] and [b]. Returns [:null:] if it gives up, or if the lists
   * aren't the same length.
   */
  Link<Element> computeLubs(Link<Element> a, Link<Element> b) {
    LinkBuilder<Element> lubs = new LinkBuilder<Element>();
    while (!a.isEmpty() && !b.isEmpty()) {
      Element lub = computeLub(a.head, b.head);
      if (lub === null) return null;
      lubs.addLast(lub);
      a = a.tail;
      b = b.tail;
    }
    return (a.isEmpty() && b.isEmpty()) ? lubs.toLink() : null;
  }

  /**
   * Computes the Least Upper Bound (LUB) of [a] and [b]. Returns
   * [:null:] if it gives up.
   */
  Element computeLub(Element a, Element b) {
    // Fast common case, but also simple initial implementation.
    if (a === b) return a;

    // TODO(ahe): Improve the following "computation"...
    return null;
  }
}
