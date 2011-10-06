// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.common.base.Preconditions;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.backend.js.ast.HasName;
import com.google.dart.compiler.backend.js.ast.JsArrayAccess;
import com.google.dart.compiler.backend.js.ast.JsArrayLiteral;
import com.google.dart.compiler.backend.js.ast.JsBinaryOperation;
import com.google.dart.compiler.backend.js.ast.JsBinaryOperator;
import com.google.dart.compiler.backend.js.ast.JsBlock;
import com.google.dart.compiler.backend.js.ast.JsBooleanLiteral;
import com.google.dart.compiler.backend.js.ast.JsBreak;
import com.google.dart.compiler.backend.js.ast.JsCase;
import com.google.dart.compiler.backend.js.ast.JsCatch;
import com.google.dart.compiler.backend.js.ast.JsConditional;
import com.google.dart.compiler.backend.js.ast.JsContinue;
import com.google.dart.compiler.backend.js.ast.JsDebugger;
import com.google.dart.compiler.backend.js.ast.JsDefault;
import com.google.dart.compiler.backend.js.ast.JsDoWhile;
import com.google.dart.compiler.backend.js.ast.JsEmpty;
import com.google.dart.compiler.backend.js.ast.JsExprStmt;
import com.google.dart.compiler.backend.js.ast.JsExpression;
import com.google.dart.compiler.backend.js.ast.JsFor;
import com.google.dart.compiler.backend.js.ast.JsForIn;
import com.google.dart.compiler.backend.js.ast.JsFunction;
import com.google.dart.compiler.backend.js.ast.JsIf;
import com.google.dart.compiler.backend.js.ast.JsInvocation;
import com.google.dart.compiler.backend.js.ast.JsLabel;
import com.google.dart.compiler.backend.js.ast.JsName;
import com.google.dart.compiler.backend.js.ast.JsNameRef;
import com.google.dart.compiler.backend.js.ast.JsNew;
import com.google.dart.compiler.backend.js.ast.JsNode;
import com.google.dart.compiler.backend.js.ast.JsNullLiteral;
import com.google.dart.compiler.backend.js.ast.JsNumberLiteral;
import com.google.dart.compiler.backend.js.ast.JsObjectLiteral;
import com.google.dart.compiler.backend.js.ast.JsParameter;
import com.google.dart.compiler.backend.js.ast.JsPostfixOperation;
import com.google.dart.compiler.backend.js.ast.JsPrefixOperation;
import com.google.dart.compiler.backend.js.ast.JsProgram;
import com.google.dart.compiler.backend.js.ast.JsPropertyInitializer;
import com.google.dart.compiler.backend.js.ast.JsRegExp;
import com.google.dart.compiler.backend.js.ast.JsReturn;
import com.google.dart.compiler.backend.js.ast.JsStatement;
import com.google.dart.compiler.backend.js.ast.JsStringLiteral;
import com.google.dart.compiler.backend.js.ast.JsSwitch;
import com.google.dart.compiler.backend.js.ast.JsSwitchMember;
import com.google.dart.compiler.backend.js.ast.JsThisRef;
import com.google.dart.compiler.backend.js.ast.JsThrow;
import com.google.dart.compiler.backend.js.ast.JsTry;
import com.google.dart.compiler.backend.js.ast.JsUnaryOperator;
import com.google.dart.compiler.backend.js.ast.JsVars;
import com.google.dart.compiler.backend.js.ast.JsVars.JsVar;
import com.google.dart.compiler.backend.js.ast.JsWhile;
import com.google.dart.compiler.common.HasSymbol;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.common.Symbol;
import com.google.javascript.jscomp.AstValidator;
import com.google.javascript.rhino.InputId;
import com.google.javascript.rhino.JSDocInfoBuilder;
import com.google.javascript.rhino.Node;
import com.google.javascript.rhino.Token;
import com.google.javascript.rhino.jstype.SimpleSourceFile;
import com.google.javascript.rhino.jstype.StaticSourceFile;

