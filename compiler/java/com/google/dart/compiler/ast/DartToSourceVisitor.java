// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.util.TextOutput;

import java.util.Iterator;
import java.util.List;

/**
 * Used by {@link DartNode} to generate Dart source from an AST subtree.
 */
public class DartToSourceVisitor extends ASTVisitor<Void> {

  private final TextOutput out;

  public DartToSourceVisitor(TextOutput out) {
    this.out = out;
  }

  @Override
  public Void visitUnit(DartUnit x) {
    p("// unit " + x.getSourceName());
    nl();
    return super.visitUnit(x);
  }

  @Override
  public Void visitComment(DartComment node) {
    return null;
  }

  @Override
  public Void visitNativeBlock(DartNativeBlock x) {
    p("native;");
    return null;
  }

  private void accept(DartNode x) {
    x.accept(this);
  }

  private void acceptList(List<? extends DartNode> xs) {
    for (DartNode x : xs) {
      x.accept(this);
    }
  }

  private void pTypeParameters(List<DartTypeParameter> typeParameters) {
    if (typeParameters != null && !typeParameters.isEmpty()) {
      p("<");
      boolean first = true;
      for (DartNode node : typeParameters) {
        if (!first) {
          p(", ");
        }
        accept(node);
        first = false;
      }
      p(">");
    }
  }

  @Override
  public Void visitLibraryDirective(DartLibraryDirective node) {
    if (node.isObsoleteFormat()) {
      p("#library(");
      accept(node.getName());
      p(");");
      nl();
    } else {
      p("library ");
      accept(node.getName());
      p(";");
      nl();
    }
    return null;
  }

  @SuppressWarnings("deprecation")
  @Override
  public Void visitImportDirective(DartImportDirective node) {
    if (node.isObsoleteFormat()) {
      p("#import(");
      accept(node.getLibraryUri());
      if (node.getOldPrefix() != null) {
        p(", prefix : ");
        accept(node.getOldPrefix());
      }
      p(");");
      nl();
    } else {
      p("import ");
      accept(node.getLibraryUri());
      if (node.getPrefix() != null) {
        p(" as ");
        accept(node.getPrefix());
      }
      for (ImportCombinator combinator : node.getCombinators()) {
        accept(combinator);
      }
      if (node.isExported()) {
        p(" & export");
      }
      p(";");
      nl();
    }
    return null;
  }

  @Override
  public Void visitFunctionTypeAlias(DartFunctionTypeAlias x) {
    p("typedef ");

    if (x.getReturnTypeNode() != null) {
      accept(x.getReturnTypeNode());
    }

    p(" ");
    accept(x.getName());
    pTypeParameters(x.getTypeParameters());

    p("(");
    printSeparatedByComma(x.getParameters());
    p(")");

    p(";");
    nl();
    nl();
    return null;
  }

  @Override
  public Void visitClass(DartClass x) {
    if (x.isInterface()) {
      p("interface ");
    } else {
      p("class ");
    }
    accept(x.getName());
    pTypeParameters(x.getTypeParameters());

    if (x.getSuperclass() != null) {
      p(" extends ");
      accept(x.getSuperclass());
    }

    List<DartTypeNode> interfaces = x.getInterfaces();
    if (interfaces != null && !interfaces.isEmpty()) {
      if (x.isInterface()) {
        p(" extends ");
      } else {
        p(" implements ");
      }
      boolean first = true;
      for (DartTypeNode cls : interfaces) {
        if (!first) {
          p(", ");
        }
        accept(cls);
        first = false;
      }
    }

    if (x.getNativeName() != null) {
      p(" native ");
      accept(x.getNativeName());
    }

    if (x.getDefaultClass() != null) {
      p(" default ");
      accept(x.getDefaultClass());
    }

    p(" {");
    nl();
    indent();

    acceptList(x.getMembers());

    outdent();
    p("}");
    nl();
    nl();
    return null;
  }

