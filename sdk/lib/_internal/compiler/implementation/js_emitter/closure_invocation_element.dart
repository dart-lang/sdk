// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

/**
 * A function element that represents a closure call. The signature is copied
 * from the given element.
 */
class ClosureInvocationElement extends FunctionElementX {
  ClosureInvocationElement(String name,
                           FunctionElement other)
      : super.from(name, other, other.enclosingElement),
        methodElement = other;

  isInstanceMember() => true;

  Element getOutermostEnclosingMemberOrTopLevel() => methodElement;

  /**
   * The [member] this invocation refers to.
   */
  Element methodElement;
}
