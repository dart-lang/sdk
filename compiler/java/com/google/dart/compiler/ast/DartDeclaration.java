// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Common supertype for most declarations. A declaration introduces a new name in a scope. Certain
 * tools, such as the IDE, need to know the location of this name, but the name should otherwise be
 * considered a part of the declaration, not an independent node. So the name is not visited when
 * traversing the AST.
 */
public abstract class DartDeclaration<N extends DartExpression> extends DartNodeWithMetadata {

  private N name; // Not visited.
  private DartComment dartDoc;
  private DartObsoleteMetadata obsoleteMetadata = DartObsoleteMetadata.EMPTY;

  protected DartDeclaration(N name) {
    this.name = becomeParentOf(name);
  }

  public final N getName() {
    return name;
  }

  public final void setName(N newName) {
    name = becomeParentOf(newName);
  }

  public DartComment getDartDoc() {
    return dartDoc;
  }

  public void setDartDoc(DartComment dartDoc) {
    // dartDoc is still parented by the containing DartUnit.
    this.dartDoc = dartDoc;
  }

  public DartObsoleteMetadata getObsoleteMetadata() {
    return obsoleteMetadata;
  }

  public void setObsoleteMetadata(DartObsoleteMetadata metadata) {
    this.obsoleteMetadata = metadata;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(dartDoc, visitor);
    super.visitChildren(visitor);
    safelyVisitChild(name, visitor);
  }
}
