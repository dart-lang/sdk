// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.util.DefaultTextOutput;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Represents a Dart compilation unit.
 */
public class DartUnit extends DartNode {

  private static final long serialVersionUID = -3407637869012712127L;

  private LibraryUnit library;
  private List<DartDirective> directives;
  private final List<DartNode> topLevelNodes;
  private final DartSource source;
  /** A list of comments. May be null. */
  private List<DartComment> comments;
  private boolean isDiet;
  private String dietParse;

  public DartUnit(DartSource sourceName) {
    this(sourceName, new ArrayList<DartNode>());
  }

  public DartUnit(DartSource source,
                  List<DartNode> nodes) {
    this.source = source;
    this.topLevelNodes = becomeParentOf(nodes);
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
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      if (directives != null) {
        v.acceptWithInsertRemove(this, directives);
      }
      v.acceptWithInsertRemove(this, topLevelNodes);
      if (comments != null) {
        v.acceptWithInsertRemove(this, comments);
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (directives != null) {
      visitor.visit(directives);
    }
    visitor.visit(topLevelNodes);
    if (comments != null) {
      visitor.visit(comments);
    }
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitUnit(this);
  }

  /**
   * Sets this unit to be a diet unit, meaning it contains no method bodies.
   */
  public void setDiet(boolean isDiet) {
    this.isDiet = isDiet;
  }

  /**
   * Whether this is an diet unit, meaning it contains no method bodies.
   */
  public boolean isDiet() {
    return isDiet;
  }

  /**
   * Generates a diet version of this unit, which contains no method bodies.
   */
  public final String toDietSource() {
    if (dietParse == null) {
      DefaultTextOutput out = new DefaultTextOutput(false);
      new DartToSourceVisitor(out, true).accept(this);
      dietParse = out.toString();
    }
    return dietParse;
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
    return directives;
  }
}
