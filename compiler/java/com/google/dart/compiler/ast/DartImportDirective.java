// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Implements the #import directive.
 */
public class DartImportDirective extends DartDirective {
  private DartStringLiteral libraryUri;

  private DartStringLiteral prefix;

  public DartImportDirective(DartStringLiteral libraryUri, DartStringLiteral prefix) {
    this.libraryUri = becomeParentOf(libraryUri);
    this.prefix = becomeParentOf(prefix);
  }

  public DartStringLiteral getLibraryUri() {
    return libraryUri;
  }

  public DartStringLiteral getPrefix() {
    return prefix;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      libraryUri = becomeParentOf(v.accept(libraryUri));
      if (prefix != null) {
        prefix = becomeParentOf(v.accept(prefix));
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    libraryUri.accept(visitor);
    if (prefix != null) {
      prefix.accept(visitor);
    }
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitImportDirective(this);
  }
}