  @Override
  public Void visitTypeNode(DartTypeNode x) {
    accept(x.getIdentifier());
    List<DartTypeNode> arguments = x.getTypeArguments();
    if (arguments != null && !arguments.isEmpty()) {
      p("<");
      printSeparatedByComma(arguments);
      p(">");
    }
    return null;
  }

  @Override
  public Void visitTypeParameter(DartTypeParameter x) {
    accept(x.getName());
    DartTypeNode bound = x.getBound();
    if (bound != null) {
      p(" extends ");
      accept(bound);
    }
    return null;
  }

  @Override
  public Void visitFieldDefinition(DartFieldDefinition x) {
    Modifiers modifiers = x.getFields().get(0).getModifiers();
    if (modifiers.isAbstractField()) {
      pAbstractField(x);
    } else {
      pFieldModifiers(x);
      if (x.getTypeNode() != null) {
        accept(x.getTypeNode());
        p(" ");
      } else {
        if (!modifiers.isFinal()) {
          p("var ");
        }
      }
      printSeparatedByComma(x.getFields());
      p(";");
    }

    nl();

    return null;
  }

  @Override
  public Void visitField(DartField x) {
    accept(x.getName());
    if (x.getValue() != null) {
      p(" = ");
      accept(x.getValue());
    }
    return null;
  }

  @Override
  public Void visitParameter(DartParameter x) {
    if (x.getModifiers().isFinal()) {
      p("final ");
    }
    if (x.getTypeNode() != null) {
      accept(x.getTypeNode());
      p(" ");
    }
    accept(x.getName());
    if (x.getFunctionParameters() != null) {
      p("(");
      printSeparatedByComma(x.getFunctionParameters());
      p(")");
    }
    if (x.getDefaultExpr() != null) {
      if (x.getModifiers().isOptional()) {
        p(" = ");
      }
      if (x.getModifiers().isNamed()) {
        p(" : ");
      }
      accept(x.getDefaultExpr());
    }
    return null;
  }

  @Override
  public Void visitMethodDefinition(DartMethodDefinition x) {
    nl();
    pMethodModifiers(x);
    // return type
    DartFunction func = x.getFunction();
    if (func.getReturnTypeNode() != null) {
      accept(func.getReturnTypeNode());
      p(" ");
    }
    // special methods
    if (x.getModifiers().isOperator()) {
      p("operator ");
    } else if (x.getModifiers().isGetter()) {
      p("get ");
    } else if (x.getModifiers().isSetter()) {
      p("set ");
    }
    // name
    pFunctionDeclaration(x.getName(), func, !x.getModifiers().isGetter());
    p(" ");
    // initializers
    List<DartInitializer> inits = x.getInitializers();
    if (!inits.isEmpty()) {
      p(": ");
      for (int i = 0; i < inits.size(); ++i) {
        accept(inits.get(i));
        if (i < inits.size() - 1) {
          p(", ");
        }
      }
    }
    // body
    if (x.getFunction().getBody() != null) {
      accept(x.getFunction().getBody());
    } else if (x.getRedirectedTypeName() != null) {
      p(" = ");
      accept(x.getRedirectedTypeName());
      if (x.getRedirectedConstructorName() != null) {
        p(".");
        accept(x.getRedirectedConstructorName());
      }
      p(";");
      nl();
    } else {
      p(";");
      nl();
    }
    // done
    return null;
  }

  @Override
  public Void visitInitializer(DartInitializer x) {
    if (!x.isInvocation()) {
      p("this.");
      p(x.getInitializerName());
      p(" = ");
    }
    accept(x.getValue());
    return null;
  }

  private void pBlock(DartBlock x, boolean newline) {
    p("{");
    nl();

    indent();
    acceptList(x.getStatements());
    outdent();

    p("}");
    if (newline) {
      nl();
    }
  }

  private void pFunctionDeclaration(DartNode name, DartFunction x, boolean includeParameters) {
    if (name != null) {
      accept(name);
    }
    if (includeParameters) {
      p("(");
      pFormalParameters(x.getParameters());
      p(")");
    }
  }

