// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.type.Type;

/**
 * Extension of {@link FieldElement} which is based on {@link DartNode} and is modifiable.
 */
public interface FieldNodeElement extends FieldElement, NodeElement {
  /**
   * Sets the inferred type of this constant.
   * 
   * @param type the {@link Type} to set, not <code>null</code>.
   */
  void setConstantType(Type type);
  
  MethodNodeElement getGetter();
  
  MethodNodeElement getSetter();
}
