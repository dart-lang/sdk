// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.InternalCompilerException;
import com.google.dart.compiler.ast.DartArrayLiteral;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartFunctionObjectInvocation;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartInvocation;
import com.google.dart.compiler.ast.DartMapLiteral;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartNodeTraverser;
import com.google.dart.compiler.ast.DartParenthesizedExpression;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartRedirectConstructorInvocation;
import com.google.dart.compiler.ast.DartStringInterpolation;
import com.google.dart.compiler.ast.DartSuperExpression;
import com.google.dart.compiler.ast.DartThisExpression;
import com.google.dart.compiler.ast.DartUnaryExpression;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.type.Type;

/**
 * Given an expression, Determines if the expression matches all the rules for a
 * compile-time constant expression and emits a resolution error if not.
 *
 * This script doesn't just resolve expressions, it also sets types to the
 * extent needed to validate compile-time constant expressions (boolean, int,
 * double, and string types might be set)
 *
 */
public class CompileTimeConstVisitor extends DartNodeTraverser<Void> {

  static CompileTimeConstVisitor create(CoreTypeProvider typeProvider, ResolutionContext context) {
    return new CompileTimeConstVisitor(typeProvider, context);
  }

  private final ResolutionContext context;

  private final Type boolType;
  private final Type doubleType;
  private final Type intType;
  private final Type numType;
  private final Type stringType;
  private final Type dynamicType;


  private CompileTimeConstVisitor(CoreTypeProvider typeProvider, ResolutionContext context) {
    this.context = context;
    this.boolType = typeProvider.getBoolType();
    this.doubleType = typeProvider.getDoubleType();
    this.intType = typeProvider.getIntType();
    this.numType = typeProvider.getNumType();
    this.stringType = typeProvider.getStringType();
    this.dynamicType = typeProvider.getDynamicType();
  }

  private boolean checkBoolean(DartNode x, Type type) {
    if (!type.equals(boolType)) {
      context.onError(x, ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN,
                              type.toString());
      return false;
    }
    return true;
  }

  private boolean checkInt(DartNode x, Type type) {
    if (!type.equals(intType)) {
      context.onError(x,         ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT,
                              type.toString());
      return false;
    }
    return true;
  }

  private boolean checkNumber(DartNode x, Type type) {
    if (!(type.equals(numType) || type.equals(intType) || type.equals(doubleType))) {
      context.onError(x, ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER,
                              type.toString());
      return false;
    }
    return true;
  }

  private boolean checkNumberBooleanOrStringType(DartNode x, Type type) {
    if (!type.equals(intType) && !type.equals(boolType)
        && !type.equals(numType) && !type.equals(doubleType) && !type.equals(stringType)) {
      context.onError(x,
          ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL,
          type.toString());
      return false;
    }
    return true;
  }

  @Override
  public Void visitBinaryExpression(DartBinaryExpression x) {
    x.visitChildren(this);

    DartExpression lhs = x.getArg1();
    DartExpression rhs = x.getArg2();
    Type lhsType = getMostSpecificType(lhs);
    Type rhsType = getMostSpecificType(rhs);
    lhsType.getClass(); // fast null check
    rhsType.getClass(); // fast null check
    switch (x.getOperator()) {
      case NE:
      case EQ:
      case NE_STRICT:
      case EQ_STRICT:
        if (checkNumberBooleanOrStringType(lhs, lhsType)
            && checkNumberBooleanOrStringType(rhs, rhsType)) {
          setType(x, boolType);
        }
        break;

      case AND:
      case OR:
        if (checkBoolean(lhs, lhsType) && checkBoolean(rhs, rhsType)) {
          setType(x, boolType);
        }
        break;

      case BIT_NOT:
      case TRUNC:
      case BIT_XOR:
      case BIT_AND:
      case BIT_OR:
      case SAR:
      case SHL:
        if (checkInt(lhs, lhsType) && checkInt(rhs, rhsType)) {
          setType(x, intType);
        }
        break;

      case ADD:
      case SUB:
      case MUL:
      case DIV:
      case MOD:
        if (checkNumber(lhs, lhsType) && checkNumber(rhs, rhsType)) {
          setType(x, numType);
        }
        break;
      case LT:
      case GT:
      case LTE:
      case GTE:
        if (checkNumber(lhs, lhsType) && checkNumber(rhs, rhsType)) {
          setType(x, boolType);
        }
        break;

      default:
        // all other operators...
        expectedConstant(x);
    }
    return null;
  }

  @Override
  public Void visitParenthesizedExpression(DartParenthesizedExpression x) {
    x.visitChildren(this);
    Type type = getMostSpecificType(x.getExpression());
    setType(x, type);
    return null;
  }

  @Override
  public Void visitPropertyAccess(DartPropertyAccess x) {
    x.visitChildren(this);
    switch (ElementKind.of(x.getQualifier().getSymbol())) {
      case CLASS:
      case LIBRARY:
      case NONE:
        // OK.
        break;
      default:
        expectedConstant(x);
        return null;
    }
    Element element = x.getName().getSymbol();
    if (element != null && !element.getModifiers().isConstant()) {
      expectedConstant(x);
    }
    Type type = getMostSpecificType(x.getName());
    setType(x, type);
    return null;
  }

