// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.common;

import com.google.common.collect.Sets;
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
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.VariableElement;
import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.InterfaceType.Member;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeKind;
import com.google.dart.compiler.type.Types;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class TypeHeuristicImplementation implements TypeHeuristic {

  private ExpressionTypeInfo typeInfo;
  private final Set<Type> dynTypes;

  public TypeHeuristicImplementation(DartUnit unit, CoreTypeProvider typeProvider) {
    typeInfo = TypeInfoVisitor.computeTypeInfo(unit, typeProvider);
    dynTypes = Sets.<Type> newHashSet(typeProvider.getDynamicType());
  }

  @Override
  public Set<Type> getTypesOf(DartExpression expr) {
    Set<Type> types = typeInfo.getTypeSets().get(expr.getNormalizedNode());
    if (types != null) {
      return types;
    }
    return dynTypes;
  }

  @Override
  public boolean isDynamic(Set<Type> types) {
    return (types == dynTypes || (types.size() > 1) || TypeKind.of(types.iterator().next())
        .equals(TypeKind.DYNAMIC));
  }

  @Override
  public Set<MethodElement> getImplementationsOf(DartExpression expr) {
    return typeInfo.getMethodImpl().get(expr.getNormalizedNode());
  }

  @Override
  public Set<FieldElement> getFieldImplementationsOf(DartExpression expr, FieldKind fieldKind) {
    Set<FieldElement> fields = null;
    if (fieldKind == FieldKind.GETTER) {
      fields = typeInfo.getGettersImpl().get(expr.getNormalizedNode());
    } else {
      fields = typeInfo.getSettersImpl().get(expr.getNormalizedNode());
    }
    assert assertFieldsMatch(fields, fieldKind);
    return fields;
  }

  public static Element maybeGetTargetElement(DartExpression expr) {
    return maybeGetTargetElement(expr, null);
  }

  private static Element maybeGetTargetElement(DartNode dartNode, Set<Element> elements) {
    Element element = null;
    String propName = null;
    elements = Sets.newHashSet();
    if (dartNode instanceof DartPropertyAccess) {
      DartPropertyAccess propAccess = (DartPropertyAccess) dartNode;
      propName = propAccess.getPropertyName();
      element = maybeGetTargetElement(propAccess.getQualifier(), elements);
    } else if (dartNode instanceof DartIdentifier) {
      element = ((DartIdentifier) dartNode).getTargetSymbol();
      if (ElementKind.of(element).equals(ElementKind.FIELD)) {
        propName = element.getName();
        element = element.getEnclosingElement();
      } else {
        return element;
      }
    } else if (dartNode instanceof DartArrayAccess) {
      return maybeGetTargetElement(((DartArrayAccess) dartNode).getTarget());
    }
    if (element != null) {
      if (TypeKind.of(element.getType()).equals(TypeKind.INTERFACE)) {
        InterfaceType iType = (InterfaceType) element.getType();
        Member member = iType.lookupMember(propName);
        if (member != null) {
          element = member.getElement();
          elements.add(element);
        }
        ClassElement classElement = iType.getElement();
        for (InterfaceType subType : classElement.getSubtypes()) {
          member = subType.lookupMember(propName);
          if (member != null) {
            elements.add(member.getElement());
          }
        }
        if (elements.size() != 1) {
          return null;
        }
      } else {
        // TypeKind (DYNAMIC, NONE, FUNCTION, ...)
        return null;
      }
    }
    return element;
  }

  private static boolean assertFieldsMatch(Set<FieldElement> fields, FieldKind fieldKind) {
    if (fields == null) {
      return true;
    }
    boolean allMatch = true;
    for (FieldElement fieldElement : fields) {
      boolean singleMatch;
      Modifiers modifiers = fieldElement.getModifiers();
      if (modifiers.isAbstractField()) {
        singleMatch = fieldKind == FieldKind.GETTER ? fieldElement.getGetter() != null
            : fieldElement.getSetter() != null;
      } else {
        singleMatch = true;
      }
      allMatch &= singleMatch;
    }
    return allMatch;
  }

  private static class TypeInfoVisitor implements DartPlainVisitor<Type> {

    private final ExpressionTypeInfo typeInfo;
    private final CoreTypeProvider typeProvider;
    private final Types typeUtils;
    private InterfaceType currentClass;
    Set<Element> visitedConstants;

    public static ExpressionTypeInfo computeTypeInfo(DartUnit unit, CoreTypeProvider typeProvider) {
      TypeInfoVisitor typeInfoVisitor = new TypeInfoVisitor(typeProvider);
      typeInfoVisitor.visitUnit(unit);
      return typeInfoVisitor.typeInfo;
    }

    private TypeInfoVisitor(CoreTypeProvider typeProvider) {
      this.typeProvider = typeProvider;
      this.typeUtils = Types.getInstance(typeProvider);
      this.typeInfo = ExpressionTypeInfo.create();
    }

    @Override
    public Type visitUnit(DartUnit node) {
      visitedConstants = Sets.newHashSet();
      Type type = visitChildrenAndReturnVoid(node);
      visitedConstants = null;
      return type;
    }

    @Override
    public Type visitClass(DartClass node) {
      beginClassContext(node);
      visitChildren(node);
      endClassContext();
      return dynamicType();
    }

    private void beginClassContext(DartClass node) {
      currentClass = node.getSymbol().getType();
    }

    private void endClassContext() {
      currentClass = null;
    }

    @Override
    public Type visitThisExpression(DartThisExpression node) {
      return recordTypeInfo(node, currentClass.getElement().getType());
    }

    @Override
    public Type visitArrayLiteral(DartArrayLiteral node) {
      visit(node.getExpressions());
      return getType(node);
    }

    @Override
    public Type visitMapLiteral(DartMapLiteral node) {
      return recordTypeInfo(node, getType(node));
    }

    @Override
    public Type visitMapLiteralEntry(DartMapLiteralEntry node) {
      return computeType(node);
    }

    @Override
    public Type visitBooleanLiteral(DartBooleanLiteral node) {
      return recordTypeInfo(node, getType(node));
    }

    @Override
    public Type visitDoubleLiteral(DartDoubleLiteral node) {
      return recordTypeInfo(node, getType(node));
    }

    @Override
    public Type visitIntegerLiteral(DartIntegerLiteral node) {
      return recordTypeInfo(node, getType(node));
    }

    @Override
    public Type visitStringLiteral(DartStringLiteral node) {
      return recordTypeInfo(node, getType(node));
    }

    @Override
    public Type visitStringInterpolation(DartStringInterpolation node) {
      return recordTypeInfo(node, getType(node));
    }

    @Override
    public Type visitNullLiteral(DartNullLiteral node) {
      return recordTypeInfo(node, nullType());
    }

    @Override
    public Type visitParenthesizedExpression(DartParenthesizedExpression node) {
      return recordTypeInfo(node, computeType(node.getExpression()));
    }

    @Override
    public Type visitTypeNode(DartTypeNode node) {
      return node.getType() == null ? dynamicType() : node.getType();
    }

    @Override
    public Type visitBlock(DartBlock node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitBreakStatement(DartBreakStatement node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitContinueStatement(DartContinueStatement node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitDefault(DartDefault node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitEmptyStatement(DartEmptyStatement node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitExprStmt(DartExprStmt node) {
      return visit(node.getExpression());
    }

    @Override
    public Type visitParameter(DartParameter node) {
      visit(node.getDefaultExpr());
      return getType(node);
    }

    @Override
    public Type visitMethodDefinition(DartMethodDefinition node) {
      visitChildren(node);
      return getType(node);
    }

    @Override
    public Type visitNewExpression(DartNewExpression node) {
      visit(node.getArgs());
      return getType(node);
    }

    @Override
    public Type visitMethodInvocation(DartMethodInvocation node) {
      visit(node.getArgs());
      Type type = computeType(node.getTarget());
      String selectorName = node.getFunctionNameString();
      type = computeAndRecordSelectorTypes(node, type, selectorName);
      return type;
    }

    @Override
    public Type visitFunction(DartFunction node) {
      visit(node.getParams());
      computeType(node.getBody());
      return getType(node.getReturnTypeNode());
    }

    @Override
    public Type visitAssertion(DartAssertion node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitImportDirective(DartImportDirective node) {
      return voidType();
    }

    @Override
    public Type visitLibraryDirective(DartLibraryDirective node) {
      return voidType();
    }

    @Override
    public Type visitNativeDirective(DartNativeDirective node) {
      return voidType();
    }

    @Override
    public Type visitResourceDirective(DartResourceDirective node) {
      return voidType();
    }

    @Override
    public Type visitSourceDirective(DartSourceDirective node) {
      return voidType();
    }

    @Override
    public void visit(List<? extends DartNode> nodes) {
      if (nodes != null) {
        for (DartNode node : nodes) {
          node.getNormalizedNode().accept(this);
        }
      }
    }

    @Override
    public Type visitArrayAccess(DartArrayAccess node) {
      Type type = computeType(node.getTarget());
      type = computeAndRecordSelectorTypes(node, type, getOperatorSelectorName(Token.INDEX));
      visit(node.getKey());
      return type;
    }

    @Override
    public Type visitPropertyAccess(DartPropertyAccess node) {
      String selectorName = node.getPropertyName();
      Type receiver = computeType(node.getQualifier());
      Type selectorType = computeAndRecordSelectorTypes(node, receiver, selectorName);
      return selectorType;
    }

    private boolean canBindConstantValue(DartExpression expr) {
      if (expr instanceof DartLiteral) {
        return true;
      } else if (expr instanceof DartBinaryExpression) {
        DartBinaryExpression binExpr = (DartBinaryExpression) expr;
        return canBindConstantValue(binExpr.getArg1()) && canBindConstantValue(binExpr.getArg2());
      } else if (expr instanceof DartUnaryExpression) {
        return canBindConstantValue(((DartUnaryExpression) expr).getArg());
      } else if (expr instanceof DartParenthesizedExpression) {
        return canBindConstantValue(((DartParenthesizedExpression) expr).getExpression());
      } else if (expr instanceof DartIdentifier || expr instanceof DartPropertyAccess) {
        Element e = maybeGetTargetElement(expr);
        switch (ElementKind.of(e)) {
          case FIELD:
            if (visitedConstants.contains(e)) {
              return false;
            }
            visitedConstants.add(e);
            FieldElement field = (FieldElement) e;
            DartField fieldNode = (DartField) field.getNode();
            boolean result = field.getModifiers().isFinal()
                && canBindConstantValue(fieldNode.getValue());
            visitedConstants.remove(e);
            return result;
          case VARIABLE:
            VariableElement var = (VariableElement) e;
            DartVariable varNode = (DartVariable) var.getNode();
            return var.getModifiers().isFinal() && canBindConstantValue(varNode.getValue());
        }
      }
      return false;
    }

    private void maybeBindConstantValues(DartExpression expr, boolean isAssignee) {
      if (canBindConstantValue(expr) && (expr == expr.getNormalizedNode())) {
        DartExpression foldedExpr = null;
        Element target = maybeGetTargetElement(expr);
        switch (ElementKind.of(target)) {
          case VARIABLE:
            if (!isAssignee && target.getModifiers().isFinal()) {
              DartVariable var = (DartVariable) target.getNode();
              foldedExpr = (DartExpression) var.getValue().clone();
            }
            break;
          case FIELD:
            if (target.getModifiers().isFinal()) {
              DartField field = (DartField) target.getNode();
              foldedExpr = (DartExpression) field.getValue().clone();
            }
            break;
          default:
            return;
        }
        // TODO (fabiomfv) : consider adding normalized field to DartExpression.
        if (foldedExpr != null) {
          if (expr instanceof DartIdentifier) {
            ((DartIdentifier) expr).setNormalizedNode(foldedExpr);
          } else if (expr instanceof DartPropertyAccess) {
            ((DartPropertyAccess) expr).setNormalizedNode(foldedExpr);
          }
        }
      }
    }

    @Override
    public Type visitBinaryExpression(DartBinaryExpression node) {
      Token opToken = node.getOperator();
      maybeBindConstantValues(node.getArg1(), opToken.isAssignmentOperator());
      Type receiver = computeType(node.getArg1());
      maybeBindConstantValues(node.getArg2(), false);
      computeType(node.getArg2());
      switch (opToken) {
        case ADD:
        case SUB:
        case MUL:
        case DIV:
        case MOD:
        case BIT_AND:
        case BIT_OR:
        case BIT_XOR:
        case SAR:
        case SHL:
        case SHR:
        case ASSIGN_ADD:
        case ASSIGN_SUB:
        case ASSIGN_MUL:
        case ASSIGN_DIV:
        case ASSIGN_MOD:
        case ASSIGN_BIT_AND:
        case ASSIGN_BIT_OR:
        case ASSIGN_BIT_XOR:
        case ASSIGN_SAR:
        case ASSIGN_SHL:
        case ASSIGN_SHR: {
          computeAndRecordSelectorTypes(node, receiver, getOperatorSelectorName(opToken));
          return receiver;
        }

        case NE:
          // There is no NE operator implementation. NE is conceptually implemented as !(e1 == e2).
          assert !opToken.isUserDefinableOperator() : "Transformation at the line below is not valid anymore";
          opToken = Token.EQ;
          // $FALL-THROUGH$
        case AND:
        case OR:
        case NOT:
        case EQ:
        case EQ_STRICT:
        case NE_STRICT:
        case LT:
        case GT:
        case LTE:
        case GTE: {
          Type opType = boolType();
          computeAndRecordSelectorTypes(node, receiver, getOperatorSelectorName(opToken));
          recordTypeInfo(node, Sets.newHashSet(opType));
          return opType;
        }

        case ASSIGN: {
          return receiver;
        }

        case COMMA:
          return computeType(node.getArg2());
      }
      return dynamicType();
    }

    // Object is implicit and when looking for == operator we will never find Object== if a child
    // class overrides it. Since Object is also an exception when calling classElement.getSubTypes()
    // we need to handle this as a special case.
    private void maybeAddObjectSelectors(DartExpression node, Type receiver, String selectorName) {
      Member iMember = typeProvider.getObjectType().lookupMember(selectorName);
      if ((iMember != null) && ElementKind.of(iMember.getElement()).equals(ElementKind.METHOD)) {
        recordMethodImpl(node, (MethodElement) iMember.getElement());
      }
    }

    private Type computeAndRecordSelectorTypes(DartExpression expression, Type receiver,
                                               String selectorName) {
      Type type = dynamicType();
      if (receiver != null) {
        if (TypeKind.of(receiver).equals(TypeKind.INTERFACE)) {
          InterfaceType baseType = (InterfaceType) receiver;
          Set<Type> types = Sets.newHashSet();
          for (InterfaceType subType : baseType.getElement().getSubtypes()) {
            InterfaceType sType = subType;
            if (isParameterizedType(sType)) {
              sType = substSubType(sType, baseType);
            }
            Type computedType = computeAndRecordSelectorType(expression, sType, selectorName);
            // void is returned as dynamic. return null to make sure void is not a valid expression
            // return type as in setters or void methods.
            if (computedType != null) {
              type = computedType;
              types.addAll(getConcreteSubTypes(type));
            }
          }
          if (types.size() > 1) {
            type = getCommonSuperType(types);
            types = Sets.newHashSet(dynamicType());
          }
          recordTypeInfo(expression, types);
        }
      }
      return type;
    }

    private Type computeAndRecordSelectorType(DartExpression expression, InterfaceType type,
                                              String selectorName) {
      Member iMember = type.lookupMember(selectorName);
      // TODO (fabiomfv): refactor this.
      if (iMember != null) {
        Element element = iMember.getElement();
        switch (ElementKind.of(element)) {
          case METHOD:
            if (!type.getElement().isInterface()) {
              recordMethodImpl(expression, (MethodElement) element);
              maybeAddObjectSelectors(expression, type, selectorName);
            }
            if (canInstantiateParametrizedType(iMember)) {
              FunctionType ftype = (FunctionType) iMember.getType();
              return ftype.getReturnType();
            }
            return dynamicType();
          case FIELD:
            FieldElement fieldElement = (FieldElement) element;
            recordFieldImpl(expression, fieldElement);
            Modifiers modifiers = fieldElement.getModifiers();
            if (modifiers.isAbstractField() && modifiers.isSetter()) {
              // void is currently dynamic which make the computation incorrect.
              return null;
            }
            return iMember.getType();
          default:
        }
      }
      return dynamicType();
    }

    private Set<Type> getConcreteSubTypes(Type type) {
      Set<Type> concreteTypes = Sets.<Type> newHashSet();
      if (TypeKind.of(type).equals(TypeKind.INTERFACE)) {
        ClassElement cls = (ClassElement) type.getElement();
        for (InterfaceType subType : cls.getSubtypes()) {
          if (!subType.getElement().isInterface()) {
            concreteTypes.add(substSubType(subType, (InterfaceType) type));
          }
        }
      }
      return concreteTypes;
    }

    private InterfaceType substSubType(InterfaceType subType, InterfaceType baseType) {
      List<? extends Type> typeArgs = baseType.getArguments();
      List<? extends Type> typeParams = asInstanceOf(subType, baseType.getElement()).getArguments();
      if (typeArgs != null && !typeArgs.isEmpty()) {
        return subType.subst(typeArgs, typeParams);
      }
      return subType;
    }

    private boolean isParameterizedType(InterfaceType type) {
      return type.getArguments() != null && !type.getArguments().isEmpty();
    }

    private boolean canInstantiateParametrizedType(Member member) {
      InterfaceType iface = member.getHolder();
      List<? extends Type> typeArgs = iface.getArguments();
      List<? extends Type> typeParams = iface.getElement().getTypeParameters();
      return typeArgs.size() == typeParams.size();
    }

    @Override
    public Type visitIdentifier(DartIdentifier node) {
      Element element = node.getTargetSymbol();
      switch (ElementKind.of(element)) {
        case CLASS:
          recordTypeInfo(node, element.getType());
          return element.getType();
        case VARIABLE:
        case PARAMETER:
          Type type = element.getType();
          recordTypeInfo(node, Sets.<Type> newHashSet(type));
          return type;
        case FIELD: {
          Element enclosing = element.getEnclosingElement();
          switch (ElementKind.of(enclosing)) {
            case CLASS:
              ClassElement cls = (ClassElement) enclosing;
              computeAndRecordSelectorTypes(node, cls.getType(), element.getName());
              break;
            case LIBRARY:
              // TODO (fabiomfv).
          }
          return element.getType();
        }
        default:
          return dynamicType();
      }
    }

    @Override
    public Type visitUnaryExpression(DartUnaryExpression node) {
      maybeBindConstantValues(node.getArg(), true);
      Type receiver = computeType(node.getArg());
      Token op = node.getOperator();
      switch (node.getOperator()) {
        case NOT:
          assert !op.isUserDefinableOperator();
          receiver = boolType();
          break;
        case INC:
        case DEC:
          assert !op.isUserDefinableOperator();
          receiver = intType();
          break;
        case SUB:
        case BIT_NOT:
          computeAndRecordSelectorTypes(node, receiver, getOperatorSelectorName(op));
          break;
      }
      recordTypeInfo(node, receiver);
      return receiver;
    }

    @Override
    public Type visitUnqualifiedInvocation(DartUnqualifiedInvocation node) {
      visit(node.getArgs());
      Type type = getType(node);
      if (node.getTarget() != null) {
        String selectorName = node.getTarget().getTargetName();
        Element element = node.getTarget().getTargetSymbol();
        if (element == null) {
          return type;
        }
        Element enclosing = element.getEnclosingElement();
        switch (ElementKind.of(enclosing)) {
          case CLASS: {
            ClassElement cls = (ClassElement) element.getEnclosingElement();
            switch (ElementKind.of(element)) {
              case FIELD:
                computeAndRecordSelectorTypes(node, cls.getType(), selectorName);
                type = element.getType();
                break;
              case METHOD:
                computeAndRecordSelectorTypes(node, cls.getType(), selectorName);
                FunctionType fType = (FunctionType) element.getType();
                type = fType.getReturnType();
                break;
              default:
                type = element.getType();
                break;
            }
            break;
          }
          case LIBRARY:
            // TODO (fabiomfv).
            break;
          case NONE:
            if (TypeKind.of(element.getType()).equals(TypeKind.FUNCTION)) {
              type = ((FunctionType) element.getType()).getReturnType();
              recordTypeInfo(node, type);
            }
            break;
        }
      }
      return type;
    }

    @Override
    public Type visitField(DartField node) {
      visitChildren(node);
      return getType(node);
    }

    @Override
    public Type visitFieldDefinition(DartFieldDefinition node) {
      visitChildrenAndReturnVoid(node);
      Type type = getType(node);
      return type;
    }

    @Override
    public Type visitFunctionExpression(DartFunctionExpression node) {
      visitChildren(node);
      return dynamicType();
    }

    @Override
    public Type visitFunctionTypeAlias(DartFunctionTypeAlias node) {
      return dynamicType();
    }

    @Override
    public Type visitFunctionObjectInvocation(DartFunctionObjectInvocation node) {
      visit(node.getArgs());
      Type type = computeType(node.getTarget());
      recordTypeInfo(node, type);
      return type;
    }

    @Override
    public Type visitCase(DartCase node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitConditional(DartConditional node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitDoWhileStatement(DartDoWhileStatement node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitForInStatement(DartForInStatement node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitForStatement(DartForStatement node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitIfStatement(DartIfStatement node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitInitializer(DartInitializer node) {
      visit(node.getValue());
      return voidType();
    }

    @Override
    public Type visitLabel(DartLabel node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitReturnStatement(DartReturnStatement node) {
      return (node.getValue() == null) ? voidType() : computeType(node.getValue());
    }

    @Override
    public Type visitSuperExpression(DartSuperExpression node) {
      visitChildren(node);
      return getType(node);
    }

    @Override
    public Type visitSwitchStatement(DartSwitchStatement node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitSyntheticErrorExpression(DartSyntheticErrorExpression node) {
      visitChildren(node);
      return dynamicType();
    }

    @Override
    public Type visitSyntheticErrorStatement(DartSyntheticErrorStatement node) {
      visitChildren(node);
      return dynamicType();
    }

    @Override
    public Type visitThrowStatement(DartThrowStatement node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitCatchBlock(DartCatchBlock node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitTryStatement(DartTryStatement node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitVariable(DartVariable node) {
      maybeBindConstantValues(node.getValue(), false);
      visit(node.getValue());
      return dynamicType();
    }

    @Override
    public Type visitVariableStatement(DartVariableStatement node) {
      Type type = computeType(node.getTypeNode());
      visitChildren(node);
      return type;
    }

    @Override
    public Type visitWhileStatement(DartWhileStatement node) {
      return visitChildrenAndReturnVoid(node);
    }

    @Override
    public Type visitNamedExpression(DartNamedExpression node) {
      visit(node.getExpression());
      return getType(node.getExpression());
    }

    @Override
    public Type visitTypeExpression(DartTypeExpression node) {
      return getType(node);
    }

    @Override
    public Type visitTypeParameter(DartTypeParameter node) {
      return getType(node);
    }

    @Override
    public Type visitNativeBlock(DartNativeBlock node) {
      return dynamicType();
    }

    @Override
    public Type visitRedirectConstructorInvocation(DartRedirectConstructorInvocation node) {
      return getType(node);
    }

    @Override
    public Type visitSuperConstructorInvocation(DartSuperConstructorInvocation node) {
      return getType(node);
    }

    @Override
    public Type visitParameterizedNode(DartParameterizedNode node) {
      return node.getExpression().accept(this);
    }

    private Type recordTypeInfo(DartExpression node, Type type) {
      if (type == null) {
        return type;
      }
      DartExpression targetNode = node.getNormalizedNode();
      Map<DartExpression, Set<Type>> typeSets = typeInfo.getTypeSets();
      Set<Type> types = typeSets.get(targetNode);
      if (types == null) {
        types = new HashSet<Type>();
      }
      switch (TypeKind.of(type)) {
        case INTERFACE: {
          ClassElement cls = (ClassElement) type.getElement();
          for (InterfaceType subType : cls.getSubtypes()) {
            InterfaceType rSubType = substSubType(subType, (InterfaceType) type);
            if (!rSubType.getElement().isInterface()) {
              types.add(rSubType);
            }
          }
        }
          break;
        case FUNCTION:
        case FUNCTION_ALIAS:
        case VARIABLE:
          // We dont handle these yet.
        case DYNAMIC:
        case NONE:
          types.add(dynamicType());
          break;
      }
      // We need to be resilient. in case interface is defined with no concrete
      // types, we should
      // not add any partial/incomplete type info we may have gathered so far.
      // for instance DOM does not have concrete types yet.
      if (!types.isEmpty()) {
        typeSets.put(targetNode, types);
      }
      return type;
    }

    private void recordMethodImpl(DartExpression expression, MethodElement method) {
      assert method != null;
      Set<MethodElement> methodImpls = typeInfo.getMethodImpl().get(expression);
      if (methodImpls == null) {
        methodImpls = Sets.newHashSet();
        typeInfo.getMethodImpl().put(expression, methodImpls);
      }
      methodImpls.add(method);
    }

    private void recordFieldImpl(DartExpression expression, FieldElement field) {
      assert field != null;
      Set<FieldElement> getters = typeInfo.getGettersImpl().get(expression);
      if (getters == null) {
        getters = Sets.newHashSet();
        typeInfo.getGettersImpl().put(expression, getters);
      }
      Set<FieldElement> setters = typeInfo.getSettersImpl().get(expression);
      if (setters == null) {
        setters = Sets.newHashSet();
        typeInfo.getSettersImpl().put(expression, setters);
      }
      Modifiers modifiers = field.getModifiers();
      if (modifiers.isAbstractField()) {
        if (field.getSetter() != null) {
          setters.add(field);
        }
        if (field.getGetter() != null) {
          getters.add(field);
        }
      } else {
        getters.add(field);
        setters.add(field);
      }
    }

    private void recordTypeInfo(DartExpression node, Set<Type> types) {
      for (Type type : types) {
        recordTypeInfo(node, type);
      }
    }

    void visitChildren(DartNode node) {
      node.getNormalizedNode().visitChildren(this);
    }

    private Type visitChildrenAndReturnVoid(DartNode node) {
      visitChildren(node);
      return voidType();
    }

    private Type visit(DartExpression expression) {
      if (expression != null) {
        return expression.getNormalizedNode().accept(this);
      }
      return voidType();
    }

    Type getType(DartNode node) {
      return (node == null) ? dynamicType() : node.getNormalizedNode().getType();
    }

    Type computeType(DartNode node) {
      return (node == null) ? dynamicType() : node.getNormalizedNode().accept(this);
    }

    private Type dynamicType() {
      return typeProvider.getDynamicType();
    }

    private Type nullType() {
      return typeProvider.getNullType();
    }

    private Type boolType() {
      return typeProvider.getBoolType();
    }

    private Type intType() {
      return typeProvider.getIntType();
    }

    private Type voidType() {
      return typeProvider.getVoidType();
    }

    private String getOperatorSelectorName(Token op) {
      switch (op) {
        case SUB:
          return "operator negate";

        case ASSIGN_ADD:
          return getOperatorSelectorName(Token.ADD);
        case ASSIGN_SUB:
          return getOperatorSelectorName(Token.SUB);
        case ASSIGN_MUL:
          return getOperatorSelectorName(Token.MUL);
        case ASSIGN_DIV:
          return getOperatorSelectorName(Token.DIV);

        case ASSIGN_BIT_OR:
          return getOperatorSelectorName(Token.BIT_OR);
        case ASSIGN_BIT_XOR:
          return getOperatorSelectorName(Token.BIT_XOR);
        case ASSIGN_BIT_AND:
          return getOperatorSelectorName(Token.BIT_AND);

        case ASSIGN_SHL:
          return getOperatorSelectorName(Token.SHL);
        case ASSIGN_SAR:
          return getOperatorSelectorName(Token.SAR);
        case ASSIGN_SHR:
          return getOperatorSelectorName(Token.SHR);
      }
      return ("operator " + op.getSyntax());
    }

    private InterfaceType asInstanceOf(Type t, ClassElement element) {
      return typeUtils.asInstanceOf(t, element);
    }

    // TODO (fabiomfv) : revisit this.
    // returns the 'root' type of the set of types or dynamic if can't find a common root type.
    private Type getCommonSuperType(Set<Type> ts) {
      if (ts.size() == 1) {
        return ts.iterator().next();
      }
      for (Type t : ts) {
        if (TypeKind.of(t).equals(TypeKind.INTERFACE) && isSuperTypeOf(t, ts)) {
          if (((ClassElement) t.getElement()).isObject()) {
            continue;
          }
          return t;
        }
      }
      return dynamicType();
    }

    private boolean isSuperTypeOf(Type type, Set<Type> sts) {
      for (Type st : sts) {
        st.getClass();
        type.getClass();
        if (!typeUtils.isSubtype(st, type)) {
          return false;
        }
      }
      return true;
    }
  }

  /**
   * Stores expressions type and implementation information.
   */
  static class ExpressionTypeInfo {

    private final Map<DartExpression, Set<Type>> typeSets;
    private final Map<DartExpression, Set<FieldElement>> getterImpl;
    private final Map<DartExpression, Set<FieldElement>> setterImpl;
    private final Map<DartExpression, Set<MethodElement>> methodImpl;

    static ExpressionTypeInfo create() {
      return new ExpressionTypeInfo();
    }

    private ExpressionTypeInfo() {
      this.typeSets = new HashMap<DartExpression, Set<Type>>();
      this.getterImpl = new HashMap<DartExpression, Set<FieldElement>>();
      this.setterImpl = new HashMap<DartExpression, Set<FieldElement>>();
      this.methodImpl = new HashMap<DartExpression, Set<MethodElement>>();
    }

    Map<DartExpression, Set<Type>> getTypeSets() {
      return typeSets;
    }

    Map<DartExpression, Set<FieldElement>> getGettersImpl() {
      return getterImpl;
    }

    Map<DartExpression, Set<FieldElement>> getSettersImpl() {
      return setterImpl;
    }

    Map<DartExpression, Set<MethodElement>> getMethodImpl() {
      return methodImpl;
    }
  }
}
