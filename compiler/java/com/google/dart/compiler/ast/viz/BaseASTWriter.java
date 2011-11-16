// Copyright (c) 2011, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast.viz;

import java.io.File;
import java.util.List;

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
import com.google.dart.compiler.ast.DartNodeTraverser;
import com.google.dart.compiler.ast.DartNullLiteral;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartParameterizedNode;
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
import com.google.dart.compiler.ast.LibraryUnit;

/**
 * Base class for the different AST dump formats
 */
public abstract class BaseASTWriter {

  private static final String[] ignoredLibs = {"corelib", "corelib_impl", "dom", "html"};
  protected final String outputDir;
  private final ASTNodeTraverser visitor;

  BaseASTWriter(String outputDir) {
    this.outputDir = outputDir;
    visitor = new ASTNodeTraverser();
  }

  private void write(String nodeType, DartNode node) {
    write(nodeType, node, "");
  }

  /**
   * Handle the write calls from the ASTNodeVisitor for a single node
   * 
   * @param nodeType - Type of node. DartNode's classname sometimes refers to inner classes. So, we
   *          pass the node type obtained from Visitor function's name.
   * @param node - The Dart node itself
   * @param data - Extra data for printing with the AST node
   */
  protected abstract void write(String nodeType, DartNode node, String data);

  // Hooks called before and after visiting tree
  protected abstract void endHook(DartUnit unit);

  protected abstract void startHook(DartUnit unit);

  /**
   * Processes a Dart Unit by visiting the parse tree
   * 
   * @param unit
   */
  public void process(DartUnit unit) {
    startHook(unit);
    unit.accept(visitor);
    endHook(unit);
  }

  /**
   * For safety, this class creates the directories required for the AST dump file
   * 
   * @param filePath - path of the AST dump file
   * @return true if directory was cleared
   */
  protected boolean makeParentDirs(String filePath) {
    int index = filePath.lastIndexOf(File.separator);
    String dirPath = filePath.substring(0, index);
    return new File(dirPath).mkdirs();
  }

  /**
   * Handle visit of children. Specialized classes override functionality to track parent-child
   * relationship here.
   * 
   * @param node
   */
  protected void visitChildren(DartNode node) {
    node.visitChildren(visitor);
  }

  boolean isIgnored(DartUnit unit) {
    LibraryUnit lu = unit.getLibrary();
    if (lu != null) {
      String libName = lu.getName();
      for (String ignoredLib : ignoredLibs) {
        if (ignoredLib.equals(libName)) {
          return true;
        }
      }
    }
    return false;
  }

  class ASTNodeTraverser extends DartNodeTraverser<Object> {

    @Override
    public void visit(List<? extends DartNode> nodes) {
      if (nodes != null)
        for (DartNode node : nodes) {
          node.accept(this);
        }
    }

