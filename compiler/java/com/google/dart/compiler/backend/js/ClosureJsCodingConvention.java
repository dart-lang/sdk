// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.common.base.Preconditions;
import com.google.javascript.jscomp.ClosureCodingConvention;
import com.google.javascript.rhino.Node;
import com.google.javascript.rhino.Token;

/**
 * A means of giving hints to the Closure Compiler:
 * - Teach the compiler the meaning of "$inherits" so the name removal
 * passes understand it is not just a method depending on the class
 * definitions and modifying global state.
 * @author johnlenz@google.com (John Lenz)
 */
class ClosureJsCodingConvention extends ClosureCodingConvention {
  /**
   * {@inheritDoc}
   *
   * <p>Understands several different inheritance patterns that occur in
   * DartC generated code.
   */
  @Override
  public SubclassRelationship getClassesDefinedByCall(Node callNode) {
    Node callName = callNode.getFirstChild();
    SubclassType type = typeofClassDefiningName(callName);
    if (type != null && callNode.getChildCount() == 3) {
      // Only one type of call is expected.
      // $inherits(SubClass, SuperClass)
      Preconditions.checkState(type == SubclassType.INHERITS);

      Node subclass = callName.getNext();
      Node superclass = callNode.getLastChild();

      // bail out if either of the side of the "inherits"
      // isn't a real class name. This prevents us from
      // doing something weird in cases like:
      // goog.inherits(MySubClass, cond ? SuperClass1 : BaseClass2)
      if (subclass != null &&
          subclass.isUnscopedQualifiedName() &&
          superclass.isUnscopedQualifiedName()) {
        return new SubclassRelationship(type, subclass, superclass);
      }
    }

    return super.getClassesDefinedByCall(callNode);
  }

  /**
   * Determines whether the given node is a class-defining name, like
   * "inherits".
   * @return The type of class-defining name, or null.
   */
  private SubclassType typeofClassDefiningName(Node callName) {
    // Check if the method name matches one of the class-defining methods.
    if (callName.getType() == Token.NAME
        && callName.getString().equals("$inherits")) {
      return SubclassType.INHERITS;
    }
    return null;
  }
}
