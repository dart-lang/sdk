// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

abstract class ResolvedVisitor<R> extends Visitor<R> {
  final Compiler compiler;
  TreeElements elements;

  ResolvedVisitor(this.elements, this.compiler);

  R visitSend(Send node) {
    Element element = elements[node];
    if (node.isSuperCall) {
      return visitSuperSend(node);
    } else if (node.isOperator) {
      return visitOperatorSend(node);
    } else if (node.isPropertyAccess) {
      if (!Elements.isUnresolved(element) && element.impliesType()) {
        // A reference to a class literal, typedef or type variable.
        return visitTypeReferenceSend(node);
      } else {
        return visitGetterSend(node);
      }
    } else if (element != null && Initializers.isConstructorRedirect(node)) {
      return visitStaticSend(node);
    } else if (Elements.isClosureSend(node, element)) {
      return visitClosureSend(node);
    } else if (element == compiler.assertMethod) {
      assert(element != null);
      return visitAssert(node);
    } else {
      if (Elements.isUnresolved(element)) {
        if (element == null) {
          // Example: f() with 'f' unbound.
          // This can only happen inside an instance method.
          return visitDynamicSend(node);
        } else {
          return visitStaticSend(node);
        }
      } else if (element.impliesType()) {
        // A reference to a class literal, typedef or type variable.
        return visitTypeReferenceSend(node);
      } else if (element.isInstanceMember()) {
        // Example: f() with 'f' bound to instance method.
        return visitDynamicSend(node);
      } else if (!element.isInstanceMember()) {
        // Example: A.f() or f() with 'f' bound to a static function.
        // Also includes new A() or new A.named() which is treated like a
        // static call to a factory.
        return visitStaticSend(node);
      } else {
        internalError("Cannot generate code for send", node: node);
        return null;
      }
    }
  }

  R visitSuperSend(Send node);
  R visitOperatorSend(Send node);
  R visitGetterSend(Send node);
  R visitClosureSend(Send node);
  R visitDynamicSend(Send node);
  R visitStaticSend(Send node);
  R visitTypeReferenceSend(Send node);
  R visitAssert(Send node);

  void internalError(String reason, {Node node});

  R visitNode(Node node) {
    internalError("Unhandled node", node: node);
    return null;
  }
}
