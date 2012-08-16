// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilationPhase;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.InternalCompilerException;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartArrayLiteral;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartBooleanLiteral;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartDeclaration;
import com.google.dart.compiler.ast.DartDoubleLiteral;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartFunctionObjectInvocation;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartInitializer;
import com.google.dart.compiler.ast.DartIntegerLiteral;
import com.google.dart.compiler.ast.DartInvocation;
import com.google.dart.compiler.ast.DartMapLiteral;
import com.google.dart.compiler.ast.DartMapLiteralEntry;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartNamedExpression;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartNullLiteral;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartParenthesizedExpression;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartRedirectConstructorInvocation;
import com.google.dart.compiler.ast.DartStringInterpolation;
import com.google.dart.compiler.ast.DartStringLiteral;
import com.google.dart.compiler.ast.DartSuperConstructorInvocation;
import com.google.dart.compiler.ast.DartSuperExpression;
import com.google.dart.compiler.ast.DartThisExpression;
import com.google.dart.compiler.ast.DartUnaryExpression;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.DartVariableStatement;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.HasSourceInfo;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeKind;

import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Given an tree, finds all compile-time constant expressions, and determines if
 * each expression matches all the rules for a compile-time constant. Emits a
 * resolution error if not.
 *
 * This script doesn't just resolve expressions, it also sets types to the
 * extent needed to validate compile-time constant expressions (boolean, int,
 * double, and string types might be set)
 */
public class CompileTimeConstantAnalyzer {

  private class ExpressionVisitor extends ASTVisitor<Void> {
    private ExpressionVisitor() {
    }

    private boolean checkBoolean(DartNode x, Type type) {
      // Spec 0.11 allows using "null" literal in place of bool.
      if (x instanceof DartNullLiteral) {
        return true;
      }
      // check actual type
      if (!type.equals(boolType)) {
        context.onError(new DartCompilationError(x,
            ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_BOOLEAN, type
                .toString()));
        return false;
      }
      return true;
    }

    private boolean checkInt(DartNode x, Type type) {
      // Spec 0.11 allows using "null" literal in place of num.
      if (x instanceof DartNullLiteral) {
        return true;
      }
      // check actual type
      if (!type.equals(intType)) {
        context
            .onError(new DartCompilationError(x,
                ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_INT, type
                    .toString()));
        return false;
      }
      return true;
    }

    private boolean checkString(DartNode x, Type type) {
      if (!type.equals(stringType)) {
        context
            .onError(new DartCompilationError(x,
                ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING, type
                    .toString()));
        return false;
      }
      return true;
    }

    private boolean checkNumber(DartNode x, Type type) {
      // for "const" constructor we check "potentially constant expression",
      // so suppose that parameters have correct type
      if (TypeKind.of(type) == TypeKind.DYNAMIC && x.getElement() != null
          && x.getElement().getEnclosingElement() instanceof MethodElement) {
        return true;
      }
      // Spec 0.11 allows using "null" literal in place of num.
      if (x instanceof DartNullLiteral) {
        return true;
      }
      // check actual type
      if (!(type.equals(numType) || type.equals(intType) || type
          .equals(doubleType))) {
        context.onError(new DartCompilationError(x,
            ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_NUMBER, type
                .toString()));

        return false;
      }
      return true;
    }

    private boolean checkNumberBooleanOrStringType(DartNode x, Type type) {
      if (type.equals(intType) || type.equals(boolType)
          || type.equals(numType) || type.equals(doubleType)
          || type.equals(stringType) || (x instanceof DartNullLiteral)) {
        return true;
      } else if (x instanceof DartStringInterpolation) {
        DartStringInterpolation interpolation = (DartStringInterpolation) x;
        for (DartExpression expression : interpolation.getExpressions()) {
          Type expressionType = getMostSpecificType(expression);
          if (!checkNumberBooleanOrStringType(expression, expressionType)) {
            return false;
          }
        }
        return true;
      }
      context.onError(new DartCompilationError(x,
          ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL,
          type.toString()));
      return false;
    }

    /**
     * Logs a general message "expected a constant expression" error. Use a more
     * specific error message when possible.
     */
    private void expectedConstant(HasSourceInfo x) {
      context.onError(new DartCompilationError(x, ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION));
    }

