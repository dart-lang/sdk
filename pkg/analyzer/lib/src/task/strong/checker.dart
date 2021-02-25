// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show TokenType;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart'
    show CompileTimeErrorCode, StrongModeCode;
import 'package:analyzer/src/task/inference_error.dart';
import 'package:meta/meta.dart';

DartType _elementType(Element e) {
  if (e == null) {
    // Malformed code - just return dynamic.
    return DynamicTypeImpl.instance;
  }
  return (e as dynamic).type;
}

Element _getKnownElement(Expression expression) {
  if (expression is ParenthesizedExpression) {
    return _getKnownElement(expression.expression);
  } else if (expression is NamedExpression) {
    return _getKnownElement(expression.expression);
  } else if (expression is FunctionExpression) {
    return expression.declaredElement;
  } else if (expression is PropertyAccess) {
    return expression.propertyName.staticElement;
  } else if (expression is Identifier) {
    return expression.staticElement;
  }
  return null;
}

/// Checks the body of functions and properties.
class CodeChecker extends RecursiveAstVisitor {
  final TypeSystemImpl rules;
  final TypeProvider typeProvider;
  final InheritanceManager3 inheritance;
  final AnalysisErrorListener reporter;

  FeatureSet _featureSet;

  CodeChecker(TypeProvider typeProvider, TypeSystemImpl rules, this.inheritance,
      AnalysisErrorListener reporter)
      : typeProvider = typeProvider,
        rules = rules,
        reporter = reporter;

  bool get _isNonNullableByDefault =>
      _featureSet.isEnabled(Feature.non_nullable);

