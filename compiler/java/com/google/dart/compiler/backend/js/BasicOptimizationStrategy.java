// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.common.collect.Sets;
import com.google.dart.compiler.ast.DartArrayAccess;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionObjectInvocation;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartInitializer;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartNullLiteral;
import com.google.dart.compiler.ast.DartReturnStatement;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartUnaryExpression;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.backend.common.TypeHeuristic;
import com.google.dart.compiler.backend.common.TypeHeuristic.FieldKind;
import com.google.dart.compiler.backend.common.TypeHeuristicImplementation;
import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ConstructorElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeKind;

import java.util.List;
import java.util.Set;

class BasicOptimizationStrategy implements OptimizationStrategy {

  private final TypeHeuristic typeHeuristic;
  private final CoreTypeProvider typeProvider;
  private static final String NUMBER_IMPLEMENTATION = "NumberImplementation";
  private static final String STRING_IMPLEMENTATION = "StringImplementation";
  private static final String BOOL_IMPLEMENTATION = "BoolImplementation";

  public BasicOptimizationStrategy(DartUnit unit, CoreTypeProvider typeProvider) {
    this.typeHeuristic = new TypeHeuristicImplementation(unit, typeProvider);
    this.typeProvider = typeProvider;
  }

  @Override
  public boolean canSkipOperatorShim(DartBinaryExpression x) {
    // If both expressions are raw js number types, we can elide the operator shim.
    Token operator = x.getOperator();
    switch (operator) {
      case SHL:
      case SAR:
      case SHR:
      case BIT_AND:
      case BIT_OR:
      case BIT_XOR:
      case LT:
      case GT:
      case LTE:
      case GTE:
      case ADD:
      case SUB:
      case MUL:
      case DIV: {
        return (isNumericType(x.getArg1()) && isNumericType(x.getArg2()));
      }

      case OR:
      case AND: {
        return ((isNumericType(x.getArg1()) && isNumericType(x.getArg2()))
            || (isBooleanType(x.getArg1()) && isBooleanType(x.getArg2())));
      }

      case NE:
      case EQ: {
        DartExpression lhs = x.getArg1();
        DartExpression rhs = x.getArg2();
        return ((isNumericType(lhs) && (isNumericType(rhs) || isNullLiteral(rhs)))
            || (isStringType(lhs) && (isStringType(rhs) || isNullLiteral(rhs)))
            || (isBooleanType(lhs) && (isBooleanType(rhs) || isNullLiteral(rhs)))
            || isNullLiteral(lhs)
            || hasSingleImplementation(x));
      }

      case EQ_STRICT:
      case NE_STRICT: {
        return true;
      }
    }

    return false;
  }

  @Override
  public boolean canSkipOperatorShim(DartUnaryExpression x) {
    Token op = x.getOperator();
    switch (op) {
      case BIT_NOT:
      case SUB: {
        return (isNumericType(x.getArg()) && hasSingleImplementation(x));
      }

      case INC:
      case DEC: {
        assert !op.isUserDefinableOperator();
        return isNumericType(x.getArg());
      }

      case NOT: {
        assert !op.isUserDefinableOperator();
        return isBooleanType(x.getArg());
      }
    }
    return false;
  }

  @Override
  public boolean canSkipArrayAccessShim(DartArrayAccess array, boolean isAssignee) {
    Set<MethodElement> impls = typeHeuristic.getImplementationsOf(array);
    if (impls != null && impls.size() == 1) {
      MethodElement impl = impls.iterator().next();
      Element arrayElement = TypeHeuristicImplementation.maybeGetTargetElement(array);
      if (isAssignee && (arrayElement == null || arrayElement.getModifiers().isFinal())) {
        return false;
      }
      return impl.getEnclosingElement().equals(typeProvider.getObjectArrayType().getElement());
    }
    return false;
  }

  private boolean isStringType(DartExpression expr) {
    return isSingleType(expr, STRING_IMPLEMENTATION);
  }

  static boolean isStringType(Set<Type> types) {
    return isSingleType(types, STRING_IMPLEMENTATION);
  }

  private boolean isBooleanType(DartExpression expr) {
    return isSingleType(expr, BOOL_IMPLEMENTATION);
  }

  static boolean isBooleanType(Set<Type> types) {
    return isSingleType(types, BOOL_IMPLEMENTATION);
  }

  private boolean isNumericType(DartExpression expr) {
    return isSingleType(typeHeuristic.getTypesOf(expr), NUMBER_IMPLEMENTATION);
  }

  static boolean isNumericType(Set<Type> types) {
    return isSingleType(types, NUMBER_IMPLEMENTATION);
  }

  private boolean isSingleType(DartExpression expr, String className) {
    Set<Type> types = typeHeuristic.getTypesOf(expr);
    return isSingleType(types, className);
  }

  private boolean hasSingleImplementation(DartBinaryExpression expr) {
    Set<MethodElement> impl = typeHeuristic.getImplementationsOf(expr);
    return ((impl != null) && (impl.size() == 1));
  }

