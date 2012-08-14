// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Implements the import directive.
 */
public class DartImportDirective extends DartDirective {
  private boolean obsoleteFormat;

  private DartStringLiteral libraryUri;

  private DartIdentifier prefix;

  private NodeList<ImportCombinator> combinators = new NodeList<ImportCombinator>(this);

  private boolean exported;

  private DartStringLiteral oldPrefix;

  public DartImportDirective(DartStringLiteral libraryUri, DartIdentifier prefix, List<ImportCombinator> combinators, boolean exported) {
    obsoleteFormat = false;
    this.libraryUri = becomeParentOf(libraryUri);
    this.prefix = becomeParentOf(prefix);
    this.combinators.addAll(combinators);
    this.exported = exported;
  }

  public DartImportDirective(DartStringLiteral libraryUri, DartBooleanLiteral exported, List<ImportCombinator> combinators, DartStringLiteral prefix) {
    obsoleteFormat = true;
    this.libraryUri = becomeParentOf(libraryUri);
    this.combinators.addAll(combinators);
    this.oldPrefix = becomeParentOf(prefix);
    this.exported = exported != null;
  }

  public DartStringLiteral getLibraryUri() {
    return libraryUri;
  }

  public boolean isExported() {
    return exported;
  }

  public boolean isObsoleteFormat() {
    // TODO(brianwilkerson) Remove this method once the obsolete format is no longer supported.
    return obsoleteFormat;
  }

  public List<ImportCombinator> getCombinators() {
    return combinators;
  }

  @Deprecated
  public DartStringLiteral getOldPrefix() {
    // TODO(brianwilkerson) Remove this method once the obsolete format is no longer supported.
    return oldPrefix;
  }

  public DartIdentifier getPrefix() {
    return prefix;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(libraryUri, visitor);
    safelyVisitChild(prefix, visitor);
    combinators.accept(visitor);
    safelyVisitChild(oldPrefix, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitImportDirective(this);
  }
}