    /**
     * Determine the most specific type assigned to an expression node. Prefer
     * the setting in the expression's element if present. Otherwise, use a type
     * tagged in the expression node itself.
     *
     * @return a non <code>null</code> type value. Dynamic if none other can be
     * determined.
     */
    private Type getMostSpecificType(DartNode node) {
      if (node != null) {
        Type type = inferredTypes.get(node);
        if (type != null) {
          return type;
        }
        Element element = node.getElement();
        if (element != null) {
          type = element.getType();
          if (type != null && TypeKind.of(type) != TypeKind.DYNAMIC) {
            return type;
          }
          if (element instanceof VariableElement) {
            VariableElement variable = (VariableElement) element;
            if (variable.getModifiers().isConstant()) {
              DartExpression value = variable.getDefaultValue();
              if (value != null) {
                type = getMostSpecificType(value);
              }
            }
          } else if (element instanceof FieldElement) {
            FieldElement field = (FieldElement) element;
            if (field.getModifiers().isConstant()) {
              type = field.getConstantType();
            }
          }
          if (type != null) {
            return type;
          }
        }
      }
      return dynamicType;
    }

    private void rememberInferredType(DartNode x, Type type) {
      if (type != null && ! type.equals(dynamicType)) {
        inferredTypes.put(x,  type);
      }
    }

    @Override
    public Void visitArrayLiteral(DartArrayLiteral x) {
      if (!x.isConst()) {
        expectedConstant(x);
      } else {
        for (DartExpression expr : x.getExpressions()) {
          expr.accept(this);
        }
      }
      return null;
    }

    @Override
    public Void visitBinaryExpression(DartBinaryExpression x) {
      x.visitChildren(this);

      DartExpression lhs = x.getArg1();
      DartExpression rhs = x.getArg2();
      Type lhsType = getMostSpecificType(lhs);
      Type rhsType = getMostSpecificType(rhs);

      switch (x.getOperator()) {
        case NE:
        case EQ:
        case NE_STRICT:
        case EQ_STRICT:
          if (checkNumberBooleanOrStringType(lhs, lhsType)
              && checkNumberBooleanOrStringType(rhs, rhsType)) {
            rememberInferredType(x, boolType);
          }
          break;

        case AND:
        case OR:
          if (checkBoolean(lhs, lhsType) && checkBoolean(rhs, rhsType)) {
            rememberInferredType(x, boolType);
          }
          break;

        case BIT_XOR:
        case BIT_AND:
        case BIT_OR:
        case SAR:
        case SHL:
          if (checkInt(lhs, lhsType) && checkInt(rhs, rhsType)) {
            rememberInferredType(x, intType);
          }
          break;

        case ADD:
          if (lhsType.equals(stringType)) {
            // TODO(zundel): remove this when + no longer acceptable as string concat operator
            if (checkString(rhs, rhsType)) {
              rememberInferredType(x, stringType);
            }
          } else {
            checkMathExpression(x, lhs, rhs, lhsType, rhsType);
          }
          break;
        case SUB:
        case MUL:
        case DIV:
          checkMathExpression(x, lhs, rhs, lhsType, rhsType);
          break;
        case MOD:
        case TRUNC:
          if (checkNumber(lhs, lhsType) && checkNumber(rhs, rhsType)) {
            rememberInferredType(x, intType);
          }
          break;
        case LT:
        case GT:
        case LTE:
        case GTE:
          if (checkNumber(lhs, lhsType) && checkNumber(rhs, rhsType)) {
            rememberInferredType(x, boolType);
          }
          break;

        default:
          // all other operators...
          expectedConstant(x);
      }
      return null;
    }

    private void checkMathExpression(DartBinaryExpression x,
                                     DartExpression lhs, DartExpression rhs,
                                     Type lhsType, Type rhsType) {
      if (checkNumber(lhs, lhsType) && checkNumber(rhs, rhsType)) {
        if (lhsType.equals(intType) && rhsType.equals(intType)) {
          rememberInferredType(x, intType);
        } else if (lhsType.equals(doubleType) && rhsType.equals(doubleType)) {
          rememberInferredType(x, doubleType);
        } else  if (lhsType.equals(doubleType) && rhsType.equals(intType)
            || lhsType.equals(intType) && rhsType.equals(doubleType)) {
          rememberInferredType(x, doubleType);
        } else {
          rememberInferredType(x, numType);
        }
      }
    }

