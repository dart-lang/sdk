// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartObsoleteMetadata;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.HasSourceInfo;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.Type;

public interface Element extends HasSourceInfo {
  String getOriginalName();

  String getName();

  ElementKind getKind();

  Type getType();

  boolean isDynamic();

  Modifiers getModifiers();
  
  DartObsoleteMetadata getMetadata();

  /**
   * @return the innermost {@link EnclosingElement} which encloses this {@link Element}.
   */
  EnclosingElement getEnclosingElement();
  
  /**
   * @return location of the name in the declaration of this {@link Element}.
   */
  SourceInfo getNameLocation();
}