  private void pFormalParameters(List<DartParameter> params) {
    boolean first = true, hasPositional = false, hasNamed = false;
    for (DartParameter param : params) {
      if (!first) {
        p(", ");
      }
      if (!hasPositional && param.getModifiers().isOptional()) {
        hasPositional = true;
        p("[");
      }
      if (!hasNamed && param.getModifiers().isNamed()) {
        hasNamed = true;
        p("{");
      }
      accept(param);
      first = false;
    }
    if (hasPositional) {
      p("]");
    }
    if (hasNamed) {
      p("}");
    }
  }
  
  @Override
  public Void visitAssertStatement(DartAssertStatement x) {
    p("assert(");
    accept(x.getCondition());
    p(");");
    return null;
  }

  @Override
  public Void visitBlock(DartBlock x) {
    pBlock(x, true);
    return null;
  }

  @Override
  public Void visitIfStatement(DartIfStatement x) {
    p("if (");
    accept(x.getCondition());
    p(") ");
    pIfBlock(x.getThenStatement(), x.getElseStatement() == null);
    if (x.getElseStatement() != null) {
      p(" else ");
      pIfBlock(x.getElseStatement(), true);
    }
    return null;
  }

  @Override
  public Void visitSwitchStatement(DartSwitchStatement x) {
    p("switch (");
    accept(x.getExpression());
    p(") {");
    nl();

    indent();
    acceptList(x.getMembers());
    outdent();

    p("}");
    nl();
    return null;
  }

  @Override
  public Void visitCase(DartCase x) {
    p("case ");
    accept(x.getExpr());
    p(":");
    nl();
    indent();
    acceptList(x.getStatements());
    outdent();
    return null;
  }

  @Override
  public Void visitDefault(DartDefault x) {
    p("default:");
    nl();
    indent();
    acceptList(x.getStatements());
    outdent();
    return null;
  }

  @Override
  public Void visitWhileStatement(DartWhileStatement x) {
    p("while (");
    accept(x.getCondition());
    p(") ");
    pIfBlock(x.getBody(), true);
    return null;
  }

  @Override
  public Void visitDoWhileStatement(DartDoWhileStatement x) {
    p("do ");
    pIfBlock(x.getBody(), false);
    p(" while (");
    accept(x.getCondition());
    p(");");
    nl();
    return null;
  }

  @Override
  public Void visitForStatement(DartForStatement x) {
    p("for (");

    // Setup
    DartStatement setup = x.getInit();
    if (setup != null) {
      if (setup instanceof DartVariableStatement) {
        // Special case to avoid an extra semicolon & newline after the var
        // statement.
        p("var ");
        printSeparatedByComma(((DartVariableStatement) setup).getVariables());
      } else {
        // Plain old expression.
        assert setup instanceof DartExprStmt;
        accept(((DartExprStmt) setup).getExpression());
      }
    }
    p("; ");

    // Condition
    if (x.getCondition() != null) {
      accept(x.getCondition());
    }
    p("; ");

    // Next
    if (x.getIncrement() != null) {
      accept(x.getIncrement());
    }
    p(") ");

    // Body
    accept(x.getBody());
    nl();
    return null;
  }

  @Override
  public Void visitForInStatement(DartForInStatement x) {
    p("for (");
    if (x.introducesVariable()) {
      DartTypeNode type = x.getVariableStatement().getTypeNode();
      if (type != null) {
        accept(type);
        p(" ");
      } else {
        p("var ");
      }
      printSeparatedByComma(x.getVariableStatement().getVariables());
    } else {
      accept(x.getIdentifier());
    }

    p(" in ");

    // iterable
    accept(x.getIterable());
    p(") ");

    // Body
    accept(x.getBody());
    nl();
    return null;
  }

  @Override
  public Void visitContinueStatement(DartContinueStatement x) {
    p("continue");
    if (x.getTargetName() != null) {
      p(" " + x.getTargetName());
    }
    p(";");
    nl();
    return null;
  }