    @Override
    public Object visitArrayAccess(DartArrayAccess node) {
      write("DartArrayAccess", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitArrayLiteral(DartArrayLiteral node) {
      write("DartArrayLiteral", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitAssertion(DartAssertion node) {
      write("DartAssertion", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitBinaryExpression(DartBinaryExpression node) {
      write("DartBinaryExpression", node, node.getOperator().name());
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitBlock(DartBlock node) {
      write("DartBlock", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitBooleanLiteral(DartBooleanLiteral node) {
      write("DartBooleanLiteral", node, new Boolean(node.getValue()).toString());
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitBreakStatement(DartBreakStatement node) {
      write("DartBreakStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitFunctionObjectInvocation(DartFunctionObjectInvocation node) {
      write("DartFunctionObjectInvocation", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitMethodInvocation(DartMethodInvocation node) {
      write("DartMethodInvocation", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitSuperConstructorInvocation(DartSuperConstructorInvocation node) {
      write("DartSuperConstructorInvocation", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitCase(DartCase node) {
      write("DartCase", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitClass(DartClass node) {
      String type = "class ";
      if (node.isInterface()) {
        type = "interface ";
      }
      write("DartClass", node, type + node.getClassName());
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitConditional(DartConditional node) {
      write("DartConditional", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitContinueStatement(DartContinueStatement node) {
      write("DartContinueStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitDefault(DartDefault node) {
      write("DartDefault", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitDoubleLiteral(DartDoubleLiteral node) {
      write("DartDoubleLiteral", node, new Double(node.getValue()).toString());
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitDoWhileStatement(DartDoWhileStatement node) {
      write("DartDoWhileStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitEmptyStatement(DartEmptyStatement node) {
      write("DartEmptyStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitExprStmt(DartExprStmt node) {
      write("DartExprStmt", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitField(DartField node) {
      write("DartField", node, node.getName().getTargetName());
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitFieldDefinition(DartFieldDefinition node) {
      write("DartFieldDefinition", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitForInStatement(DartForInStatement node) {
      write("DartForInStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitForStatement(DartForStatement node) {
      write("DartForStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitFunction(DartFunction node) {
      write("DartFunction", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitFunctionExpression(DartFunctionExpression node) {
      write("DartFunctionExpression", node);
      return null;
    }

    @Override
    public Object visitFunctionTypeAlias(DartFunctionTypeAlias node) {
      write("DartFunctionTypeAlias", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitIdentifier(DartIdentifier node) {
      write("DartIdentifier", node, node.getTargetName());
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitIfStatement(DartIfStatement node) {
      write("DartIfStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitImportDirective(DartImportDirective node) {
      write("DartImportDirective", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitInitializer(DartInitializer node) {
      write("DartInitializer", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitIntegerLiteral(DartIntegerLiteral node) {
      write("DartIntegerLiteral", node, node.getValue().toString());
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitLabel(DartLabel node) {
      write("DartLabel", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitLibraryDirective(DartLibraryDirective node) {
      write("DartLibraryDirective", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitMapLiteral(DartMapLiteral node) {
      write("DartMapLiteral", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitMapLiteralEntry(DartMapLiteralEntry node) {
      write("DartMapLiteralEntry", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitMethodDefinition(DartMethodDefinition node) {
      write("DartMethodDefinition", node, node.getName().toString());
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitNativeDirective(DartNativeDirective node) {
      write("DartNativeDirective", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitNewExpression(DartNewExpression node) {
      write("DartNewExpression", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitNullLiteral(DartNullLiteral node) {
      write("DartNullLiteral", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitParameter(DartParameter node) {
      write("DartParameter", node, node.getParameterName());
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitParameterizedNode(DartParameterizedNode node) {
      write("DartParameterizedNode", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitParenthesizedExpression(DartParenthesizedExpression node) {
      write("DartParenthesizedExpression", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitPropertyAccess(DartPropertyAccess node) {
      write("DartPropertyAccess", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitTypeNode(DartTypeNode node) {
      write("DartTypeNode", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitResourceDirective(DartResourceDirective node) {
      write("DartResourceDirective", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitReturnStatement(DartReturnStatement node) {
      write("DartReturnStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitSourceDirective(DartSourceDirective node) {
      write("DartSourceDirective", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitStringLiteral(DartStringLiteral node) {
      write("DartStringLiteral", node, '"' + node.getValue() + '"');
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitStringInterpolation(DartStringInterpolation node) {
      write("DartStringInterpolation", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitSuperExpression(DartSuperExpression node) {
      write("DartSuperExpression", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitSwitchStatement(DartSwitchStatement node) {
      write("DartSwitchStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitSyntheticErrorExpression(DartSyntheticErrorExpression node) {
      write("DartSyntheticErrorExpression", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitSyntheticErrorStatement(DartSyntheticErrorStatement node) {
      write("DartSyntheticErrorStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitThisExpression(DartThisExpression node) {
      write("DartThisExpression", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitThrowStatement(DartThrowStatement node) {
      write("DartThrowStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitCatchBlock(DartCatchBlock node) {
      write("DartCatchBlock", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitTryStatement(DartTryStatement node) {
      write("DartTryStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitUnaryExpression(DartUnaryExpression node) {
      write("DartUnaryExpression", node, node.getOperator().name());
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitUnit(DartUnit node) {
      if (!isIgnored(node)) {
        visitChildren(node);
      }
      return null;
    }

    @Override
    public Object visitUnqualifiedInvocation(DartUnqualifiedInvocation node) {
      write("DartUnqualifiedInvocation", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitVariable(DartVariable node) {
      write("DartVariable", node, node.getVariableName());
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitVariableStatement(DartVariableStatement node) {
      write("DartVariableStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitWhileStatement(DartWhileStatement node) {
      write("DartWhileStatement", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitNamedExpression(DartNamedExpression node) {
      write("DartNamedExpression", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitTypeExpression(DartTypeExpression node) {
      write("DartTypeExpression", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitTypeParameter(DartTypeParameter node) {
      write("DartTypeParameter", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitNativeBlock(DartNativeBlock node) {
      write("DartNativeBlock", node);
      visitChildren(node);
      return null;
    }

    @Override
    public Object visitRedirectConstructorInvocation(DartRedirectConstructorInvocation node) {
      write("DartRedirectConstructorInvocation", node);
      visitChildren(node);
      return null;
    }
  }
}