    @Override
    public Void visitBooleanLiteral(DartBooleanLiteral x) {
      rememberInferredType(x, boolType);
      return null;
    }

    @Override
    public Void visitDoubleLiteral(DartDoubleLiteral x) {
      rememberInferredType(x, doubleType);
      return null;
    }

    @Override
    public Void visitField(DartField x) {
      x.visitChildren(this);
      if (x.getType() == null || x.getType().equals(dynamicType)) {
        Type type = getMostSpecificType(x.getValue());
        rememberInferredType(x, type);
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
    public Void visitNamedExpression(DartNamedExpression node) {
      return node.getExpression().accept(this);
    }

    @Override
    public Void visitIdentifier(DartIdentifier x) {
      x.visitChildren(this);

      if (x.getParent() instanceof DartDeclaration<?>
          && ((DartDeclaration<?>) x.getParent()).getName() == x) {
        return null;
      }

      Element element = x.getElement();
      switch (ElementKind.of(element)) {
        case CLASS:
        case PARAMETER:
        case LIBRARY_PREFIX:
          break;

        case FIELD:
          FieldElement fieldElement = (FieldElement) element;

          // Check for circular references.
          if (element != null && visitedElements.contains(element)) {
            context.onError(new DartCompilationError(x, ResolverErrorCode.CIRCULAR_REFERENCE));
            rememberInferredType(x, getMostSpecificType(x));
            return null;
          }
          visitedElements.add(element);

          // Should be declared as constant.
          // TODO(brianwilkerson) Remove the second condition when final variables are no longer
          // treated like constants
          if (!element.getModifiers().isConstant() && !element.getModifiers().isFinal()) {
            expectedConstant(x);
          }

          // Infer type by visiting node or cached from Element.
          final Type inferredType;
          if (element instanceof FieldNodeElement) {
            FieldNodeElement fieldNodeElement = (FieldNodeElement) element;
            DartNode fieldNode = fieldNodeElement.getNode();
            fieldNode.accept(this);
            inferredType = getMostSpecificType(fieldNode);
            fieldNodeElement.setConstantType(inferredType);
          } else if (fieldElement.getType() != null
              && !fieldElement.getType().equals(dynamicType)) {
            inferredType = fieldElement.getType();
          } else {
            inferredType = fieldElement.getConstantType();
          }

          // Done with this element.
          visitedElements.remove(element);

          rememberInferredType(x, inferredType);
          break;

        case METHOD:
          if (!element.getModifiers().isStatic() && !Elements.isTopLevel(element)) {
            expectedConstant(x);
          }
          return null;

        case NONE:
          expectedConstant(x);
          return null;

        default:
          throw new InternalCompilerException("Unexpected element "
              + x.toString() + " kind: " + ElementKind.of(element)
              + " evaluating type for compile-time constant expression.");
      }
      return null;
    }


    @Override
    public Void visitIntegerLiteral(DartIntegerLiteral x) {
      rememberInferredType(x, intType);
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
        for (DartMapLiteralEntry entry : x.getEntries()) {
          entry.accept(this);
        }
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
        for (DartExpression arg : x.getArguments()) {
          arg.accept(this);
        }
      }
      rememberInferredType(x, x.getConstructor().getType());
      return null;
    }

    @Override
    public Void visitParenthesizedExpression(DartParenthesizedExpression x) {
      x.visitChildren(this);
      Type type = getMostSpecificType(x.getExpression());
      rememberInferredType(x, type);
      return null;
    }

    @Override
    public Void visitPropertyAccess(DartPropertyAccess x) {
      switch (ElementKind.of(x.getQualifier().getElement())) {
        case CLASS:
        case LIBRARY_PREFIX:
        case NONE:
          // OK.
          break;
        default:
          expectedConstant(x);
          return null;
      }

      Type type = getMostSpecificType(x.getName());
      rememberInferredType(x, type);

      Element element = x.getName().getElement();
      if (element != null) {
        // OK. Static method reference.
        if (ElementKind.of(element) == ElementKind.METHOD && element.getModifiers().isStatic()) {
          return null;
        }
        // OK. Constant field.
        // TODO(brianwilkerson) Remove the second condition when final variables are no longer
        // treated like constants
        if (element.getModifiers().isConstant() || element.getModifiers().isFinal()) {
          return null;
        }
        // Fail.
        expectedConstant(x);
      }
      return null;
    }

    @Override
    public Void visitRedirectConstructorInvocation(DartRedirectConstructorInvocation x) {
      Element element = x.getElement();
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
      x.visitChildren(this);
      for (DartExpression expression : x.getExpressions()) {
        Type expressionType = getMostSpecificType(expression);
        checkNumberBooleanOrStringType(expression, expressionType);
      }
      return null;
    }

    @Override
    public Void visitStringLiteral(DartStringLiteral x) {
      rememberInferredType(x, stringType);
      return null;
    }

    @Override
    public Void visitSuperExpression(DartSuperExpression x) {
      if (!x.getElement().getModifiers().isConstant()) {
        expectedConstant(x);
      }
      return null;
    }

    @Override
    public Void visitThisExpression(DartThisExpression x) {
      // No need to traverse, this expressions are never constant
      expectedConstant(x);
      return null;
    }

    @Override
    public Void visitUnaryExpression(DartUnaryExpression x) {
      x.visitChildren(this);

      Type type = getMostSpecificType(x.getArg());
      switch (x.getOperator()) {
        case NOT:
          if (checkBoolean(x.getArg(), type)) {
            rememberInferredType(x, boolType);
          }
          break;
        case SUB:
          if (checkNumber(x.getArg(), type)) {
            rememberInferredType(x, numType);
          }
          break;
        case BIT_NOT:
          if (checkInt(x.getArg(), type)) {
            rememberInferredType(x, intType);
          }
          break;
        default:
          expectedConstant(x);
      }
      return null;
    }

    @Override
    public Void visitSuperConstructorInvocation(DartSuperConstructorInvocation x) {
      x.visitChildren(this);
      return null;
    }

    @Override
    public Void visitUnqualifiedInvocation(DartUnqualifiedInvocation x) {
      // No need to traverse, always disallowed.
      expectedConstant(x);
      return null;
    }
  }

