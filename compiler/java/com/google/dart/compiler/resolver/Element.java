// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.type.Type;

public interface Element {
  String getOriginalName();

  DartNode getNode();

  void setNode(DartLabel node);

  String getName();

  ElementKind getKind();

  Type getType();

  boolean isDynamic();

  Modifiers getModifiers();

  /**
   * Returns the innermost {@link EnclosingElement} which declares this element.
   */
  EnclosingElement getEnclosingElement();
}
