// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.base.Joiner;
import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.LinkedListMultimap;
import com.google.common.collect.Multimap;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilationPhase;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.ErrorCode;
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
import com.google.dart.compiler.ast.DartNodeTraverser;
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
import com.google.dart.compiler.ast.ElementReference;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ConstructorElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.CyclicDeclarationException;
import com.google.dart.compiler.resolver.DuplicatedInterfaceException;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.EnclosingElement;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.ResolverErrorCode;
import com.google.dart.compiler.resolver.TypeErrorCode;
import com.google.dart.compiler.resolver.VariableElement;
import com.google.dart.compiler.type.InterfaceType.Member;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Analyzer of static type information.
 */
public class TypeAnalyzer implements DartCompilationPhase {
  private final ConcurrentHashMap<ClassElement, List<Element>> unimplementedElements =
      new ConcurrentHashMap<ClassElement, List<Element>>();
  private final Set<ClassElement> diagnosedAbstractClasses =
      Collections.newSetFromMap(new ConcurrentHashMap<ClassElement, Boolean>());

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
    ConcurrentHashMap<ClassElement, List<Element>> unimplementedElements =
        new ConcurrentHashMap<ClassElement, List<Element>>();
    Set<ClassElement> diagnosed =
        Collections.newSetFromMap(new ConcurrentHashMap<ClassElement, Boolean>());
    Analyzer analyzer = new Analyzer(context, typeProvider, unimplementedElements, diagnosed);
    analyzer.setCurrentClass(currentClass);
    return node.accept(analyzer);
  }

  @Override
  public DartUnit exec(DartUnit unit, DartCompilerContext context,
                       CoreTypeProvider typeProvider) {
    unit.accept(new Analyzer(context, typeProvider, unimplementedElements,
                             diagnosedAbstractClasses));
    return unit;
  }

  @VisibleForTesting
  static class Analyzer implements DartPlainVisitor<Type> {
    private final DynamicType dynamicType;
    private final Type stringType;
    private final InterfaceType defaultLiteralMapType;
    private final Type voidType;
    private final DartCompilerContext context;
    private final Types types;
    private Type expected;
    private InterfaceType currentClass;
    private final ConcurrentHashMap<ClassElement, List<Element>> unimplementedElements;
    private final InterfaceType boolType;
    private final InterfaceType numType;
    private final InterfaceType intType;
    private final Type nullType;
    private final InterfaceType functionType;
    private final InterfaceType dynamicIteratorType;

    /**
     * Keeps track of the number of nested catches, used to detect re-throws
     * outside of any catch block.
     */
    private int catchDepth = 0;


    Analyzer(DartCompilerContext context, CoreTypeProvider typeProvider,
             ConcurrentHashMap<ClassElement, List<Element>> unimplementedElements,
             Set<ClassElement> diagnosedAbstractClasses) {
      this.context = context;
      this.unimplementedElements = unimplementedElements;
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
    }

    @VisibleForTesting
    void setCurrentClass(InterfaceType type) {
      currentClass = type;
    }

    private InterfaceType getCurrentClass() {
      return currentClass;
    }

    private DynamicType typeError(DartNode node, ErrorCode code, Object... arguments) {
      onError(node, code, arguments);
      return dynamicType;
    }

    private void onError(DartNode node, ErrorCode code, Object... arguments) {
      context.onError(new DartCompilationError(node, code, arguments));
    }

    AssertionError internalError(DartNode node, String message, Object... arguments) {
      message = String.format(message, arguments);
      context.onError(new DartCompilationError(node, TypeErrorCode.INTERNAL_ERROR,
                                                        message));
      return new AssertionError("Internal error: " + message);
    }

    private Type typeOfLiteral(DartLiteral node) {
      return node.getType();
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
        case ASSIGN_SHR:
          return Token.SHR;
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
      return checkConstructorForwarding(node, node.getSymbol());
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

    private Type analyzeBinaryOperator(ElementReference node, Type lhs, Token operator,
                                       DartNode diagnosticNode, DartExpression rhs) {
      Type rhsType = nonVoidTypeOf(rhs);
      String methodName = methodNameForBinaryOperator(operator);
      Member member = lookupMember(lhs, methodName, diagnosticNode);
      if (member != null) {
        node.setReferencedElement(member.getElement());
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

        case ASSIGN_SHR:
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

        case SHR:
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
      List<Type> argumentTypes = new ArrayList<Type>(argumentNodes.size());
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

    private void checkAssignable(DartNode node, Type t, Type s) {
      t.getClass(); // Null check.
      s.getClass(); // Null check.
      if (!types.isAssignable(t, s)) {
        typeError(node, TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, s, t);
      }
    }

    private void checkAssignable(Type targetType, DartExpression node) {
      checkAssignable(node, targetType, nonVoidTypeOf(node));
    }

    private Type analyzeMethodInvocation(Type receiver, Member member, String name,
                                         DartNode diagnosticNode,
                                         List<Type> argumentTypes,
                                         List<? extends DartExpression> argumentNodes) {
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
                                List<? extends DartExpression> argumentNodes,
                                Iterator<Type> argumentTypes, FunctionType ftype) {
      int argumentCount = 0;
      List<? extends Type> parameterTypes = ftype.getParameterTypes();
      for (Type parameterType : parameterTypes) {
        if (argumentTypes.hasNext()) {
          checkAssignable(argumentNodes.get(argumentCount), parameterType, argumentTypes.next());
          argumentCount++;
        } else {
          typeError(diagnosticNode, TypeErrorCode.MISSING_ARGUMENT, parameterType);
        }
      }
      Map<String, Type> namedParameterTypes = ftype.getNamedParameterTypes();
      Iterator<Type> named = namedParameterTypes.values().iterator();
      while (named.hasNext() && argumentTypes.hasNext()) {
        checkAssignable(argumentNodes.get(argumentCount), named.next(), argumentTypes.next());
        argumentCount++;
      }
      while (ftype.hasRest() && argumentTypes.hasNext()) {
        checkAssignable(argumentNodes.get(argumentCount), ftype.getRest(), argumentTypes.next());
        argumentCount++;
      }
      while (argumentTypes.hasNext()) {
        argumentTypes.next();
        typeError(argumentNodes.get(argumentCount), TypeErrorCode.EXTRA_ARGUMENT);
        argumentCount++;
      }
      return ftype.getReturnType();
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
                         itype.getArguments(), itype.getElement().getTypeParameters(),
                         badBoundIsError);
          return itype;
        }

        default:
          return type;
      }
    }

    private void validateBounds(List<? extends DartNode> diagnosticNodes,
                                List<? extends Type> arguments,
                                List<? extends Type> parameters,
                                boolean badBoundIsError) {
      if (arguments.size() == parameters.size() && arguments.size() == diagnosticNodes.size()) {
        List<Type> bounds = new ArrayList<Type>(parameters.size());
        for (Type parameter : parameters) {
          TypeVariable variable = (TypeVariable) parameter;
          Type bound = variable.getTypeVariableElement().getBound();
          if (bound == null) {
            internalError(variable.getElement().getNode(), "bound is null");
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

    Type typeOf(DartNode node) {
      if (node == null) {
        return dynamicType;
      }
      return node.accept(this);
    }

    private Type nonVoidTypeOf(DartNode node) {
      Type type = typeOf(node);
      if (type.getKind().equals(TypeKind.VOID)) {
        return typeError(node, TypeErrorCode.VOID);
      }
      return type;
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
          if (returnType.getKind().equals(TypeKind.VOID)) {
            typeError(conditionNode, TypeErrorCode.VOID);
          }
          checkAssignable(conditionNode, boolType, returnType);
          break;

        default:
          checkAssignable(conditionNode, boolType, condition);
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
      node.setReferencedElement(functionType.getElement());
      return checkInvocation(node, node, null, typeOf(node.getTarget()));
    }

    @Override
    public Type visitMethodInvocation(DartMethodInvocation node) {
      String name = node.getFunctionNameString();
      Element element = (Element) node.getTargetSymbol();
      if (element != null && (element.getModifiers().isStatic()
                              || Elements.isTopLevel(element))) {
        node.setReferencedElement(element);
        return checkInvocation(node, node, name, element.getType());
      }
      Type receiver = nonVoidTypeOf(node.getTarget());
      List<DartExpression> arguments = node.getArgs();
      Member member = lookupMember(receiver, name, node);
      if (member != null) {
        node.setReferencedElement(member.getElement());
      }
      return analyzeMethodInvocation(receiver, member, name,
                                     node.getFunctionName(), analyzeArgumentTypes(arguments),
                                     arguments);
    }

    @Override
    public Type visitSuperConstructorInvocation(DartSuperConstructorInvocation node) {
      return checkConstructorForwarding(node, node.getSymbol());
    }

    private Type checkConstructorForwarding(DartInvocation node, ConstructorElement element) {
      if (element == null) {
        visit(node.getArgs());
        return voidType;
      } else {
        node.setReferencedElement(element);
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
      ClassElement element = node.getSymbol();
      InterfaceType type = element.getType();
      findUnimplementedMembers(element);
      setCurrentClass(type);
      visit(node.getTypeParameters());
      if (node.getSuperclass() != null) {
        validateTypeNode(node.getSuperclass(), true);
      }
      if (node.getInterfaces() != null) {
        for (DartTypeNode interfaceNode : node.getInterfaces()) {
          validateTypeNode(interfaceNode, true);
        }
      }
      if (node.getDefaultClass() != null) {
        validateTypeNode(node.getDefaultClass(), true);
      }
      visit(node.getMembers());
      checkInterfaceConstructors(element);
      // Report unimplemented members.
      if (!node.isAbstract()) {
        ClassElement cls = node.getSymbol();
        List<Element> unimplementedMembers = findUnimplementedMembers(cls);
        if (unimplementedMembers.size() > 0) {
          StringBuilder sb = getUnimplementedMembersMessage(cls, unimplementedMembers);
          typeError(
              node.getName(),
              TypeErrorCode.ABSTRACT_CLASS_WITHOUT_ABSTRACT_MODIFIER,
              cls.getName(),
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
                  interfaceConstructor.getNode(),
                  TypeErrorCode.FACTORY_CONSTRUCTOR_TYPES,
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

    private List<Element> findUnimplementedMembers(ClassElement element) {
      if (element.isInterface()) {
        element.getNode().accept(new AbstractMethodFinder(element.getType()));
        return Collections.emptyList();
      }
      List<Element> members = unimplementedElements.get(element);
      if (members != null) {
        return members;
      }
      synchronized (element) {
        members = unimplementedElements.get(element);
        if (members != null) {
          return members;
        }
        AbstractMethodFinder finder = new AbstractMethodFinder(element.getType());
        element.getNode().accept(finder);
        unimplementedElements.put(element, finder.unimplementedElements);
        return finder.unimplementedElements;
      }
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
      visit(node.getParams());
      expected = typeOf(node.getReturnTypeNode());
      typeOf(node.getBody());
      expected = previous;
      return voidType;
    }

    @Override
    public Type visitFunctionExpression(DartFunctionExpression node) {
      node.visitChildren(this);
      return ((Element) node.getSymbol()).getType();
    }

    @Override
    public Type visitFunctionTypeAlias(DartFunctionTypeAlias node) {
      return typeAsVoid(node);
    }

    @Override
    public Type visitIdentifier(DartIdentifier node) {
      Element element = node.getTargetSymbol();
      Type type;
      switch (ElementKind.of(element)) {
        case VARIABLE:
        case PARAMETER:
        case FUNCTION_OBJECT:
          type = element.getType();
          break;

        case FIELD:
        case METHOD:
          type = typeAsMemberOf(element, currentClass);
          break;

        case NONE:
          return typeError(node, TypeErrorCode.CANNOT_BE_RESOLVED, node.getTargetName());

        case DYNAMIC:
          return element.getType();

        default:
          return voidType;
      }
      node.setReferencedElement(element);
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

      // This ensures that the declared type is assignable to Map<String, dynamic>.
      // For example, the user should not write Map<int,int>.
      checkAssignable(node, type, defaultLiteralMapType);

      Type valueType = type.getArguments().get(1);
      // Check the map literal entries against the return type.
      for (DartMapLiteralEntry literalEntry : node.getEntries()) {
        checkAssignable(literalEntry, typeOf(literalEntry), valueType);
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
      MethodElement methodElement = node.getSymbol();
      FunctionType type = methodElement.getFunctionType();
      if (methodElement.getModifiers().isFactory()) {
        analyzeFactory(node.getName(), (ConstructorElement) methodElement);
      } else {
        if (!type.getTypeVariables().isEmpty()) {
          internalError(node, "generic methods are not supported");
        }
      }
      return typeAsVoid(node);
    }

    private void analyzeFactory(DartExpression name, final ConstructorElement methodElement) {
      DartNodeTraverser<Void> visitor = new DartNodeTraverser<Void>() {
        @Override
        public Void visitParameterizedNode(DartParameterizedNode node) {
          DartExpression expression = node.getExpression();
          Element e = null;
          if (expression instanceof DartIdentifier) {
            e = ((DartIdentifier) expression).getTargetSymbol();
          } else if (expression instanceof DartPropertyAccess) {
            e = ((DartPropertyAccess) expression).getTargetSymbol();
          }
          if (!ElementKind.of(e).equals(ElementKind.CLASS)) {
            return null;
          }
          ClassElement cls = (ClassElement) e;
          InterfaceType type = cls.getType();
          List<DartTypeParameter> parameterNodes = node.getTypeParameters();
          List<? extends Type> arguments = type.getArguments();
          if (parameterNodes.size() == 0) {
            return null;
          }
          Analyzer.this.visit(parameterNodes);
          List<TypeVariable> typeVariables = methodElement.getFunctionType().getTypeVariables();
          validateBounds(parameterNodes, arguments, typeVariables, true);
          return null;
        }
      };
      name.accept(visitor);
    }

    @Override
    public Type visitNewExpression(DartNewExpression node) {
      ConstructorElement constructorElement = node.getSymbol();
      node.setReferencedElement(constructorElement);
      DartTypeNode typeNode = Types.constructorTypeNode(node);
      DartNode typeName = typeNode.getIdentifier();
      Type type = validateTypeNode(typeNode, true);
      if (constructorElement == null) {
        visit(node.getArgs());
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
          List<? extends Type> arguments = ifaceType.getArguments();
          ftype = (FunctionType) ftype.subst(arguments, ifaceType.getElement().getTypeParameters());
          List<TypeVariable> typeVariables = ftype.getTypeVariables();
          if (arguments.size() == typeVariables.size()) {
            ftype = (FunctionType) ftype.subst(arguments, typeVariables);
          }
          checkInvocation(node, node, null, ftype);
        }
      }
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
      VariableElement parameter = node.getSymbol();
      FieldElement initializerElement = parameter.getParameterInitializerElement();
      if (initializerElement != null) {
        checkAssignable(node, parameter.getType(), initializerElement.getType());
      }
      return checkInitializedDeclaration(node, node.getDefaultExpr());
    }

    @Override
    public Type visitParenthesizedExpression(DartParenthesizedExpression node) {
      return node.getExpression().accept(this);
    }

    @Override
    public Type visitPropertyAccess(DartPropertyAccess node) {
      Element element = node.getTargetSymbol();
      node.setReferencedElement(element);
      if (element != null && (element.getModifiers().isStatic()
                              || Elements.isTopLevel(element))) {
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
      node.setReferencedElement(element);
      Modifiers modifiers = element.getModifiers();
      if (modifiers.isStatic()) {
        return typeError(node.getName(),
                         TypeErrorCode.STATIC_MEMBER_ACCESSED_THROUGH_INSTANCE,
                         name, element.getName());
      }
      switch (element.getKind()) {
        case CONSTRUCTOR:
          return typeError(node.getName(), TypeErrorCode.MEMBER_IS_A_CONSTRUCTOR,
                           name, element.getName());

        case METHOD:
        case FIELD:
          return member.getType();

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
      } else {
        return currentClass.getElement().getSupertype();
      }
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
      return getCurrentClass();
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
              node.setReferencedElement(member.getElement());
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
          node.setReferencedElement(element);
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
      String name = target.getTargetName();
      Element element = target.getTargetSymbol();
      node.setReferencedElement(element);
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
      List<? extends DartExpression> argumentNodes = node.getArgs();
      List<Type> argumentTypes = new ArrayList<Type>(argumentNodes.size());
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
      return node.getExpression().accept(this);
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
        checkAssignable(elementType, expression);
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
      } else {
        return checkInitializedDeclaration(node, node.getValue());
      }
    }

    private Type checkInitializedDeclaration(DartDeclaration<?> node, DartExpression value) {
      if (value != null) {
        checkAssignable(node.getSymbol().getType(), value);
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
    public Type visitParameterizedNode(DartParameterizedNode node) {
      throw internalError(node, "unexpected node");
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

    private class AbstractMethodFinder extends DartNodeTraverser<Void> {
      private final InterfaceType currentClass;
      private final Multimap<String, Element> superMembers;
      private final List<Element> unimplementedElements;

      private AbstractMethodFinder(InterfaceType currentClass) {
        this.currentClass = currentClass;
        this.superMembers = LinkedListMultimap.create();
        this.unimplementedElements = new ArrayList<Element>();
      }

      @Override
      public Void visitNode(DartNode node) {
        throw new AssertionError();
      }

      @Override
      public Void visitClass(DartClass node) {
        assert node.getSymbol().getType() == currentClass;

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
        EnclosingElement currentLibrary = currentClass.getElement().getEnclosingElement();
        for (InterfaceType supertype : supertypes) {
          for (Element member : supertype.getElement().getMembers()) {
            String name = member.getName();
            if (name.startsWith("_")) {
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
          FieldElement field = node.getSymbol();
          String name = field.getName();
          List<Element> overridden = new ArrayList<Element>(superMembers.removeAll(name));
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
        MethodElement method = node.getSymbol();
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
      private boolean canOverride(DartExpression node, Modifiers modifiers, Element element) {
        if (element.getModifiers().isStatic()) {
          onError(node, ResolverErrorCode.CANNOT_OVERRIDE_STATIC_MEMBER,
                          element.getName(), element.getEnclosingElement().getName());
          return false;
        } else if (modifiers.isStatic()) {
          onError(node, ResolverErrorCode.CANNOT_OVERRIDE_INSTANCE_MEMBER,
                          element.getName(), element.getEnclosingElement().getName());
          return false;
        }
        return true;
      }

      /**
       * Report a static type error if member cannot override superElement, that is, they are not
       * assignable.
       */
      private void checkOverride(DartExpression node, Element member, Element superElement) {
        String name = member.getName();
        Type superMember = typeAsMemberOf(superElement, currentClass);
        if (member.getKind() == ElementKind.METHOD
            && superElement.getKind() == ElementKind.METHOD) {
          if (!types.isSubtype(member.getType(), superMember)) {
            typeError(node, TypeErrorCode.CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE,
                      name, superElement.getEnclosingElement().getName(),
                      member.getType(), superMember);
          }
        } else if (!types.isAssignable(superMember, member.getType())) {
          typeError(node, TypeErrorCode.CANNOT_OVERRIDE_TYPED_MEMBER,
                    name, superElement.getEnclosingElement().getName(),
                    member.getType(), superMember);
        }
      }
    }
  }
}
