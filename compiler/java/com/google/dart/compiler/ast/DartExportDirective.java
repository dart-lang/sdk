// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Implements the export directive.
 */
public class DartExportDirective extends DartDirective {
  private DartStringLiteral libraryUri;

  private NodeList<ImportCombinator> combinators = new NodeList<ImportCombinator>(this);

  public DartExportDirective(DartStringLiteral libraryUri, List<ImportCombinator> combinators) {
    this.libraryUri = becomeParentOf(libraryUri);
    this.combinators.addAll(combinators);
  }

  public DartStringLiteral getLibraryUri() {
    return libraryUri;
  }

  public List<ImportCombinator> getCombinators() {
    return combinators;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(libraryUri, visitor);
    combinators.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitExportDirective(this);
  }
}