  NullabilitySuffix get _noneOrStarSuffix {
    return _isNonNullableByDefault
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  void checkArgument(Expression arg, DartType expectedType) {
    // Preserve named argument structure, so their immediate parent is the
    // method invocation.
    Expression baseExpression = arg is NamedExpression ? arg.expression : arg;
    checkAssignment(baseExpression, expectedType);
  }

  void checkArgumentList(ArgumentList node, FunctionType type) {
    NodeList<Expression> list = node.arguments;
    int len = list.length;
    for (int i = 0; i < len; ++i) {
      Expression arg = list[i];
      ParameterElement element = arg.staticParameterElement;
      if (element == null) {
        // We found an argument mismatch, the analyzer will report this too,
        // so no need to insert an error for this here.
        continue;
      }
      checkArgument(arg, _elementType(element));
    }
  }

  void checkAssignment(Expression expr, DartType to) {
    checkForCast(expr, from: expr.staticType, to: to);
  }

  /// Analyzer checks boolean conversions, but we need to check too, because
  /// it uses the default assignability rules that allow `dynamic` and `Object`
  /// to be assigned to bool with no message.
  void checkBoolean(Expression expr) =>
      checkAssignment(expr, typeProvider.boolType);

  void checkCollectionElement(
      CollectionElement element, DartType expectedType) {
    if (element is ForElement) {
      checkCollectionElement(element.body, expectedType);
    } else if (element is IfElement) {
      checkBoolean(element.condition);
      checkCollectionElement(element.thenElement, expectedType);
      checkCollectionElement(element.elseElement, expectedType);
    } else if (element is Expression) {
      checkAssignment(element, expectedType);
    } else if (element is SpreadElement) {
      // Spread expression may be dynamic in which case it's implicitly downcast
      // to Iterable<dynamic>
      DartType expressionCastType = typeProvider.iterableDynamicType;
      checkAssignment(element.expression, expressionCastType);

      var exprType = element.expression.staticType;
      var asIterableType = exprType.asInstanceOf(typeProvider.iterableElement);

      if (asIterableType != null) {
        var elementType = asIterableType.typeArguments[0];
        // Items in the spread will then potentially be downcast to the expected
        // type.
        _checkImplicitCast(element.expression,
            to: expectedType, from: elementType, forSpread: true);
      }
    }
  }

  void checkForCast(
    Expression expr, {
    @required DartType from,
    @required DartType to,
  }) {
    if (expr is ParenthesizedExpression) {
      checkForCast(expr.expression, from: from, to: to);
    } else {
      _checkImplicitCast(expr, from: from, to: to);
    }
  }

  void checkMapElement(CollectionElement element, DartType expectedKeyType,
      DartType expectedValueType) {
    if (element is ForElement) {
      checkMapElement(element.body, expectedKeyType, expectedValueType);
    } else if (element is IfElement) {
      checkBoolean(element.condition);
      checkMapElement(element.thenElement, expectedKeyType, expectedValueType);
      checkMapElement(element.elseElement, expectedKeyType, expectedValueType);
    } else if (element is MapLiteralEntry) {
      checkAssignment(element.key, expectedKeyType);
      checkAssignment(element.value, expectedValueType);
    } else if (element is SpreadElement) {
      // Spread expression may be dynamic in which case it's implicitly downcast
      // to Map<dynamic, dynamic>
      DartType expressionCastType = typeProvider.mapType2(
          DynamicTypeImpl.instance, DynamicTypeImpl.instance);
      checkAssignment(element.expression, expressionCastType);

      var exprType = element.expression.staticType;
      var asMapType = exprType.asInstanceOf(typeProvider.mapElement);

      if (asMapType != null) {
        var elementKeyType = asMapType.typeArguments[0];
        var elementValueType = asMapType.typeArguments[1];
        // Keys and values in the spread will then potentially be downcast to
        // the expected types.
        _checkImplicitCast(element.expression,
            to: expectedKeyType, from: elementKeyType, forSpreadKey: true);
        _checkImplicitCast(element.expression,
            to: expectedValueType,
            from: elementValueType,
            forSpreadValue: true);
      }
    }
  }

  DartType getAnnotatedType(TypeAnnotation type) {
    return type?.type ?? DynamicTypeImpl.instance;
  }

  @override
  void visitAsExpression(AsExpression node) {
    // We could do the same check as the IsExpression below, but that is
    // potentially too conservative.  Instead, at runtime, we must fail hard
    // if the Dart as and the DDC as would return different values.
    node.visitChildren(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;
    var right = node.rightHandSide;
    Token operator = node.operator;
    TokenType operatorType = operator.type;
    if (operatorType == TokenType.EQ ||
        operatorType == TokenType.QUESTION_QUESTION_EQ) {
      checkForCast(right, from: right.staticType, to: node.writeType);
    } else if (operatorType == TokenType.AMPERSAND_AMPERSAND_EQ ||
        operatorType == TokenType.BAR_BAR_EQ) {
      checkBoolean(left);
      checkBoolean(right);
    } else {
      _checkCompoundAssignment(node);
    }
    node.visitChildren(this);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var op = node.operator;
    if (!op.isUserDefinableOperator) {
      switch (op.type) {
        case TokenType.AMPERSAND_AMPERSAND:
        case TokenType.BAR_BAR:
          checkBoolean(node.leftOperand);
          checkBoolean(node.rightOperand);
          break;
        case TokenType.BANG_EQ:
        case TokenType.BANG_EQ_EQ:
        case TokenType.EQ_EQ_EQ:
        case TokenType.QUESTION_QUESTION:
          break;
        default:
          assert(false);
      }
    }
    node.visitChildren(this);
  }

  @override
  void visitComment(Comment node) {
    // skip, no need to do typechecking inside comments (they may contain
    // comment references which would require resolution).
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _featureSet = node.featureSet;
    node.visitChildren(this);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    checkBoolean(node.condition);
    node.visitChildren(this);
  }

  // Check invocations
  /// Check constructor declaration to ensure correct super call placement.
  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    node.visitChildren(this);

    final init = node.initializers;
    for (int i = 0, last = init.length - 1; i < last; i++) {
      final initializer = init[i];
      if (initializer is SuperConstructorInvocation) {
        // TODO(srawlins): Don't report this when
        //  [CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR] or
        //  [CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS] is reported for
        //  this constructor.
        var source = (node.root as CompilationUnit).declaredElement.source;
        var token = initializer.superKeyword;
        reporter.onError(AnalysisError(source, token.offset, token.length,
            CompileTimeErrorCode.INVALID_SUPER_INVOCATION, [initializer]));
      }
    }
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    var field = node.fieldName;
    var element = field.staticElement;
    DartType staticType = _elementType(element);
    checkAssignment(node.expression, staticType);
    node.visitChildren(this);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    // Check that defaults have the proper subtype.
    var parameter = node.parameter;
    var parameterType = _elementType(parameter.declaredElement);
    assert(parameterType != null);
    var defaultValue = node.defaultValue;
    if (defaultValue != null) {
      checkAssignment(defaultValue, parameterType);
    }

    node.visitChildren(this);
  }

  @override
  void visitDoStatement(DoStatement node) {
    checkBoolean(node.condition);
    node.visitChildren(this);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _checkReturnOrYield(node.expression, node);
    node.visitChildren(this);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _visitForEachParts(node, node.loopVariable?.identifier);
    node.visitChildren(this);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _visitForEachParts(node, node.identifier);
    node.visitChildren(this);
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    if (node.condition != null) {
      checkBoolean(node.condition);
    }
    node.visitChildren(this);
  }

  @override
  void visitForPartsWithExpression(ForPartsWithExpression node) {
    if (node.condition != null) {
      checkBoolean(node.condition);
    }
    node.visitChildren(this);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkFunctionApplication(node);
    node.visitChildren(this);
  }

  @override
  void visitIfStatement(IfStatement node) {
    checkBoolean(node.condition);
    node.visitChildren(this);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    var element = node.writeOrReadElement;
    if (element is MethodElement) {
      var type = element.type;
      // Analyzer should enforce number of parameter types, but check in
      // case we have erroneous input.
      if (type.normalParameterTypes.isNotEmpty) {
        checkArgument(node.index, type.normalParameterTypes[0]);
      }
    } else {
      // TODO(vsm): Assert that the analyzer found an error here?
    }
    node.visitChildren(this);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var arguments = node.argumentList;
    var element = node.constructorName.staticElement;
    if (element != null) {
      var type = _elementType(element);
      checkArgumentList(arguments, type);
    }
    node.visitChildren(this);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    DartType type = DynamicTypeImpl.instance;
    if (node.typeArguments != null) {
      NodeList<TypeAnnotation> targs = node.typeArguments.arguments;
      if (targs.isNotEmpty) {
        type = targs[0].type;
      }
    } else {
      DartType staticType = node.staticType;
      if (staticType is InterfaceType) {
        List<DartType> targs = staticType.typeArguments;
        if (targs != null && targs.isNotEmpty) {
          type = targs[0];
        }
      }
    }
    NodeList<CollectionElement> elements = node.elements;
    for (int i = 0; i < elements.length; i++) {
      checkCollectionElement(elements[i], type);
    }
    super.visitListLiteral(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    var element = node.methodName.staticElement;
    if (element != null) {
      _checkFunctionApplication(node);
    }
    // Don't visit methodName, we already checked things related to the call.
    node.target?.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList?.accept(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _checkUnary(node.operand, node.operator, node.staticElement,
        readType: node.readType, writeType: node.writeType);
    node.visitChildren(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.type == TokenType.BANG) {
      checkBoolean(node.operand);
    } else {
      _checkUnary(node.operand, node.operator, node.staticElement,
          readType: node.readType, writeType: node.writeType);
    }
    node.visitChildren(this);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var type = node.staticElement?.type;
    // TODO(leafp): There's a TODO in visitRedirectingConstructorInvocation
    // in the element_resolver to handle the case that the element is null
    // and emit an error.  In the meantime, just be defensive here.
    if (type != null) {
      checkArgumentList(node.argumentList, type);
    }
    node.visitChildren(this);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _checkReturnOrYield(node.expression, node);
    node.visitChildren(this);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isMap) {
      DartType keyType = DynamicTypeImpl.instance;
      DartType valueType = DynamicTypeImpl.instance;
      if (node.typeArguments != null) {
        NodeList<TypeAnnotation> typeArguments = node.typeArguments.arguments;
        if (typeArguments.isNotEmpty) {
          keyType = typeArguments[0].type;
        }
        if (typeArguments.length > 1) {
          valueType = typeArguments[1].type;
        }
      } else {
        DartType staticType = node.staticType;
        if (staticType is InterfaceType) {
          List<DartType> typeArguments = staticType.typeArguments;
          if (typeArguments != null) {
            if (typeArguments.isNotEmpty) {
              keyType = typeArguments[0];
            }
            if (typeArguments.length > 1) {
              valueType = typeArguments[1];
            }
          }
        }
      }
      NodeList<CollectionElement> elements = node.elements;
      for (int i = 0; i < elements.length; i++) {
        checkMapElement(elements[i], keyType, valueType);
      }
    } else if (node.isSet) {
      DartType type = DynamicTypeImpl.instance;
      if (node.typeArguments != null) {
        NodeList<TypeAnnotation> typeArguments = node.typeArguments.arguments;
        if (typeArguments.isNotEmpty) {
          type = typeArguments[0].type;
        }
      } else {
        DartType staticType = node.staticType;
        if (staticType is InterfaceType) {
          List<DartType> typeArguments = staticType.typeArguments;
          if (typeArguments != null && typeArguments.isNotEmpty) {
            type = typeArguments[0];
          }
        }
      }
      NodeList<CollectionElement> elements = node.elements;
      for (int i = 0; i < elements.length; i++) {
        checkCollectionElement(elements[i], type);
      }
    }
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    var element = node.staticElement;
    if (element != null) {
      var type = node.staticElement.type;
      checkArgumentList(node.argumentList, type);
    }
    node.visitChildren(this);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    // SwitchStatement defines a boolean conversion to check the result of the
    // case value == the switch value, but in dev_compiler we require a boolean
    // return type from an overridden == operator (because Object.==), so
    // checking in SwitchStatement shouldn't be necessary.
    node.visitChildren(this);
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    VariableElement variableElement =
        node == null ? null : node.declaredElement;
    AstNode parent = node.parent;
    if (variableElement != null &&
        parent is VariableDeclarationList &&
        parent.type == null &&
        node.initializer != null) {
      if (variableElement.kind == ElementKind.TOP_LEVEL_VARIABLE ||
          variableElement.kind == ElementKind.FIELD) {
        _validateTopLevelInitializer(variableElement.name, node.initializer);
      }
    }
    return super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    TypeAnnotation type = node.type;
    if (type != null) {
      for (VariableDeclaration variable in node.variables) {
        var initializer = variable.initializer;
        if (initializer != null) {
          checkForCast(initializer,
              from: initializer.staticType, to: type.type);
        }
      }
    }

    node.visitChildren(this);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    checkBoolean(node.condition);
    node.visitChildren(this);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _checkReturnOrYield(node.expression, node, yieldStar: node.star != null);
    node.visitChildren(this);
  }

  void _checkCompoundAssignment(AssignmentExpression expr) {
    var op = expr.operator.type;
    assert(op.isAssignmentOperator && op != TokenType.EQ);
    var methodElement = expr.staticElement;
    if (methodElement != null) {
      // Sanity check the operator.
      assert(methodElement.isOperator);
      var functionType = methodElement.type;
      var paramTypes = functionType.normalParameterTypes;
      assert(paramTypes.length == 1);
      assert(functionType.namedParameterTypes.isEmpty);
      assert(functionType.optionalParameterTypes.isEmpty);

      // Refine the return type.
      var rhsType = expr.rightHandSide.staticType;
      var returnType = rules.refineBinaryExpressionType(
        expr.readType,
        op,
        rhsType,
        functionType.returnType,
        methodElement,
      );

      // Check the argument for an implicit cast.
      _checkImplicitCast(expr.rightHandSide, to: paramTypes[0], from: rhsType);

      // Check the return type for an implicit cast.
      //
      // If needed, mark the assignment to indicate a down cast when we assign
      // back to it. So these two implicit casts are equivalent:
      //
      //     y = /*implicit cast*/(y + 42);
      //     /*implicit assignment cast*/y += 42;
      //
      _checkImplicitCast(expr.leftHandSide,
          to: expr.writeType, from: returnType, opAssign: true);
    }
  }

  void _checkFunctionApplication(InvocationExpression node) {
    var ft = _getTypeAsCaller(node);

    if (ft != null) {
      checkArgumentList(node.argumentList, ft);
    }
  }

  /// Given an expression [expr] of type [fromType], returns true if an implicit
  /// downcast is required, false if it is not, or null if the types are
  /// unrelated.
  bool _checkFunctionTypeCasts(
      Expression expr, FunctionType to, DartType fromType) {
    bool callTearoff = false;
    FunctionType from;
    if (fromType is FunctionType) {
      from = fromType;
    } else if (fromType is InterfaceType) {
      from = rules.getCallMethodType(fromType);
      callTearoff = true;
    }
    if (from == null) {
      return null; // unrelated
    }

    if (rules.isSubtypeOf2(from, to)) {
      // Sound subtype.
      // However we may still need cast if we have a call tearoff.
      return callTearoff;
    }

    if (rules.isSubtypeOf2(to, from)) {
      // Assignable, but needs cast.
      return true;
    }

    return null;
  }

  /// Checks if an implicit cast of [expr] from [from] type to [to] type is
  /// needed, and if so records it.
  ///
  /// If [from] is omitted, uses the static type of [expr].
  ///
  /// If [expr] does not require an implicit cast because it is not related to
  /// [to] or is already a subtype of it, does nothing.
  void _checkImplicitCast(Expression expr,
      {@required DartType to,
      @required DartType from,
      bool opAssign = false,
      bool forSpread = false,
      bool forSpreadKey = false,
      bool forSpreadValue = false}) {
    if (_isNonNullableByDefault) {
      return;
    }

    if (_needsImplicitCast(expr, to: to, from: from) == true) {
      _recordImplicitCast(expr, to,
          from: from,
          opAssign: opAssign,
          forSpread: forSpread,
          forSpreadKey: forSpreadKey,
          forSpreadValue: forSpreadValue);
    }
  }

  void _checkReturnOrYield(Expression expression, AstNode node,
      {bool yieldStar = false}) {
    FunctionBody body = node.thisOrAncestorOfType<FunctionBody>();
    var type = _getExpectedReturnType(body, yieldStar: yieldStar);
    if (type == null) {
      // We have a type mismatch: the async/async*/sync* modifier does
      // not match the return or yield type.  We should have already gotten an
      // analyzer error in this case.
      return;
    }
    // TODO(vsm): Enforce void or dynamic (to void?) when expression is null.
    if (expression != null) checkAssignment(expression, type);
  }

  void _checkUnary(Expression operand, Token op, MethodElement element,
      {@required DartType readType, @required DartType writeType}) {
    bool isIncrementAssign = op.type.isIncrementOperator;
    if (op.isUserDefinableOperator || isIncrementAssign) {
      if (element != null && isIncrementAssign) {
        // For ++ and --, even if it is not dynamic, we still need to check
        // that the user defined method accepts an `int` as the RHS.
        //
        // We assume Analyzer has done this already (in ErrorVerifier).
        //
        // However, we also need to check the return type.

        // Refine the return type.
        var functionType = element.type;
        var rhsType = typeProvider.intType;
        var returnType = rules.refineBinaryExpressionType(
          readType,
          TokenType.PLUS,
          rhsType,
          functionType.returnType,
          element,
        );

        // Skip the argument check - `int` cannot be downcast.
        //
        // Check the return type for an implicit cast.
        //
        // If needed, mark the assignment to indicate a down cast when we assign
        // back to it. So these two implicit casts are equivalent:
        //
        //     y = /*implicit cast*/(y + 1);
        //     /*implicit assignment cast*/y++;
        //
        _checkImplicitCast(operand,
            to: writeType, from: returnType, opAssign: true);
      }
    }
  }

  /// Gets the expected return type of the given function [body], either from
  /// a normal return/yield, or from a yield*.
  DartType _getExpectedReturnType(FunctionBody body, {bool yieldStar = false}) {
    FunctionType functionType;
    var parent = body.parent;
    if (parent is Declaration) {
      functionType = _elementType(parent.declaredElement);
    } else {
      assert(parent is FunctionExpression);
      functionType =
          (parent as FunctionExpression).staticType ?? DynamicTypeImpl.instance;
    }

    var type = functionType.returnType;

    ClassElement expectedElement;
    if (body.isAsynchronous) {
      if (body.isGenerator) {
        // Stream<T> -> T
        expectedElement = typeProvider.streamElement;
      } else {
        // Future<T> -> FutureOr<T>
        var typeArg = (type.element == typeProvider.futureElement)
            ? (type as InterfaceType).typeArguments[0]
            : typeProvider.dynamicType;
        return typeProvider.futureOrType2(typeArg);
      }
    } else {
      if (body.isGenerator) {
        // Iterable<T> -> T
        expectedElement = typeProvider.iterableElement;
      } else {
        // T -> T
        return type;
      }
    }
    if (yieldStar) {
      if (type.isDynamic) {
        // Ensure it's at least a Stream / Iterable.
        return expectedElement.instantiate(
          typeArguments: [typeProvider.dynamicType],
          nullabilitySuffix: _noneOrStarSuffix,
        );
      } else {
        // Analyzer will provide a separate error if expected type
        // is not compatible with type.
        return type;
      }
    }
    if (type.isDynamic) {
      return type;
    } else if (type is InterfaceType && type.element == expectedElement) {
      return type.typeArguments[0];
    } else {
      // Malformed type - fallback on analyzer error.
      return null;
    }
  }

  DartType _getInstanceTypeArgument(
      DartType expressionType, ClassElement instanceType) {
    var asInstanceType = expressionType.asInstanceOf(instanceType);
    if (asInstanceType != null) {
      return asInstanceType.typeArguments[0];
    }
    return null;
  }

  /// Given an expression, return its type assuming it is
  /// in the caller position of a call (that is, accounting
  /// for the possibility of a call method).  Returns null
  /// if expression is not statically callable.
  FunctionType _getTypeAsCaller(InvocationExpression node) {
    DartType type = node.staticInvokeType;
    if (type is FunctionType) {
      return type;
    } else if (type is InterfaceType) {
      return rules.getCallMethodType(type);
    }
    return null;
  }

  /// Returns true if we need an implicit cast of [expr] from [from] type to
  /// [to] type, returns false if no cast is needed, and returns null if the
  /// types are statically incompatible, or the types are compatible but don't
  /// allow implicit cast (ie, void, which is one form of Top which will not
  /// downcast implicitly).
  ///
  /// If [from] is omitted, uses the static type of [expr]
  bool _needsImplicitCast(Expression expr,
      {@required DartType from, @required DartType to}) {
    // Void is considered Top, but may only be *explicitly* cast.
    if (from.isVoid) return null;

    if (to is FunctionType) {
      bool needsCast = _checkFunctionTypeCasts(expr, to, from);
      if (needsCast != null) return needsCast;
    }

    // fromT <: toT, no coercion needed.
    if (rules.isSubtypeOf2(from, to)) {
      return false;
    }

    // Down cast or legal sideways cast, coercion needed.
    if (rules.isAssignableTo2(from, to)) {
      return true;
    }

    // Special case for FutureOr to handle returned values from async functions.
    // In this case, we're more permissive than assignability.
    if (to.isDartAsyncFutureOr) {
      var to1 = (to as InterfaceType).typeArguments[0];
      var to2 = typeProvider.futureType2(to1);
      return _needsImplicitCast(expr, to: to1, from: from) == true ||
          _needsImplicitCast(expr, to: to2, from: from) == true;
    }

    // Anything else is an illegal sideways cast.
    // However, these will have been reported already in error_verifier, so we
    // don't need to report them again.
    return null;
  }

  /// Records an implicit cast for the [expr] from [from] to [to].
  ///
  /// This will emit the appropriate error/warning/hint message as well as mark
  /// the AST node.
  void _recordImplicitCast(Expression expr, DartType to,
      {DartType from,
      bool opAssign = false,
      bool forSpread = false,
      bool forSpreadKey = false,
      bool forSpreadValue = false}) {
    // If this is an implicit tearoff, we need to mark the cast, but we don't
    // want to warn if it's a legal subtype.
    if (from is InterfaceType && rules.acceptsFunctionType(to)) {
      var type = rules.getCallMethodType(from);
      if (type != null && rules.isSubtypeOf2(type, to)) {
        return;
      }
    }

    if (!forSpread && !forSpreadKey && !forSpreadValue) {
      // Spreads are special in that they may create downcasts at runtime but
      // those casts are implied so we don't treat them as strictly.

      // Inference "casts":
      if (expr is Literal) {
        // fromT should be an exact type - this will almost certainly fail at
        // runtime.
        if (expr is ListLiteral) {
          _recordMessage(
              expr, CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST, [from, to]);
        } else if (expr is SetOrMapLiteral) {
          if (expr.isMap) {
            _recordMessage(expr, CompileTimeErrorCode.INVALID_CAST_LITERAL_MAP,
                [from, to]);
          } else if (expr.isSet) {
            _recordMessage(expr, CompileTimeErrorCode.INVALID_CAST_LITERAL_SET,
                [from, to]);
          } else {
            // This should only happen when the code is invalid, in which case
            // the error should have been reported elsewhere.
          }
        } else {
          _recordMessage(expr, CompileTimeErrorCode.INVALID_CAST_LITERAL,
              [expr, from, to]);
        }
        return;
      }

      if (expr is FunctionExpression) {
        // TODO(srawlins): Add _any_ test that shows this code is reported.
        _recordMessage(
            expr, CompileTimeErrorCode.INVALID_CAST_FUNCTION_EXPR, [from, to]);
        return;
      }

      if (expr is InstanceCreationExpression) {
        ConstructorElement e = expr.constructorName.staticElement;
        if (e == null || !e.isFactory) {
          // fromT should be an exact type - this will almost certainly fail at
          // runtime.
          _recordMessage(
              expr, CompileTimeErrorCode.INVALID_CAST_NEW_EXPR, [from, to]);
          return;
        }
      }

      Element e = _getKnownElement(expr);
      if (e is FunctionElement || e is MethodElement && e.isStatic) {
        _recordMessage(
            expr,
            e is MethodElement
                ? CompileTimeErrorCode.INVALID_CAST_METHOD
                : CompileTimeErrorCode.INVALID_CAST_FUNCTION,
            [e.name, from, to]);
        return;
      }
    }
  }

  void _recordMessage(AstNode node, ErrorCode errorCode, List arguments) {
    // TODO(brianwilkerson) Convert this class to use an ErrorReporter so that
    //  the logic for converting types is in one place.
    arguments = arguments.map((argument) {
      if (argument is DartType) {
        return argument.getDisplayString(withNullability: false);
      } else {
        return argument;
      }
    }).toList();

    int begin = node is AnnotatedNode
        ? node.firstTokenAfterCommentAndMetadata.offset
        : node.offset;
    int length = node.end - begin;
    var source = (node.root as CompilationUnit).declaredElement.source;
    var error = AnalysisError(source, begin, length, errorCode, arguments);
    reporter.onError(error);
  }

  void _validateTopLevelInitializer(String name, Expression n) {
    n.accept(_TopLevelInitializerValidator(this, name));
  }

  void _visitForEachParts(ForEachParts node, SimpleIdentifier loopVariable) {
    if (loopVariable.staticElement is! VariableElement) {
      return;
    }
    VariableElement loopVariableElement = loopVariable.staticElement;

    // Safely handle malformed statements.
    if (loopVariable == null) {
      return;
    }
    Token awaitKeyword;
    AstNode parent = node.parent;
    if (parent is ForStatement) {
      awaitKeyword = parent.awaitKeyword;
    } else if (parent is ForElement) {
      awaitKeyword = parent.awaitKeyword;
    } else {
      throw StateError(
          'Unexpected parent of ForEachParts: ${parent.runtimeType}');
    }
    // Find the element type of the sequence.
    var sequenceElement = awaitKeyword != null
        ? typeProvider.streamElement
        : typeProvider.iterableElement;
    var iterableType = node.iterable.staticType;
    var elementType = _getInstanceTypeArgument(iterableType, sequenceElement);

    // If the sequence is not an Iterable (or Stream for await for) but is a
    // supertype of it, do an implicit downcast to Iterable<dynamic>. Then
    // we'll do a separate cast of the dynamic element to the variable's type.
    if (elementType == null) {
      var sequenceType = sequenceElement.instantiate(
        typeArguments: [typeProvider.dynamicType],
        nullabilitySuffix: _noneOrStarSuffix,
      );

      if (rules.isSubtypeOf2(sequenceType, iterableType)) {
        _recordImplicitCast(node.iterable, sequenceType, from: iterableType);
        elementType = DynamicTypeImpl.instance;
      }
    }
    // If the sequence doesn't implement the interface at all, [ErrorVerifier]
    // will report the error, so ignore it here.
    if (elementType != null) {
      // Insert a cast from the sequence's element type to the loop variable's
      // if needed.
      _checkImplicitCast(loopVariable,
          to: loopVariableElement.type, from: elementType);
    }
  }
}

class _TopLevelInitializerValidator extends RecursiveAstVisitor<void> {
  final CodeChecker _codeChecker;
  final String _name;

  _TopLevelInitializerValidator(this._codeChecker, this._name);

  void validateHasType(AstNode n, PropertyAccessorElement e) {
    if (e.hasImplicitReturnType) {
      var variable = e.declaration.variable as PropertyInducingElementImpl;
      TopLevelInferenceError error = variable.typeInferenceError;
      if (error != null) {
        if (error.kind == TopLevelInferenceErrorKind.dependencyCycle) {
          // Errors on const should have been reported with
          // [CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT].
          if (!variable.isConst) {
            _codeChecker._recordMessage(n, CompileTimeErrorCode.TOP_LEVEL_CYCLE,
                [_name, error.arguments]);
          }
        } else {
          _codeChecker._recordMessage(
              n, StrongModeCode.TOP_LEVEL_IDENTIFIER_NO_TYPE, [_name, e.name]);
        }
      }
    }
  }

  void validateIdentifierElement(AstNode n, Element e,
      {bool isMethodCall = false}) {
    if (e == null) {
      return;
    }

    Element enclosing = e.enclosingElement;
    if (enclosing is CompilationUnitElement) {
      if (e is PropertyAccessorElement) {
        validateHasType(n, e);
      }
    } else if (enclosing is ClassElement) {
      if (e is PropertyAccessorElement) {
        if (e.isStatic) {
          validateHasType(n, e);
        } else if (e.hasImplicitReturnType) {
          _codeChecker._recordMessage(
              n, StrongModeCode.TOP_LEVEL_INSTANCE_GETTER, [_name, e.name]);
        }
      } else if (!isMethodCall &&
          e is ExecutableElement &&
          e.kind == ElementKind.METHOD &&
          !e.isStatic) {
        if (_hasAnyImplicitType(e)) {
          _codeChecker._recordMessage(
              n, StrongModeCode.TOP_LEVEL_INSTANCE_METHOD, [_name, e.name]);
        }
      }
    }
  }

  @override
  visitAsExpression(AsExpression node) {
    // Nothing to validate.
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    TokenType operator = node.operator.type;
    if (operator == TokenType.AMPERSAND_AMPERSAND ||
        operator == TokenType.BAR_BAR ||
        operator == TokenType.EQ_EQ ||
        operator == TokenType.BANG_EQ) {
      // These operators give 'bool', no need to validate operands.
    } else {
      node.leftOperand.accept(this);
    }
  }

  @override
  visitCascadeExpression(CascadeExpression node) {
    node.target.accept(this);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    // No need to validate the condition, since it can't affect type inference.
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    FunctionBody body = node.body;
    if (body is ExpressionFunctionBody) {
      body.expression.accept(this);
    } else {
      _codeChecker._recordMessage(
          node, StrongModeCode.TOP_LEVEL_FUNCTION_LITERAL_BLOCK, []);
    }
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (node.typeArguments != null) {
      return;
    }

    var function = node.function;
    if (function is PropertyAccess) {
      var propertyName = function.propertyName;
      validateIdentifierElement(propertyName, propertyName.staticElement);
    }

    var functionType = node.function.staticType;
    if (functionType is FunctionType && functionType.typeFormals.isNotEmpty) {
      node.argumentList.accept(this);
    }
  }

  @override
  visitIndexExpression(IndexExpression node) {
    // Nothing to validate.
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    var constructor = node.constructorName.staticElement;
    ClassElement class_ = constructor?.enclosingElement;
    if (node.constructorName.type.typeArguments == null &&
        class_ != null &&
        class_.typeParameters.isNotEmpty) {
      // Type inference might depend on the parameters
      super.visitInstanceCreationExpression(node);
    }
  }

  @override
  visitIsExpression(IsExpression node) {
    // Nothing to validate.
  }

  @override
  visitListLiteral(ListLiteral node) {
    if (node.typeArguments == null) {
      super.visitListLiteral(node);
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    node.target?.accept(this);
    var method = node.methodName.staticElement;
    validateIdentifierElement(node, method, isMethodCall: true);
    if (method is ExecutableElement) {
      if (method.kind == ElementKind.METHOD &&
          !method.isStatic &&
          method.hasImplicitReturnType) {
        _codeChecker._recordMessage(node,
            StrongModeCode.TOP_LEVEL_INSTANCE_METHOD, [_name, method.name]);
      }
      if (node.typeArguments == null && method.typeParameters.isNotEmpty) {
        if (method.kind == ElementKind.METHOD &&
            !method.isStatic &&
            _anyParameterHasImplicitType(method)) {
          _codeChecker._recordMessage(node,
              StrongModeCode.TOP_LEVEL_INSTANCE_METHOD, [_name, method.name]);
        }
        // Type inference might depend on the parameters
        node.argumentList?.accept(this);
      }
    }
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    if (node.operator.type == TokenType.BANG) {
      // This operator gives 'bool', no need to validate operands.
    } else {
      node.operand.accept(this);
    }
  }

  @override
  visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.typeArguments == null) {
      super.visitSetOrMapLiteral(node);
    }
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    validateIdentifierElement(node, node.staticElement);
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    // Nothing to validate.
  }

  bool _anyParameterHasImplicitType(ExecutableElement e) {
    for (var parameter in e.parameters) {
      if (parameter.hasImplicitType) return true;
    }
    return false;
  }

  bool _hasAnyImplicitType(ExecutableElement e) {
    if (e.hasImplicitReturnType) return true;
    return _anyParameterHasImplicitType(e);
  }
}
