// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.base.Joiner;
import com.google.common.base.Objects;
import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.LinkedListMultimap;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Multimap;
import com.google.common.collect.Sets;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilationPhase;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ErrorSeverity;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.SystemLibraryManager;
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
import com.google.dart.compiler.ast.DartDeclaration;
import com.google.dart.compiler.ast.DartDefault;
import com.google.dart.compiler.ast.DartDoWhileStatement;
import com.google.dart.compiler.ast.DartDoubleLiteral;
import com.google.dart.compiler.ast.DartEmptyStatement;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
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
import com.google.dart.compiler.ast.DartInvocation;
import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartLibraryDirective;
import com.google.dart.compiler.ast.DartLiteral;
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
import com.google.dart.compiler.ast.DartReturnBlock;
import com.google.dart.compiler.ast.DartReturnStatement;
import com.google.dart.compiler.ast.DartSourceDirective;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartStringInterpolation;
import com.google.dart.compiler.ast.DartStringLiteral;
import com.google.dart.compiler.ast.DartSuperConstructorInvocation;
import com.google.dart.compiler.ast.DartSuperExpression;
import com.google.dart.compiler.ast.DartSwitchMember;
import com.google.dart.compiler.ast.DartSwitchStatement;
import com.google.dart.compiler.ast.DartSyntheticErrorExpression;
import com.google.dart.compiler.ast.DartSyntheticErrorIdentifier;
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
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.HasSourceInfo;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ClassNodeElement;
import com.google.dart.compiler.resolver.ConstructorElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.CyclicDeclarationException;
import com.google.dart.compiler.resolver.DuplicatedInterfaceException;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.FunctionAliasElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.NodeElement;
import com.google.dart.compiler.resolver.ResolverErrorCode;
import com.google.dart.compiler.resolver.TypeErrorCode;
import com.google.dart.compiler.resolver.VariableElement;
import com.google.dart.compiler.type.InterfaceType.Member;
import com.google.dart.compiler.util.apache.ObjectUtils;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

/**
 * Analyzer of static type information.
 */
public class TypeAnalyzer implements DartCompilationPhase {

  private final Set<ClassElement> diagnosedAbstractClasses = Sets.newHashSet();

  /**
   * Perform type analysis on the given AST rooted at <code>node</code>.
   *
   * @param node The root of the tree to analyze
   * @param typeProvider The source of pre-defined type definitions
   * @param context The compilation context (DartCompilerContext)
   * @param currentClass The class that contains <code>node</code>. Will be null
   *        for top-level declarations.
   * @return The type of <code>node</code>.
   */
  public static Type analyze(DartNode node, CoreTypeProvider typeProvider,
                             DartCompilerContext context, InterfaceType currentClass) {
    Set<ClassElement> diagnosed = Sets.newHashSet();
    Analyzer analyzer = new Analyzer(context, typeProvider, diagnosed);
    analyzer.setCurrentClass(currentClass);
    return node.accept(analyzer);
  }

  @Override
  public DartUnit exec(DartUnit unit, DartCompilerContext context, CoreTypeProvider typeProvider) {
    unit.accept(new Analyzer(context, typeProvider, diagnosedAbstractClasses));
    return unit;
  }

  @VisibleForTesting
  static class Analyzer extends ASTVisitor<Type> {
    private final DynamicType dynamicType;
    private final Type stringType;
    private final InterfaceType defaultLiteralMapType;
    private final Type voidType;
    private final DartCompilerContext context;
    private final Types types;
    private Type expected;
    private InterfaceType currentClass;
    private final InterfaceType boolType;
    private final InterfaceType numType;
    private final InterfaceType intType;
    private final InterfaceType doubleType;
    private final Type nullType;
    private final InterfaceType functionType;
    private final InterfaceType dynamicIteratorType;
    private final boolean developerModeChecks;
    private final boolean suppressSdkWarnings;

    /**
     * Keeps track of the number of nested catches, used to detect re-throws
     * outside of any catch block.
     */
    private int catchDepth = 0;

    Analyzer(DartCompilerContext context, CoreTypeProvider typeProvider,
             Set<ClassElement> diagnosedAbstractClasses) {
      this.context = context;
      this.developerModeChecks = context.getCompilerConfiguration().developerModeChecks();
      this.types = Types.getInstance(typeProvider);
      this.dynamicType = typeProvider.getDynamicType();
      this.stringType = typeProvider.getStringType();
      this.defaultLiteralMapType = typeProvider.getMapType(stringType, dynamicType);
      this.voidType = typeProvider.getVoidType();
      this.boolType = typeProvider.getBoolType();
      this.numType = typeProvider.getNumType();
      this.intType = typeProvider.getIntType();
      this.doubleType = typeProvider.getDoubleType();
      this.nullType = typeProvider.getNullType();
      this.functionType = typeProvider.getFunctionType();
      this.dynamicIteratorType = typeProvider.getIteratorType(dynamicType);
      this.suppressSdkWarnings = context.getCompilerConfiguration().getCompilerOptions()
          .suppressSdkWarnings();
    }

    @VisibleForTesting
    void setCurrentClass(InterfaceType type) {
      currentClass = type;
    }

    private InterfaceType getCurrentClass() {
      return currentClass;
    }

    private DynamicType typeError(HasSourceInfo node, ErrorCode code, Object... arguments) {
      onError(node, code, arguments);
      return dynamicType;
    }

    private void onError(HasSourceInfo node, ErrorCode errorCode, Object... arguments) {
      onError(node.getSourceInfo(), errorCode, arguments);
    }

    private void onError(SourceInfo errorTarget, ErrorCode errorCode, Object... arguments) {
      Source source = errorTarget.getSource();
      if (suppressSdkWarnings && errorCode.getErrorSeverity() == ErrorSeverity.WARNING) {
        if (source != null && SystemLibraryManager.isDartUri(source.getUri())) {
          return;
        }
      }
      context.onError(new DartCompilationError(errorTarget, errorCode, arguments));
    }

    AssertionError internalError(HasSourceInfo node, String message, Object... arguments) {
      message = String.format(message, arguments);
      context.onError(new DartCompilationError(node, TypeErrorCode.INTERNAL_ERROR,
                                                        message));
      return new AssertionError("Internal error: " + message);
    }

    private Type typeOfLiteral(DartLiteral node) {
      Type type = node.getType();
      return type == null ? voidType : type;
    }

    private Token getBasicOperator(DartNode diagnosticNode, Token op) {
      switch(op) {
        case INC:
          return Token.ADD;
        case DEC:
          return Token.SUB;
        case ASSIGN_BIT_OR:
          return Token.BIT_OR;
        case ASSIGN_BIT_XOR:
          return Token.BIT_XOR;
        case ASSIGN_BIT_AND:
          return Token.BIT_AND;
        case ASSIGN_SHL:
          return Token.SHL;
        case ASSIGN_SAR:
          return Token.SAR;
        case ASSIGN_ADD:
          return Token.ADD;
        case ASSIGN_SUB:
          return Token.SUB;
        case ASSIGN_MUL:
          return Token.MUL;
        case ASSIGN_DIV:
          return Token.DIV;
        case ASSIGN_MOD:
          return Token.MOD;
        case ASSIGN_TRUNC:
          return Token.TRUNC;
        default:
          internalError(diagnosticNode, "unexpected operator %s", op.name());
          return null;
      }
    }

    @Override
    public Type visitRedirectConstructorInvocation(DartRedirectConstructorInvocation node) {
      return checkConstructorForwarding(node, node.getElement());
    }

    private String methodNameForUnaryOperator(DartNode diagnosticNode, Token operator) {
      if (operator == Token.SUB) {
        return "operator negate";
      } else if (operator == Token.BIT_NOT) {
        return "operator ~";
      }
      return "operator " + getBasicOperator(diagnosticNode, operator).getSyntax();
    }

    private String methodNameForBinaryOperator(Token operator) {
      if (operator == Token.EQ) {
        return "operator equals";
      }
      return "operator " + operator.getSyntax();
    }

    private Type analyzeBinaryOperator(DartNode node, Type lhsType, Token operator,
        DartNode diagnosticNode, DartExpression rhs) {
      Type rhsType = nonVoidTypeOf(rhs);
      String methodName = methodNameForBinaryOperator(operator);
      Member member = lookupMember(lhsType, methodName, diagnosticNode);
      if (member != null) {
        node.setElement(member.getElement());
        Type returnType = analyzeMethodInvocation(lhsType, member, methodName, diagnosticNode,
            Collections.<Type> singletonList(rhsType),
            Collections.<DartExpression> singletonList(rhs));
        // tweak return type for int/int and int/double operators
        {
          boolean lhsInt = intType.equals(lhsType);
          boolean rhsInt = intType.equals(rhsType);
          boolean lhsDouble = doubleType.equals(lhsType);
          boolean rhsDouble = doubleType.equals(rhsType);
          switch (operator) {
            case ADD:
            case SUB:
            case MUL:
            case TRUNC:
            case MOD:
              if (lhsInt && rhsInt) {
                return intType;
              }
            case DIV:
              if (lhsDouble || rhsDouble) {
                return doubleType;
              }
          }
        }
        // done
        return returnType;
      } else {
        return dynamicType;
      }
    }