import java.util.HashMap;
import java.util.Map;


/**
 * Translate a Dart JS AST to a Closure Compiler AST.
 * @author johnlenz@google.com (John Lenz)
 */
public class ClosureJsAstTranslator {
   private final Map<Source, StaticSourceFile> sourceCache =
       new HashMap<Source, StaticSourceFile>();

   private final boolean validate;

   ClosureJsAstTranslator(boolean validate) {
     this.validate = validate;
   }

   private StaticSourceFile getClosureSourceFile(Source source) {
     StaticSourceFile closureSourceFile = sourceCache.get(source);
     if (closureSourceFile == null) {
       closureSourceFile = new SimpleSourceFile(source.getName(), false);
       sourceCache.put(source, closureSourceFile);
     }
     return closureSourceFile;
   }

   public Node translate(JsProgram program, InputId inputId, Source source) {
     Node script = new Node(Token.SCRIPT);
     script.putBooleanProp(Node.SYNTHETIC_BLOCK_PROP, true);
     script.setInputId(inputId);
     script.putProp(Node.SOURCENAME_PROP, source.getName());
     script.setStaticSourceFile(getClosureSourceFile(source));
     for (JsStatement s : program.getGlobalBlock().getStatements()) {
       script.addChildToBack(transform(s));
     }
     // Validate the structural integrity of the AST.
     if (validate) {
       new AstValidator().validateScript(script);
     }
     return script;
   }

   private Node transform(JsStatement x) {
     switch (x.getKind()) {
       case BLOCK:
         return transform((JsBlock)x);
       case BREAK:
         return transform((JsBreak)x);
       case CONTINUE:
         return transform((JsContinue)x);
       case DEBUGGER:
         return transform((JsDebugger)x);
       case DO:
         return transform((JsDoWhile)x);
       case EMPTY:
         return transform((JsEmpty)x);
       case EXPR_STMT:
         return transform((JsExprStmt)x);
       case FOR:
         return transform((JsFor)x);
       case FOR_IN:
         return transform((JsForIn)x);
       case IF:
         return transform((JsIf)x);
       case LABEL:
         return transform((JsLabel)x);
       case RETURN:
         return transform((JsReturn)x);
       case SWITCH:
         return transform((JsSwitch)x);
       case THROW:
         return transform((JsThrow)x);
       case TRY:
         return transform((JsTry)x);
       case VARS:
         return transform((JsVars)x);
       case WHILE:
         return transform((JsWhile)x);
       default:
         throw new IllegalStateException(
            "Unexpected statement type: " + x.getClass().getSimpleName());
    }
  }

  private Node transform(JsExpression x) {
    assert x != null;
    switch (x.getKind()) {
      case ARRAY:
        return transform((JsArrayLiteral)x);
      case ARRAY_ACCESS:
        return transform((JsArrayAccess)x);
      case BINARY_OP:
        return transform((JsBinaryOperation)x);
      case CONDITIONAL:
        return transform((JsConditional)x);
      case INVOKE:
        return transform((JsInvocation)x);
      case FUNCTION:
        return transform((JsFunction)x);
      case OBJECT:
        return transform((JsObjectLiteral)x);
      case BOOLEAN:
        return transform((JsBooleanLiteral)x);
      case NULL:
        return transform((JsNullLiteral)x);
      case NUMBER:
        return transform((JsNumberLiteral)x);
      case REGEXP:
        return transform((JsRegExp)x);
      case STRING:
        return transform((JsStringLiteral)x);
      case THIS:
        return transform((JsThisRef)x);
      case NAME_REF:
        return transform((JsNameRef)x);
      case NEW:
        return transform((JsNew)x);
      case POSTFIX_OP:
        return transform((JsPostfixOperation)x);
      case PREFIX_OP:
        return transform((JsPrefixOperation)x);
      default:
        throw new IllegalStateException(
          "Unexpected expression type: " + x.getClass().getSimpleName());
    }
  }

