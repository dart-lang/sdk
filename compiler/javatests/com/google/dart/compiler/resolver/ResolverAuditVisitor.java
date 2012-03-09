// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


package com.google.dart.compiler.resolver;

import com.google.common.base.Joiner;
import com.google.common.collect.Lists;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartParameterizedTypeNode;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.common.SourceInfo;

import java.util.List;

/**
 * Look for  DartIdentifier nodes in the tree whose elements are null.  They should all either
 * be resolved, or marked as an unresolved element.
 */
public class ResolverAuditVisitor extends ASTVisitor<Void> {
  public static void exec(DartNode root) {
    ResolverAuditVisitor visitor = new ResolverAuditVisitor();
    root.accept(visitor);
    List<String> results = visitor.getFailures();
    if (results.size() > 0) {
      StringBuilder out = new StringBuilder("Missing elements found in AST\n");
      Joiner.on("\n").appendTo(out, results);
      ResolverTestCase.fail(out.toString());
    }
  }

  private List<String> failures = Lists.newArrayList();

  public List<String> getFailures() {
    return failures;
  }

  @Override
  public Void visitClass(DartClass node) {
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitIdentifier(DartIdentifier node) {
    if (node.getElement() == null) {
      SourceInfo sourceInfo = node.getSourceInfo();
      failures.add("Identifier: "
          + node.getName()
          + " has null element @ ("
          + sourceInfo.getLine()
          + ":"
          + sourceInfo.getColumn()
          + ")");
    }
    return null;
  }

  @Override
  public Void visitParameterizedTypeNode(DartParameterizedTypeNode node) {
    node.getExpression().accept(this);
    visit(node.getTypeParameters());
    return null;
  }

  @Override
  public Void visitTypeNode(DartTypeNode node) {
    node.getIdentifier().accept(this);
    visit(node.getTypeArguments());
    return null;
  }

  @Override
  public Void visitTypeParameter(DartTypeParameter node) {
    node.getName().accept(this);
    if (node.getBound() != null) {
      node.getBound().accept(this);
    }
    return null;
  }
}