    @Override
    public Type visitBinaryExpression(DartBinaryExpression node) {
      DartExpression lhsNode = node.getArg1();
      Type lhs = nonVoidTypeOf(lhsNode);
      DartExpression rhsNode = node.getArg2();
      Token operator = node.getOperator();
      switch (operator) {
        case ASSIGN: {
          Type rhs = nonVoidTypeOf(rhsNode);
          checkPropagatedTypeCompatible(lhsNode, rhs);
          if (!hasInferredType(lhsNode)) {
            checkAssignable(rhsNode, lhs, rhs);
          }
          return rhs;
        }

        case ASSIGN_ADD: {
          checkStringConcatPlus(lhsNode);
          checkStringConcatPlus(rhsNode);
        }
        case ASSIGN_SUB:
        case ASSIGN_MUL:
        case ASSIGN_DIV:
        case ASSIGN_MOD:
        case ASSIGN_TRUNC: {
          Token basicOperator = getBasicOperator(node, operator);
          Type type = analyzeBinaryOperator(node, lhs, basicOperator, lhsNode, rhsNode);
          checkAssignable(node, lhs, type);
          return type;
        }

        case OR:
        case AND: {
          checkAssignable(lhsNode, boolType, lhs);
          checkAssignable(boolType, rhsNode);
          return boolType;
        }

        case ASSIGN_BIT_OR:
        case ASSIGN_BIT_XOR:
        case ASSIGN_BIT_AND:
        case ASSIGN_SHL:
        case ASSIGN_SAR: {
          // Bit operations are only supported by integers and
          // thus cannot be looked up on num. To ease usage of
          // bit operations, we currently allow them to be used
          // if the left-hand-side is of type num.
          // TODO(karlklose) find a clean solution, i.e., without a special case for num.
          if (lhs.equals(numType)) {
            checkAssignable(rhsNode, numType, typeOf(rhsNode));
            return intType;
          } else {
            Token basicOperator = getBasicOperator(node, operator);
            Type type = analyzeBinaryOperator(node, lhs, basicOperator, lhsNode, rhsNode);
            checkAssignable(node, lhs, type);
            return type;
          }
        }

        case BIT_OR:
        case BIT_XOR:
        case BIT_AND:
        case SHL:
        case SAR: {
          // Bit operations are only supported by integers and
          // thus cannot be looked up on num. To ease usage of
          // bit operations, we currently allow them to be used
          // if the left-hand-side is of type num.
          // TODO(karlklose) find a clean solution, i.e., without a special case for num.
          if (lhs.equals(numType)) {
            checkAssignable(rhsNode, numType, typeOf(rhsNode));
            return intType;
          } else {
            return analyzeBinaryOperator(node, lhs, operator, lhsNode, rhsNode);
          }
        }

        case ADD:  {
          checkStringConcatPlus(lhsNode);
          checkStringConcatPlus(rhsNode);
        }
        case SUB:
        case MUL:
        case DIV:
        case TRUNC:
        case MOD:
        case LT:
        case GT:
        case LTE:
        case GTE:
          return analyzeBinaryOperator(node, lhs, operator, lhsNode, rhsNode);

        case EQ: {
          // try to resolve "==" to "operator equals()", but don't complain if can not find it
          String methodName = methodNameForBinaryOperator(operator);
          InterfaceType itype = types.getInterfaceType(lhs);
          if (itype != null) {
            Member member = itype.lookupMember(methodName);
            if (member != null) {
              node.setElement(member.getElement());
            }
          }
        }
       case NE:
       case EQ_STRICT:
       case NE_STRICT:
         nonVoidTypeOf(rhsNode);
         return boolType;

       case AS:
         return typeOf(rhsNode);

       case IS:
         if (rhsNode instanceof DartUnaryExpression) {
           assert ((DartUnaryExpression) rhsNode).getOperator() == Token.NOT;
           nonVoidTypeOf(((DartUnaryExpression) rhsNode).getArg());
         } else {
           nonVoidTypeOf(rhsNode);
         }
         return boolType;

       case COMMA:
         return typeOf(rhsNode);

        default:
          throw new AssertionError("Unknown operator: " + operator);
      }
    }

    private void checkStringConcatPlus(DartExpression node) {
      if (node != null) {
        Type type = null;
        if (node.getElement() != null) {
          type = node.getElement().getType();
        } else if (node.getType() != null) {
          type = node.getType();
        }
        if (type != null) {
          if (type.equals(stringType)) {
            onError(node, TypeErrorCode.PLUS_CANNOT_BE_USED_FOR_STRING_CONCAT);
          }
        }
      }
    }

    @Override
    public Type visitVariableStatement(DartVariableStatement node) {
      Type type = typeOf(node.getTypeNode());
      visit(node.getVariables());
      return type;
    }

    private List<Type> analyzeArgumentTypes(List<? extends DartExpression> argumentNodes) {
      List<Type> argumentTypes = Lists.newArrayListWithCapacity(argumentNodes.size());
      for (DartExpression argumentNode : argumentNodes) {
        argumentTypes.add(nonVoidTypeOf(argumentNode));
      }
      return argumentTypes;
    }

    private Member lookupMember(Type receiver, String methodName, DartNode diagnosticNode) {
      InterfaceType itype = types.getInterfaceType(receiver);
      if (itype == null) {
        diagnoseNonInterfaceType(diagnosticNode, receiver);
        return null;
      }
      Member member = itype.lookupMember(methodName);
      if (member == null) {
        typeError(diagnosticNode, TypeErrorCode.INTERFACE_HAS_NO_METHOD_NAMED,
                  receiver, methodName);
        return null;
      }
      return member;
    }

    /**
     * Checks that if left-hand-side is {@link VariableElement} with propagated type, then it
     * assigned value type is compatible with this propagated type.
     */
    private void checkPropagatedTypeCompatible(DartExpression lhsNode, Type rhs) {
      if (lhsNode.getElement() instanceof VariableElement) {
        VariableElement variableElement = (VariableElement) lhsNode.getElement();
        Type variableType = variableElement.getType();
        if (variableType.isInferred() && !types.isAssignable(variableType, rhs)) {
          Elements.setType(variableElement, dynamicType);
        }
      }
    }

    /**
     * @return <code>true</code> if given {@link DartNode} has inferred {@link Type}.
     */
    private static boolean hasInferredType(DartNode node) {
      return node != null && hasInferredType(node.getElement());
    }

    /**
     * @return <code>true</code> if given {@link Element} is has inferred {@link Type}.
     */
    private static boolean hasInferredType(Element element) {
      return element != null && element.getType() != null && element.getType().isInferred();
    }

    /**
     * Helper for visiting {@link DartNode} which happens only if "condition" is satisfied. Attempts
     * to infer types of {@link VariableElement}s from given "condition".
     */
    private void visitConditionalNode(DartExpression condition, DartNode node) {
      final VariableElementsRestorer variableRestorer = new VariableElementsRestorer();
      try {
        if (condition != null) {
          condition.accept(new ASTVisitor<Void>() {
            boolean negation = false;
            @Override
            public Void visitUnaryExpression(DartUnaryExpression node) {
              boolean negationOld = negation;
              try {
                if (node.getOperator() == Token.NOT) {
                  negation = !negation;
                }
                return super.visitUnaryExpression(node);
              } finally {
                negation = negationOld;
              }
            }

            @Override
            public Void visitBinaryExpression(DartBinaryExpression node) {
              // don't infer type if condition negated
              if (!negation && (node.getOperator() == Token.IS || node.getOperator() == Token.AS)) {
                DartExpression arg1 = node.getArg1();
                DartExpression arg2 = node.getArg2();
                if (arg1 instanceof DartIdentifier && arg1.getElement() instanceof VariableElement
                    && arg2 instanceof DartTypeExpression) {
                  VariableElement variableElement = (VariableElement) arg1.getElement();
                  Type rhsType = arg2.getType();
                  Type varType = Types.makeInferred(rhsType);
                  variableRestorer.setType(variableElement, varType);
                }
              }
              // visit && expressions
              if (node.getOperator() == Token.AND) {
                return super.visitBinaryExpression(node);
              }
              // other operators, such as || - don't infer types
              return null;
            }
          });
        }
        typeOf(node);
      } finally {
        variableRestorer.restore();
      }
    }

    /**
     * Helper to temporarily set {@link Type} of {@link VariableElement} and restore original later.
     */
    private class VariableElementsRestorer {
      private final Map<VariableElement, Type> typesMap = Maps.newHashMap();
      void setType(VariableElement element, Type inferredType) {
        Type currentType = element.getType();
        // remember original if not yet
        if (!typesMap.containsKey(element)) {
          typesMap.put(element, currentType);
        }
        // apply inferred type
        if (inferredType != null) {
          if (TypeKind.of(currentType) == TypeKind.DYNAMIC && currentType.isInferred()) {
            // if we fell back to Dynamic, keep it
          } else {
            Type unionType = getUnionType(currentType, inferredType);
            Elements.setType(element, unionType);
          }
        }
      }

      /**
       * @return the {@link Type} which is both "a" and "b" types. May be "Dynamic" if "a" and "b"
       *         don't form hierarchy.
       */
      Type getUnionType(Type a, Type b) {
        if (TypeKind.of(a) == TypeKind.DYNAMIC) {
          return b;
        }
        if (TypeKind.of(b) == TypeKind.DYNAMIC) {
          return a;
        }
        if (types.isSubtype(a, b)) {
          return a;
        }
        if (types.isSubtype(b, a)) {
          return b;
        }
        // TODO(scheglov) return union of types, but this is not easy
        return Types.makeInferred(dynamicType);
      }

      void restore() {
        for (Entry<VariableElement, Type> entry : typesMap.entrySet()) {
          Elements.setType(entry.getKey(), entry.getValue());
        }
      }
    }

    /**
     * @return <code>true</code> if we can prove that given {@link DartStatement} always leads to
     *         the exit from the enclosing function.
     */
    private static boolean isExitFromFunction(DartStatement statement) {
      // "return" is always exit
      if (statement instanceof DartReturnStatement) {
        return true;
      }
      // "throw" is exit if no enclosing "try"
      if (statement instanceof DartThrowStatement) {
        for (DartNode p = statement; p != null && !(p instanceof DartFunction); p = p.getParent()) {
          // TODO(scheglov) Can be enhanced:
          // 1. check if there is "catch" block which can catch this exception;
          // 2. even if there is such "catch", we will not visit the rest of the "try".
          if (p instanceof DartTryStatement) {
            return false;
          }
        }
        return true;
      }
      // "block" is exit if its last statement is exit
      if (statement instanceof DartBlock) {
        DartBlock block = (DartBlock) statement;
        List<DartStatement> statements = block.getStatements();
        if (!statements.isEmpty()) {
          return isExitFromFunction(statements.get(statements.size() - 1));
        }
      }
      // can not prove that given statement is always exit
      return false;
    }

    /**
     * Helper for setting {@link Type}s of {@link VariableElement}s when given "condition" is NOT
     * satisfied.
     */
    private static void inferVariableTypesFromIsNotConditions(DartExpression condition,
        final VariableElementsRestorer variableRestorer) {
      condition.accept(new ASTVisitor<Void>() {
        boolean negation = false;

        @Override
        public Void visitUnaryExpression(DartUnaryExpression node) {
          boolean negationOld = negation;
          try {
            if (node.getOperator() == Token.NOT) {
              negation = !negation;
            }
            return super.visitUnaryExpression(node);
          } finally {
            negation = negationOld;
          }
        }

        @Override
        public Void visitBinaryExpression(DartBinaryExpression node) {
          // analyze (v is Type)
          if (node.getOperator() == Token.IS) {
            DartExpression arg1 = node.getArg1();
            DartExpression arg2 = node.getArg2();
            if (arg1 instanceof DartIdentifier && arg1.getElement() instanceof VariableElement) {
              VariableElement variableElement = (VariableElement) arg1.getElement();
              // !(v is Type)
              if (negation && arg2 instanceof DartTypeExpression) {
                Type isType = arg2.getType();
                Type varType = Types.makeInferred(isType);
                variableRestorer.setType(variableElement, varType);
              }
              // (v is! Type)
              if (!negation) {
                if (arg2 instanceof DartUnaryExpression) {
                  DartUnaryExpression unary2 = (DartUnaryExpression) arg2;
                  if (unary2.getOperator() == Token.NOT
                      && unary2.getArg() instanceof DartTypeExpression) {
                    Type isType = unary2.getArg().getType();
                    Type varType = Types.makeInferred(isType);
                    variableRestorer.setType(variableElement, varType);
                  }
                }
              }
            }
          }
          // visit || expressions
          if (node.getOperator() == Token.OR) {
            return super.visitBinaryExpression(node);
          }
          // other operators, such as && - don't infer types
          return null;
        }
      });
    }

