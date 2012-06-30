// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Implements the #import directive.
 */
public class DartImportDirective extends DartDirective {
  private DartStringLiteral libraryUri;

  private DartBooleanLiteral exported;

  private NodeList<ImportCombinator> combinators = new NodeList<ImportCombinator>(this);

  private DartStringLiteral prefix;

  public DartImportDirective(DartStringLiteral libraryUri, DartBooleanLiteral exported, List<ImportCombinator> combinators, DartStringLiteral prefix) {
    this.libraryUri = becomeParentOf(libraryUri);
    this.exported = becomeParentOf(exported);
    this.combinators.addAll(combinators);
    this.prefix = becomeParentOf(prefix);
  }

  public DartStringLiteral getLibraryUri() {
    return libraryUri;
  }

  public DartBooleanLiteral getExported() {
    return exported;
  }

  public List<ImportCombinator> getCombinators() {
    return combinators;
  }

  public DartStringLiteral getPrefix() {
    return prefix;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(libraryUri, visitor);
    safelyVisitChild(exported, visitor);
    combinators.accept(visitor);
    safelyVisitChild(prefix, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitImportDirective(this);
  }
}
