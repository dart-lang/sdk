// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.type.DynamicType;

/**
 * Dummy element corresponding to {@link DynamicType}.
 */
public interface DynamicElement extends FunctionAliasElement, LibraryElement, FieldElement,
                                        LabelElement, SuperElement, VariableElement,
                                        TypeVariableElement, ConstructorElement {
  @Override
  DynamicType getType();
}
