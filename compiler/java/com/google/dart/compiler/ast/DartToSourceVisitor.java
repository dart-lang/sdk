// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.collect.Lists;
import com.google.dart.compiler.common.GenerateSourceMap;
import com.google.dart.compiler.common.HasSourceInfo;
import com.google.dart.compiler.common.SourceMapping;
import com.google.dart.compiler.util.TextOutput;
import com.google.debugging.sourcemap.FilePosition;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/**
 * Used by {@link DartNode} to generate Dart source from an AST subtree.
 */
public class DartToSourceVisitor extends DartVisitor {

  private final TextOutput out;
  private boolean buildMappings;
  private List<SourceMapping> mappings = Lists.newArrayList();
  private final boolean isDiet;

  private final boolean calculateHash;
  
  public DartToSourceVisitor(TextOutput out) {
    this(out, false);
  }

  public DartToSourceVisitor(TextOutput out, boolean isDiet) {
    this.out = out;
    this.isDiet = isDiet;
    this.calculateHash = false;
  }
  
  public DartToSourceVisitor(TextOutput out, boolean isDiet, boolean calculateHash) {
    this.out = out;
    this.isDiet = isDiet;
    this.calculateHash = calculateHash;
  }
  
  public void generateSourceMap(boolean generate) {
    this.buildMappings = generate;
  }

  public void writeSourceMap(Appendable out, String name) throws IOException {
    GenerateSourceMap generator = new GenerateSourceMap();
    for (SourceMapping m : mappings) {
      generator.addMapping(m.getNode(), m.getStart(), m.getEnd());
    }
    generator.appendTo(out, name);
  }

  @Override
  public void doTraverse(DartVisitable x, DartContext ctx) {
    SourceMapping m = null;

    boolean mapThis = shouldMap(x);
    if (mapThis) {
      m = new SourceMapping((HasSourceInfo) x, new FilePosition(out.getLine(), out.getColumn()));
      mappings.add(m);
    }

    super.doTraverse(x, ctx);

    if (mapThis) {
      m.setEnd(new FilePosition(out.getLine(), out.getColumn()));
    }
  }

  /**
   * Filter uninteresting AST nodes out of the source map
   */
  private boolean shouldMap(DartVisitable x) {
    return buildMappings && !(x instanceof DartExprStmt);
  }

  @Override
  public boolean visit(DartUnit x, DartContext ctx) {
    p("// unit " + x.getSourceName());
    nl();
    acceptList(x.getTopLevelNodes());
    return false;
  }

  @Override
  public boolean visit(DartNativeBlock x, DartContext ctx) {
    p("native;");
    return false;
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
  public boolean visit(DartFunctionTypeAlias x, DartContext ctx) {
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
    return false;
  }

  @Override
  public boolean visit(DartClass x, DartContext ctx) {
    int start = 0;
    if (calculateHash == true) {
      start = out.getPosition();
    }
    
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
      p(" factory ");
      accept(x.getDefaultClass());
    }

    p(" {");
    nl();
    indent();

    acceptList(x.getMembers());

    outdent();
    p("}");
    if (calculateHash == true) {
      x.setHash(out.toString().substring(start, out.getPosition()).hashCode());
    }
    nl();
    nl();
    return false;
  }

  @Override
  public boolean visit(DartTypeNode x, DartContext ctx) {
    accept(x.getIdentifier());
    List<DartTypeNode> arguments = x.getTypeArguments();
    if (arguments != null && !arguments.isEmpty()) {
      p("<");
      printSeparatedByComma(arguments);
      p(">");
    }
    return false;
  }

  @Override
  public boolean visit(DartTypeParameter x, DartContext ctx) {
    accept(x.getName());
    DartTypeNode bound = x.getBound();
    if (bound != null) {
      p(" extends ");
      accept(bound);
    }
    return false;
  }

  @Override
  public boolean visit(DartFieldDefinition x, DartContext ctx) {
    Modifiers modifiers = x.getFields().get(0).getModifiers();
    if (modifiers.isAbstractField()) {
      pAbstractField(x, ctx);
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

    return false;
  }

  @Override
  public boolean visit(DartField x, DartContext ctx) {
    accept(x.getName());
    if (x.getValue() != null) {
      p(" = ");
      accept(x.getValue());
    }
    return false;
  }

  @Override
  public boolean visit(DartParameter x, DartContext ctx) {
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
      p(" = ");
      accept(x.getDefaultExpr());
    }
    return false;
  }