    private boolean checkAssignable(DartNode node, Type t, Type s) {
      t.getClass(); // Null check.
      s.getClass(); // Null check.
      // ignore inferred types, treat them as Dynamic
      if (t.isInferred() || s.isInferred()) {
        return true;
      }
      // do check and report error
      if (!types.isAssignable(t, s)) {
        typeError(node, TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, s, t);
        return false;
      }
      // OK
      return true;
    }

    private boolean checkAssignable(Type targetType, DartExpression node) {
      // analyze "node"
      Type nodeType = typeOf(node);
      // target is Dynamic, any source type is good, even "void"
      if (TypeKind.of(targetType) == TypeKind.DYNAMIC) {
        return true;
      }
      // source was Dynamic
      if (hasInferredType(node)) {
        return true;
      }
      // OK, check types
      checkNonVoid(node, nodeType);
      return checkAssignable(node, targetType, nodeType);
    }

    private Type analyzeMethodInvocation(Type receiver, Member member, String name,
                                         DartNode diagnosticNode,
                                         List<Type> argumentTypes,
                                         List<DartExpression> argumentNodes) {
      if (member == null) {
        return dynamicType;
      }
      FunctionType ftype;
      Element element = member.getElement();
      switch (ElementKind.of(element)) {
        case METHOD: {
          MethodElement method = (MethodElement) element;
          if (method.getModifiers().isStatic()) {
            return typeError(diagnosticNode, TypeErrorCode.IS_STATIC_METHOD_IN,
                             name, receiver);
          }
          ftype = (FunctionType) member.getType();
          break;
        }
        case FIELD: {
          FieldElement field = (FieldElement) element;
          if (field.getModifiers().isStatic()) {
            return typeError(diagnosticNode, TypeErrorCode.IS_STATIC_FIELD_IN,
                             name, receiver);
          }
          switch (TypeKind.of(member.getType())) {
            case FUNCTION:
              ftype = (FunctionType) member.getType();
              break;
            case FUNCTION_ALIAS:
              ftype = types.asFunctionType((FunctionAliasType) member.getType());
              break;
            case DYNAMIC:
              return member.getType();
            default:
              // target.field() as Function invocation.
              if (types.isAssignable(functionType, field.getType())) {
                return dynamicType;
              }
              // "field" is not Function, so bad structure.
              return typeError(diagnosticNode, TypeErrorCode.USE_ASSIGNMENT_ON_SETTER,
                               name, receiver);
          }
          break;
        }
        default:
          return typeError(diagnosticNode, TypeErrorCode.NOT_A_METHOD_IN, name, receiver);
      }
      return checkArguments(diagnosticNode, argumentNodes, argumentTypes.iterator(), ftype);
    }

    private Type diagnoseNonInterfaceType(DartNode node, Type type) {
      switch (TypeKind.of(type)) {
        case DYNAMIC:
          return type;

        case FUNCTION:
        case FUNCTION_ALIAS:
        case INTERFACE:
        case VARIABLE:
          // Cannot happen.
          throw internalError(node, type.toString());

        case NONE:
          throw internalError(node, "type is null");

        case VOID:
          return typeError(node, TypeErrorCode.VOID);

        default:
          throw internalError(node, type.getKind().name());
      }
    }

    private Type checkArguments(DartNode diagnosticNode,
                                List<DartExpression> argumentNodes,
                                Iterator<Type> argumentTypes, FunctionType ftype) {
      int argumentIndex = 0;
      // Check positional parameters.
      List<Type> parameterTypes = ftype.getParameterTypes();
      for (Type parameterType : parameterTypes) {
        parameterType.getClass(); // quick null check
        if (argumentTypes.hasNext()) {
          Type argumentType = argumentTypes.next();
          argumentType.getClass(); // quick null check
          checkAssignable(argumentNodes.get(argumentIndex), parameterType, argumentType);
          argumentIndex++;
        } else {
          onError(diagnosticNode, TypeErrorCode.MISSING_ARGUMENT, parameterType);
          return ftype.getReturnType();
        }
      }
      // Check named parameters.
      {
        Set<String> usedNamedParametersPositional = Sets.newHashSet();
        Set<String> usedNamedParametersNamed = Sets.newHashSet();
        // Prepare named parameters.
        Map<String, Type> namedParameterTypes = ftype.getNamedParameterTypes();
        Iterator<Entry<String, Type>> namedParameterTypesIterator =
            namedParameterTypes.entrySet().iterator();
        // Check positional arguments for named parameters.
        while (namedParameterTypesIterator.hasNext()
            && argumentTypes.hasNext()
            && !(argumentNodes.get(argumentIndex) instanceof DartNamedExpression)) {
          Entry<String, Type> namedEntry = namedParameterTypesIterator.next();
          String parameterName = namedEntry.getKey();
          usedNamedParametersPositional.add(parameterName);
          Type namedType = namedEntry.getValue();
          namedType.getClass(); // quick null check
          Type argumentType = argumentTypes.next();
          argumentType.getClass(); // quick null check
          checkAssignable(argumentNodes.get(argumentIndex), namedType, argumentType);
          argumentIndex++;
        }
        // Check named arguments for named parameters.
        while (argumentTypes.hasNext()
            && argumentNodes.get(argumentIndex) instanceof DartNamedExpression) {
          DartNamedExpression namedExpression =
              (DartNamedExpression) argumentNodes.get(argumentIndex);
          DartExpression argumentNode = argumentNodes.get(argumentIndex);
          // Prepare parameter name.
          String parameterName = namedExpression.getName().getName();
          if (usedNamedParametersPositional.contains(parameterName)) {
            onError(argumentNode, TypeErrorCode.DUPLICATE_NAMED_ARGUMENT);
          } else if (usedNamedParametersNamed.contains(parameterName)) {
            onError(argumentNode, ResolverErrorCode.DUPLICATE_NAMED_ARGUMENT);
          } else {
            usedNamedParametersNamed.add(parameterName);
          }
          // Check parameter type.
          Type namedParameterType = namedParameterTypes.get(parameterName);
          Type argumentType = argumentTypes.next();
          if (namedParameterType != null) {
            argumentType.getClass(); // quick null check
            checkAssignable(argumentNode, namedParameterType, argumentType);
          } else {
            onError(argumentNode, TypeErrorCode.NO_SUCH_NAMED_PARAMETER, parameterName);
          }
          argumentIndex++;
        }
      }
      // Check rest (currently removed from specification).
      if (ftype.hasRest()) {
        while (argumentTypes.hasNext()) {
          checkAssignable(argumentNodes.get(argumentIndex), ftype.getRest(), argumentTypes.next());
          argumentIndex++;
        }
      }
      // Report extra arguments.
      while (argumentTypes.hasNext()) {
        argumentTypes.next();
        onError(argumentNodes.get(argumentIndex), TypeErrorCode.EXTRA_ARGUMENT);
        argumentIndex++;
      }

      // Return type.
      Type type = ftype.getReturnType();
      type.getClass(); // quick null check
      return type;
    }

    @Override
    public Type visitTypeNode(DartTypeNode node) {
      return validateTypeNode(node, false);
    }

    private Type validateTypeNode(DartTypeNode node, boolean badBoundIsError) {
      Type type = node.getType(); // Already calculated by resolver.
      switch (TypeKind.of(type)) {
        case NONE:
          return typeError(node, TypeErrorCode.INTERNAL_ERROR,
                           String.format("type \"%s\" is null", node));
        case INTERFACE: {
          InterfaceType itype = (InterfaceType) type;
          validateBounds(node.getTypeArguments(),
                         itype.getArguments(),
                         itype.getElement().getTypeParameters(),
                         badBoundIsError);
          return itype;
        }
        default:
          return type;
      }
    }

    private void validateBounds(List<? extends DartNode> diagnosticNodes,
                                List<Type> arguments,
                                List<Type> parameters,
                                boolean badBoundIsError) {
      if (arguments.size() == parameters.size() && arguments.size() == diagnosticNodes.size()) {
        List<Type> bounds = Lists.newArrayListWithCapacity(parameters.size());
        for (Type parameter : parameters) {
          TypeVariable variable = (TypeVariable) parameter;
          Type bound = variable.getTypeVariableElement().getBound();
          if (bound == null) {
            internalError(variable.getElement(), "bound is null");
          }
          bounds.add(bound);
        }
        bounds = Types.subst(bounds, arguments, parameters);
        for (int i = 0; i < arguments.size(); i++) {
          Type t = bounds.get(i);
          Type s = arguments.get(i);
          if (!types.isAssignable(t, s)) {
            if (badBoundIsError) {
              onError(diagnosticNodes.get(i),
                        ResolverErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, s, t);
            } else {
              onError(diagnosticNodes.get(i),
                        TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, s, t);
            }
          }
        }
      }
    }

    /* Check for a type variable is repeated in its own bounds:
     * e.g. Foo<T extends T>
     */
    private void checkCyclicBounds(List<? extends Type> arguments) {
      for (Type argument : arguments) {
        if (TypeKind.of(argument).equals(TypeKind.VARIABLE)) {
          TypeVariable typeVar = (TypeVariable) argument;
          checkCyclicBound(typeVar, typeVar.getTypeVariableElement().getBound());
        }
      }
    }

    private void checkCyclicBound(TypeVariable variable, Type bound) {
      switch(TypeKind.of(bound)) {
        case VARIABLE: {
          TypeVariable boundType = (TypeVariable)bound;
          if (boundType.equals(variable)) {
            onError(boundType.getElement(),
                    TypeErrorCode.CYCLIC_REFERENCE_TO_TYPE_VARIABLE,
                    boundType.getElement().getOriginalName());
          }
          break;
        }
        default:
          break;
      }
    }

    /**
     * Returns the type of a node.  If a type of an expression can't be resolved,
     * returns the dynamic type.
     *
     * @return a non-null type
     */
    Type typeOf(DartNode node) {
      if (node == null) {
        return dynamicType;
      }
      Type result = node.accept(this);
      if (result == null) {
         return dynamicType;
      }
      node.setType(result);
      return result;
    }

    /**
     * Returns the type of a node, registering an error if the type is unresolved or
     * void.
     *
     * @return a non-null type
     */
    private Type nonVoidTypeOf(DartNode node) {
      Type type = typeOf(node);
      return checkNonVoid(node, type);
    }

