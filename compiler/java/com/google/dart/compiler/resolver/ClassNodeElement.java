// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.resolver;

import java.util.List;

public interface ClassNodeElement extends ClassElement, NodeElement {
  /**
   * Sets {@link Element}s which as not implemented in this {@link ClassElement}.
   */
  void setUnimplementedMembers(List<Element> members);
}