  private boolean isNullLiteral(DartExpression expr) {
    return expr instanceof DartNullLiteral;
  }

  private static boolean isSingleType(Set<Type> types, String className) {
    if (types.size() != 1) {
      return false;
    }

    Type type = types.iterator().next();
    if (type.getKind() == TypeKind.INTERFACE) {
      return className.equals(type.getElement().getName());
    }
    return false;
  }

  /**
   * Return {@link FieldElement} if the {@link DartIdentifier} is actually an access to the field
   * and we can optimize away the call to the generated getter.
   */
  @Override
  public FieldElement findOptimizableFieldElementFor(DartExpression expr, FieldKind fieldKind) {
    Set<DartExpression> visited = Sets.newHashSet();
    FieldElement field = maybeGetInlineableField(expr, fieldKind, visited);
    visited = null;
    return field;
  }

  private FieldElement maybeGetInlineableField(DartExpression expr, FieldKind fieldKind,
                                               Set<DartExpression> visited) {
    if (visited.contains(expr)) {
      // If field references itself, it will cause a cycle. in this case, we return null.
      return null;
    }
    visited.add(expr);

    // if the field is referenced in a function expression we cannot inline it.
    if (expr.getParent() instanceof DartFunctionObjectInvocation) {
      return null;
    }

    Set<FieldElement> impls = typeHeuristic.getFieldImplementationsOf(expr, fieldKind);
    if ((impls != null) && (impls.size() == 1)) {
      FieldElement field = impls.iterator().next();

      // Check if field is non-abstract and can be 'trivially' inlined.
      if (isFieldInlinable(field, fieldKind)) {
        return field;
      }

      // Check if field is native and whitelisted.
      if (isWhitelistedNativeField(field, fieldKind)) {
        return field;
      }

      // Check if field is abstract and has no side effect.
      FieldElement backingField = maybeGetNonAbstractFieldGetter(field, fieldKind, visited);
      if (backingField != null) {
        return backingField;
      }
    }
    return null;
  }

  private FieldElement maybeGetNonAbstractFieldGetter(FieldElement field, FieldKind fieldKind,
                                                      Set<DartExpression> visited) {
    if (field.getModifiers().isAbstractField()) {
      if (fieldKind.equals(FieldKind.GETTER) && (field.getGetter() != null)) {
        DartMethodDefinition getter = (DartMethodDefinition) field.getGetter().getNode();
        if (getter != null && getter.getFunction() != null) {
          DartFunction fnGetter = getter.getFunction();
          if (fnGetter.getBody() != null && fnGetter.getBody().getStatements() != null
              && fnGetter.getBody().getStatements().size() == 1) {
            DartStatement stmt = fnGetter.getBody().getStatements().iterator().next();
            if (stmt instanceof DartReturnStatement) {
              DartReturnStatement returnStmt = (DartReturnStatement) stmt;
              return maybeGetInlineableField(returnStmt.getValue(), fieldKind, visited);
            }
          }
        }
      }
    }
    return null;
  }

  @Override
  public Element findElementFor(DartMethodInvocation expr) {
    Set<MethodElement> impls = typeHeuristic.getImplementationsOf(expr);
    if ((impls != null) && (impls.size() == 1)) {
      return impls.iterator().next();
    }
    return (Element) expr.getTargetSymbol();
  }

  @Override
  public boolean canSkipNormalization(DartBinaryExpression expr) {
    Token operator = expr.getOperator();
    Set<Type> types = typeHeuristic.getTypesOf(expr.getArg1());
    switch (operator) {
      case ASSIGN_ADD: {
        if (!canInlineSideEffect(expr.getArg1())) {
          return false;
        }
        return isNumericType(types) || isStringType(types);
      }
      case ASSIGN_SUB:
      case ASSIGN_MUL:
      case ASSIGN_DIV:
      case ASSIGN_SHR:
      case ASSIGN_SAR:
      case ASSIGN_SHL:
      case ASSIGN_BIT_AND:
      case ASSIGN_BIT_OR:
      case ASSIGN_BIT_XOR: {
        if (!canInlineSideEffect(expr.getArg1())) {
          return false;
        }
        return isNumericType(types);
      }
      case AND:
      case OR: {
        return isNumericType(types) || isBooleanType(types);
      }
      case ASSIGN_TRUNC:
      case ASSIGN_MOD:
        // TRUNC and MOD cannot skip normalization as there is no 'native' javascript
        // equivalent operator.
        return false;
      default:
        throw new AssertionError("Internal Error: Unknown operator " + operator);
    }
  }

  @Override
  public boolean canSkipNormalization(DartUnaryExpression expr) {
    Token operator = expr.getOperator();
    Set<Type> types = typeHeuristic.getTypesOf(expr.getArg());
    switch (operator) {
      case DEC:
      case INC: {
        // DEC, INC are not user definable.
        if (!canInlineSideEffect(expr.getArg())) {
          return false;
        }
        return isNumericType(types);
      }
      default:
        throw new AssertionError("Internal Error: Unknown operator " + operator);
    }
  }