    /**
     * @return the given {@link Type}, registering an error if it is unresolved or void.
     */
    private Type checkNonVoid(HasSourceInfo errorTarget, Type type) {
      switch (TypeKind.of(type)) {
        case VOID:
        case NONE:
          return typeError(errorTarget, TypeErrorCode.VOID);
        default:
          return type;
      }
    }

    @Override
    public Type visitArrayAccess(DartArrayAccess node) {
      Type target = typeOf(node.getTarget());
      return analyzeBinaryOperator(node, target, Token.INDEX, node, node.getKey());
    }

    /**
     * Asserts that given {@link DartExpression} is valid for using in "assert" statement.
     */
    private void checkAssertCondition(DartExpression conditionNode) {
      Type condition = nonVoidTypeOf(conditionNode);
      switch (condition.getKind()) {
        case FUNCTION:
          FunctionType ftype = (FunctionType) condition;
          Type returnType = ftype.getReturnType();
          if (!types.isAssignable(boolType, returnType) || !ftype.getParameterTypes().isEmpty()) {
            typeError(conditionNode, TypeErrorCode.ASSERT_BOOL);
          }
          break;

        default:
          if (!types.isAssignable(boolType, condition)) {
            typeError(conditionNode, TypeErrorCode.ASSERT_BOOL);
          }
          break;
      }
    }

    @Override
    public Type visitBlock(DartBlock node) {
      return typeAsVoid(node);
    }

    @Override
    public Type visitReturnBlock(DartReturnBlock node) {
      // 'assert' is statement
      if (node.getStatements().size() == 1
          && node.getStatements().get(0) instanceof DartReturnStatement) {
        DartReturnStatement statement = (DartReturnStatement) node.getStatements().get(0);
        DartExpression value = statement.getValue();
        if (value != null && Elements.isArtificialAssertMethod(value.getElement())) {
          typeError(value, TypeErrorCode.ASSERT_IS_STATEMENT);
          return voidType;
        }
      }
      // continue
      return super.visitReturnBlock(node);
    }

    private Type typeAsVoid(DartNode node) {
      node.visitChildren(this);
      return voidType;
    }

    @Override
    public Type visitBreakStatement(DartBreakStatement node) {
      return voidType;
    }

    @Override
    public Type visitFunctionObjectInvocation(DartFunctionObjectInvocation node) {
      node.setElement(functionType.getElement());
      return checkInvocation(node, node, null, typeOf(node.getTarget()));
    }

    @Override
    public Type visitMethodInvocation(DartMethodInvocation node) {
      String name = node.getFunctionNameString();
      Element element = node.getElement();
      if (element != null && (element.getModifiers().isStatic()
                              || Elements.isTopLevel(element))) {
        node.setElement(element);
        return checkInvocation(node, node, name, element.getType());
      }
      DartNode target = node.getTarget();
      Type receiver = nonVoidTypeOf(target);
      List<DartExpression> arguments = node.getArguments();
      Member member = lookupMember(receiver, name, node);
      if (member != null) {
        node.setElement(member.getElement());
      }
      return analyzeMethodInvocation(receiver, member, name,
                                     node.getFunctionName(), analyzeArgumentTypes(arguments),
                                     arguments);
    }

    @Override
    public Type visitSuperConstructorInvocation(DartSuperConstructorInvocation node) {
      return checkConstructorForwarding(node, node.getElement());
    }

    private Type checkConstructorForwarding(DartInvocation node, ConstructorElement element) {
      if (element == null) {
        visit(node.getArguments());
        return voidType;
      } else {
        node.setElement(element);
        checkInvocation(node, node, null, typeAsMemberOf(element, currentClass));
        return voidType;
      }
    }

    @Override
    public Type visitCase(DartCase node) {
      node.visitChildren(this);
      return voidType;
    }

    @Override
    public Type visitClass(DartClass node) {
      ClassNodeElement element = node.getElement();
      InterfaceType type = element.getType();
      checkCyclicBounds(type.getArguments());
      List<Element> unimplementedMembers = findUnimplementedMembers(element);
      setCurrentClass(type);
      visit(node.getTypeParameters());
      if (node.getSuperclass() != null) {
        validateTypeNode(node.getSuperclass(), false);
      }
      if (node.getInterfaces() != null) {
        for (DartTypeNode interfaceNode : node.getInterfaces()) {
          validateTypeNode(interfaceNode, false);
        }
      }

      visit(node.getMembers());
      checkInterfaceConstructors(element);
      // Report unimplemented members.
      if (!node.isAbstract()) {
        if (unimplementedMembers.size() > 0) {
          StringBuilder sb = getUnimplementedMembersMessage(element, unimplementedMembers);
          typeError(
              node.getName(),
              TypeErrorCode.ABSTRACT_CLASS_WITHOUT_ABSTRACT_MODIFIER,
              element.getName(),
              sb);
        }
      }
      // Finish current class.
      setCurrentClass(null);
      return type;
    }

    /**
     * Checks that interface constructors have corresponding methods in default class.
     */
    private void checkInterfaceConstructors(ClassElement interfaceElement) {
      // If no default class, do nothing.
      if (interfaceElement.getDefaultClass() == null) {
        return;
      }
      // Analyze all constructors.
      String interfaceClassName = interfaceElement.getName();
      String defaultClassName = interfaceElement.getDefaultClass().getElement().getName();
      for (ConstructorElement interfaceConstructor : interfaceElement.getConstructors()) {
        ConstructorElement defaultConstructor = interfaceConstructor.getDefaultConstructor();
        if (defaultConstructor != null) {
          // TODO(scheglov)
          // It is a compile-time error if kI and kF do not have identical type parameters
          // TODO /end
          // Validate types of required and optional parameters.
          {
            List<String> interfaceTypes = Elements.getParameterTypeNames(interfaceConstructor);
            List<String> defaultTypes = Elements.getParameterTypeNames(defaultConstructor);
            if (interfaceTypes.size() == defaultTypes.size()
                && !interfaceTypes.equals(defaultTypes)) {
              onError(
                  interfaceConstructor,
                  TypeErrorCode.DEFAULT_CONSTRUCTOR_TYPES,
                  Elements.getRawMethodName(interfaceConstructor),
                  interfaceClassName,
                  Joiner.on(",").join(interfaceTypes),
                  Elements.getRawMethodName(defaultConstructor),
                  defaultClassName,
                  Joiner.on(",").join(defaultTypes));
            }
          }
        }
      }
    }

    private List<Element> findUnimplementedMembers(ClassElement classElement) {
      // May be has members already (cached or already analyzed ClassNodeElement).
      List<Element> members = classElement.getUnimplementedMembers();
      if (members != null) {
        return members;
      }
      // If no cached result, then should be node based.
      ClassNodeElement classNodeElement = (ClassNodeElement) classElement;
      // Analyze ClassElement node.
      AbstractMethodFinder finder = new AbstractMethodFinder(classNodeElement.getType());
      classNodeElement.getNode().accept(finder);
      // Prepare unimplemented members.
      if (classNodeElement.isInterface()) {
        members = Collections.emptyList();
      } else {
        members = finder.unimplementedElements;
      }
      // Remember unimplemented methods.
      classNodeElement.setUnimplementedMembers(members);
      return members;
    }

    @Override
    public Type visitConditional(DartConditional node) {
      checkCondition(node.getCondition());
      Type left = typeOf(node.getThenExpression());
      Type right = typeOf(node.getElseExpression());
      return types.leastUpperBound(left, right);
    }

    private Type checkCondition(DartExpression condition) {
      Type type = nonVoidTypeOf(condition);
      checkAssignable(condition, boolType, type);
      return type;
    }

    @Override
    public Type visitContinueStatement(DartContinueStatement node) {
      return voidType;
    }

    @Override
    public Type visitDefault(DartDefault node) {
      node.visitChildren(this);
      return typeAsVoid(node);
    }

    @Override
    public Type visitDoWhileStatement(DartDoWhileStatement node) {
      checkCondition(node.getCondition());
      typeOf(node.getBody());
      return voidType;
    }

    @Override
    public Type visitEmptyStatement(DartEmptyStatement node) {
      return typeAsVoid(node);
    }

    @Override
    public Type visitExprStmt(DartExprStmt node) {
      // special support for incomplete "assert"
      if (node.getExpression() instanceof DartIdentifier) {
        DartIdentifier identifier = (DartIdentifier) node.getExpression();
        NodeElement element = identifier.getElement();
        if (Objects.equal(identifier.getName(), "assert")
            && Elements.isArtificialAssertMethod(element)) {
          onError(node, TypeErrorCode.ASSERT_NUMBER_ARGUMENTS);
          return voidType;
        }
      }
      // normal
      typeOf(node.getExpression());
      return voidType;
    }

    @Override
    public Type visitFieldDefinition(DartFieldDefinition node) {
      node.visitChildren(this);
      return voidType;
    }

    @Override
    public Type visitForInStatement(DartForInStatement node) {
      Type variableType;
      VariableElement variableElement;
      if (node.introducesVariable()) {
        variableType = typeOf(node.getVariableStatement());
        variableElement = node.getVariableStatement().getVariables().get(0).getElement();
      } else {
        variableType = typeOf(node.getIdentifier());
        variableElement = (VariableElement) node.getIdentifier().getElement();
      }
      // prepare Iterable type
      DartExpression iterableExpression = node.getIterable();
      Type iterableType = typeOf(iterableExpression);
      // analyze compatibility of variable and Iterator elements types
      Member iteratorMember = lookupMember(iterableType, "iterator", iterableExpression);
      Type elementType = null;
      if (iteratorMember != null) {
        if (TypeKind.of(iteratorMember.getType()) == TypeKind.FUNCTION) {
          FunctionType iteratorMethod = (FunctionType) iteratorMember.getType();
          InterfaceType asInstanceOf = types.asInstanceOf(iteratorMethod.getReturnType(),
              dynamicIteratorType.getElement());
          if (asInstanceOf != null) {
            elementType = asInstanceOf.getArguments().get(0);
            checkAssignable(iterableExpression, variableType, elementType);
          } else {
            InterfaceType expectedIteratorType = dynamicIteratorType.subst(
                Arrays.asList(variableType), dynamicIteratorType.getElement().getTypeParameters());
            typeError(iterableExpression,
                TypeErrorCode.FOR_IN_WITH_INVALID_ITERATOR_RETURN_TYPE,
                expectedIteratorType);
          }
        } else {
          // Not a function
          typeError(iterableExpression, TypeErrorCode.FOR_IN_WITH_ITERATOR_FIELD);
        }
      }
      // visit body with inferred variable type
      VariableElementsRestorer variableRestorer = new VariableElementsRestorer();
      try {
        if (elementType != null) {
          variableRestorer.setType(variableElement, elementType);
        }
        return typeAsVoid(node.getBody());
      } finally {
        variableRestorer.restore();
      }
    }

