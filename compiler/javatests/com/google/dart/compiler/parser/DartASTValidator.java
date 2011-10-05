// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.ast.DartArrayAccess;
import com.google.dart.compiler.ast.DartArrayLiteral;
import com.google.dart.compiler.ast.DartAssertion;
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
import com.google.dart.compiler.ast.DartParameterizedNode;
import com.google.dart.compiler.ast.DartParenthesizedExpression;
import com.google.dart.compiler.ast.DartPlainVisitor;
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
import com.google.dart.compiler.type.Type;

import junit.framework.Assert;

import java.util.ArrayList;
import java.util.List;

public class DartASTValidator implements DartPlainVisitor<Object> {

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
        int start = node.getSourceStart();
        if (start <= previousEnd) {
          errors.add("Node starts (" + start + ") before previous sibling's end (" + previousEnd
              + ") or nodes are not in source order");
        }
        node.accept(this);
        previousEnd = start + node.getSourceLength() - 1;
      }
    }
  }

  @Override
  public Object visitArrayAccess(DartArrayAccess node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitArrayLiteral(DartArrayLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitAssertion(DartAssertion node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitBinaryExpression(DartBinaryExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitBlock(DartBlock node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitBooleanLiteral(DartBooleanLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitBreakStatement(DartBreakStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitCase(DartCase node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitCatchBlock(DartCatchBlock node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitClass(DartClass node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitConditional(DartConditional node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitContinueStatement(DartContinueStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitDefault(DartDefault node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitDoubleLiteral(DartDoubleLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitDoWhileStatement(DartDoWhileStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitEmptyStatement(DartEmptyStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitExprStmt(DartExprStmt node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitFieldDefinition(DartFieldDefinition node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitField(DartField node) {
    validate(node);
    node.visitChildren(this);
    node.getName().accept(this);
    return null;
  }

  @Override
  public Object visitForInStatement(DartForInStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitForStatement(DartForStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitFunction(DartFunction node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitFunctionExpression(DartFunctionExpression node) {
    validate(node);
    DartIdentifier name = node.getName();
    if (name != null) {
      name.accept(this);
    }
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitFunctionObjectInvocation(DartFunctionObjectInvocation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitFunctionTypeAlias(DartFunctionTypeAlias node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitIdentifier(DartIdentifier node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitIfStatement(DartIfStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitImportDirective(DartImportDirective node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitInitializer(DartInitializer node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitIntegerLiteral(DartIntegerLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitLabel(DartLabel node) {
    validate(node);
    node.getLabel().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitLibraryDirective(DartLibraryDirective node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitMapLiteral(DartMapLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitMapLiteralEntry(DartMapLiteralEntry node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitMethodDefinition(DartMethodDefinition node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitMethodInvocation(DartMethodInvocation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitNativeBlock(DartNativeBlock node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitNativeDirective(DartNativeDirective node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitNewExpression(DartNewExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitNullLiteral(DartNullLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitParameter(DartParameter node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitParenthesizedExpression(DartParenthesizedExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitPropertyAccess(DartPropertyAccess node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitResourceDirective(DartResourceDirective node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitReturnStatement(DartReturnStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitSourceDirective(DartSourceDirective node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitNamedExpression(DartNamedExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitStringInterpolation(DartStringInterpolation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitStringLiteral(DartStringLiteral node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitSuperConstructorInvocation(
      DartSuperConstructorInvocation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitSuperExpression(DartSuperExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitSwitchStatement(DartSwitchStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Type visitSyntheticErrorExpression(DartSyntheticErrorExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Type visitSyntheticErrorStatement(DartSyntheticErrorStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitThisExpression(DartThisExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitThrowStatement(DartThrowStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitTryStatement(DartTryStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitTypeExpression(DartTypeExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitTypeNode(DartTypeNode node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitTypeParameter(DartTypeParameter node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitUnaryExpression(DartUnaryExpression node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitUnit(DartUnit node) {
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitUnqualifiedInvocation(DartUnqualifiedInvocation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitVariable(DartVariable node) {
    validate(node);
    node.getName().accept(this);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitVariableStatement(DartVariableStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitWhileStatement(DartWhileStatement node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  @Override
  public Object visitRedirectConstructorInvocation(DartRedirectConstructorInvocation node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }

  private void validate(DartNode node) {
    DartNode parent = node.getParent();
    if (parent == null) {
      errors.add("No parent for " + node.getClass().getName());
    }

    int nodeStart = node.getSourceStart();
    int nodeLength = node.getSourceLength();
    if (nodeStart < 0 || nodeLength < 0) {
      errors.add("No source info for " + node.getClass().getName());
    }

    if (parent != null) {
      int nodeEnd = nodeStart + nodeLength;
      int parentStart = parent.getSourceStart();
      int parentEnd = parentStart + parent.getSourceLength();
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
  public Object visitParameterizedNode(DartParameterizedNode node) {
    validate(node);
    node.visitChildren(this);
    return null;
  }
}
