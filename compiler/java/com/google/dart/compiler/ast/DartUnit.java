// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.collect.Sets;
import com.google.dart.compiler.DartSource;

import java.util.List;
import java.util.Set;

/**
 * Represents a Dart compilation unit.
 */
public class DartUnit extends DartNode {

  @SuppressWarnings("unused")
  private static final long serialVersionUID = -3407637869012712127L;

  private LibraryUnit library;
  private final NodeList<DartDirective> directives = NodeList.create(this);
  private final NodeList<DartNode> topLevelNodes = NodeList.create(this);
  private final NodeList<DartComment> comments = NodeList.create(this);
  private final DartSource source;
  private final boolean isDiet;

  public DartUnit(DartSource source, boolean isDiet) {
    this.source = source;
    this.isDiet = isDiet;
  }

  public String getSourceName() {
    return source.getName();
  }

  public List<DartComment> getComments() {
    return comments;
  }

  public void setLibrary(LibraryUnit library) {
    this.library = library;
  }

  public LibraryUnit getLibrary() {
    return library;
  }

  public List<DartNode> getTopLevelNodes() {
    return topLevelNodes;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    directives.accept(visitor);
    topLevelNodes.accept(visitor);
    comments.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitUnit(this);
  }

  /**
   * Whether this is an diet unit, meaning it contains no method bodies.
   */
  public boolean isDiet() {
    return isDiet;
  }

  /**
   * Answer the receiver's directives, not <code>null</code>.
   */
  public List<DartDirective> getDirectives() {
    return directives;
  }

  /**
   * @return the names of top-level declarations.
   */
  public Set<String> getTopDeclarationNames() {
    Set<String> topLevelSymbols = Sets.newHashSet();
    for (DartNode node : getTopLevelNodes()) {
      if (node instanceof DartClass) {
        DartIdentifier name = ((DartClass) node).getName();
        topLevelSymbols.add(name.getName());
      }
      if (node instanceof DartFunctionTypeAlias) {
        DartIdentifier name = ((DartFunctionTypeAlias) node).getName();
        topLevelSymbols.add(name.getName());
      }
      if (node instanceof DartMethodDefinition) {
        DartExpression name = ((DartMethodDefinition) node).getName();
        if (name instanceof DartIdentifier) {
          topLevelSymbols.add(((DartIdentifier) name).getName());
        }
      }
      if (node instanceof DartFieldDefinition) {
        DartFieldDefinition fieldDefinition = (DartFieldDefinition) node;
        List<DartField> fields = fieldDefinition.getFields();
        for (DartField variable : fields) {
          topLevelSymbols.add(variable.getName().getName());
        }
      }
    }
    return topLevelSymbols;
  }

  /**
   * @return the {@link Set} of names of all declarations.
   */
  public Set<String> getDeclarationNames() {
    final Set<String> symbols = Sets.newHashSet();
    accept(new ASTVisitor<Void>() {
      @Override
      public Void visitFunctionTypeAlias(DartFunctionTypeAlias node) {
        symbols.add(node.getName().getName());
        return super.visitFunctionTypeAlias(node);
      }

      @Override
      public Void visitClass(DartClass node) {
        symbols.add(node.getClassName());
        return super.visitClass(node);
      }

      @Override
      public Void visitTypeParameter(DartTypeParameter node) {
        symbols.add(node.getName().getName());
        return super.visitTypeParameter(node);
      }

      @Override
      public Void visitField(DartField node) {
        symbols.add(node.getName().getName());
        return super.visitField(node);
      }

      @Override
      public Void visitMethodDefinition(DartMethodDefinition node) {
        if (node.getName() instanceof DartIdentifier) {
          symbols.add(((DartIdentifier) node.getName()).getName());
        }
        return super.visitMethodDefinition(node);
      }

      @Override
      public Void visitParameter(DartParameter node) {
        symbols.add(node.getParameterName());
        return super.visitParameter(node);
      }

      @Override
      public Void visitVariable(DartVariable node) {
        symbols.add(node.getVariableName());
        return super.visitVariable(node);
      }
    });
    return symbols;
  }
}