  private class FindCompileTimeConstantExpressionsVisitor extends ASTVisitor<Void> {
    private ClassElement currentClass;
    private boolean inConstConstructor;

    @Override
    public Void visitArrayLiteral(DartArrayLiteral node) {
      if (node.isConst()) {
        for (DartExpression expr : node.getExpressions()) {
          checkConstantExpression(expr);
        }
        return null;
      }
      return super.visitArrayLiteral(node);
    }

    @Override
    public Void visitField(DartField node) {
      if (node.getParent() != null) {
        DartNode pp = node.getParent().getParent();
        boolean isFinalTopLevelField = node.getModifiers().isFinal() && pp instanceof DartUnit;
        boolean isClassField = pp instanceof DartClass;
        boolean isStatic = node.getModifiers().isStatic();
        boolean isConst = node.getModifiers().isConstant();
        if (isFinalTopLevelField || (isClassField && isStatic) || isConst) {
          Type type = checkConstantExpression(node.getValue());
          if (node.getElement().getType().equals(dynamicType)) {
            node.getElement().setConstantType(type);
          }
          return null;
        }
        if (isClassField && !isStatic) {
          DartExpression value = node.getValue();
          checkInstanceFieldInitializer(value);
        }
      }
      return super.visitField(node);
    }

    @Override
    public Void visitClass(DartClass node) {
      ClassElement oldClassElement = currentClass;
      currentClass = node.getElement();
      try {
        return super.visitClass(node);
      } finally {
        currentClass = oldClassElement;
      }
    }

    @Override
    public Void visitMethodDefinition(DartMethodDefinition node) {
      inConstConstructor = node.getModifiers().isConstant();
      return super.visitMethodDefinition(node);
    }

    @Override
    public Void visitInitializer(DartInitializer node) {
      if (inConstConstructor) {
        String name = node.getInitializerName();
        if (name != null) {
          Element member = currentClass.lookupLocalElement(name);
          if (member instanceof FieldElement) {
            if (member.getModifiers().isFinal()) {
              checkConstantExpression(node.getValue());
            }
          }
        } else {
          DartExpression value = node.getValue();
          if (value instanceof DartSuperConstructorInvocation
              || value instanceof DartRedirectConstructorInvocation) {
            List<DartExpression> arguments = ((DartInvocation) value).getArguments();
            for (DartExpression argument : arguments) {
              checkConstantExpression(argument);
            }
          }
        }
      }
      return super.visitInitializer(node);
    }

