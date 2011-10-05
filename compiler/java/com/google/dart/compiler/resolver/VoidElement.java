// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

/**
 * Implementation of "void". There is no public interface for this class as Element already exposes
 * all the functionality needed.
 */
class VoidElement extends AbstractElement {
  private VoidElement() {
    super(null, "void");
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.VOID;
  }

  static Element getInstance() {
    return new VoidElement();
  }

  @Override
  public boolean equals(Object other) {
    return other instanceof VoidElement;
  }

  @Override
  public int hashCode() {
    return VoidElement.class.hashCode();
  }
}