  @Override
  public Void visitBreakStatement(DartBreakStatement x) {
    p("break");
    if (x.getTargetName() != null) {
      p(" " + x.getTargetName());
    }
    p(";");
    nl();
    return null;
  }

  @Override
  public Void visitReturnStatement(DartReturnStatement x) {
    p("return");
    if (x.getValue() != null) {
      p(" ");
      accept(x.getValue());
    }
    p(";");
    nl();
    return null;
  }

  @Override
  public Void visitTryStatement(DartTryStatement x) {
    p("try ");
    accept(x.getTryBlock());
    acceptList(x.getCatchBlocks());
    if (x.getFinallyBlock() != null) {
      p("finally ");
      accept(x.getFinallyBlock());
    }
    return null;
  }

  @Override
  public Void visitCatchBlock(DartCatchBlock x) {
    DartParameter catchParameter = x.getException();
    DartTypeNode type = catchParameter.getTypeNode();
    if (type != null) {
      p("on ");
      accept(type);
      p(" ");
    }
    p("catch (");
    accept(catchParameter.getName());
    if (x.getStackTrace() != null) {
      p(", ");
      accept(x.getStackTrace());
    }
    p(") ");
    accept(x.getBlock());
    return null;
  }

  @Override
  public Void visitThrowExpression(DartThrowExpression x) {
    p("throw");
    if (x.getException() != null) {
      p(" ");
      accept(x.getException());
    }
    return null;
  }

  @Override
  public Void visitVariableStatement(DartVariableStatement x) {
    if (x.getTypeNode() != null) {
      accept(x.getTypeNode());
      p(" ");
    } else {
      p("var ");
    }
    printSeparatedByComma(x.getVariables());
    p(";");
    nl();
    return null;
  }

  @Override
  public Void visitVariable(DartVariable x) {
    accept(x.getName());
    if (x.getValue() != null) {
      p(" = ");
      accept(x.getValue());
    }
    return null;
  }

  @Override
  public Void visitEmptyStatement(DartEmptyStatement x) {
    p(";");
    nl();
    return null;
  }

  @Override
  public Void visitLabel(DartLabel x) {
    p(x.getName());
    p(": ");
    accept(x.getStatement());
    return null;
  }

  @Override
  public Void visitExprStmt(DartExprStmt x) {
    accept(x.getExpression());
    p(";");
    nl();
    return null;
  }

  @Override
  public Void visitBinaryExpression(DartBinaryExpression x) {
    accept(x.getArg1());
    p(" ");
    p(x.getOperator().getSyntax());
    p(" ");
    accept(x.getArg2());
    return null;
  }

  @Override
  public Void visitConditional(DartConditional x) {
    accept(x.getCondition());
    p(" ? ");
    accept(x.getThenExpression());
    p(" : ");
    accept(x.getElseExpression());
    return null;
  }

  @Override
  public Void visitUnaryExpression(DartUnaryExpression x) {
    if (x.isPrefix()) {
      p(x.getOperator().getSyntax());
    }
    accept(x.getArg());
    if (!x.isPrefix()) {
      p(x.getOperator().getSyntax());
    }
    return null;
  }

  @Override
  public Void visitPropertyAccess(DartPropertyAccess x) {
    if (x.getQualifier() != null) {
      accept(x.getQualifier());
    }
    if (x.isCascade()) {
      p("..");
    } else {
      p(".");
    }
    p(x.getPropertyName());
    return null;
  }

  @Override
  public Void visitCascadeExpression(DartCascadeExpression x) {
    accept(x.getTarget());
    acceptList(x.getCascadeSections());
    return null;
  }

  @Override
  public Void visitArrayAccess(DartArrayAccess x) {
    if (x.isCascade()) {
      p("..");
    } else {
      accept(x.getTarget());
    }
    p("[");
    accept(x.getKey());
    p("]");
    return null;
  }

  private void pArgs(List<? extends DartNode> args) {
    p("(");
    printSeparatedByComma(args);
    p(")");
  }

