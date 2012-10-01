// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ResolvedVisitor<R> extends Visitor<R> {
  TreeElements elements;

  ResolvedVisitor(this.elements);

  R visitSend(Send node) {
    if (node.isSuperCall) {
      return visitSuperSend(node);
    } else if (node.isOperator) {
      return visitOperatorSend(node);
    } else if (node.isPropertyAccess) {
      return visitGetterSend(node);
    } else if (Elements.isClosureSend(node, elements[node])) {
      return visitClosureSend(node);
    } else {
      Element element = elements[node];
      if (Elements.isUnresolved(element)) {
        if (element == null) {
          // Example: f() with 'f' unbound.
          // This can only happen inside an instance method.
          return visitDynamicSend(node);
        } else {
          return visitStaticSend(node);
        }
      } else if (element.kind == ElementKind.CLASS) {
        internalError("Cannot generate code for send", node: node);
      } else if (element.isInstanceMember()) {
        // Example: f() with 'f' bound to instance method.
        return visitDynamicSend(node);
      } else if (element.kind === ElementKind.FOREIGN) {
        return visitForeignSend(node);
      } else if (!element.isInstanceMember()) {
        // Example: A.f() or f() with 'f' bound to a static function.
        // Also includes new A() or new A.named() which is treated like a
        // static call to a factory.
        return visitStaticSend(node);
      } else {
        internalError("Cannot generate code for send", node: node);
      }
    }
  }

  abstract R visitSuperSend(Send node);
  abstract R visitOperatorSend(Send node);
  abstract R visitGetterSend(Send node);
  abstract R visitClosureSend(Send node);
  abstract R visitDynamicSend(Send node);
  abstract R visitForeignSend(Send node);
  abstract R visitStaticSend(Send node);

  abstract void internalError(String reason, [Node node]);

  R visitNode(Node node) {
    internalError("Unhandled node", node);
  }
}