  @Override
  public boolean visit(DartMethodDefinition x, DartContext ctx) {
    nl();
    pMethodModifiers(x);
    DartFunction func = x.getFunction();
    if (func.getReturnTypeNode() != null) {
      accept(func.getReturnTypeNode());
      p(" ");
    }
    if (x.getModifiers().isOperator()) {
      p("operator ");
    } else if (x.getModifiers().isGetter()) {
      p("get ");
    } else if (x.getModifiers().isSetter()) {
      p("set ");
    }
    pFunctionDeclaration(x.getName(), func);
    p(" ");
    if (!isDiet) {
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
    }
    if (x.getFunction().getBody() != null) {
      accept(x.getFunction().getBody());
    } else {
      if (isDiet && x.getModifiers().isRedirectedConstructor() && !x.getModifiers().isConstant()) {
        p("{ }");
      } else {
        p(";");
      }
      nl();
    }
    return false;
  }

  @Override
  public boolean visit(DartInitializer x, DartContext ctx) {
    if (!x.isInvocation()) {
      p("this.");
      p(x.getInitializerName());
      p(" = ");
    }
    accept(x.getValue());
    return false;
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

  private void pFunctionDeclaration(DartNode name, DartFunction x) {
    if (name != null) {
      accept(name);
    }
    p("(");
    pFormalParameters(x.getParams());
    p(")");
  }

  private void pFormalParameters(List<DartParameter> params) {
    boolean first = true, hasNamed = false;
    for (DartParameter param : params) {
      if (!first) {
        p(", ");
      }
      if (!hasNamed && param.getModifiers().isNamed()) {
        hasNamed = true;
        p("[");
      }
      accept(param);
      first = false;
    }
    if (hasNamed) {
      p("]");
    }
  }

  @Override
  public boolean visit(DartBlock x, DartContext ctx) {
    if (isDiet) {
      p("{ }");
      nl();
      return false;
    }

    pBlock(x, true);
    return false;
  }

  @Override
  public boolean visit(DartAssertion x, DartContext ctx) {
    p("assert(");
    accept(x.getExpression());
    p(");");
    nl();
    return false;
  }

  @Override
  public boolean visit(DartIfStatement x, DartContext ctx) {
    p("if (");
    accept(x.getCondition());
    p(") ");
    pIfBlock(x.getThenStatement(), x.getElseStatement() == null);
    if (x.getElseStatement() != null) {
      p(" else ");
      pIfBlock(x.getElseStatement(), true);
    }
    return false;
  }

  @Override
  public boolean visit(DartSwitchStatement x, DartContext ctx) {
    p("switch (");
    accept(x.getExpression());
    p(") {");
    nl();

    indent();
    acceptList(x.getMembers());
    outdent();

    p("}");
    nl();
    return false;
  }

  @Override
  public boolean visit(DartCase x, DartContext ctx) {
    p("case ");
    accept(x.getExpr());
    p(":");
    nl();
    indent();
    acceptList(x.getStatements());
    outdent();
    return false;
  }

  @Override
  public boolean visit(DartDefault x, DartContext ctx) {
    p("default:");
    nl();
    indent();
    acceptList(x.getStatements());
    outdent();
    return false;
  }

  @Override
  public boolean visit(DartWhileStatement x, DartContext ctx) {
    p("while (");
    accept(x.getCondition());
    p(") ");
    pIfBlock(x.getBody(), true);
    return false;
  }

  @Override
  public boolean visit(DartDoWhileStatement x, DartContext ctx) {
    p("do ");
    pIfBlock(x.getBody(), false);
    p(" while (");
    accept(x.getCondition());
    p(");");
    nl();
    return false;
  }

  @Override
  public boolean visit(DartForStatement x, DartContext ctx) {
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
    return false;
  }

  @Override
  public boolean visit(DartForInStatement x, DartContext ctx) {
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
    return false;
  }

  @Override
  public boolean visit(DartContinueStatement x, DartContext ctx) {
    p("continue");
    if (x.getTargetName() != null) {
      p(" " + x.getTargetName());
    }
    p(";");
    nl();
    return false;
  }

  @Override
  public boolean visit(DartBreakStatement x, DartContext ctx) {
    p("break");
    if (x.getTargetName() != null) {
      p(" " + x.getTargetName());
    }
    p(";");
    nl();
    return false;
  }

  @Override
  public boolean visit(DartReturnStatement x, DartContext ctx) {
    p("return");
    if (x.getValue() != null) {
      p(" ");
      accept(x.getValue());
    }
    p(";");
    nl();
    return false;
  }

  @Override
  public boolean visit(DartTryStatement x, DartContext ctx) {
    p("try ");
    accept(x.getTryBlock());
    acceptList(x.getCatchBlocks());
    if (x.getFinallyBlock() != null) {
      p("finally ");
      accept(x.getFinallyBlock());
    }
    return false;
  }

  private void visitCatchParameter(DartParameter x) {
    if (!x.getModifiers().isFinal() && x.getTypeNode() == null) {
      p("var ");
    }
    accept(x);
  }

  @Override
  public boolean visit(DartCatchBlock x, DartContext ctx) {
    p("catch (");
    visitCatchParameter(x.getException());
    if (x.getStackTrace() != null) {
      p(", ");
      visitCatchParameter(x.getStackTrace());
    }
    p(") ");
    accept(x.getBlock());
    return false;
  }

  @Override
  public boolean visit(DartThrowStatement x, DartContext ctx) {
    p("throw");
    if (x.getException() != null) {
      p(" ");
      accept(x.getException());
    }
    p(";");
    nl();
    return false;
  }

  @Override
  public boolean visit(DartVariableStatement x, DartContext ctx) {
    if (x.getTypeNode() != null) {
      accept(x.getTypeNode());
      p(" ");
    } else {
      p("var ");
    }
    printSeparatedByComma(x.getVariables());
    p(";");
    nl();
    return false;
  }

  @Override
  public boolean visit(DartVariable x, DartContext ctx) {
    accept(x.getName());
    if (x.getValue() != null) {
      p(" = ");
      accept(x.getValue());
    }
    return false;
  }

  @Override
  public boolean visit(DartEmptyStatement x, DartContext ctx) {
    p(";");
    nl();
    return false;
  }

  @Override
  public boolean visit(DartLabel x, DartContext ctx) {
    p(x.getName());
    p(": ");
    accept(x.getStatement());
    return false;
  }

  @Override
  public boolean visit(DartExprStmt x, DartContext ctx) {
    accept(x.getExpression());
    p(";");
    nl();
    return false;
  }

  @Override
  public boolean visit(DartBinaryExpression x, DartContext ctx) {
    accept(x.getArg1());
    p(" ");
    p(x.getOperator().getSyntax());
    p(" ");
    accept(x.getArg2());
    return false;
  }

  @Override
  public boolean visit(DartConditional x, DartContext ctx) {
    accept(x.getCondition());
    p(" ? ");
    accept(x.getThenExpression());
    p(" : ");
    accept(x.getElseExpression());
    return false;
  }

  @Override
  public boolean visit(DartUnaryExpression x, DartContext ctx) {
    if (x.isPrefix()) {
      p(x.getOperator().getSyntax());
    }
    accept(x.getArg());
    if (!x.isPrefix()) {
      p(x.getOperator().getSyntax());
    }
    return false;
  }

  @Override
  public boolean visit(DartPropertyAccess x, DartContext ctx) {
    accept(x.getQualifier());
    p(".");
    p(x.getPropertyName());
    return false;
  }

  @Override
  public boolean visit(DartArrayAccess x, DartContext ctx) {
    accept(x.getTarget());
    p("[");
    accept(x.getKey());
    p("]");
    return false;
  }

  private void pArgs(List<? extends DartNode> args) {
    p("(");
    printSeparatedByComma(args);
    p(")");
  }

  @Override
  public boolean visit(DartUnqualifiedInvocation x, DartContext ctx) {
    accept(x.getTarget());
    pArgs(x.getArgs());
    return false;
  }

  @Override
  public boolean visit(DartFunctionObjectInvocation x, DartContext ctx) {
    accept(x.getTarget());
    pArgs(x.getArgs());
    return false;
  }

  @Override
  public boolean visit(DartMethodInvocation x, DartContext ctx) {
    accept(x.getTarget());
    p(".");
    accept(x.getFunctionName());
    pArgs(x.getArgs());
    return false;
  }

  @Override
  public boolean visit(DartSyntheticErrorExpression node, DartContext ctx) {
    p("[error: " + node.getTokenString() + "]");
    return false;
  }

  @Override
  public boolean visit(DartSyntheticErrorStatement node, DartContext ctx) {
    p("[error: " + node.getTokenString() + "]");
    return false;
  }

  @Override
  public boolean visit(DartThisExpression x, DartContext ctx) {
    p("this");
    return false;
  }

  @Override
  public boolean visit(DartSuperExpression x, DartContext ctx) {
    p("super");
    return false;
  }

  @Override
  public boolean visit(DartSuperConstructorInvocation x, DartContext ctx) {
    p("super");
    if (x.getName() != null) {
      p(".");
      accept(x.getName());
    }
    pArgs(x.getArgs());
    return false;
  }

  @Override
  public boolean visit(DartNewExpression x, DartContext ctx) {
    p("new ");
    accept(x.getConstructor());
    pArgs(x.getArgs());
    return false;
  }

  @Override
  public boolean visit(DartFunctionExpression x, DartContext ctx) {
    DartFunction func = x.getFunction();
    if (func.getReturnTypeNode() != null) {
      accept(func.getReturnTypeNode());
      p(" ");
    }
    DartIdentifier name = x.getName();
    pFunctionDeclaration(name, x.getFunction());
    p(" ");
    if (x.getFunction().getBody() != null) {
      pBlock(x.getFunction().getBody(), false);
    }
    return false;
  }

  @Override
  public boolean visit(DartIdentifier x, DartContext ctx) {
    p(x.getTargetName());
    return false;
  }

  @Override
  public boolean visit(DartNullLiteral x, DartContext ctx) {
    p("null");
    return false;
  }

  @Override
  public boolean visit(DartRedirectConstructorInvocation x, DartContext ctx) {
    p("this");
    if (x.getName() != null) {
      p(".");
      accept(x.getName());
    }
    pArgs(x.getArgs());
    return false;
  }

  @Override
  public boolean visit(DartStringLiteral x, DartContext ctx) {
    p("\"");
    // 'replaceAll' takes regular expressions as first argument and parses the second argument
    // for captured groups. We must escape backslashes twice: once to escape them in the source
    // code and once for the regular expression parser.
    String escaped =  x.getValue().replaceAll("\\\\", "\\\\\\\\");
    escaped = escaped.replaceAll("\"", "\\\\\"");
    escaped = escaped.replaceAll("'", "\\\\'");
    escaped = escaped.replaceAll("\\n", "\\\\n");
    // In the replacement string '$' is used to refer to captured groups. We have to escape the
    // dollar.
    escaped = escaped.replaceAll("\\$", "\\\\\\$");
    p(escaped);
    p("\"");
    return false;
  }

  @Override
  public boolean visit(DartStringInterpolation x, DartContext ctx) {
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
    return false;
  }

  @Override
  public boolean visit(DartBooleanLiteral x, DartContext ctx) {
    p(Boolean.toString(x.getValue()));
    return false;
  }

  @Override
  public boolean visit(DartIntegerLiteral x, DartContext ctx) {
    p(x.getValue().toString());
    return false;
  }

  @Override
  public boolean visit(DartDoubleLiteral x, DartContext ctx) {
    p(Double.toString(x.getValue()));
    return false;
  }

  @Override
  public boolean visit(DartArrayLiteral x, DartContext ctx) {
    p("[");
    printSeparatedByComma(x.getExpressions());
    p("]");
    return false;
  }

  @Override
  public boolean visit(DartMapLiteral x, DartContext ctx) {
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
    return false;
  }

  @Override
  public boolean visit(DartMapLiteralEntry x, DartContext ctx) {
    // Always quote keys just to be safe. This could be optimized to only quote
    // unsafe identifiers.
    accept(x.getKey());
    p(" : ");
    accept(x.getValue());
    return false;
  }

  @Override
  public boolean visit(DartParameterizedNode x, DartContext ctx) {
    accept(x.getExpression());
    p("<");
    printSeparatedByComma(x.getTypeParameters());
    p(">");
    return false;
  }

  @Override
  public boolean visit(DartParenthesizedExpression x, DartContext ctx) {
    p("(");
    accept(x.getExpression());
    p(")");
    return false;
  }

  @Override
  public boolean visit(DartNamedExpression x, DartContext ctx) {
    accept(x.getName());
    p(":");
    accept(x.getExpression());
    return false;
  }

  private void pAbstractField(DartFieldDefinition x, DartContext ctx) {
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