    @Override
    public Type visitForStatement(DartForStatement node) {
      typeOf(node.getInit());
      DartExpression condition = node.getCondition();
      checkCondition(condition);
      visitConditionalNode(condition, node.getBody());
      visitConditionalNode(condition, node.getIncrement());
      return voidType;
    }

    @Override
    public Type visitFunction(DartFunction node) {
      Type previous = expected;
      visit(node.getParameters());
      expected = typeOf(node.getReturnTypeNode());
      typeOf(node.getBody());
      expected = previous;
      return voidType;
    }

    @Override
    public Type visitFunctionExpression(DartFunctionExpression node) {
      node.visitChildren(this);
      Type result = ((Element) node.getElement()).getType();
      result.getClass(); // quick null check
      return result;
    }

    @Override
    public Type visitFunctionTypeAlias(DartFunctionTypeAlias node) {
      FunctionAliasElement element = node.getElement();
      FunctionAliasType type = element.getType();
      if (TypeKind.of(type) == TypeKind.FUNCTION_ALIAS) {
        checkCyclicBounds(type.getElement().getTypeParameters());
        if (hasFunctionTypeAliasSelfReference(element)) {
          onError(node, TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF);
        }
      }
      return typeAsVoid(node);
    }

    @Override
    public Type visitSyntheticErrorIdentifier(DartSyntheticErrorIdentifier node) {
      return dynamicType;
    }

    @Override
    public Type visitIdentifier(DartIdentifier node) {
      if (node.getType() != null) {
        return node.getType();
      }
      Element element = node.getElement();
      Type type;
      switch (ElementKind.of(element)) {
        case VARIABLE:
        case PARAMETER:
        case FUNCTION_OBJECT:
          type = element.getType();
          type.getClass(); // quick null check

          break;

        case FIELD:
          type = typeAsMemberOf(element, currentClass);
          // try to resolve as getter/setter
          FieldElement fieldElement = (FieldElement) element;
          if (Elements.inGetterContext(node)) {
            MethodElement getter = fieldElement.getGetter();
            if (getter != null) {
              type = getter.getReturnType();
              node.setType(type);
            }
          } else if (Elements.inSetterContext(node)) {
            MethodElement setter = fieldElement.getSetter();
            if (setter != null) {
              if (setter.getParameters().size() > 0) {
                type = setter.getParameters().get(0).getType();
                node.setType(voidType);
              }
            }
          }
          type.getClass(); // quick null check
          break;

        case METHOD:
          type = typeAsMemberOf(element, currentClass);
          type.getClass(); // quick null check
          break;

        case NONE:
          return typeError(node, TypeErrorCode.CANNOT_BE_RESOLVED, node.getName());

        case DYNAMIC:
          return element.getType();

        default:
          return voidType;
      }
      return type;
    }

    @Override
    public Type visitIfStatement(DartIfStatement node) {
      DartExpression condition = node.getCondition();
      checkCondition(condition);
      // visit "then"
      DartStatement thenStatement = node.getThenStatement();
      visitConditionalNode(condition, thenStatement);
      // visit "else"
      {
        DartStatement elseStatement = node.getElseStatement();
        VariableElementsRestorer variableRestorer = new VariableElementsRestorer();
        // if has "else", then types inferred from "is! Type" applied only to "else"
        if (elseStatement != null) {
          inferVariableTypesFromIsNotConditions(condition, variableRestorer);
          typeOf(elseStatement);
          variableRestorer.restore();
        }
        // if no "else", then inferred types applied to the end of the method
        if (elseStatement == null && isExitFromFunction(thenStatement)) {
          inferVariableTypesFromIsNotConditions(condition, variableRestorer);
        }

      }
      // done
      return voidType;
    }

    @Override
    public Type visitInitializer(DartInitializer node) {
      DartIdentifier name = node.getName();
      if (name != null) {
        checkAssignable(typeOf(name), node.getValue());
      } else {
        typeOf(node.getValue());
      }
      return voidType;
    }

    @Override
    public Type visitLabel(DartLabel node) {
      return typeAsVoid(node);
    }

    @Override
    public Type visitMapLiteral(DartMapLiteral node) {
      visit(node.getTypeArguments());
      InterfaceType type = node.getType();

      // The Map literal has an implicit key type of String, so only one parameter is
      // specified <V> where V is the type of the value.
      checkAssignable(node, type, defaultLiteralMapType);

      // Check the map literal entries against the return type.
      Type valueType = type.getArguments().get(1);
      for (DartMapLiteralEntry literalEntry : node.getEntries()) {
        boolean isValueAssignable = checkAssignable(literalEntry, typeOf(literalEntry), valueType);
        if (developerModeChecks && !isValueAssignable) {
          typeError(literalEntry, ResolverErrorCode.MAP_LITERAL_ELEMENT_TYPE, valueType);
        }
      }

      // Check that each key literal is unique.
      Set<String> keyValues = Sets.newHashSet();
      for (DartMapLiteralEntry literalEntry : node.getEntries()) {
        if (literalEntry.getKey() instanceof DartStringLiteral) {
          DartStringLiteral keyLiteral = (DartStringLiteral) literalEntry.getKey();
          String keyValue = keyLiteral.getValue();
          if (keyValues.contains(keyValue)) {
            typeError(keyLiteral, TypeErrorCode.MAP_LITERAL_KEY_UNIQUE);
          }
          keyValues.add(keyValue);
        }
      }

      return type;
    }

    @Override
    public Type visitMapLiteralEntry(DartMapLiteralEntry node) {
      nonVoidTypeOf(node.getKey());
      return nonVoidTypeOf(node.getValue());
    }

    @Override
    public Type visitMethodDefinition(DartMethodDefinition node) {
      MethodElement methodElement = node.getElement();
      Modifiers modifiers = methodElement.getModifiers();
      DartTypeNode returnTypeNode = node.getFunction().getReturnTypeNode();
      if (modifiers.isFactory()) {
        analyzeFactory(node.getName(), (ConstructorElement) methodElement);
      } else if (modifiers.isSetter()) {
        if (returnTypeNode != null && returnTypeNode.getType() != voidType) {
          typeError(returnTypeNode, TypeErrorCode.SETTER_RETURN_TYPE, methodElement.getName());
        }
        if (methodElement.getParameters().size() > 0) {
          Element parameterElement = methodElement.getParameters().get(0);
          Type setterType = parameterElement.getType();
          MethodElement getterElement = Elements.lookupFieldElementGetter(
              methodElement.getEnclosingElement(), methodElement.getName());

          if (getterElement != null) {
            // prepare "getter" type
            Type getterType;

            // prepare super types between "getter" and "setter" enclosing types
            Type getterDeclarationType = getterElement.getEnclosingElement().getType();
            List<InterfaceType> superTypes;
            if (currentClass != null) {
              superTypes = getIntermediateSuperTypes(currentClass, getterDeclarationType);
            } else {
              superTypes = Lists.newArrayList();
            }
            // convert "getter" function type to use "setter" type parameters
            FunctionType getterFunctionType = (FunctionType) getterElement.getType();
            for (InterfaceType superType : superTypes) {
              List<Type> superArguments = superType.getArguments();
              List<Type> superParameters = superType.getElement().getTypeParameters();
              getterFunctionType = (FunctionType) getterFunctionType.subst(superArguments,
                  superParameters);
            }
            // get return type
            getterType = getterFunctionType.getReturnType();

            // compare "getter" and "setter" types
            if (!types.isAssignable(setterType, getterType)) {
              typeError(parameterElement, TypeErrorCode.SETTER_TYPE_MUST_BE_ASSIGNABLE,
                  setterType.getElement().getName(), getterType.getElement().getName());
            }
          }
        }
      }
      // operator "equals" should return "bool"
      if (modifiers.isOperator() && methodElement.getName().equals("equals")
          && returnTypeNode != null) {
        Type returnType = node.getElement().getFunctionType().getReturnType();
        if (!Objects.equal(returnType, boolType)) {
          typeError(returnTypeNode, TypeErrorCode.OPERATOR_EQUALS_BOOL_RETURN_TYPE);

        }
      }
      // operator "negate" should return numeric type
      if (modifiers.isOperator() && methodElement.getName().equals("negate")
          && returnTypeNode != null) {
        Type returnType = node.getElement().getFunctionType().getReturnType();
        if (!types.isSubtype(returnType, numType)) {
          typeError(returnTypeNode, TypeErrorCode.OPERATOR_NEGATE_NUM_RETURN_TYPE);
        }
      }
      // done
      return typeAsVoid(node);
    }

    /**
     * @return "super" {@link InterfaceType}s used in declarations from "subType" to "superType",
     *         first item is given "superType". May be empty, but not <code>null</code>.
     */
    private List<InterfaceType> getIntermediateSuperTypes(InterfaceType subType, Type superType) {
      LinkedList<InterfaceType> superTypes = Lists.newLinkedList();
      InterfaceType t = subType.getElement().getSupertype();
      while (t != null) {
        superTypes.addFirst(t);
        if (Objects.equal(t.getElement().getType(), superType)) {
          break;
        }
        t = t.getElement().getSupertype();
      }
      return superTypes;
    }

    private void analyzeFactory(DartExpression name, final ConstructorElement methodElement) {
      ASTVisitor<Void> visitor = new ASTVisitor<Void>() {
        @Override
        public Void visitParameterizedTypeNode(DartParameterizedTypeNode node) {
          DartExpression expression = node.getExpression();
          Element e = null;
          if (expression instanceof DartIdentifier) {
            e = ((DartIdentifier) expression).getElement();
          } else if (expression instanceof DartPropertyAccess) {
            e = ((DartPropertyAccess) expression).getElement();
          }
          if (!ElementKind.of(e).equals(ElementKind.CLASS)) {
            return null;
          }
          List<DartTypeParameter> parameterNodes = node.getTypeParameters();
          assert (parameterNodes.size() == 0);
          return null;
        }
      };
      name.accept(visitor);
    }