  @Override
  public boolean isWhitelistedNativeField(FieldElement field, FieldKind fieldKind) {
    // TODO (fabiomfv) : Given that we only whitelist two types and one field, hardcode the logic
    // for now. If the number grows, consider moving to a map.
    // Assumes the native field name is the same as the FieldElement name.
    if (isNativeFieldWithAccessor(field, fieldKind)) {
      Element fieldHolder = field.getEnclosingElement();
      if (fieldHolder.equals(typeProvider.getObjectArrayType().getElement())
         || fieldHolder.equals(typeProvider.getStringImplementationType().getElement())) {
        return field.getName().equals("length");
      }
    }
    return false;
  }

  private boolean canInlineSideEffect(DartExpression expr) {
    if (expr instanceof DartArrayAccess) {
      Set<MethodElement> impls = typeHeuristic.getImplementationsOf(expr);
      if (impls != null) {
        for (MethodElement impl : impls) {
          if (ElementKind.of(impl.getEnclosingElement()).equals(ElementKind.CLASS)) {
            ClassElement cls = (ClassElement) impl.getEnclosingElement();
            Element indexAssignOp = cls.lookupLocalElement("operator []=");
            if (indexAssignOp != null && !cls.getType().equals(typeProvider.getObjectArrayType())) {
              return false;
            }
          }
        }
        return true;
      }
    } else {
      Element element = TypeHeuristicImplementation.maybeGetTargetElement(expr);
      if ((element != null) && element.getModifiers().isFinal()) {
        return false;
      }
      switch (ElementKind.of(element)) {
        case FIELD: {
          return isFieldInlinable((FieldElement) element);
        }
        case PARAMETER:
        case VARIABLE:
          return true;
      }
    }
    return false;
  }

  private boolean isFieldInlinable(FieldElement field) {
    return !field.isStatic() && !field.isDynamic() && !field.getModifiers().isAbstractField();
  }

  private boolean isFieldInlinable(FieldElement field, FieldKind fieldKind) {
    return isFieldInlinable(field)
        && (fieldKind != FieldKind.SETTER || !field.getModifiers().isFinal());
  }

  private boolean isNativeFieldWithAccessor(FieldElement field, FieldKind fieldKind) {
    if (fieldKind == FieldKind.GETTER && field.getGetter() != null) {
      return field.getGetter().getModifiers().isNative();
    } else if (fieldKind == FieldKind.SETTER && field.getSetter() != null) {
      return field.getSetter().getModifiers().isNative();
    }
    return false;
  }

  private boolean hasSingleImplementation(DartExpression expr) {
    Set<MethodElement> impls = typeHeuristic.getImplementationsOf(expr);
    return ((impls != null) && (impls.size() == 1));
  }

  @Override
  public boolean canInlineInitializers(ConstructorElement constructorElement) {
    // For now we only inline classes that don't have Only immediate subtypes of object that are
    // not subclassed.
    // We will refine this in the near future to include arbitrary class hierarchies.
    ClassElement classElement = (ClassElement) constructorElement.getEnclosingElement();
    if (canEmitOptimizedClassConstructor(classElement)) {
      Modifiers modifiers = constructorElement.getModifiers();
      if (modifiers.isRedirectedConstructor() || modifiers.isConstant()) {
        return false;
      }
      return (classElement.isObjectChild() && (classElement.getSubtypes().size() == 1));
    }
    return false;
  }

  @Override
  public boolean canEmitOptimizedClassConstructor(ClassElement classElement) {
    // For now we only inline classes that don't have Only immediate subtypes of object that are
    // not subclassed.
    // We will refine this in the near future to include arbitrary class hierarchies.
    if (classElement.getModifiers().isNative()) {
      return false;
    }
    List<ConstructorElement> constructors = classElement.getConstructors();
    if (constructors.size() != 1) {
      return false;
    }
    ConstructorElement constructor = constructors.iterator().next();
    Modifiers modifiers = constructor.getModifiers();
    if (modifiers.isStatic() || modifiers.isConstant() || modifiers.isNative()) {
      return false;
    }
    DartMethodDefinition method = (DartMethodDefinition) constructor.getNode();
    for (DartParameter param : method.getFunction().getParams()) {
      if (param.getModifiers().isNamed() || (param.getDefaultExpr() != null)) {
        return false;
      }
    }
    for (DartInitializer initializer : method.getInitializers()) {
      // TODO (fabiomfv) :
      // Function expressions in initializers are being revisited due to the possiblity of having
      // closures on 'this' that is not fully created at the time of initialization. Keeping the
      // simplest case for now. Will revisit this in the next round.
      if (initializer.getValue() instanceof DartFunctionExpression) {
        return false;
      }
    }
    return true;
  }

  @Override
  public boolean canOptimizeFunctionExpressionBind(DartFunctionExpression expr) {
    DartFunction fn = expr.getFunction();
    if (fn != null) {
      for (DartParameter param : fn.getParams()) {
        if (param.getModifiers().isNamed()) {
          return false;
        }
      }
    }
    return true;
  }
}
