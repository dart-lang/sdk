// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Implements the #native directive.
 */
public class DartNativeDirective extends DartDirective {
  private DartStringLiteral nativeUri;

  public DartNativeDirective(DartStringLiteral nativeUri) {
    this.nativeUri = becomeParentOf(nativeUri);
  }

  public DartStringLiteral getNativeUri() {
    return nativeUri;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    nativeUri.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitNativeDirective(this);
  }
}