    @Override
    public Type visitNewExpression(DartNewExpression node) {
      ConstructorElement constructorElement = node.getElement();

      DartTypeNode typeNode = Types.constructorTypeNode(node);
      Type type = null;

      // When using a constructor defined in an interface, the bounds can be tighter
      // in the default class than defined in the interface.
      if (TypeKind.of(typeNode.getType()).equals(TypeKind.INTERFACE)
          && ((InterfaceType)typeNode.getType()).getElement().isInterface()) {
        InterfaceType itype = (InterfaceType)typeNode.getType();
        ClassElement interfaceElement = itype.getElement();
        InterfaceType defaultClassType = interfaceElement.getDefaultClass();
        if (defaultClassType != null && defaultClassType.getElement() != null) {
          validateBounds(typeNode.getTypeArguments(),
                         itype.getArguments(),
                         defaultClassType.getElement().getTypeParameters(),
                         false);
          type = itype;
        }
      }
      if (type == null) {
        type = validateTypeNode(typeNode, false);
      }

      DartNode typeName = typeNode.getIdentifier();

      if (constructorElement == null) {
        visit(node.getArguments());
      } else {
        ClassElement cls = (ClassElement) constructorElement.getEnclosingElement();
        // Add warning for instantiating abstract class.
        if (!constructorElement.getModifiers().isFactory()) {
          if (cls.isAbstract()) {
            typeError(typeName, TypeErrorCode.INSTANTIATION_OF_ABSTRACT_CLASS, cls.getName());
          } else {
            List<Element> unimplementedMembers = findUnimplementedMembers(cls);
            if (unimplementedMembers.size() > 0) {
              StringBuilder sb = getUnimplementedMembersMessage(cls, unimplementedMembers);
              typeError(
                  typeName,
                  TypeErrorCode.INSTANTIATION_OF_CLASS_WITH_UNIMPLEMENTED_MEMBERS,
                  cls.getName(),
                  sb);
            }
          }
        }
        // Check type arguments.
        FunctionType ftype = (FunctionType) constructorElement.getType();

        if (ftype != null && TypeKind.of(type).equals(TypeKind.INTERFACE)) {
          InterfaceType ifaceType = (InterfaceType) type;

          List<Type> substParams;
          if (ifaceType.getElement().isInterface()) {
            // The constructor in the interface is resolved to the type parameters declared in
            // the interface, but the constructor body has type parameters resolved to the type
            // parameters in the default class.  This substitution patches up the type variable
            // references used in parameters so they match the concrete class.
            substParams = ((ClassElement)constructorElement.getEnclosingElement()).getType().getArguments();
          } else {
            substParams = ifaceType.getElement().getTypeParameters();
          }
          List<Type> arguments = ifaceType.getArguments();
          ftype = (FunctionType) ftype.subst(arguments, substParams);
          checkInvocation(node, node, null, ftype);
        }
      }
      type.getClass(); // quick null check
      return type;
    }

    /**
     * @param cls the {@link ClassElement}  which has unimplemented members.
     * @param unimplementedMembers the unimplemented members {@link Element}s.
     * @return the {@link StringBuilder} with message about unimplemented members.
     */
    private StringBuilder getUnimplementedMembersMessage(ClassElement cls,
        List<Element> unimplementedMembers) {
      // Prepare groups of unimplemented members for each type.
      Multimap<String, String> membersByTypes = ArrayListMultimap.create();
      for (Element member : unimplementedMembers) {
        ClassElement enclosingElement = (ClassElement) member.getEnclosingElement();
        InterfaceType instance = types.asInstanceOf(cls.getType(), enclosingElement);
        Type memberType = member.getType().subst(instance.getArguments(),
                                                 enclosingElement.getTypeParameters());
        if (memberType.getKind().equals(TypeKind.FUNCTION)) {
          FunctionType ftype = (FunctionType) memberType;
          StringBuilder sb = new StringBuilder();
          sb.append(ftype.getReturnType());
          sb.append(" ");
          sb.append(member.getName());
          String string = ftype.toString();
          sb.append(string, 0, string.lastIndexOf(" -> "));
          membersByTypes.put(enclosingElement.getName(), sb.toString());
        } else {
          StringBuilder sb = new StringBuilder();
          sb.append(memberType);
          sb.append(" ");
          sb.append(member.getName());
          membersByTypes.put(enclosingElement.getName(), sb.toString());
        }
      }
      // Output unimplemented members with grouping by class.
      StringBuilder sb = new StringBuilder();
      for (String typeName : membersByTypes.keySet()) {
        sb.append("\n    # From ");
        sb.append(typeName);
        sb.append(":");
        for (String memberString : membersByTypes.get(typeName)) {
          sb.append("\n        ");
          sb.append(memberString);
        }
      }
      return sb;
    }

    @Override
    public Type visitNullLiteral(DartNullLiteral node) {
      return nullType;
    }

    @Override
    public Type visitParameter(DartParameter node) {
      VariableElement parameter = node.getElement();
      FieldElement initializerElement = parameter.getParameterInitializerElement();
      if (initializerElement != null) {
        checkAssignable(node, parameter.getType(), initializerElement.getType());
      }
      return checkInitializedDeclaration(node, node.getDefaultExpr());
    }

    @Override
    public Type visitParenthesizedExpression(DartParenthesizedExpression node) {
      Type type = nonVoidTypeOf(node.getExpression());
      type.getClass(); // quick null check
      return type;
    }

    @Override
    public Type visitPropertyAccess(DartPropertyAccess node) {
      if (node.getType() != null) {
        return node.getType();
      }
      Element element = node.getElement();
      if (element != null) {
        return element.getType();
      }
      DartNode qualifier = node.getQualifier();
      Type receiver = nonVoidTypeOf(qualifier);
      // convert into InterfaceType
      InterfaceType cls = types.getInterfaceType(receiver);
      if (cls == null) {
        return diagnoseNonInterfaceType(qualifier, receiver);
      }
      // Do not visit the name, it may not have been resolved.
      String name = node.getPropertyName();
      InterfaceType.Member member = cls.lookupMember(name);
      if (member == null) {
        return typeError(node.getName(), TypeErrorCode.NOT_A_MEMBER_OF, name, cls);
      }
      element = member.getElement();
      node.setElement(element);
      Modifiers modifiers = element.getModifiers();
      if (modifiers.isStatic()) {
        return typeError(node.getName(),
                         TypeErrorCode.STATIC_MEMBER_ACCESSED_THROUGH_INSTANCE,
                         name, element.getName());
      }
      switch (element.getKind()) {
        case DYNAMIC:
          return dynamicType;
        case CONSTRUCTOR:
          return typeError(node.getName(), TypeErrorCode.MEMBER_IS_A_CONSTRUCTOR,
                           name, element.getName());

        case METHOD:
          return member.getType();

        case FIELD:
          FieldElement fieldElement = (FieldElement) element;
          Modifiers fieldModifiers = fieldElement.getModifiers();
          MethodElement getter = fieldElement.getGetter();
          MethodElement setter = fieldElement.getSetter();
          boolean inSetterContext = Elements.inSetterContext(node);
          boolean inGetterContext = Elements.inGetterContext(node);
          ClassElement enclosingClass = null;
          if (fieldElement.getEnclosingElement() instanceof ClassElement) {
            enclosingClass = (ClassElement) fieldElement.getEnclosingElement();
          }

          // Implicit field declared as "final".
          if (!fieldModifiers.isAbstractField() && fieldModifiers.isFinal() && inSetterContext) {
            return typeError(node.getName(), TypeErrorCode.FIELD_IS_FINAL, node.getName());
          }

          // Check for cases when property has no setter or getter.
          if (fieldModifiers.isAbstractField() && enclosingClass != null) {
            // Check for using field without getter in other operation that assignment.
            if (inGetterContext) {
              if (getter == null) {
                getter = Elements.lookupFieldElementGetter(enclosingClass, name);
                if (getter == null) {
                  return typeError(node.getName(), TypeErrorCode.FIELD_HAS_NO_GETTER, node.getName());
                }
              }
              node.setElement(getter);
            }
            // Check for using field without setter in some assignment variant.
            if (inSetterContext) {
                if (setter == null) {
                  setter = Elements.lookupFieldElementSetter(enclosingClass, name);
                  if (setter == null) {
                    return typeError(node.getName(), TypeErrorCode.FIELD_HAS_NO_SETTER, node.getName());
                  }
                }
                node.setElement(setter);
            }
          }

          Type result = member.getType();
          if (fieldModifiers.isAbstractField()) {
            if (inSetterContext) {
              result = member.getSetterType();
              if (result == null) {
                return typeError(node.getName(), TypeErrorCode.FIELD_HAS_NO_SETTER, node.getName());
              }
            }
            if (inGetterContext) {
              result = member.getGetterType();
              if (result == null) {
                return typeError(node.getName(), TypeErrorCode.FIELD_HAS_NO_GETTER, node.getName());
              }
            }
          }
          node.setType(result);
          return result;

        default:
          throw internalError(node.getName(), "unexpected kind %s", element.getKind());
      }
    }

    @Override
    public Type visitReturnStatement(DartReturnStatement node) {
      DartExpression value = node.getValue();
      if (value == null) {
        if (!types.isSubtype(voidType, expected)) {
          typeError(node, TypeErrorCode.MISSING_RETURN_VALUE, expected);
        }
      } else {
        checkAssignable(value == null ? node : value, expected, typeOf(value));
      }
      return voidType;
    }

    @Override
    public Type visitSuperExpression(DartSuperExpression node) {
      if (currentClass == null) {
        return dynamicType;
      }
      Type type = currentClass.getElement().getSupertype();
      type.getClass(); // quick null check
      return type;
    }

    @Override
    public Type visitSwitchStatement(DartSwitchStatement node) {
      node.visitChildren(this);
      // analyze "expression"
      DartExpression expression = node.getExpression();
      Type switchType = nonVoidTypeOf(expression);
      // check "case" expressions compatibility
      Type sameCaseType = null;
      for (DartSwitchMember switchMember : node.getMembers()) {
        if (switchMember instanceof DartCase) {
          DartCase caseMember = (DartCase) switchMember;
          DartExpression caseExpr = caseMember.getExpr();
          Type caseType = nonVoidTypeOf(caseExpr);
          // should be "int" or "String"
          if (!Objects.equal(caseType, intType) && !Objects.equal(caseType, stringType)) {
            onError(caseExpr, TypeErrorCode.CASE_EXPRESSION_SHOULD_BE_INT_STRING, caseType);
            continue;
          }
          // all "case expressions" should be same type
          if (sameCaseType == null) {
            sameCaseType = caseType;
          }
          if (!Objects.equal(caseType, sameCaseType)) {
            onError(caseExpr, TypeErrorCode.CASE_EXPRESSIONS_SHOULD_BE_SAME_TYPE, sameCaseType,
                caseType);
          }
          // compatibility of "switch expression" and "case expression" types
          checkAssignable(caseExpr, switchType, caseType);
        }
      }
      return voidType;
    }

    @Override
    public Type visitSyntheticErrorExpression(DartSyntheticErrorExpression node) {
      return dynamicType;
    }

    @Override
    public Type visitSyntheticErrorStatement(DartSyntheticErrorStatement node) {
      return dynamicType;
    }

    @Override
    public Type visitThisExpression(DartThisExpression node) {
      Type type = getCurrentClass();
      if (type == null) {
        // this was used in a static context, so it should have already generated a fatal error
        return voidType;
      }
      return type;
    }

