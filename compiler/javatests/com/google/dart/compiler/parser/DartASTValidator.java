// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartArrayAccess;
import com.google.dart.compiler.ast.DartArrayLiteral;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartBooleanLiteral;
import com.google.dart.compiler.ast.DartBreakStatement;
import com.google.dart.compiler.ast.DartCase;
import com.google.dart.compiler.ast.DartCatchBlock;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartConditional;
import com.google.dart.compiler.ast.DartContinueStatement;
import com.google.dart.compiler.ast.DartDefault;
import com.google.dart.compiler.ast.DartDoWhileStatement;
import com.google.dart.compiler.ast.DartDoubleLiteral;
import com.google.dart.compiler.ast.DartEmptyStatement;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartForInStatement;
import com.google.dart.compiler.ast.DartForStatement;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionObjectInvocation;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartIfStatement;
import com.google.dart.compiler.ast.DartImportDirective;
import com.google.dart.compiler.ast.DartInitializer;
import com.google.dart.compiler.ast.DartIntegerLiteral;
import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartLibraryDirective;
import com.google.dart.compiler.ast.DartMapLiteral;
import com.google.dart.compiler.ast.DartMapLiteralEntry;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartNamedExpression;
import com.google.dart.compiler.ast.DartNativeBlock;
import com.google.dart.compiler.ast.DartNativeDirective;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartNullLiteral;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartParameterizedTypeNode;
import com.google.dart.compiler.ast.DartParenthesizedExpression;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartRedirectConstructorInvocation;
import com.google.dart.compiler.ast.DartResourceDirective;
import com.google.dart.compiler.ast.DartReturnStatement;
import com.google.dart.compiler.ast.DartSourceDirective;
import com.google.dart.compiler.ast.DartStringInterpolation;
import com.google.dart.compiler.ast.DartStringLiteral;
import com.google.dart.compiler.ast.DartSuperConstructorInvocation;
import com.google.dart.compiler.ast.DartSuperExpression;
import com.google.dart.compiler.ast.DartSwitchStatement;
import com.google.dart.compiler.ast.DartSyntheticErrorExpression;
import com.google.dart.compiler.ast.DartSyntheticErrorStatement;
import com.google.dart.compiler.ast.DartThisExpression;
import com.google.dart.compiler.ast.DartThrowStatement;
import com.google.dart.compiler.ast.DartTryStatement;
import com.google.dart.compiler.ast.DartTypeExpression;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnaryExpression;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.DartVariableStatement;
import com.google.dart.compiler.ast.DartWhileStatement;

import junit.framework.Assert;

import java.util.ArrayList;
import java.util.List;

public class DartASTValidator extends ASTVisitor<Void> {

  private ArrayList<String> errors = new ArrayList<String>();

  public void assertValid() {
    if (!errors.isEmpty()) {
      StringBuilder builder = new StringBuilder();
      builder.append("Invalid AST structure:");
      for (String message : errors) {
        builder.append("\r\n   ");
        builder.append(message);
      }
      Assert.fail(builder.toString());
    }
  }

  @Override
  public void visit(List<? extends DartNode> nodes) {
    if (nodes != null) {
      int previousEnd = -1;
      for (DartNode node : nodes) {
        int start = node.getSourceInfo().getOffset();
        if (start <= previousEnd) {
          errors.add("Node starts (" + start + ") before previous sibling's end (" + previousEnd
              + ") or nodes are not in source order");
        }
        node.accept(this);
        previousEnd = start + node.getSourceInfo().getLength() - 1;
      }
    }
  }