  private Node transform(JsSwitchMember x) {
    switch (x.getKind()) {
      case CASE:
        return transform((JsCase)x);
      case DEFAULT:
        return transform((JsDefault)x);
      default:
        throw new IllegalStateException(
            "Unexpected switch member type: " + x.getClass().getSimpleName());
    }
  }

  private Node transform(JsArrayAccess x) {
    Node n = new Node(Token.GETELEM,
        transform(x.getArrayExpr()),
        transform(x.getIndexExpr()));
    return applySourceInfo(n, x);
  }

  private Node transform(JsArrayLiteral x) {
    Node n = new Node(Token.ARRAYLIT);
    for (Object element : x.getExpressions()) {
      JsExpression arg = (JsExpression) element;
      n.addChildToBack(transform(arg));
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsBinaryOperation x) {
    JsBinaryOperator op = x.getOperator();
    Node n = new Node(getTokenForOp(op),
        transform(x.getArg1()),
        transform(x.getArg2()));
    return applySourceInfo(n, x);
  }

  private Node transform(JsBlock x) {
    Node n = new Node(Token.BLOCK);
    for (JsStatement s : x.getStatements()) {
      n.addChildToBack(transform(s));
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsBooleanLiteral x) {
    Node n = new Node(x.getValue() ? Token.TRUE : Token.FALSE);
    return applySourceInfo(n, x);
  }

  private Node transform(JsBreak x) {
    Node n = new Node(Token.BREAK);

    JsNameRef label = x.getLabel();
    if (label != null) {
      n.addChildToBack(transformLabel(label));
    }

    return applySourceInfo(n, x);
  }

  private Node transform(JsCase x) {
    Node n = new Node(Token.CASE);
    n.addChildToBack(transform(x.getCaseExpr()));

    Node body = new Node(Token.BLOCK);
    body.putBooleanProp(Node.SYNTHETIC_BLOCK_PROP, true);
    applySourceInfo(body, x);
    n.addChildToBack(body);

    for (Object element : x.getStmts()) {
      JsStatement stmt = (JsStatement) element;
      body.addChildToBack(transform(stmt));
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsCatch x) {
    Node n = new Node(Token.CATCH,
        transformName(x.getParameter().getName()),
        transform(x.getBody()));
    Preconditions.checkState(x.getCondition() == null);
    return applySourceInfo(n, x);
  }

  private Node transform(JsConditional x) {
    Node n = new Node(Token.HOOK,
        transform(x.getTestExpression()),
        transform(x.getThenExpression()),
        transform(x.getElseExpression()));
    return applySourceInfo(n, x);
  }

  private Node transform(JsContinue x) {
    Node n = new Node(Token.CONTINUE);

    JsNameRef label = x.getLabel();
    if (label != null) {
      n.addChildToBack(transformLabel(label));
    }

    return applySourceInfo(n, x);
  }

  private Node transform(JsDebugger x) {
    Node n = new Node(Token.DEBUGGER);
    return applySourceInfo(n, x);
  }

  private Node transform(JsDefault x) {
    Node n = new Node(Token.DEFAULT);

    Node body = new Node(Token.BLOCK);
    body.putBooleanProp(Node.SYNTHETIC_BLOCK_PROP, true);
    applySourceInfo(body, x);
    n.addChildToBack(body);

    for (Object element : x.getStmts()) {
      JsStatement stmt = (JsStatement) element;
      body.addChildToBack(transform(stmt));
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsDoWhile x) {
    Node n = new Node(Token.DO,
      transformBody(x.getBody(), x),
      transform(x.getCondition()));
    return applySourceInfo(n, x);
  }

  private Node transform(JsEmpty x) {
    return new Node(Token.EMPTY);
  }

  private Node transform(JsExprStmt x) {
    // The Dart JS AST doesn't produce function declarations, instead
    // they are expressions statements:
    Node expr = transform(x.getExpression());
    if (expr.getType() != Token.FUNCTION) {
      return new Node(Token.EXPR_RESULT, expr);
    } else {
      return expr;
    }
  }

  private Node transform(JsFor x) {
    Node n = new Node(Token.FOR);

    // The init expressions or var decl.
    //
    if (x.getInitExpr() != null) {
      n.addChildToBack(transform(x.getInitExpr()));
    } else if (x.getInitVars() != null) {
      n.addChildToBack(transform(x.getInitVars()));
    } else {
      n.addChildToBack(new Node(Token.EMPTY));
    }

    // The loop test.
    //
    if (x.getCondition() != null) {
      n.addChildToBack(transform(x.getCondition()));
    } else {
      n.addChildToBack(new Node(Token.EMPTY));
    }

    // The incr expression.
    //
    if (x.getIncrExpr() != null) {
      n.addChildToBack(transform(x.getIncrExpr()));
    } else {
      n.addChildToBack(new Node(Token.EMPTY));
    }

    n.addChildToBack(transformBody(x.getBody(), x));
    return applySourceInfo(n, x);
  }

  private Node transform(JsForIn x) {
    Node n = new Node(Token.FOR);

    if (x.getIterVarName() != null) {
      Node expr = new Node(Token.VAR,
          transformName(x.getIterVarName()));
      n.addChildToBack(expr);
    } else {
      // Just a name ref.
      //
      n.addChildToBack(transform(x.getIterExpr()));
    }

    n.addChildToBack(transform(x.getObjExpr()));
    n.addChildToBack(transformBody(x.getBody(), x));
    return applySourceInfo(n, x);
  }

  private Node transform(JsFunction x) {
    Node n = new Node(Token.FUNCTION);
    if (x.getName() != null) {
      n.addChildToBack(getNameNodeFor(x));
      applyOriginalName(n, x);
    } else {
      Node emptyName = Node.newString(Token.NAME, "");
      applySourceInfo(emptyName, x);
      n.addChildToBack(emptyName);
      n.putProp(Node.ORIGINALNAME_PROP, "");
    }

    Node params = new Node(Token.LP);
    for (Object element : x.getParameters()) {
      JsParameter param = (JsParameter) element;
      params.addChildToBack(transform(param));
    }
    applySourceInfo(n, x);
    n.addChildToBack(params);

    n.addChildToBack(transform(x.getBody()));

    if (x.isConstructor()) {
      JSDocInfoBuilder builder = new JSDocInfoBuilder(false);
      builder.recordConstructor();
      n.setJSDocInfo(builder.build(n));
    }

    return applySourceInfo(n, x);
  }

  private Node transform(JsIf x) {
    Node n = new Node(Token.IF,
        transform(x.getIfExpr()),
        transformBody(x.getThenStmt(), x));
    if (x.getElseStmt() != null) {
      n.addChildToBack(transformBody(x.getElseStmt(), x));
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsInvocation x) {
    Node n = new Node(Token.CALL,
        transform(x.getQualifier()));
    for (Object element : x.getArguments()) {
      JsExpression arg = (JsExpression) element;
      n.addChildToBack(transform(arg));
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsLabel x) {
    Node n = new Node(Token.LABEL,
      transformLabel(x.getName()),
      transform(x.getStmt()));

    return applySourceInfo(n, x);
  }

  private Node transform(JsNameRef x) {
    Node n;
    if (x.getQualifier() != null) {
      n = new Node(Token.GETPROP,
        transform(x.getQualifier()),
        transformNameAsString(x.getShortIdent(), x));
    } else {
      n = transformName(x.getShortIdent(), x);
    }
    applyOriginalName(n, x);
    return applySourceInfo(n, x);
  }

  private Node transform(JsNew x) {
    Node n = new Node(Token.NEW,
        transform(x.getConstructorExpression()));
    for (Object element : x.getArguments()) {
      JsExpression arg = (JsExpression) element;
      n.addChildToBack(transform(arg));
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsNullLiteral x) {
    return new Node(Token.NULL);
  }

  private Node transform(JsNumberLiteral x) {
    return Node.newNumber(x.getValue());
  }

  private Node transform(JsObjectLiteral x) {
    Node n = new Node(Token.OBJECTLIT);

    for (Object element : x.getPropertyInitializers()) {
      JsPropertyInitializer propInit = (JsPropertyInitializer) element;
      Node key = transform(propInit.getLabelExpr());
      Preconditions.checkState(key.getType() == Token.STRING);
      key.addChildToBack(transform(propInit.getValueExpr()));
      n.addChildToBack(key);
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsParameter x) {
    return getNameNodeFor(x);
  }

  private Node transform(JsPostfixOperation x) {
    Node n = new Node(getTokenForOp(x.getOperator()),
        transform(x.getArg()));
    n.putBooleanProp(Node.INCRDECR_PROP, true);
    return applySourceInfo(n, x);
  }

  private Node transform(JsPrefixOperation x) {
    Node n = new Node(getTokenForOp(x.getOperator()),
        transform(x.getArg()));
    return applySourceInfo(n, x);
  }

  private Node transform(JsRegExp x) {
    String flags = x.getFlags();
    Node n = new Node(Token.REGEXP,
        Node.newString(x.getPattern()),
        Node.newString(flags != null ? x.getFlags() : ""));
    return applySourceInfo(n, x);
  }

  private Node transform(JsReturn x) {
    Node n = new Node(Token.RETURN);
    JsExpression result = x.getExpr();
    if (result != null) {
      n.addChildToBack(transform(x.getExpr()));
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsStringLiteral x) {
    return Node.newString(x.getValue());
  }

  private Node transform(JsSwitch x) {
    Node n = new Node(Token.SWITCH,
        transform(x.getExpr()));
    for (JsSwitchMember member : x.getCases()) {
      n.addChildToBack(transform(member));
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsThisRef x) {
    Node n = new Node(Token.THIS);
    return applySourceInfo(n, x);
  }

  private Node transform(JsThrow x) {
    Node n = new Node(Token.THROW,
        transform(x.getExpr()));
    return applySourceInfo(n, x);
  }

  private Node transform(JsTry x) {
    Node n = new Node(Token.TRY,
        transform(x.getTryBlock()));

    Node catches = new Node(Token.BLOCK);
    for (JsCatch catchBlock : x.getCatches()) {
      catches.addChildToBack(transform(catchBlock));
    }
    n.addChildToBack(catches);

    JsBlock finallyBlock = x.getFinallyBlock();
    if (finallyBlock != null) {
      n.addChildToBack(transform(finallyBlock));
    }

    return applySourceInfo(n, x);
  }

  private Node transform(JsVar x) {
    Node n = getNameNodeFor(x);
    JsExpression initExpr = x.getInitExpr();
    if (initExpr != null) {
      n.addChildToBack(transform(initExpr));
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsVars x) {
    Node n = new Node(Token.VAR);
    for (JsVar var : x) {
      n.addChildToBack(transform(var));
    }
    return applySourceInfo(n, x);
  }

  private Node transform(JsWhile x) {
    Node n = new Node(Token.WHILE,
      transform(x.getCondition()),
      transformBody(x.getBody(), x));
    return applySourceInfo(n, x);
  }

  private Node transformBody(JsStatement x, SourceInfo parent) {
    Node n = transform(x);
    if (n.getType() != Token.BLOCK) {
      Node stmt = n;
      n = new Node(Token.BLOCK);
      if (n.getType() != Token.EMPTY) {
        n.addChildToBack(stmt);
      }
      applySourceInfo(n, parent);
    }
    return n;
  }

  private Node transformLabel(JsNameRef label) {
    Node n = Node.newString(Token.LABEL_NAME, getName(label));
    return applySourceInfo(n, label);
  }

  private Node transformLabel(JsName label) {
    Node n = Node.newString(Token.LABEL_NAME, getName(label));
    return applySourceInfo(n, label.getStaticRef());
  }

  private Node transformName(JsName name) {
    Node n = Node.newString(Token.NAME, getName(name));
    return applySourceInfo(n, name.getStaticRef());
  }

  private Node transformName(String name, SourceInfo info) {
    Node n = Node.newString(Token.NAME, name);
    return applySourceInfo(n, info);
  }

  private Node transformNameAsString(String name, SourceInfo info) {
    Node n = Node.newString(name);
    return applySourceInfo(n, info);
  }

  private Node getNameNodeFor(HasName hasName) {
    Node n = Node.newString(Token.NAME, getName(hasName.getName()));
    applyOriginalName(n, (JsNode)hasName);
    return applySourceInfo(n, (SourceInfo)hasName);
  }

  private String getName(JsName name) {
    return name.getShortIdent();
  }

  private String getName(JsNameRef name) {
    return name.getShortIdent();
  }

  private int getTokenForOp(JsUnaryOperator op) {
    switch (op) {
      case BIT_NOT: return Token.BITNOT;
      case DEC: return Token.DEC;
      case DELETE: return Token.DELPROP;
      case INC: return Token.INC;
      case NEG: return Token.NEG;
      case POS: return Token.POS;
      case NOT: return Token.NOT;
      case TYPEOF: return Token.TYPEOF;
      case VOID: return Token.VOID;
    }
    throw new IllegalStateException();
  }

  private int getTokenForOp(JsBinaryOperator op) {
    switch (op) {
      case MUL: return Token.MUL;
      case DIV: return Token.DIV;
      case MOD: return Token.MOD;
      case ADD: return Token.ADD;
      case SUB: return Token.SUB;
      case SHL: return Token.LSH;
      case SHR: return Token.RSH;
      case SHRU: return Token.URSH;
      case LT: return Token.LT;
      case LTE: return Token.LE;
      case GT: return Token.GT;
      case GTE: return Token.GE;
      case INSTANCEOF: return Token.INSTANCEOF;
      case INOP: return Token.IN;
      case EQ: return Token.EQ;
      case NEQ: return Token.NE;
      case REF_EQ: return Token.SHEQ;
      case REF_NEQ: return Token.SHNE;
      case BIT_AND: return Token.BITAND;
      case BIT_XOR: return Token.BITXOR;
      case BIT_OR: return Token.BITOR;
      case AND: return Token.AND;
      case OR: return Token.OR;
      case ASG: return Token.ASSIGN;
      case ASG_ADD: return Token.ASSIGN_ADD;
      case ASG_SUB: return Token.ASSIGN_SUB;
      case ASG_MUL: return Token.ASSIGN_MUL;
      case ASG_DIV: return Token.ASSIGN_DIV;
      case ASG_MOD: return Token.ASSIGN_MOD;
      case ASG_SHL: return Token.ASSIGN_LSH;
      case ASG_SHR: return Token.ASSIGN_RSH;
      case ASG_SHRU: return Token.ASSIGN_URSH;
      case ASG_BIT_AND: return Token.ASSIGN_BITAND;
      case ASG_BIT_OR: return Token.ASSIGN_BITOR;
      case ASG_BIT_XOR: return Token.ASSIGN_BITXOR;
      case COMMA: return Token.COMMA;
    }
    return 0;
  }

  private Node applyOriginalName(Node n, JsNode x) {
    if (x instanceof HasSymbol) {
      Symbol symbol = ((HasSymbol)x).getSymbol();
      if (symbol != null) {
        String originalName = symbol.getOriginalSymbolName();
        n.putProp(Node.ORIGINALNAME_PROP, originalName);
      }
    }
    return n;
  }

  private Node applySourceInfo(Node n, SourceInfo info) {
    if (info != null && info.getSource() != null) {
      n.setStaticSourceFile(getClosureSourceFile(info.getSource()));
      n.setLineno(info.getSourceLine());
      n.setCharno(info.getSourceColumn());
    }
    return n;
  }
}