    @Override
    public Type visitThrowStatement(DartThrowStatement node) {
      if (catchDepth == 0 && node.getException() == null) {
        context.onError(new DartCompilationError(node,
            ResolverErrorCode.RETHROW_NOT_IN_CATCH));
      }
      return typeAsVoid(node);
    }

    @Override
    public Type visitCatchBlock(DartCatchBlock node) {
      ++catchDepth;
      typeOf(node.getException());
      // TODO(karlklose) Check type of stack trace variable.
      typeOf(node.getStackTrace());
      typeOf(node.getBlock());
      --catchDepth;
      return voidType;
    }

    @Override
    public Type visitTryStatement(DartTryStatement node) {
      return typeAsVoid(node);
    }

    @Override
    public Type visitUnaryExpression(DartUnaryExpression node) {
      DartExpression expression = node.getArg();
      Type type = nonVoidTypeOf(expression);
      Token operator = node.getOperator();
      switch (operator) {
        case BIT_NOT:
          // Bit operations are only supported by integers and
          // thus cannot be looked up on num. To ease usage of
          // bit operations, we currently allow them to be used
          // if the left-hand-side is of type num.
          // TODO(karlklose) find a clean solution, i.e., without a special case for num.
          if (type.equals(numType)) {
            return intType;
          } else {
            String name = methodNameForUnaryOperator(node, operator);
            Member member = lookupMember(type, name, node);
            if (member != null) {
              node.setElement(member.getElement());
              return analyzeMethodInvocation(type, member, name, node,
                                             Collections.<Type>emptyList(),
                                             Collections.<DartExpression>emptyList());
            } else {
              return dynamicType;
            }
          }
        case NOT:
          checkAssignable(boolType, expression);
          return boolType;
        case SUB:
        case INC:
        case DEC: {
          if (type.getElement().isDynamic()) {
            return type;
          }
          InterfaceType itype = types.getInterfaceType(type);
          String operatorMethodName = methodNameForUnaryOperator(node, operator);
          Member member = itype.lookupMember(operatorMethodName);
          if (member == null) {
            return typeError(expression, TypeErrorCode.CANNOT_BE_RESOLVED,
                             operatorMethodName);
          }
          MethodElement element = ((MethodElement) member.getElement());
          node.setElement(element);
          Type returnType = ((FunctionType) member.getType()).getReturnType();
          if (operator == Token.INC || operator == Token.DEC) {
            // For INC and DEC, "operator +" and "operator -" are used to add and subtract one,
            // respectively. Check that the resolved operator has a compatible parameter type.
            Iterator<VariableElement> it = element.getParameters().iterator();
            if  (!types.isAssignable(numType, it.next().getType())) {
              typeError(node, TypeErrorCode.OPERATOR_WRONG_OPERAND_TYPE,
                  operatorMethodName, numType.toString());
            }
            // Check that the return type of the operator is compatible with the receiver.
            checkAssignable(node, type, returnType);
          }
          return node.isPrefix() ? returnType : type;
        }
        default:
          throw internalError(node, "unknown operator %s", operator.toString());
      }
    }

    @Override
    public Type visitUnit(DartUnit node) {
      return typeAsVoid(node);
    }

    @Override
    public Type visitUnqualifiedInvocation(DartUnqualifiedInvocation node) {
      DartIdentifier target = node.getTarget();
      String name = target.getName();
      Element element = target.getElement();
      node.setElement(element);
      // special support for "assert"
      if (Elements.isArtificialAssertMethod(element)) {
        if (node.getArguments().size() == 1) {
          DartExpression condition = node.getArguments().get(0);
          checkAssertCondition(condition);
        } else {
          onError(node, TypeErrorCode.ASSERT_NUMBER_ARGUMENTS);
        }
        return voidType;
      }
      // normal invocation
      Type type;
      switch (ElementKind.of(element)) {
        case FIELD:
        case METHOD:
          type = typeAsMemberOf(element, currentClass);
          break;
        case NONE:
          // already reported by resolver
          return dynamicType;
        default:
          type = element.getType();
          break;
      }
      return checkInvocation(node, target, name, type);
    }

    private Type checkInvocation(DartInvocation node, DartNode diagnosticNode, String name,
                                 Type type) {
      List<DartExpression> argumentNodes = node.getArguments();
      List<Type> argumentTypes = Lists.newArrayListWithCapacity(argumentNodes.size());
      for (DartExpression argumentNode : argumentNodes) {
        argumentTypes.add(nonVoidTypeOf(argumentNode));
      }
      switch (TypeKind.of(type)) {
        case FUNCTION_ALIAS:
          return checkArguments(node, argumentNodes, argumentTypes.iterator(),
                                types.asFunctionType((FunctionAliasType) type));
        case FUNCTION:
          return checkArguments(node, argumentNodes, argumentTypes.iterator(), (FunctionType) type);
        case DYNAMIC:
          return type;
        default:
          if (types.isAssignable(functionType, type)) {
            // A subtype of interface Function.
            return dynamicType;
          } else if (name == null) {
            return typeError(diagnosticNode, TypeErrorCode.NOT_A_FUNCTION, type);
          } else {
            return typeError(diagnosticNode, TypeErrorCode.NOT_A_METHOD_IN, name,
                             currentClass);
          }
      }
    }

    /**
     * Return the type of member as if it was a member of subtype. For example, the type of t in Sub
     * should be String, not T:
     *
     * <pre>
     *   class Super&lt;T> {
     *     T t;
     *   }
     *   class Sub extends Super&lt;String> {
     *   }
     * </pre>
     */
    private Type typeAsMemberOf(Element member, InterfaceType subtype) {
      Element holder = member.getEnclosingElement();
      if (!ElementKind.of(holder).equals(ElementKind.CLASS)) {
        return member.getType();
      }
      ClassElement superclass = (ClassElement) holder;
      InterfaceType supertype = types.asInstanceOf(subtype, superclass);
      Type type = member.getType().subst(supertype.getArguments(),
                                         supertype.getElement().getTypeParameters());
      type.getClass(); // quick null check
      return type;
    }

    @Override
    public Type visitVariable(DartVariable node) {
      Type result = checkInitializedDeclaration(node, node.getValue());
      // if no type declared for variables, try to use type of value
      {
        VariableElement element = node.getElement();
        if (element != null && TypeKind.of(element.getType()) == TypeKind.DYNAMIC) {
          DartExpression value = node.getValue();
          if (value != null) {
            Type valueType = value.getType();
            if (valueType != null && TypeKind.of(valueType) != TypeKind.DYNAMIC) {
              Type varType = Types.makeInferred(valueType);
              Elements.setType(element, varType);
              node.getName().setType(varType);
            }
          }
        }
      }
      // done
      return result;
    }

    @Override
    public Type visitWhileStatement(DartWhileStatement node) {
      DartExpression condition = node.getCondition();
      checkCondition(condition);
      visitConditionalNode(condition, node.getBody());
      return voidType;
    }

    @Override
    public Type visitNamedExpression(DartNamedExpression node) {
      // TODO(jgw): Checking of named parameters in progress.

      // Intentionally skip the expression's name -- it's stored as an identifier, but doesn't need
      // to be resolved or type-checked.
      Type type = nonVoidTypeOf(node.getExpression());
      type.getClass(); // quick null check
      return type;
    }

    @Override
    public Type visitTypeExpression(DartTypeExpression node) {
      return typeOf(node.getTypeNode());
    }

    @Override
    public Type visitTypeParameter(DartTypeParameter node) {
      if (node.getBound() != null) {
        validateTypeNode(node.getBound(), true);
      }
      return voidType;
    }

    @Override
    public Type visitNativeBlock(DartNativeBlock node) {
      return typeAsVoid(node);
    }

    @Override
    public void visit(List<? extends DartNode> nodes) {
      if (nodes != null) {
        for (DartNode node : nodes) {
          node.accept(this);
        }
      }
    }

    @Override
    public Type visitArrayLiteral(DartArrayLiteral node) {
      visit(node.getTypeArguments());
      InterfaceType interfaceType = node.getType();
      if (interfaceType != null
          && interfaceType.getArguments() != null
          && interfaceType.getArguments().size() > 0) {
        Type elementType = interfaceType.getArguments().get(0);
        for (DartExpression expression : node.getExpressions()) {
          boolean isValueAssignable = checkAssignable(elementType, expression);
          if (developerModeChecks && !isValueAssignable) {
            typeError(expression, ResolverErrorCode.LIST_LITERAL_ELEMENT_TYPE, elementType);
          }
        }
      }
      return interfaceType;
    }

    @Override
    public Type visitBooleanLiteral(DartBooleanLiteral node) {
      return typeOfLiteral(node);
    }

    @Override
    public Type visitDoubleLiteral(DartDoubleLiteral node) {
      return typeOfLiteral(node);
    }

    @Override
    public Type visitField(DartField node) {
      DartMethodDefinition accessor = node.getAccessor();
      if (accessor != null) {
        return typeOf(accessor);
      } else if (node.getElement().getConstantType() != null) {
        checkAssignable(node, node.getElement().getType(), node.getElement().getConstantType());
        return node.getElement().getType();
      } else {
        Type result = checkInitializedDeclaration(node, node.getValue());
        // if no type declared for variables, try to use type of value
        {
          Element element = node.getElement();
          if (element != null && TypeKind.of(element.getType()) == TypeKind.DYNAMIC) {
            DartExpression value = node.getValue();
            if (value != null) {
              Type valueType = value.getType();
              if (TypeKind.of(valueType) != TypeKind.DYNAMIC) {
                Type varType = Types.makeInferred(valueType);
                Elements.setType(element, varType);
              }
            }
          }
        }
        // done
        return result;
      }
    }

    private Type checkInitializedDeclaration(DartDeclaration<?> node, DartExpression value) {
      if (value != null && node.getElement() != null) {
        checkAssignable(node.getElement().getType(), value);
      }
      return voidType;
    }

    /**
     * @return <code>true</code> if given {@link FunctionAliasElement} has direct or indirect
     *         reference to itself using other {@link FunctionAliasElement}s.
     */
    private boolean hasFunctionTypeAliasSelfReference(FunctionAliasElement target) {
      Set<FunctionAliasElement> visited = Sets.newHashSet();
      return hasFunctionTypeAliasReference(visited, target, target);
    }

    /**
     * Checks if "target" is referenced by "current".
     */
    private boolean hasFunctionTypeAliasReference(Set<FunctionAliasElement> visited,
        FunctionAliasElement target, FunctionAliasElement current) {
      FunctionType type = current.getFunctionType();
      // prepare Types directly referenced by "current"
      Set<Type> referencedTypes = Sets.newHashSet();
      if (type != null) {
        // return type
        referencedTypes.add(type.getReturnType());
        // parameters
        referencedTypes.addAll(type.getParameterTypes());
        referencedTypes.addAll(type.getNamedParameterTypes().values());
      }
      // check that referenced types do not have references on "target"
      for (Type referencedType : referencedTypes) {
        if (referencedType != null
            && hasFunctionTypeAliasReference(visited, target, referencedType.getElement())) {
          return true;
        }
      }
      // no
      return false;
    }

