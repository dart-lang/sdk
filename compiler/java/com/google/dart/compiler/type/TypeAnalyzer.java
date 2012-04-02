// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.base.Joiner;
import com.google.common.base.Objects;
import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.ImmutableSet;
import com.google.common.collect.LinkedListMultimap;
import com.google.common.collect.Lists;
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
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.HasSourceInfo;
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
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.ResolverErrorCode;
import com.google.dart.compiler.resolver.TypeErrorCode;
import com.google.dart.compiler.resolver.VariableElement;
import com.google.dart.compiler.type.InterfaceType.Member;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

/**
 * Analyzer of static type information.
 */
public class TypeAnalyzer implements DartCompilationPhase {
  private static final ImmutableSet<Token> ASSIGN_OPERATORS =
      Sets.immutableEnumSet(
          Token.ASSIGN,
          Token.ASSIGN_BIT_OR,
          Token.ASSIGN_BIT_XOR,
          Token.ASSIGN_BIT_AND,
          Token.ASSIGN_SHL,
          Token.ASSIGN_SAR,
          Token.ASSIGN_ADD,
          Token.ASSIGN_SUB,
          Token.ASSIGN_MUL,
          Token.ASSIGN_DIV,
          Token.ASSIGN_MOD,
          Token.ASSIGN_TRUNC);
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
      Source source = node.getSourceInfo().getSource();
      if (suppressSdkWarnings && errorCode.getErrorSeverity() == ErrorSeverity.WARNING) {
        if (source != null && SystemLibraryManager.isDartUri(source.getUri())) {
          return;
        }
      }
      context.onError(new DartCompilationError(node, errorCode, arguments));
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
      return "operator " + operator.getSyntax();
    }

    private Type analyzeBinaryOperator(DartNode node, Type lhs, Token operator,
                                       DartNode diagnosticNode, DartExpression rhs) {
      Type rhsType = nonVoidTypeOf(rhs);
      String methodName = methodNameForBinaryOperator(operator);
      Member member = lookupMember(lhs, methodName, diagnosticNode);
      if (member != null) {
        node.setElement(member.getElement());
        return analyzeMethodInvocation(lhs, member, methodName, diagnosticNode,
                                       Collections.<Type>singletonList(rhsType),
                                       Collections.<DartExpression>singletonList(rhs));
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
          checkAssignable(rhsNode, lhs, rhs);
          return rhs;
        }

        case ASSIGN_ADD:
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

        case ADD:
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

       case EQ:
       case NE:
       case EQ_STRICT:
       case NE_STRICT:
         nonVoidTypeOf(rhsNode);
         return boolType;

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

    private boolean checkAssignable(DartNode node, Type t, Type s) {
      t.getClass(); // Null check.
      s.getClass(); // Null check.
      if (!types.isAssignable(t, s)) {
        typeError(node, TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, s, t);
        return false;
      }
      return true;
    }

    private boolean checkAssignable(Type targetType, DartExpression node) {
      return checkAssignable(node, targetType, nonVoidTypeOf(node));
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
      switch (TypeKind.of(type)) {
        case VOID:
        case NONE:
          return typeError(node, TypeErrorCode.VOID);
        default:
          return type;
      }
    }

    @Override
    public Type visitArrayAccess(DartArrayAccess node) {
      Type target = typeOf(node.getTarget());
      return analyzeBinaryOperator(node, target, Token.INDEX, node, node.getKey());
    }

    @Override
    public Type visitAssertion(DartAssertion node) {
      DartExpression conditionNode = node.getExpression();
      Type condition = nonVoidTypeOf(conditionNode);
      switch (condition.getKind()) {
        case FUNCTION:
          FunctionType ftype = (FunctionType) condition;
          Type returnType = ftype.getReturnType();
          if (!types.isAssignable(boolType, returnType) || !ftype.getParameterTypes().isEmpty()) {
            typeError(node, TypeErrorCode.ASSERT_BOOL);
          }
          break;

        default:
          if (!types.isAssignable(boolType, condition)) {
            typeError(node, TypeErrorCode.ASSERT_BOOL);
          }
          break;
      }
      return voidType;
    }

    @Override
    public Type visitBlock(DartBlock node) {
      return typeAsVoid(node);
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
      Element element = (Element) node.getElement();
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
      if (node.introducesVariable()) {
        variableType = typeOf(node.getVariableStatement());
      } else {
        variableType = typeOf(node.getIdentifier());
      }
      DartExpression iterableExpression = node.getIterable();
      Type iterableType = typeOf(iterableExpression);
      Member iteratorMember = lookupMember(iterableType, "iterator", iterableExpression);
      if (iteratorMember != null) {
        if (TypeKind.of(iteratorMember.getType()) == TypeKind.FUNCTION) {
          FunctionType iteratorMethod = (FunctionType) iteratorMember.getType();
          InterfaceType asInstanceOf = types.asInstanceOf(iteratorMethod.getReturnType(),
              dynamicIteratorType.getElement());
          if (asInstanceOf != null) {
            checkAssignable(iterableExpression, variableType, asInstanceOf.getArguments().get(0));
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
      return typeAsVoid(node);
    }

    @Override
    public Type visitForStatement(DartForStatement node) {
      typeOf(node.getInit());
      checkCondition(node.getCondition());
      typeOf(node.getIncrement());
      typeOf(node.getBody());
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
      if (TypeKind.of(node.getElement().getType()).equals(TypeKind.FUNCTION_ALIAS)) {
        FunctionAliasType type = node.getElement().getType();
        checkCyclicBounds(type.getElement().getTypeParameters());
      }
      return typeAsVoid(node);
    }

    @Override
    public Type visitIdentifier(DartIdentifier node) {
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
      checkCondition(node.getCondition());
      typeOf(node.getThenStatement());
      typeOf(node.getElseStatement());
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
      if (modifiers.isFactory()) {
        analyzeFactory(node.getName(), (ConstructorElement) methodElement);
      } else if (modifiers.isSetter()) {
        DartTypeNode returnType = node.getFunction().getReturnTypeNode();
        if (returnType != null && returnType.getType() != voidType) {
          typeError(returnType, TypeErrorCode.SETTER_RETURN_TYPE, methodElement.getName());
        }
        if (currentClass != null && methodElement.getParameters().size() > 0) {
          Element parameterElement = methodElement.getParameters().get(0);
          Type setterType = parameterElement.getType();
          MethodElement getterElement = Elements.lookupFieldElementGetter(currentClass.getElement(),
                                                                          methodElement.getName());
          if (getterElement != null) {
            Type getterType = getterElement.getReturnType();
            if (!types.isAssignable(setterType, getterType)) {
              typeError(parameterElement, TypeErrorCode.SETTER_TYPE_MUST_BE_ASSIGNABLE,
                        setterType.getElement().getName(),
                        getterType.getElement().getName());
            }
          }
        }
      }
      return typeAsVoid(node);
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
        if (cls.isAbstract()) {
          ErrorCode errorCode =
              constructorElement.getModifiers().isFactory()
                  ? TypeErrorCode.INSTANTIATION_OF_ABSTRACT_CLASS_USING_FACTORY
                  : TypeErrorCode.INSTANTIATION_OF_ABSTRACT_CLASS;
          typeError(typeName, errorCode, cls.getName());
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
      Type type = node.getExpression().accept(this);
      type.getClass(); // quick null check
      return type;
    }

    @Override
    public Type visitPropertyAccess(DartPropertyAccess node) {
      Element element = node.getElement();
      if (element != null && (element.getModifiers().isStatic()
                              || Elements.isTopLevel(element))) {
        return element.getType();
      }
      if (element instanceof ConstructorElement) {
        return element.getType();
      }
      DartNode qualifier = node.getQualifier();
      Type receiver = nonVoidTypeOf(qualifier);
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
          MethodElement getter = fieldElement.getGetter();
          MethodElement setter = fieldElement.getSetter();
          boolean inSetterContext = inSetterContext(node);
          boolean inGetterContext = inGetterContext(node);
          ClassElement enclosingClass = null;
          if (fieldElement.getEnclosingElement() instanceof ClassElement) {
            enclosingClass = (ClassElement) fieldElement.getEnclosingElement();
          }
          // Check for cases when property has no setter or getter.
          if (fieldElement.getModifiers().isAbstractField() && enclosingClass != null) {
            // Check for using field without getter in other operation that assignment.
            if (inGetterContext && getter == null
                && Elements.lookupFieldElementGetter(enclosingClass, name) == null) {
              return typeError(node.getName(), TypeErrorCode.FIELD_HAS_NO_GETTER, node.getName());
            }
            // Check for using field without setter in some assignment variant.
            if (inSetterContext && setter == null
                && Elements.lookupFieldElementSetter(enclosingClass, name) == null) {
                return typeError(node.getName(),
                                 TypeErrorCode.FIELD_HAS_NO_SETTER,
                                 node.getName());
            }
          }

          Type result = member.getType();
          if (fieldElement.getModifiers().isAbstractField()) {
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
          return result;

        default:
          throw internalError(node.getName(), "unexpected kind %s", element.getKind());
      }
    }

    private boolean inSetterContext(DartNode node) {
      if (node.getParent() instanceof DartBinaryExpression) {
        DartBinaryExpression expr = (DartBinaryExpression) node.getParent();
        if (ASSIGN_OPERATORS.contains(expr.getOperator()) && expr.getArg1() == node) {
          return true;
        }
      }
      return false;
    }

    /**
     * An assignment of the form node = <expr> is a write-only expression.  Other types
     * of assignments also read the value and require a getter access.
     */
    private boolean inGetterContext(DartNode node) {
      if (node.getParent() instanceof DartBinaryExpression) {
        DartBinaryExpression expr = (DartBinaryExpression) node.getParent();
        if (Token.ASSIGN.equals(expr.getOperator()) && expr.getArg1() == node) {
          return false;
        }
      }
      return true;
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
      return typeAsVoid(node);
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
      Type type;
      switch (ElementKind.of(element)) {
        case FIELD:
        case METHOD:
          type = typeAsMemberOf(element, currentClass);
          break;
        case NONE:
          return typeError(target, TypeErrorCode.NOT_A_METHOD_IN, name, currentClass);
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
      return checkInitializedDeclaration(node, node.getValue());
    }

    @Override
    public Type visitWhileStatement(DartWhileStatement node) {
      checkCondition(node.getCondition());
      typeOf(node.getBody());
      return voidType;
    }

    @Override
    public Type visitNamedExpression(DartNamedExpression node) {
      // TODO(jgw): Checking of named parameters in progress.

      // Intentionally skip the expression's name -- it's stored as an identifier, but doesn't need
      // to be resolved or type-checked.
      Type type =  node.getExpression().accept(this);
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
      InterfaceType type = node.getType();
      Type elementType = type.getArguments().get(0);
      for (DartExpression expression : node.getExpressions()) {
        boolean isValueAssignable = checkAssignable(elementType, expression);
        if (developerModeChecks && !isValueAssignable) {
          typeError(expression, ResolverErrorCode.LIST_LITERAL_ELEMENT_TYPE, elementType);
        }
      }
      return type;
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
        return checkInitializedDeclaration(node, node.getValue());
      }
    }

    private Type checkInitializedDeclaration(DartDeclaration<?> node, DartExpression value) {
      if (value != null && node.getElement() != null) {
        checkAssignable(node.getElement().getType(), value);
      }
      return voidType;
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
                  typeError(node, TypeErrorCode.SUPERTYPE_HAS_METHOD, name,
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
                  typeError(node, TypeErrorCode.SUPERTYPE_HAS_FIELD, element.getName(),
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