    @Override
    public Void visitMapLiteral(DartMapLiteral node) {
      if (node.isConst()) {
        for (DartMapLiteralEntry entry : node.getEntries()) {
          checkConstantExpression(entry.getKey());
          checkConstantExpression(entry.getValue());
        }
        return null;
      }
      return super.visitMapLiteral(node);
    }

    @Override
    public Void visitNewExpression(DartNewExpression node) {
      if (node.isConst()) {
        for (DartExpression arg : node.getArguments()) {
          checkConstantExpression(arg);
        }
        return null;
      }
      return super.visitNewExpression(node);
    }

    @Override
    public Void visitParameter(DartParameter node) {
      checkConstantExpression(node.getDefaultExpr());
      List<DartParameter> parameters = node.getFunctionParameters();
      if (parameters != null) {
        for (DartParameter parameter : parameters) {
          visitParameter(parameter);
        }
      }
      return null;
    }

    @Override
    public Void visitVariableStatement(DartVariableStatement node) {
      Modifiers modifiers = node.getModifiers();
      if (modifiers.isConstant() || (modifiers.isStatic() && modifiers.isFinal())) {
        for (DartVariable variable : node.getVariables()) {
          if (variable.getValue() != null) {
            checkConstantExpression(variable.getValue());
          }
        }
        return null;
      }
      return super.visitVariableStatement(node);
    }

    @Override
    public Void visitRedirectConstructorInvocation(DartRedirectConstructorInvocation node) {
      // Don't evaluate now, wait until it is referenced and evaluate as part of the expression
      return null;
    }

    @Override
    public Void visitSuperConstructorInvocation(DartSuperConstructorInvocation node) {
      // Don't evaluate now, wait until it is referenced and evaluate as part of the expression
      return null;
    }
  }

  public static class Phase implements DartCompilationPhase {
    /**
     * Executes element resolution on the given compilation unit.
     *
     * @param context The listener through which compilation errors are reported
     *          (not <code>null</code>)
     */
    @Override
    public DartUnit exec(DartUnit unit, DartCompilerContext context,
                         CoreTypeProvider typeProvider) {
      new CompileTimeConstantAnalyzer(typeProvider, context).exec(unit);
      return unit;
    }
  }

  public Set<Element> visitedElements = Sets.newHashSet();

  public Map<DartNode, Type> inferredTypes = Maps.newHashMap();

  private final DartCompilerContext context;
  private final Type boolType;
  private final Type doubleType;
  private final Type intType;
  private final Type numType;
  private final Type stringType;
  private final Type dynamicType;

  public CompileTimeConstantAnalyzer(CoreTypeProvider typeProvider,
      DartCompilerContext context) {
    this.context = context;
    this.boolType = typeProvider.getBoolType();
    this.doubleType = typeProvider.getDoubleType();
    this.intType = typeProvider.getIntType();
    this.numType = typeProvider.getNumType();
    this.stringType = typeProvider.getStringType();
    this.dynamicType = typeProvider.getDynamicType();
  }

  private Type checkConstantExpression(DartExpression expression) {
    if (expression != null) {
      ExpressionVisitor visitor = new ExpressionVisitor();
      expression.accept(visitor);
      return visitor.getMostSpecificType(expression);
    }
    return null;
  }

  public void exec(DartUnit unit) {
    unit.accept(new FindCompileTimeConstantExpressionsVisitor());
  }

  private void checkInstanceFieldInitializer(DartExpression value) {
    if (value != null) {
      value.accept(new ASTVisitor<Void>() {
        @Override
        public Void visitThisExpression(DartThisExpression node) {
          context.onError(new DartCompilationError(node,
              ResolverErrorCode.CANNOT_USE_THIS_IN_INSTANCE_FIELD_INITIALIZER));
          return null;
        }
        @Override
        public Void visitIdentifier(DartIdentifier node) {
          NodeElement element = node.getElement();
          if (ElementKind.of(element) == ElementKind.FIELD) {
            FieldElement fieldElement = (FieldElement) element;
            boolean isStatic = fieldElement.getModifiers().isStatic()
                || Elements.isTopLevel(fieldElement);
            if (!isStatic) {
              context.onError(new DartCompilationError(node,
                  ResolverErrorCode.CANNOT_USE_INSTANCE_FIELD_IN_INSTANCE_FIELD_INITIALIZER));
            }
          }
          return null;
        }
      });
    }
  }
}