  @Override
  public Void visitUnqualifiedInvocation(DartUnqualifiedInvocation x) {
    accept(x.getTarget());
    pArgs(x.getArguments());
    return null;
  }

  @Override
  public Void visitFunctionObjectInvocation(DartFunctionObjectInvocation x) {
    accept(x.getTarget());
    pArgs(x.getArguments());
    return null;
  }

  @Override
  public Void visitMethodInvocation(DartMethodInvocation x) {
    if (x.isCascade()) {
      p("..");
    } else {
      accept(x.getTarget());
      p(".");
    }
    accept(x.getFunctionName());
    pArgs(x.getArguments());
    return null;
  }

  @Override
  public Void visitSyntheticErrorExpression(DartSyntheticErrorExpression node) {
    p("[error: " + node.getTokenString() + "]");
    return null;
  }

  @Override
  public Void visitSyntheticErrorStatement(DartSyntheticErrorStatement node) {
    p("[error: " + node.getTokenString() + "]");
    return null;
  }

  @Override
  public Void visitThisExpression(DartThisExpression x) {
    p("this");
    return null;
  }

  @Override
  public Void visitSuperExpression(DartSuperExpression x) {
    p("super");
    return null;
  }

  @Override
  public Void visitSuperConstructorInvocation(DartSuperConstructorInvocation x) {
    p("super");
    if (x.getName() != null) {
      p(".");
      accept(x.getName());
    }
    pArgs(x.getArguments());
    return null;
  }

  @Override
  public Void visitNewExpression(DartNewExpression x) {
    if (x.isConst()) {
      p("const ");
    } else {
      p("new ");
    }
    accept(x.getConstructor());
    pArgs(x.getArguments());
    return null;
  }

  @Override
  public Void visitFunctionExpression(DartFunctionExpression x) {
    DartFunction func = x.getFunction();
    if (func.getReturnTypeNode() != null) {
      accept(func.getReturnTypeNode());
      p(" ");
    }
    DartIdentifier name = x.getName();
    pFunctionDeclaration(name, x.getFunction(), true);
    p(" ");
    if (x.getFunction().getBody() != null) {
      pBlock(x.getFunction().getBody(), false);
    }
    return null;
  }

  @Override
  public Void visitIdentifier(DartIdentifier x) {
    p(x.getName());
    return null;
  }

  @Override
  public Void visitNullLiteral(DartNullLiteral x) {
    p("null");
    return null;
  }

  @Override
  public Void visitRedirectConstructorInvocation(DartRedirectConstructorInvocation x) {
    p("this");
    if (x.getName() != null) {
      p(".");
      accept(x.getName());
    }
    pArgs(x.getArguments());
    return null;
  }

  @Override
  public Void visitStringLiteral(DartStringLiteral x) {
    if (x.getValue() == null) {
      return null;
    }
    p("\"");
    // 'replaceAll' takes regular expressions as first argument and parses the second argument
    // for captured groups. We must escape backslashes twice: once to escape them in the source
    // code and once for the regular expression parser.
    String escaped = x.getValue().replaceAll("\\\\", "\\\\\\\\");
    escaped = escaped.replaceAll("\"", "\\\\\"");
    escaped = escaped.replaceAll("'", "\\\\'");
    escaped = escaped.replaceAll("\\n", "\\\\n");
    // In the replacement string '$' is used to refer to captured groups. We have to escape the
    // dollar.
    escaped = escaped.replaceAll("\\$", "\\\\\\$");
    p(escaped);
    p("\"");
    return null;
  }

  @Override
  public Void visitStringInterpolation(DartStringInterpolation x) {
    p("\"");
    // do not use the default visitor recursion, instead alternate strings and
    // expressions:
    Iterator<DartExpression> eIter = x.getExpressions().iterator();
    boolean first = true;
    for (DartStringLiteral lit : x.getStrings()) {
      if (first) {
        first = false;
      } else {
        p("${");
        assert eIter.hasNext() : "DartStringInterpolation invariant broken.";
        accept(eIter.next());
        p("}");
      }
      p(lit.getValue().replaceAll("\"", "\\\""));
    }
    p("\"");
    return null;
  }