  @Override
  public Void visitArrayAccess(DartArrayAccess node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitArrayLiteral(DartArrayLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitBinaryExpression(DartBinaryExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitBlock(DartBlock node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitBooleanLiteral(DartBooleanLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitBreakStatement(DartBreakStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitCase(DartCase node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitCatchBlock(DartCatchBlock node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitClass(DartClass node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitConditional(DartConditional node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitContinueStatement(DartContinueStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitDefault(DartDefault node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitDoubleLiteral(DartDoubleLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitDoWhileStatement(DartDoWhileStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitEmptyStatement(DartEmptyStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitExprStmt(DartExprStmt node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitFieldDefinition(DartFieldDefinition node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitField(DartField node) {
    validate(node);
    node.visitChildren(this);
    node.getName().accept(this);
    return null;
  }

  @Override
  public Void visitForInStatement(DartForInStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitForStatement(DartForStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitFunction(DartFunction node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitFunctionExpression(DartFunctionExpression node) {
    validate(node);
    DartIdentifier name = node.getName();
    if (name != null) {
      name.accept(this);
    }
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitFunctionObjectInvocation(DartFunctionObjectInvocation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitFunctionTypeAlias(DartFunctionTypeAlias node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitIdentifier(DartIdentifier node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitIfStatement(DartIfStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitImportDirective(DartImportDirective node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitInitializer(DartInitializer node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitIntegerLiteral(DartIntegerLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitLabel(DartLabel node) {
    validate(node);
    node.getLabel().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitLibraryDirective(DartLibraryDirective node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitMapLiteral(DartMapLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitMapLiteralEntry(DartMapLiteralEntry node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitMethodDefinition(DartMethodDefinition node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitMethodInvocation(DartMethodInvocation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitNativeBlock(DartNativeBlock node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitNativeDirective(DartNativeDirective node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitNewExpression(DartNewExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitNullLiteral(DartNullLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitParameter(DartParameter node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitParenthesizedExpression(DartParenthesizedExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitPropertyAccess(DartPropertyAccess node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitResourceDirective(DartResourceDirective node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitReturnStatement(DartReturnStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitSourceDirective(DartSourceDirective node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitNamedExpression(DartNamedExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitStringInterpolation(DartStringInterpolation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitStringLiteral(DartStringLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitSuperConstructorInvocation(
      DartSuperConstructorInvocation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitSuperExpression(DartSuperExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitSwitchStatement(DartSwitchStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitSyntheticErrorExpression(DartSyntheticErrorExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitSyntheticErrorStatement(DartSyntheticErrorStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitThisExpression(DartThisExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitThrowStatement(DartThrowStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitTryStatement(DartTryStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitTypeExpression(DartTypeExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitTypeNode(DartTypeNode node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitTypeParameter(DartTypeParameter node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitUnaryExpression(DartUnaryExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitUnit(DartUnit node) {
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitUnqualifiedInvocation(DartUnqualifiedInvocation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitVariable(DartVariable node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitVariableStatement(DartVariableStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitWhileStatement(DartWhileStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Void visitRedirectConstructorInvocation(DartRedirectConstructorInvocation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  private void validate(DartNode node) {
    DartNode parent = node.getParent();
    if (parent == null) {
      errors.add("No parent for " + node.getClass().getName());
    }

    int nodeStart = node.getSourceInfo().getOffset();
    int nodeLength = node.getSourceInfo().getLength();
    if (nodeStart < 0 || nodeLength < 0) {
      errors.add("No source info for " + node.getClass().getName());
    }

    if (parent != null) {
      int nodeEnd = nodeStart + nodeLength;
      int parentStart = parent.getSourceInfo().getOffset();
      int parentEnd = parentStart + parent.getSourceInfo().getLength();
      if (parentStart > nodeStart) {
        errors.add("Invalid source start (" + nodeStart + ") for "
            + node.getClass().getName() + " inside "
            + parent.getClass().getName() + " (" + parentStart + ")");
      }
      if (nodeEnd > parentEnd) {
        errors.add("Invalid source end (" + nodeEnd + ") for "
            + node.getClass().getName() + " inside "
            + parent.getClass().getName() + " (" + parentStart + ")");
      }
    }

    if (node instanceof DartSyntheticErrorExpression
        || node instanceof DartSyntheticErrorExpression) {
      errors.add("Parser error at (" + nodeStart + ")");
    }
  }

  @Override
  public Void visitParameterizedTypeNode(DartParameterizedTypeNode node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }
}
