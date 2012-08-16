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
public abstract class DartDeclaration<N extends DartExpression> extends DartNode {

  private N name; // Not visited.
  private DartComment dartDoc;
  private DartObsoleteMetadata metadata = DartObsoleteMetadata.EMPTY;

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

  public DartObsoleteMetadata getMetadata() {
    return metadata;
  }

  public void setMetadata(DartObsoleteMetadata metadata) {
    this.metadata = metadata;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(name, visitor);
  }
}