  @Override
  public Void visitRedirectConstructorInvocation(DartRedirectConstructorInvocation x) {
    Element element = x.getSymbol();
    if (element != null) {
      if (!element.getModifiers().isConstant()) {
        expectedConstant(x);
      }
    }
    x.visitChildren(this);
    return null;
  }

  @Override
  public Void visitStringInterpolation(DartStringInterpolation x) {
    expectedConstant(x);
    return null;
  }

  @Override
  public Void visitSuperExpression(DartSuperExpression x) {
    // No need to traverse further - super() expressions are never constant
    expectedConstant(x);
    return null;
  }

  @Override
  public Void visitUnaryExpression(DartUnaryExpression x) {
    x.visitChildren(this);

    Type type = getMostSpecificType(x.getArg());
    switch (x.getOperator()) {
      case NOT:
        if (checkBoolean(x, type)) {
          x.setType(boolType);
        }
        break;
      case SUB:
        if (checkNumber(x, type)) {
          x.setType(numType);
        }
        break;
      case BIT_NOT:
        if (checkInt(x, type)) {
          x.setType(intType);
        }
        break;
      default:
        expectedConstant(x);
    }
    return null;
  }

  @Override
  public Void visitArrayLiteral(DartArrayLiteral x) {
    if (!x.isConst()) {
      expectedConstant(x);
    } else {
      x.visitChildren(this);
    }
    return null;
  }

  @Override
  public Void visitFunction(DartFunction x) {
    // No need to traverse, functions are always disallowed.
    expectedConstant(x);
    return null;
  }

  @Override
  public Void visitFunctionObjectInvocation(DartFunctionObjectInvocation x) {
    // No need to traverse, function object invocations are always disallowed.
    expectedConstant(x);
    return null;
  }

  @Override
  public Void visitIdentifier(DartIdentifier x) {
    x.visitChildren(this);

    Element element = x.getSymbol();
    switch(ElementKind.of(element)) {
      case CLASS:
      case PARAMETER:
        // OK
        break;
      case FIELD:
      case CONSTRUCTOR:
      case VARIABLE:
      if (!element.getModifiers().isConstant()) {
        expectedConstant(x);
      } else {
        setType(x, getMostSpecificType(x));
      }
      break;

      case NONE:
        Type type = getMostSpecificType(x);
        if (dynamicType.equals(type)) {
          // TODO(zundel) This is the case for unresolved identifiers that need to be recursively
          // checked.
          // expectedConstant(x);
        }
        setType(x, type);
        break;
      default:
        throw new InternalCompilerException("Unexpected element " + x.toString()
            + " kind: " + ElementKind.of(element)
            + " evaluating type for compile-time constant expression.");
    }
    return null;
  }


  @Override
  public Void visitInvocation(DartInvocation x) {
    // No need to traverse, invocations are always disallowed.
    expectedConstant(x);
    return null;
  }

  @Override
  public Void visitMapLiteral(DartMapLiteral x) {
    if (!x.isConst()) {
      expectedConstant(x);
    } else {
      x.visitChildren(this);
    }
    return null;
  }

  @Override
  public Void visitMethodInvocation(DartMethodInvocation x) {
    // No need to traverse, method invocations are always disallowed.
    expectedConstant(x);
    return null;
  }

  @Override
  public Void visitNewExpression(DartNewExpression x) {
    if (!x.isConst()) {
      expectedConstant(x);
    } else {
      x.visitChildren(this);
    }
    return null;
  }


  @Override
  public Void visitThisExpression(DartThisExpression x) {
    // No need to traverse, this expressions are always disallowed.
    expectedConstant(x);
    return null;
  }

  @Override
  public Void visitUnqualifiedInvocation(DartUnqualifiedInvocation x) {
    // No need to traverse, always disallowed.
    expectedConstant(x);
    return null;
  }

  /**
   * Logs a general message "expected a constant expression" error.  Use a more
   * specific error message when possible.
   */
  private void expectedConstant(DartNode x) {
    context.onError(x, ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION);
  }

  /**
   * Determine the most specific type assigned to an expression node. Prefer the
   * setting in the expression's symbol if present. Otherwise, use a type tagged
   * in the expression node itself.
   *
   * @return a non <code>null</code> type value. Dynamic if none other can be
   * determined.
   */
  private Type getMostSpecificType(DartExpression expr) {
    // TODO(zundel): this routine needs to recursively resolve as compile time constants any
    // symbols that have not yet been resolved.
    Element element = (Element)expr.getSymbol();
    switch (ElementKind.of(element)) {
      case FIELD:
        return ((FieldElement)element).getType();
      case METHOD:
        return ((MethodElement)element).getType();
      case VARIABLE:
        return((VariableElement)element).getType();
      case CONSTRUCTOR:
        return ((ConstructorElement)element).getType();
      case NONE:
        if (expr.getType() != null) {
          return expr.getType();
        }
        return dynamicType;
      default:
        throw new InternalCompilerException("Unexpected element " + expr.toString()
                                            + " kind: " + ElementKind.of(element)
                                            + "evaluating type for compile-time constant expression.");
    }
  }

  private void setType(DartExpression x, Type type) {
    Element element = (Element)x.getSymbol();
    if (element != null) {
      Elements.setType(element, type);
    }
    // Also set on the expression node itself.  Not every expression has a symbol.
    x.setType(type);
  }
}