  @Override
  public Void visitBooleanLiteral(DartBooleanLiteral x) {
    p(Boolean.toString(x.getValue()));
    return null;
  }

  @Override
  public Void visitIntegerLiteral(DartIntegerLiteral x) {
    p(x.getValue().toString());
    return null;
  }

  @Override
  public Void visitDoubleLiteral(DartDoubleLiteral x) {
    p(Double.toString(x.getValue()));
    return null;
  }

  @Override
  public Void visitArrayLiteral(DartArrayLiteral x) {
    List<DartTypeNode> typeArguments = x.getTypeArguments();
    if (typeArguments != null && typeArguments.size() > 0) {
      p("<");
      printSeparatedByComma(typeArguments);
      p(">");
    }
    p("[");
    printSeparatedByComma(x.getExpressions());
    p("]");
    return null;
  }

  @Override
  public Void visitMapLiteral(DartMapLiteral x) {
    List<DartTypeNode> typeArguments = x.getTypeArguments();
    if (typeArguments != null && typeArguments.size() > 0) {
      p("<");
      printSeparatedByComma(typeArguments);
      p(">");
    }
    p("{");
    List<DartMapLiteralEntry> entries = x.getEntries();
    for (int i = 0; i < entries.size(); ++i) {
      DartMapLiteralEntry entry = entries.get(i);
      accept(entry);
      if (i < entries.size() - 1) {
        p(", ");
      }
    }
    p("}");
    return null;
  }

  @Override
  public Void visitMapLiteralEntry(DartMapLiteralEntry x) {
    // Always quote keys just to be safe. This could be optimized to only quote
    // unsafe identifiers.
    accept(x.getKey());
    p(" : ");
    accept(x.getValue());
    return null;
  }

  @Override
  public Void visitParameterizedTypeNode(DartParameterizedTypeNode x) {
    accept(x.getExpression());
    if (!x.getTypeParameters().isEmpty()) {
      p("<");
      printSeparatedByComma(x.getTypeParameters());
      p(">");
    }
    return null;
  }

  @Override
  public Void visitParenthesizedExpression(DartParenthesizedExpression x) {
    p("(");
    accept(x.getExpression());
    p(")");
    return null;
  }

  @Override
  public Void visitNamedExpression(DartNamedExpression x) {
    accept(x.getName());
    p(":");
    accept(x.getExpression());
    return null;
  }

  private void pAbstractField(DartFieldDefinition x) {
    accept(x.getFields().get(0).getAccessor());
  }

  private void pIfBlock(DartStatement stmt, boolean newline) {
    if (stmt instanceof DartBlock) {
      pBlock((DartBlock) stmt, newline);
    } else {
      p("{");
      nl();
      indent();
      accept(stmt);
      outdent();
      p("}");
      if (newline) {
        nl();
      }
    }
  }

  private void printSeparatedByComma(List<? extends DartNode> nodes) {
    boolean first = true;
    for (DartNode node : nodes) {
      if (!first) {
        p(", ");
      }
      accept(node);
      first = false;
    }
  }

  private void pFieldModifiers(DartFieldDefinition field) {
    Modifiers modifiers = field.getFields().get(0).getModifiers();
    if (modifiers.isStatic()) {
      p("static ");
    }
    if (modifiers.isFinal()) {
      p("final ");
    }
  }

  private void pMethodModifiers(DartMethodDefinition method) {
    if (method.getModifiers().isConstant()) {
      p("const ");
    }
    if (method.getModifiers().isStatic()) {
      p("static ");
    }
    if (method.getModifiers().isAbstract()) {
      p("abstract ");
    }
    if (method.getModifiers().isFactory()) {
      p("factory ");
    }
  }

  private void p(String x) {
    out.print(x);
  }

  private void nl() {
    out.newline();
  }

  private void indent() {
    out.indentIn();
  }

  private void outdent() {
    out.indentOut();
  }
}
