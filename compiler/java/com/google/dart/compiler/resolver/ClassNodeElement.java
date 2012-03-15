// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartNode;

import java.util.List;

/**
 * Extension of {@link ClassElement} which is based on {@link DartNode}.
 */
public interface ClassNodeElement extends ClassElement, NodeElement {
  Iterable<NodeElement> getMembers();

  List<ConstructorNodeElement> getConstructors();

  /**
   * Sets {@link Element}s which as not implemented in this {@link ClassElement}.
   */
  void setUnimplementedMembers(List<Element> members);
}
