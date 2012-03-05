// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.collect.Lists;
import com.google.common.collect.Sets;
import com.google.dart.compiler.DartSource;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;

/**
 * Represents a Dart compilation unit.
 */
public class DartUnit extends DartNode {

  private static final long serialVersionUID = -3407637869012712127L;

  private LibraryUnit library;
  private List<DartDirective> directives;
  private final List<DartNode> topLevelNodes = Lists.newArrayList();
  private final DartSource source;
  private final boolean isDiet;
  /** A list of comments. May be null. */
  private List<DartComment> comments;

  public DartUnit(DartSource source, boolean isDiet) {
    this.source = source;
    this.isDiet = isDiet;
  }

  public void addTopLevelNode(DartNode node) {
    topLevelNodes.add(becomeParentOf(node));
  }

  public String getSourceName() {
    return source.getName();
  }

  @Override
  public DartSource getSource() {
    return source;
  }

  public void addComment(DartComment comment) {
    if (comments == null) {
      comments = new ArrayList<DartComment>();
    }
    comments.add(becomeParentOf(comment));
  }

  public List<DartComment> getComments() {
    return comments == null ? null : Collections.unmodifiableList(comments);
  }

  public boolean removeComment(DartComment comment) {
    return comments == null ? false : comments.remove(comment);
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
    if (directives != null) {
      visitor.visit(directives);
    }
    visitor.visit(topLevelNodes);
    if (comments != null) {
      visitor.visit(comments);
    }
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
   * Add the specified directive to the receiver's list of directives
   */
  public void addDirective(DartDirective directive) {
    if (directives == null) {
      directives = new ArrayList<DartDirective>();
    }
    directives.add(becomeParentOf(directive));
  }

  /**
   * Answer the receiver's directives or <code>null</code> if none
   */
  public List<DartDirective> getDirectives() {
    if (directives == null) {
      return Collections.<DartDirective> emptyList();
    }
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
        topLevelSymbols.add(name.getTargetName());
      }
      if (node instanceof DartFunctionTypeAlias) {
        DartIdentifier name = ((DartFunctionTypeAlias) node).getName();
        topLevelSymbols.add(name.getTargetName());
      }
      if (node instanceof DartMethodDefinition) {
        DartExpression name = ((DartMethodDefinition) node).getName();
        if (name instanceof DartIdentifier) {
          topLevelSymbols.add(((DartIdentifier) name).getTargetName());
        }
      }
      if (node instanceof DartFieldDefinition) {
        DartFieldDefinition fieldDefinition = (DartFieldDefinition) node;
        List<DartField> fields = fieldDefinition.getFields();
        for (DartField variable : fields) {
          topLevelSymbols.add(variable.getName().getTargetName());
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
        symbols.add(node.getName().getTargetName());
        return super.visitFunctionTypeAlias(node);
      }

      @Override
      public Void visitClass(DartClass node) {
        symbols.add(node.getClassName());
        return super.visitClass(node);
      }

      @Override
      public Void visitTypeParameter(DartTypeParameter node) {
        symbols.add(node.getName().getTargetName());
        return super.visitTypeParameter(node);
      }

      @Override
      public Void visitField(DartField node) {
        symbols.add(node.getName().getTargetName());
        return super.visitField(node);
      }

      @Override
      public Void visitMethodDefinition(DartMethodDefinition node) {
        if (node.getName() instanceof DartIdentifier) {
          symbols.add(((DartIdentifier) node.getName()).getTargetName());
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