// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('types');

#import('../leg.dart');
#import('../tree/tree.dart');
#import('../elements/elements.dart');

/**
 * The types task infers guaranteed types globally.
 */
class TypesTask extends CompilerTask {
  final String name = 'Type inference';
  final bool enabled = false;

  TypesTask(Compiler compiler) : super(compiler);

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
    if (!enabled) return null;
    return measure(() {
      // TODO(ahe): Do something real here.
      if (element.enclosingElement.name.slowToString() == 'print') {
        return compiler.stringClass;
      }
      return null;
    });
  }

  /**
   * Return the (inferred) guaranteed type of [node].
   * [node] must be an AST node of [owner].
   */
  Element getGuaranteedTypeOfNode(Node node, Element owner) {
    if (!enabled) return null;
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

  isConcreteSend(Send node) {
    if (node.argumentsNode === null) return true;
    if (node.arguments.isEmpty()) return true;
    if (node.receiver !== null && concreteTypes[node.receiver] === null) {
      return false;
    }
    for (Node argument in node.arguments) {
      if (concreteTypes[argument] === null) return false;
    }
    return true;
  }

  visitSend(Send node) {
    if (node.argumentsNode === null) return;
    if (node.arguments.isEmpty()) return;
    if (node.selector.toString() != 'print') return;
    node.visitChildren(this);
    if (isConcreteSend(node)) {
      interest(node, 'all arguments are concrete');
    } else {
      interest(node, 'not all arguments are concrete');
    }
  }

  visitSendSet(SendSet node) {
    // TODO(ahe): Implement this. For now, overridden to avoid calling
    // visitSend through super.
    node.visitChildren(this);
  }

  interest(Node node, String note) {
    if (!task.enabled) return;
    var message = MessageKind.GENERIC.message([note]);
    task.compiler.reportWarning(node, message);
  }
}