    /**
     * Checks if "target" is referenced by "current".
     */
    private boolean hasFunctionTypeAliasReference(Set<FunctionAliasElement> visited,
        FunctionAliasElement target, Element currentElement) {
      // only if "current" in function type alias
      if (!(currentElement instanceof FunctionAliasElement)) {
        return false;
      }
      FunctionAliasElement current = (FunctionAliasElement) currentElement;
      // found "target"
      if (Objects.equal(target, current)) {
        return true;
      }
      // prevent recursion
      if (visited.contains(current)) {
        return false;
      }
      visited.add(current);
      // check type of "current" function type alias
      return hasFunctionTypeAliasReference(visited, target, current);
    }

    @Override
    public Type visitIntegerLiteral(DartIntegerLiteral node) {
      return typeOfLiteral(node);
    }

    @Override
    public Type visitStringLiteral(DartStringLiteral node) {
      return typeOfLiteral(node);
    }

    @Override
    public Type visitStringInterpolation(DartStringInterpolation node) {
      visit(node.getExpressions());
      return typeOfLiteral(node);
    }

    @Override
    public Type visitParameterizedTypeNode(DartParameterizedTypeNode node) {
      visit(node.getTypeParameters());
      Type type = node.getType();
      type.getClass(); // quick null check
      return type;
    }

    @Override
    public Type visitImportDirective(DartImportDirective node) {
      return typeAsVoid(node);
    }

    @Override
    public Type visitLibraryDirective(DartLibraryDirective node) {
      return typeAsVoid(node);
    }

    @Override
    public Type visitNativeDirective(DartNativeDirective node) {
      return typeAsVoid(node);
    }

    @Override
    public Type visitResourceDirective(DartResourceDirective node) {
      return typeAsVoid(node);
    }

    @Override
    public Type visitSourceDirective(DartSourceDirective node) {
      return typeAsVoid(node);
    }

    private class AbstractMethodFinder extends ASTVisitor<Void> {
      private final InterfaceType currentClass;
      private final Multimap<String, Element> superMembers = LinkedListMultimap.create();
      private final List<Element> unimplementedElements = Lists.newArrayList();

      private AbstractMethodFinder(InterfaceType currentClass) {
        this.currentClass = currentClass;
      }

      @Override
      public Void visitNode(DartNode node) {
        throw new AssertionError();
      }

      @Override
      public Void visitClass(DartClass node) {
        assert node.getElement().getType() == currentClass;

        // Prepare supertypes - all superclasses and interfaces.
        List<InterfaceType> supertypes = Collections.emptyList();
        boolean hasCyclicDeclaration = false;
        try {
          supertypes = currentClass.getElement().getAllSupertypes();
        } catch (CyclicDeclarationException e) {
          // Already reported by resolver.
          hasCyclicDeclaration = true;
        } catch (DuplicatedInterfaceException e) {
          // Already reported by resolver.
        }

        // Add all super members to resolve.
        Element currentLibrary = currentClass.getElement().getEnclosingElement();
        for (InterfaceType supertype : supertypes) {
          for (Element member : supertype.getElement().getMembers()) {
            String name = member.getName();
            if (DartIdentifier.isPrivateName(name)) {
              if (currentLibrary != member.getEnclosingElement().getEnclosingElement()) {
                continue;
              }
            }
            superMembers.put(name, member);
          }
        }

        // Visit members, so resolve methods declared in this class.
        this.visit(node.getMembers());

        // If interface, we don't care about unimplemented methods.
        if (currentClass.getElement().isInterface()) {
          return null;
        }

        // If we have cyclic declaration, hierarchy is broken, no reason to report unimplemented.
        if (hasCyclicDeclaration) {
          return null;
        }

        // Visit superclasses (without interfaces) and mark methods as implemented.
        InterfaceType supertype = currentClass.getElement().getSupertype();
        while (supertype != null) {
          ClassElement superclass = supertype.getElement();
          for (Element member : superclass.getMembers()) {
            if (!member.getModifiers().isAbstract()) {
              superMembers.removeAll(member.getName());
            }
          }
          supertype = supertype.getElement().getSupertype();
        }

        // All remaining methods are unimplemented.
        for (String name : superMembers.keys()) {
          Collection<Element> elements = superMembers.removeAll(name);
          for (Element element : elements) {
            if (!element.getModifiers().isStatic()) {
              unimplementedElements.add(element);
              break; // Only report the first unimplemented element with this name.
            }
          }
        }
        return null;
      }

      @Override
      public Void visitFieldDefinition(DartFieldDefinition node) {
        this.visit(node.getFields());
        return null;
      }

      @Override
      public Void visitField(DartField node) {
        if (superMembers != null) {
          FieldElement field = node.getElement();
          String name = field.getName();
          Collection<Element> overridden = superMembers.removeAll(name);
          for (Element element : overridden) {
            if (canOverride(node.getName(), field.getModifiers(), element)) {
              switch (element.getKind()) {
                case FIELD:
                  checkOverride(node.getName(), field, element);
                  break;
                case METHOD:
                  typeError(node.getName(), TypeErrorCode.SUPERTYPE_HAS_METHOD, name,
                            element.getEnclosingElement().getName());
                  break;

                default:
                  typeError(node, TypeErrorCode.INTERNAL_ERROR, element);
                  break;
              }
            }
          }
        }
        return null;
      }

      @Override
      public Void visitMethodDefinition(DartMethodDefinition node) {
        MethodElement method = node.getElement();
        String name = method.getName();
        if (superMembers != null && !method.isConstructor()) {
          Collection<Element> overridden = superMembers.removeAll(name);
          for (Element element : overridden) {
            if (canOverride(node.getName(), method.getModifiers(), element)) {
              switch (element.getKind()) {
                case METHOD:
                  checkOverride(node.getName(), method, element);
                  break;

                case FIELD:
                  typeError(node.getName(), TypeErrorCode.SUPERTYPE_HAS_FIELD, element.getName(),
                            element.getEnclosingElement().getName());
                  break;

                default:
                  typeError(node, TypeErrorCode.INTERNAL_ERROR, element);
                  break;
              }
            }
          }
        }
        return null;
      }

      /**
       * Report a compile-time error if either modifiers or elements.getModifiers() is static.
       * @returns true if no compile-time error was reported
       */
      private boolean canOverride(HasSourceInfo errorTarget, Modifiers modifiers, Element element) {
        if (element.getModifiers().isStatic()) {
          onError(errorTarget, TypeErrorCode.OVERRIDING_INHERITED_STATIC_MEMBER,
                          element.getName(), element.getEnclosingElement().getName());
          return false;
        } else if (modifiers.isStatic()) {
          onError(errorTarget, ResolverErrorCode.CANNOT_OVERRIDE_INSTANCE_MEMBER,
                          element.getName(), element.getEnclosingElement().getName());
          return false;
        }
        return true;
      }

      /**
       * Report a static type error if member cannot override superElement, that
       * is, they are not assignable.
       */
      private void checkOverride(HasSourceInfo errorTarget, Element member, Element superElement) {
        String name = member.getName();
        Type superMember = typeAsMemberOf(superElement, currentClass);
        if (member.getKind() == ElementKind.METHOD && superElement.getKind() == ElementKind.METHOD) {
          MethodElement method = (MethodElement) member;
          MethodElement superMethod = (MethodElement) superElement;
          if (hasLegalMethodOverrideSignature(errorTarget, method, superMethod)) {
            if (!types.isSubtype(member.getType(), superMember)) {
              typeError(errorTarget,
                        TypeErrorCode.CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE,
                        name,
                        superElement.getEnclosingElement().getName(),
                        member.getType(),
                        superMember);
            }
          }
        } else if (!types.isAssignable(superMember, member.getType())) {
          typeError(errorTarget,
                    TypeErrorCode.CANNOT_OVERRIDE_TYPED_MEMBER,
                    name,
                    superElement.getEnclosingElement().getName(),
                    member.getType(),
                    superMember);
        }
      }

      /**
       * @return <code>true</code> if given "method" has signature compatible with "superMethod".
       */
      private boolean hasLegalMethodOverrideSignature(HasSourceInfo errorTarget,
                                                      MethodElement method,
                                                      MethodElement superMethod) {
        // Prepare parameters.
        List<VariableElement> parameters = method.getParameters();
        List<VariableElement> superParameters = superMethod.getParameters();
        // Number of required parameters should be same.
        {
          int numRequired = getNumRequiredParameters(parameters);
          int superNumRequired = getNumRequiredParameters(superParameters);
          if (numRequired != superNumRequired) {
            onError(errorTarget,
                    ResolverErrorCode.CANNOT_OVERRIDE_METHOD_NUM_REQUIRED_PARAMS,
                    method.getName());
            return false;
          }
        }
        // "method" should have at least all named parameters of "superMethod" in the same order.
        List<VariableElement> named = getNamedParameters(parameters);
        List<VariableElement> superNamed = getNamedParameters(superParameters);
        Iterator<VariableElement> namedIterator = named.iterator();
        Iterator<VariableElement> superNamedIterator = superNamed.iterator();
        while (superNamedIterator.hasNext()) {
          VariableElement superParameter = superNamedIterator.next();
          if (namedIterator.hasNext()) {
            VariableElement parameter = namedIterator.next();
            if (Objects.equal(parameter.getName(), superParameter.getName())) {
              DartExpression superDefValue = superParameter.getDefaultValue();
              DartExpression defValue = parameter.getDefaultValue();
              if (superDefValue != null
                  && !Objects.equal(ObjectUtils.toString(defValue),
                      ObjectUtils.toString(superDefValue))) {
                onError(parameter.getSourceInfo(),
                    TypeErrorCode.CANNOT_OVERRIDE_METHOD_DEFAULT_VALUE, method.getName(),
                    superDefValue);
              }
              continue;
            }
          }
          onError(errorTarget, ResolverErrorCode.CANNOT_OVERRIDE_METHOD_NAMED_PARAMS, method.getName());
          return false;
        }
        return true;
      }

      private int getNumRequiredParameters(List<VariableElement> parameters) {
        int numRequired = 0;
        for (VariableElement parameter : parameters) {
          if (!parameter.isNamed()) {
            numRequired++;
          }
        }
        return numRequired;
      }

      private List<VariableElement> getNamedParameters(List<VariableElement> parameters) {
        List<VariableElement> named = Lists.newArrayList();
        for (VariableElement v : parameters) {
          if (v.isNamed()) {
            named.add(v);
          }
        }
        return named;
      }
    }
  }
}
