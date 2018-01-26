// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this was ported from package:dev_compiler, and needs to be
// refactored to fit into analyzer.
library analyzer.src.task.strong.checker;

import 'dart:collection';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart' show TokenType;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/error_processor.dart' show ErrorProcessor;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart' show StrongModeCode;
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/summary/idl.dart';

import 'ast_properties.dart';

/// Given an [expression] and a corresponding [typeSystem] and [typeProvider],
/// gets the known static type of the expression.
///
/// Normally when we ask for an expression's type, we get the type of the
/// storage slot that would contain it. For function types, this is necessarily
/// a "fuzzy arrow" that treats `dynamic` as bottom. However, if we're
/// interested in the expression's own type, it can often be a "strict arrow"
/// because we know it evaluates to a specific, concrete function, and we can
/// treat "dynamic" as top for that case, which is more permissive.
DartType getDefiniteType(
    Expression expression, TypeSystem typeSystem, TypeProvider typeProvider,
    {bool read: false}) {
  DartType type;
  if (read) {
    type = getReadType(expression);
  } else {
    type = expression.staticType;
  }
  type ??= DynamicTypeImpl.instance;
  if (typeSystem is StrongTypeSystemImpl &&
      type is FunctionType &&
      hasStrictArrow(expression)) {
    // Remove fuzzy arrow if possible.
    return typeSystem.functionTypeToConcreteType(type);
  }
  return type;
}

DartType getReadType(Expression expression) {
  if (expression is IndexExpression) {
    return expression.auxiliaryElements?.staticElement?.returnType;
  }
  {
    Element setter;
    if (expression is PrefixedIdentifier) {
      setter = expression.staticElement;
    } else if (expression is PropertyAccess) {
      setter = expression.propertyName.staticElement;
    } else if (expression is SimpleIdentifier) {
      setter = expression.staticElement;
    }
    if (setter is PropertyAccessorElement && setter.isSetter) {
      var getter = setter.variable.getter;
      if (getter != null) {
        return getter.returnType;
      }
    }
  }
  if (expression is SimpleIdentifier) {
    var aux = expression.auxiliaryElements;
    if (aux != null) {
      return aux.staticElement?.returnType;
    }
  }
  return expression.staticType;
}

bool hasStrictArrow(Expression expression) {
  var element = _getKnownElement(expression);
  return element is FunctionElement || element is MethodElement;
}

/// Given a generic class [element] find its covariant upper bound, using
/// the type system [rules].
///
/// Unlike [TypeSystem.instantiateToBounds], this will change `dynamic` into
/// `Object` to work around an issue with fuzzy arrows.
InterfaceType _getCovariantUpperBound(TypeSystem rules, ClassElement element) {
  var upperBound = rules.instantiateToBounds(element.type) as InterfaceType;
  var typeArgs = upperBound.typeArguments;
  // TODO(jmesserly): remove this. It is a workaround for fuzzy arrows.
  // To prevent extra checks due to fuzzy arrows, we need to instantiate with
  // `Object` rather than `dynamic`. Consider a case like:
  //
  //     class C<T> {
  //       void forEach(f(T t)) {}
  //     }
  //
  // If we try `(dynamic) ~> void <: (T) ~> void` with fuzzy arrows, we will
  // treat `dynamic` as `bottom` and get `(bottom) -> void <: (T) -> void`
  // which indicates that a check is required on the parameter `f`. This check
  // is not sufficient when `T` is `dynamic`, however, because calling a
  // function with a fuzzy arrow type is not safe and requires a dynamic call.
  // See: https://github.com/dart-lang/sdk/issues/29295
  //
  // For all other values of T, the check is unnecessary: it is sound to pass
  // a function that accepts any Object.
  if (typeArgs.any((t) => t.isDynamic)) {
    var newTypeArgs = typeArgs
        .map((t) => t.isDynamic ? rules.typeProvider.objectType : t)
        .toList();
    upperBound = element.type.instantiate(newTypeArgs);
  }
  return upperBound;
}

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
    return expression.element;
  } else if (expression is PropertyAccess) {
    return expression.propertyName.staticElement;
  } else if (expression is Identifier) {
    return expression.staticElement;
  }
  return null;
}

/// Return the field on type corresponding to member, or null if none
/// exists or the "field" is actually a getter/setter.
FieldElement _getMemberField(
    InterfaceType type, PropertyAccessorElement member) {
  String memberName = member.name;
  FieldElement field;
  if (member.isGetter) {
    // The subclass member is an explicit getter or a field
    // - lookup the getter on the superclass.
    var getter = type.getGetter(memberName);
    if (getter == null || getter.isStatic) return null;
    field = getter.variable;
  } else if (!member.isSynthetic) {
    // The subclass member is an explicit setter
    // - lookup the setter on the superclass.
    // Note: an implicit (synthetic) setter would have already been flagged on
    // the getter above.
    var setter = type.getSetter(memberName);
    if (setter == null || setter.isStatic) return null;
    field = setter.variable;
  } else {
    return null;
  }
  if (field.isSynthetic) return null;
  return field;
}

/// Looks up the declaration that matches [member] in [type] and returns it's
/// declared type.
FunctionType _getMemberType(InterfaceType type, ExecutableElement member) {
  if (member.isPrivate && type.element.library != member.library) {
    return null;
  }

  var name = member.name;
  var baseMember = member is PropertyAccessorElement
      ? (member.isGetter ? type.getGetter(name) : type.getSetter(name))
      : type.getMethod(name);
  if (baseMember == null || baseMember.isStatic) return null;
  return baseMember.type;
}

/// Checks the body of functions and properties.
class CodeChecker extends RecursiveAstVisitor {
  final StrongTypeSystemImpl rules;
  final TypeProvider typeProvider;
  final AnalysisErrorListener reporter;
  final AnalysisOptionsImpl _options;
  _OverrideChecker _overrideChecker;

  bool _failure = false;
  bool _hasImplicitCasts;
  HashSet<ExecutableElement> _covariantPrivateMembers;

  CodeChecker(TypeProvider typeProvider, StrongTypeSystemImpl rules,
      AnalysisErrorListener reporter, this._options)
      : typeProvider = typeProvider,
        rules = rules,
        reporter = reporter {
    _overrideChecker = new _OverrideChecker(this);
  }

  bool get failure => _failure;

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

  void checkAssignment(Expression expr, DartType type) {
    checkForCast(expr, type);
  }

  void checkDeclarationCast(Expression expr, DartType type) {
    checkForCast(expr, type, isDeclarationCast: true);
  }

  void checkForCast(Expression expr, DartType type,
      {bool isDeclarationCast = false}) {
    if (expr is ParenthesizedExpression) {
      checkForCast(expr.expression, type);
    } else {
      _checkImplicitCast(expr, type, isDeclarationCast: isDeclarationCast);
    }
  }

  /// Analyzer checks boolean conversions, but we need to check too, because
  /// it uses the default assignability rules that allow `dynamic` and `Object`
  /// to be assigned to bool with no message.
  void checkBoolean(Expression expr) =>
      checkAssignment(expr, typeProvider.boolType);

  void _checkFunctionApplication(InvocationExpression node) {
    var ft = _getTypeAsCaller(node);

    if (_isDynamicCall(node, ft)) {
      // If f is Function and this is a method invocation, we should have
      // gotten an analyzer error, so no need to issue another error.
      _recordDynamicInvoke(node, node.function);
    } else {
      checkArgumentList(node.argumentList, ft);
    }
  }

  DartType getType(TypeAnnotation type) {
    return type?.type ?? DynamicTypeImpl.instance;
  }

  void reset() {
    _failure = false;
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
    Token operator = node.operator;
    TokenType operatorType = operator.type;
    if (operatorType == TokenType.EQ ||
        operatorType == TokenType.QUESTION_QUESTION_EQ) {
      DartType staticType = _getDefiniteType(node.leftHandSide);
      checkAssignment(node.rightHandSide, staticType);
    } else if (operatorType == TokenType.AMPERSAND_AMPERSAND_EQ ||
        operatorType == TokenType.BAR_BAR_EQ) {
      checkAssignment(node.leftHandSide, typeProvider.boolType);
      checkAssignment(node.rightHandSide, typeProvider.boolType);
    } else {
      _checkCompoundAssignment(node);
    }
    node.visitChildren(this);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var op = node.operator;
    if (op.isUserDefinableOperator) {
      var element = node.staticElement;
      if (element == null) {
        // Dynamic invocation
        // TODO(vsm): Move this logic to the resolver?
        if (op.type != TokenType.EQ_EQ && op.type != TokenType.BANG_EQ) {
          _recordDynamicInvoke(node, node.leftOperand);
        }
      } else {
        // Method invocation.
        if (element is MethodElement) {
          var type = element.type;
          // Analyzer should enforce number of parameter types, but check in
          // case we have erroneous input.
          if (type.normalParameterTypes.isNotEmpty) {
            checkArgument(node.rightOperand, type.normalParameterTypes[0]);
          }
        } else {
          // TODO(vsm): Assert that the analyzer found an error here?
        }
      }
    } else {
      // Non-method operator.
      switch (op.type) {
        case TokenType.AMPERSAND_AMPERSAND:
        case TokenType.BAR_BAR:
          checkBoolean(node.leftOperand);
          checkBoolean(node.rightOperand);
          break;
        case TokenType.BANG_EQ:
          break;
        case TokenType.QUESTION_QUESTION:
          break;
        default:
          assert(false);
      }
    }
    node.visitChildren(this);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _overrideChecker.check(node);
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _overrideChecker.check(node);
    super.visitClassTypeAlias(node);
  }

  @override
  void visitComment(Comment node) {
    // skip, no need to do typechecking inside comments (they may contain
    // comment references which would require resolution).
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _hasImplicitCasts = false;
    _covariantPrivateMembers = new HashSet();
    node.visitChildren(this);
    setHasImplicitCasts(node, _hasImplicitCasts);
    setCovariantPrivateMembers(node, _covariantPrivateMembers);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    checkBoolean(node.condition);
    node.visitChildren(this);
  }

  /// Check constructor declaration to ensure correct super call placement.
  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    node.visitChildren(this);

    final init = node.initializers;
    for (int i = 0, last = init.length - 1; i < last; i++) {
      final node = init[i];
      if (node is SuperConstructorInvocation) {
        _recordMessage(node, StrongModeCode.INVALID_SUPER_INVOCATION, [node]);
      }
    }
  }

  // Check invocations
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
    var parameterType = _elementType(parameter.element);
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
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var element = node.element;
    var typeName = node.type;
    if (typeName != null) {
      var type = _elementType(element);
      var fieldElement =
          node.identifier.staticElement as FieldFormalParameterElement;
      var fieldType = _elementType(fieldElement.field);
      if (!rules.isSubtypeOf(type, fieldType)) {
        _recordMessage(node, StrongModeCode.INVALID_PARAMETER_DECLARATION,
            [node, fieldType]);
      }
    }
    node.visitChildren(this);
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    var loopVariable = node.identifier ?? node.loopVariable?.identifier;

    // Safely handle malformed statements.
    if (loopVariable != null) {
      // Find the element type of the sequence.
      var sequenceInterface = node.awaitKeyword != null
          ? typeProvider.streamType
          : typeProvider.iterableType;
      var iterableType = _getDefiniteType(node.iterable);
      var elementType =
          rules.mostSpecificTypeArgument(iterableType, sequenceInterface);

      // If the sequence is not an Iterable (or Stream for await for) but is a
      // supertype of it, do an implicit downcast to Iterable<dynamic>. Then
      // we'll do a separate cast of the dynamic element to the variable's type.
      if (elementType == null) {
        var sequenceType =
            sequenceInterface.instantiate([DynamicTypeImpl.instance]);

        if (rules.isSubtypeOf(sequenceType, iterableType)) {
          _recordImplicitCast(node.iterable, sequenceType, from: iterableType);
          elementType = DynamicTypeImpl.instance;
        }
      }

      // If the sequence doesn't implement the interface at all, [ErrorVerifier]
      // will report the error, so ignore it here.
      if (elementType != null) {
        // Insert a cast from the sequence's element type to the loop variable's
        // if needed.
        _checkImplicitCast(loopVariable, _getDefiniteType(loopVariable),
            from: elementType, isDeclarationCast: true);
      }
    }

    node.visitChildren(this);
  }

  @override
  void visitForStatement(ForStatement node) {
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
    var target = node.realTarget;
    var element = node.staticElement;
    if (element == null) {
      _recordDynamicInvoke(node, target);
    } else if (element is MethodElement) {
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
    var element = node.staticElement;
    if (element != null) {
      var type = _elementType(node.staticElement);
      checkArgumentList(arguments, type);
    }
    node.visitChildren(this);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _checkRuntimeTypeCheck(node, node.type);
    node.visitChildren(this);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    DartType type = DynamicTypeImpl.instance;
    if (node.typeArguments != null) {
      NodeList<TypeAnnotation> targs = node.typeArguments.arguments;
      if (targs.length > 0) {
        type = targs[0].type;
      }
    } else {
      DartType staticType = node.staticType;
      if (staticType is InterfaceType) {
        List<DartType> targs = staticType.typeArguments;
        if (targs != null && targs.length > 0) {
          type = targs[0];
        }
      }
    }
    NodeList<Expression> elements = node.elements;
    for (int i = 0; i < elements.length; i++) {
      checkArgument(elements[i], type);
    }
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    DartType ktype = DynamicTypeImpl.instance;
    DartType vtype = DynamicTypeImpl.instance;
    if (node.typeArguments != null) {
      NodeList<TypeAnnotation> targs = node.typeArguments.arguments;
      if (targs.length > 0) {
        ktype = targs[0].type;
      }
      if (targs.length > 1) {
        vtype = targs[1].type;
      }
    } else {
      DartType staticType = node.staticType;
      if (staticType is InterfaceType) {
        List<DartType> targs = staticType.typeArguments;
        if (targs != null) {
          if (targs.length > 0) {
            ktype = targs[0];
          }
          if (targs.length > 1) {
            vtype = targs[1];
          }
        }
      }
    }
    NodeList<MapLiteralEntry> entries = node.entries;
    for (int i = 0; i < entries.length; i++) {
      MapLiteralEntry entry = entries[i];
      checkArgument(entry.key, ktype);
      checkArgument(entry.value, vtype);
    }
    super.visitMapLiteral(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    var target = node.realTarget;
    var element = node.methodName.staticElement;
    if (element == null && !typeProvider.isObjectMethod(node.methodName.name)) {
      _recordDynamicInvoke(node, target);

      // Mark the tear-off as being dynamic, too. This lets us distinguish
      // cases like:
      //
      //     dynamic d;
      //     d.someMethod(...); // the whole method call must be a dynamic send.
      //
      // ... from case like:
      //
      //     SomeType s;
      //     s.someDynamicField(...); // static get, followed by dynamic call.
      //
      // The first case is handled here, the second case is handled below when
      // we call [checkFunctionApplication].
      setIsDynamicInvoke(node.methodName, true);
    } else {
      _checkImplicitCovarianceCast(node, target, element);
      _checkFunctionApplication(node);
    }
    // Don't visit methodName, we already checked things related to the call.
    node.target?.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList?.accept(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _checkUnary(node.operand, node.operator, node.staticElement);
    node.visitChildren(this);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkFieldAccess(node, node.prefix, node.identifier);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.type == TokenType.BANG) {
      checkBoolean(node.operand);
    } else {
      _checkUnary(node.operand, node.operator, node.staticElement);
    }
    node.visitChildren(this);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _checkFieldAccess(node, node.realTarget, node.propertyName);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var type = resolutionMap.staticElementForConstructorReference(node)?.type;
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
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    var element = node.staticElement;
    if (element != null) {
      var type = resolutionMap.staticElementForConstructorReference(node).type;
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
    VariableElement variableElement = node == null
        ? null
        : resolutionMap.elementDeclaredByVariableDeclaration(node);
    if (!node.isConst &&
        !node.isFinal &&
        node.initializer == null &&
        rules.isNonNullableType(variableElement?.type)) {
      _recordMessage(
          node,
          StaticTypeWarningCode.NON_NULLABLE_FIELD_NOT_INITIALIZED,
          [node.name, variableElement?.type]);
    }
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

    for (VariableDeclaration variable in node.variables) {
      var initializer = variable.initializer;
      if (initializer != null) {
        if (type != null) {
          checkDeclarationCast(initializer, type.type);
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
    var methodElement = resolutionMap.staticElementForMethodReference(expr);
    if (methodElement == null) {
      // Dynamic invocation.
      _recordDynamicInvoke(expr, expr.leftHandSide);
    } else {
      // Sanity check the operator.
      assert(methodElement.isOperator);
      var functionType = methodElement.type;
      var paramTypes = functionType.normalParameterTypes;
      assert(paramTypes.length == 1);
      assert(functionType.namedParameterTypes.isEmpty);
      assert(functionType.optionalParameterTypes.isEmpty);

      // Refine the return type.
      var rhsType = _getDefiniteType(expr.rightHandSide);
      var lhsType = _getDefiniteType(expr.leftHandSide);
      var returnType = rules.refineBinaryExpressionType(
          lhsType, op, rhsType, functionType.returnType);

      // Check the argument for an implicit cast.
      _checkImplicitCast(expr.rightHandSide, paramTypes[0], from: rhsType);

      // Check the return type for an implicit cast.
      //
      // If needed, mark the assignment to indicate a down cast when we assign
      // back to it. So these two implicit casts are equivalent:
      //
      //     y = /*implicit cast*/(y + 42);
      //     /*implicit assignment cast*/y += 42;
      //
      _checkImplicitCast(expr.leftHandSide, lhsType,
          from: returnType, opAssign: true);
    }
  }

  void _checkFieldAccess(
      AstNode node, Expression target, SimpleIdentifier field) {
    var element = field.staticElement;
    _checkImplicitCovarianceCast(node, target, element);
    if (element == null && !typeProvider.isObjectMember(field.name)) {
      _recordDynamicInvoke(node, target);
    }
    node.visitChildren(this);
  }

  /// Checks if an implicit cast of [expr] from [from] type to [to] type is
  /// needed, and if so records it.
  ///
  /// If [from] is omitted, uses the static type of [expr].
  ///
  /// If [expr] does not require an implicit cast because it is not related to
  /// [to] or is already a subtype of it, does nothing.
  void _checkImplicitCast(Expression expr, DartType to,
      {DartType from, bool opAssign: false, bool isDeclarationCast: false}) {
    from ??= _getDefiniteType(expr);

    _hintOnFuzzyArrows(expr, to, from);

    if (_needsImplicitCast(expr, to,
            from: from, isDeclarationCast: isDeclarationCast) ==
        true) {
      _recordImplicitCast(expr, to, from: from, opAssign: opAssign);
    }
  }

  /// Checks if the assignment is valid with respect to non-nullable types.
  /// Returns `false` if a nullable expression is assigned to a variable of
  /// non-nullable type and `true` otherwise.
  bool _checkNonNullAssignment(
      Expression expression, DartType to, DartType from) {
    if (rules.isNonNullableType(to) && rules.isNullableType(from)) {
      _recordMessage(
          expression, StaticTypeWarningCode.INVALID_ASSIGNMENT, [from, to]);
      return false;
    }
    return true;
  }

  void _checkReturnOrYield(Expression expression, AstNode node,
      {bool yieldStar: false}) {
    FunctionBody body = node.getAncestor((n) => n is FunctionBody);
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

  void _checkRuntimeTypeCheck(AstNode node, TypeAnnotation annotation) {
    var type = getType(annotation);
    if (!rules.isGroundType(type)) {
      _recordMessage(node, StrongModeCode.NON_GROUND_TYPE_CHECK_INFO, [type]);
    }
  }

  void _checkUnary(Expression operand, Token op, MethodElement element) {
    bool isIncrementAssign =
        op.type == TokenType.PLUS_PLUS || op.type == TokenType.MINUS_MINUS;
    if (op.isUserDefinableOperator || isIncrementAssign) {
      if (element == null) {
        _recordDynamicInvoke(operand.parent, operand);
      } else if (isIncrementAssign) {
        // For ++ and --, even if it is not dynamic, we still need to check
        // that the user defined method accepts an `int` as the RHS.
        //
        // We assume Analyzer has done this already (in ErrorVerifier).
        //
        // However, we also need to check the return type.

        // Refine the return type.
        var functionType = element.type;
        var rhsType = typeProvider.intType;
        var lhsType = _getDefiniteType(operand);
        var returnType = rules.refineBinaryExpressionType(
            lhsType, TokenType.PLUS, rhsType, functionType.returnType);

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
        _checkImplicitCast(operand, lhsType, from: returnType, opAssign: true);
      }
    }
  }

  DartType _getDefiniteType(Expression expr) =>
      getDefiniteType(expr, rules, typeProvider);

  /// If we're calling into [member] through the [target], we may need to
  /// insert a caller side check for soundness on the result of the expression
  /// [node].
  ///
  /// This happens when [target] is an unsafe covariant interface, and [member]
  /// could return a type that is not a subtype of the expected static type
  /// given target's type. For example:
  ///
  ///     typedef F<T>(T t);
  ///     class C<T> {
  ///       F<T> f;
  ///       C(this.f);
  ///     }
  ///     test1() {
  ///       C<Object> c = new C<int>((int x) => x + 42));
  ///       F<Object> f = c.f; // need an implicit cast here.
  ///       f('hello');
  ///     }
  ///
  /// Here target is `c`, the target type is `C<Object>`, the member is
  /// `get f() -> F<T>`, and the expression node is `c.f`. When we call `c.f`
  /// the expected static result is `F<Object>`. However `c.f` actually returns
  /// `F<int>`, which is not a subtype of `F<Object>`. So this method will add
  /// an implicit cast `(c.f as F<Object>)` to guard against this case.
  ///
  /// Note that it is possible for the cast to succeed, for example:
  /// `new C<int>((Object x) => '$x'))`. It is safe to pass any object to that
  /// function, including an `int`.
  void _checkImplicitCovarianceCast(
      Expression node, Expression target, Element member) {
    // If we're calling an instance method or getter, then we
    // want to check the result type.
    //
    // We intentionally ignore method tear-offs, because those methods have
    // covariance checks for their parameters inside the method.
    var targetType = target?.staticType;
    if (member is ExecutableElement &&
        _isInstanceMember(member) &&
        targetType is InterfaceType &&
        targetType.typeArguments.isNotEmpty &&
        !_targetHasKnownGenericTypeArguments(target)) {
      // Track private setters/method calls. We can sometimes eliminate the
      // parameter check in code generation, if it was never needed.
      // This member will need a check, however, because we are calling through
      // an unsafe target.
      if (member.isPrivate && member.parameters.isNotEmpty) {
        _covariantPrivateMembers
            .add(member is ExecutableMember ? member.baseElement : member);
      }

      // Get the lower bound of the declared return type (e.g. `F<Null>`) and
      // see if it can be assigned to the expected type (e.g. `F<Object>`).
      //
      // That way we can tell if any lower `T` will work or not.
      var classType = targetType.element.type;
      var classLowerBound = classType.instantiate(new List.filled(
          classType.typeParameters.length, typeProvider.nullType));
      var memberLowerBound = _lookUpMember(classLowerBound, member).type;
      var expectedType = member.returnType;

      if (!rules.isSubtypeOf(memberLowerBound.returnType, expectedType)) {
        var isMethod = member is MethodElement;
        var isCall = node is MethodInvocation;

        if (isMethod && !isCall) {
          // If `o.m` is a method tearoff, cast to the method type.
          setImplicitCast(node, member.type);
        } else if (!isMethod && isCall) {
          // If `o.g()` is calling a field/getter `g`, we need to cast `o.g`
          // before the call: `(o.g as expectedType)(args)`.
          // This cannot be represented by an `as` node without changing the
          // Dart AST structure, so we record it as a special cast.
          setImplicitOperationCast(node, expectedType);
        } else {
          // For method calls `o.m()` or getters `o.g`, simply cast the result.
          setImplicitCast(node, expectedType);
        }
        _hasImplicitCasts = true;
      }
    }
  }

  /// Returns true if we can safely skip the covariance checks because [target]
  /// has known type arguments, such as `this` `super` or a non-factory `new`.
  ///
  /// For example:
  ///
  ///     class C<T> {
  ///       T _t;
  ///     }
  ///     class D<T> extends C<T> {
  ///        method<S extends T>(T t, C<T> c) {
  ///          // implicit cast: t as T;
  ///          // implicit cast: c as C<T>;
  ///
  ///          // These do not need further checks. The type parameter `T` for
  ///          // `this` must be the same as our `T`
  ///          this._t = t;
  ///          super._t = t;
  ///          new C<T>()._t = t; // non-factory
  ///
  ///          // This needs further checks. The type of `c` could be `C<S>` for
  ///          // some `S <: T`.
  ///          c._t = t;
  ///          // factory statically returns `C<T>`, dynamically returns `C<S>`.
  ///          new F<T, S>()._t = t;
  ///        }
  ///     }
  ///     class F<T, S extends T> extends C<T> {
  ///       factory F() => new C<S>();
  ///     }
  ///
  bool _targetHasKnownGenericTypeArguments(Expression target) {
    return target == null || // implicit this
        target is ThisExpression ||
        target is SuperExpression ||
        target is InstanceCreationExpression &&
            target.staticElement?.isFactory == false;
  }

  bool _isInstanceMember(ExecutableElement e) =>
      !e.isStatic &&
      (e is MethodElement ||
          e is PropertyAccessorElement && e.variable is FieldElement);

  ExecutableElement _lookUpMember(InterfaceType type, ExecutableElement e) {
    var name = e.name;
    var library = e.library;
    return e is PropertyAccessorElement
        ? (e.isGetter
            ? type.lookUpInheritedGetter(name, library: library)
            : type.lookUpInheritedSetter(name, library: library))
        : type.lookUpInheritedMethod(name, library: library);
  }

  /// Gets the expected return type of the given function [body], either from
  /// a normal return/yield, or from a yield*.
  DartType _getExpectedReturnType(FunctionBody body, {bool yieldStar: false}) {
    FunctionType functionType;
    var parent = body.parent;
    if (parent is Declaration) {
      functionType = _elementType(parent.element);
    } else {
      assert(parent is FunctionExpression);
      functionType =
          (parent as FunctionExpression).staticType ?? DynamicTypeImpl.instance;
    }

    var type = functionType.returnType;

    InterfaceType expectedType = null;
    if (body.isAsynchronous) {
      if (body.isGenerator) {
        // Stream<T> -> T
        expectedType = typeProvider.streamType;
      } else {
        // Future<T> -> FutureOr<T>
        var typeArg = (type.element == typeProvider.futureType.element)
            ? (type as InterfaceType).typeArguments[0]
            : typeProvider.dynamicType;
        return typeProvider.futureOrType.instantiate([typeArg]);
      }
    } else {
      if (body.isGenerator) {
        // Iterable<T> -> T
        expectedType = typeProvider.iterableType;
      } else {
        // T -> T
        return type;
      }
    }
    if (yieldStar) {
      if (type.isDynamic) {
        // Ensure it's at least a Stream / Iterable.
        return expectedType.instantiate([typeProvider.dynamicType]);
      } else {
        // Analyzer will provide a separate error if expected type
        // is not compatible with type.
        return type;
      }
    }
    if (type.isDynamic) {
      return type;
    } else if (type is InterfaceType && type.element == expectedType.element) {
      return type.typeArguments[0];
    } else {
      // Malformed type - fallback on analyzer error.
      return null;
    }
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
      return rules.getCallMethodDefiniteType(type);
    }
    return null;
  }

  /// Returns `true` if the expression is a dynamic function call or method
  /// invocation.
  bool _isDynamicCall(InvocationExpression call, FunctionType ft) {
    // TODO(leafp): This will currently return true if t is Function
    // This is probably the most correct thing to do for now, since
    // this code is also used by the back end.  Maybe revisit at some
    // point?
    if (ft == null) return true;
    // Dynamic as the parameter type is treated as bottom.  A function with
    // a dynamic parameter type requires a dynamic call in general.
    // However, as an optimization, if we have an original definition, we know
    // dynamic is reified as Object - in this case a regular call is fine.
    if (hasStrictArrow(call.function)) {
      return false;
    }
    return rules.anyParameterType(ft, (pt) => pt.isDynamic);
  }

  void _hintOnFuzzyArrows(Expression expr, DartType to, DartType from) {
    // If it is a subtype with fuzzy arrows on,
    // check to see if it still is with them off.
    if (rules.isSubtypeOf(from, to)) {
      // Remove fuzzy arrows
      var cFrom = rules.typeToConcreteType(from);
      var cTo = rules.typeToConcreteType(to);
      // If still true, no warning needed
      if (rules.isSubtypeOf(cFrom, cTo)) return;
      _recordMessage(expr, StrongModeCode.USES_DYNAMIC_AS_BOTTOM, [from, to]);
    }
  }

  /// Returns true if we need an implicit cast of [expr] from [from] type to
  /// [to] type, returns false if no cast is needed, and returns null if the
  /// types are statically incompatible.
  ///
  /// If [from] is omitted, uses the static type of [expr]
  bool _needsImplicitCast(Expression expr, DartType to,
      {DartType from, bool isDeclarationCast: false}) {
    from ??= _getDefiniteType(expr);

    if (!_checkNonNullAssignment(expr, to, from)) return false;

    // We can use anything as void.
    if (to.isVoid) return false;

    // fromT <: toT, no coercion needed.
    if (rules.isSubtypeOf(from, to)) return false;

    // Down cast or legal sideways cast, coercion needed.
    if (rules.isAssignableTo(from, to, isDeclarationCast: isDeclarationCast))
      return true;

    // Special case for FutureOr to handle returned values from async functions.
    // In this case, we're more permissive than assignability.
    if (to.element == typeProvider.futureOrType.element) {
      var to1 = (to as InterfaceType).typeArguments[0];
      var to2 = typeProvider.futureType.instantiate([to1]);
      return _needsImplicitCast(expr, to1, from: from) == true ||
          _needsImplicitCast(expr, to2, from: from) == true;
    }

    // Anything else is an illegal sideways cast.
    // However, these will have been reported already in error_verifier, so we
    // don't need to report them again.
    return null;
  }

  void _recordDynamicInvoke(AstNode node, Expression target) {
    _recordMessage(node, StrongModeCode.DYNAMIC_INVOKE, [node]);
    // TODO(jmesserly): we may eventually want to record if the whole operation
    // (node) was dynamic, rather than the target, but this is an easier fit
    // with what we used to do.
    if (target != null) setIsDynamicInvoke(target, true);
  }

  /// Records an implicit cast for the [expr] from [from] to [to].
  ///
  /// This will emit the appropriate error/warning/hint message as well as mark
  /// the AST node.
  void _recordImplicitCast(Expression expr, DartType to,
      {DartType from, bool opAssign: false}) {
    // Inference "casts":
    if (expr is Literal) {
      // fromT should be an exact type - this will almost certainly fail at
      // runtime.
      if (expr is ListLiteral) {
        _recordMessage(
            expr, StrongModeCode.INVALID_CAST_LITERAL_LIST, [from, to]);
      } else if (expr is MapLiteral) {
        _recordMessage(
            expr, StrongModeCode.INVALID_CAST_LITERAL_MAP, [from, to]);
      } else {
        _recordMessage(
            expr, StrongModeCode.INVALID_CAST_LITERAL, [expr, from, to]);
      }
      return;
    }

    if (expr is FunctionExpression) {
      _recordMessage(
          expr, StrongModeCode.INVALID_CAST_FUNCTION_EXPR, [from, to]);
      return;
    }

    if (expr is InstanceCreationExpression) {
      ConstructorElement e = expr.staticElement;
      if (e == null || !e.isFactory) {
        // fromT should be an exact type - this will almost certainly fail at
        // runtime.
        _recordMessage(expr, StrongModeCode.INVALID_CAST_NEW_EXPR, [from, to]);
        return;
      }
    }

    Element e = _getKnownElement(expr);
    if (e is FunctionElement || e is MethodElement && e.isStatic) {
      _recordMessage(
          expr,
          e is MethodElement
              ? StrongModeCode.INVALID_CAST_METHOD
              : StrongModeCode.INVALID_CAST_FUNCTION,
          [e.name, from, to]);
      return;
    }

    // Composite cast: these are more likely to fail.
    bool downCastComposite = false;
    if (!rules.isGroundType(to)) {
      // This cast is (probably) due to our different treatment of dynamic.
      // It may be more likely to fail at runtime.
      if (from is InterfaceType) {
        // For class types, we'd like to allow non-generic down casts, e.g.,
        // Iterable<T> to List<T>.  The intuition here is that raw (generic)
        // casts are problematic, and we should complain about those.
        var typeArgs = from.typeArguments;
        downCastComposite =
            typeArgs.isEmpty || typeArgs.any((t) => t.isDynamic);
      } else {
        downCastComposite = !from.isDynamic;
      }
    }

    var parent = expr.parent;
    ErrorCode errorCode;
    if (downCastComposite) {
      errorCode = StrongModeCode.DOWN_CAST_COMPOSITE;
    } else if (from.isDynamic) {
      errorCode = StrongModeCode.DYNAMIC_CAST;
    } else if (parent is VariableDeclaration && parent.initializer == expr) {
      errorCode = StrongModeCode.ASSIGNMENT_CAST;
    } else {
      errorCode = opAssign
          ? StrongModeCode.DOWN_CAST_IMPLICIT_ASSIGN
          : StrongModeCode.DOWN_CAST_IMPLICIT;
    }
    _recordMessage(expr, errorCode, [from, to]);
    if (opAssign) {
      setImplicitOperationCast(expr, to);
    } else {
      setImplicitCast(expr, to);
    }
    _hasImplicitCasts = true;
  }

  void _recordMessage(AstNode node, ErrorCode errorCode, List arguments) {
    // Compute the right severity taking the analysis options into account.
    // We construct a dummy error to make the common case where we end up
    // ignoring the strong mode message cheaper.
    var processor = ErrorProcessor.getProcessor(_options,
        new AnalysisError.forValues(null, -1, 0, errorCode, null, null));
    var severity =
        (processor != null) ? processor.severity : errorCode.errorSeverity;

    if (severity == ErrorSeverity.ERROR) {
      _failure = true;
    }
    if (errorCode.type == ErrorType.HINT &&
        errorCode.name.startsWith('STRONG_MODE_TOP_LEVEL_')) {
      severity = ErrorSeverity.ERROR;
    }
    if (severity != ErrorSeverity.INFO || _options.strongModeHints) {
      int begin = node is AnnotatedNode
          ? node.firstTokenAfterCommentAndMetadata.offset
          : node.offset;
      int length = node.end - begin;
      var source = resolutionMap
          .elementDeclaredByCompilationUnit(node.root as CompilationUnit)
          .source;
      var error =
          new AnalysisError(source, begin, length, errorCode, arguments);
      reporter.onError(error);
    }
  }

  void _validateTopLevelInitializer(String name, Expression n) {
    n.accept(new _TopLevelInitializerValidator(this, name));
  }
}

/// Checks for overriding declarations of fields and methods. This is used to
/// check overrides between classes and superclasses, interfaces, and mixin
/// applications.
class _OverrideChecker {
  final StrongTypeSystemImpl rules;
  final CodeChecker _checker;

  _OverrideChecker(CodeChecker checker)
      : _checker = checker,
        rules = checker.rules;

  void check(Declaration node) {
    var element =
        resolutionMap.elementDeclaredByDeclaration(node) as ClassElement;
    if (element.type.isObject) {
      return;
    }
    _checkSuperOverrides(node, element);
    _checkMixinApplicationOverrides(node, element);
    _checkAllInterfaceOverrides(node, element);
    _checkForCovariantGenerics(node, element);
  }

  /// Finds implicit casts that we need on parameters and type formals to
  /// ensure soundness of covariant generics, and records them on the [node].
  ///
  /// The parameter checks can be retrived using [getClassCovariantParameters]
  /// and [getSuperclassCovariantParameters].
  ///
  /// For each member of this class and non-overridden inherited member, we
  /// check to see if any generic super interface permits an unsound call to the
  /// concrete member. For example:
  ///
  ///     class C<T> {
  ///       add(T t) {} // C<Object>.add is unsafe, need a check on `t`
  ///     }
  ///     class D extends C<int> {
  ///       add(int t) {} // C<Object>.add is unsafe, need a check on `t`
  ///     }
  ///     class E extends C<int> {
  ///       add(Object t) {} // no check needed, C<Object>.add is safe
  ///     }
  ///
  void _checkForCovariantGenerics(Declaration node, ClassElement element) {
    // Find all generic interfaces that could be used to call into members of
    // this class. This will help us identify which parameters need checks
    // for soundness.
    var allCovariant = _findAllGenericInterfaces(element.type);
    if (allCovariant.isEmpty) return;

    var seenConcreteMembers = new HashSet<String>();
    var members = _getConcreteMembers(element.type, seenConcreteMembers);

    // For members on this class, check them against all generic interfaces.
    var checks = _findCovariantChecks(members, allCovariant);
    // Store those checks on the class declaration.
    setClassCovariantParameters(node, checks);

    // For members of the superclass, we may need to add checks because this
    // class adds a new unsafe interface. Collect those checks.
    checks = _findSuperclassCovariantChecks(
        element, allCovariant, seenConcreteMembers);
    // Store the checks on the class declaration, it will need to ensure the
    // inherited members are appropriately guarded to ensure soundness.
    setSuperclassCovariantParameters(node, checks);
  }

  /// For each member of this class and non-overridden inherited member, we
  /// check to see if any generic super interface permits an unsound call to the
  /// concrete member. For example:
  ///
  /// We must check non-overridden inherited members because this class could
  /// contain a new interface that permits unsound access to that member. In
  /// those cases, the class is expected to insert stub that checks the type
  /// before calling `super`. For example:
  ///
  ///     class C<T> {
  ///       add(T t) {}
  ///     }
  ///     class D {
  ///       add(int t) {}
  ///     }
  ///     class E extends D implements C<int> {
  ///       // C<Object>.add is unsafe, and D.m is marked for a check.
  ///       //
  ///       // one way to implement this is to generate a stub method:
  ///       // add(t) => super.add(t as int);
  ///     }
  ///
  Set<Element> _findSuperclassCovariantChecks(ClassElement element,
      Set<ClassElement> allCovariant, HashSet<String> seenConcreteMembers) {
    var visited = new HashSet<ClassElement>()..add(element);
    var superChecks = _createCovariantCheckSet();
    var existingChecks = _createCovariantCheckSet();

    void visitImmediateSuper(InterfaceType type) {
      // For members of mixins/supertypes, check them against new interfaces,
      // and also record any existing checks they already had.
      var oldCovariant = _findAllGenericInterfaces(type);
      var newCovariant = allCovariant.difference(oldCovariant);
      if (newCovariant.isEmpty) return;

      void visitSuper(InterfaceType type) {
        var element = type.element;
        if (visited.add(element)) {
          var members = _getConcreteMembers(type, seenConcreteMembers);
          _findCovariantChecks(members, newCovariant, superChecks);
          _findCovariantChecks(members, oldCovariant, existingChecks);
          element.mixins.reversed.forEach(visitSuper);
          var s = element.supertype;
          if (s != null) visitSuper(s);
        }
      }

      visitSuper(type);
    }

    element.mixins.reversed.forEach(visitImmediateSuper);
    var s = element.supertype;
    if (s != null) visitImmediateSuper(s);

    superChecks.removeAll(existingChecks);
    return superChecks;
  }

  /// Gets all concrete instance members declared on this type, skipping already
  /// [seenConcreteMembers] and adding any found ones to it.
  ///
  /// By tracking the set of seen members, we can visit superclasses and mixins
  /// and ultimately collect every most-derived member exposed by a given type.
  static List<ExecutableElement> _getConcreteMembers(
      InterfaceType type, HashSet<String> seenConcreteMembers) {
    var members = <ExecutableElement>[];
    for (var declaredMembers in [type.accessors, type.methods]) {
      for (var member in declaredMembers) {
        // We only visit each most derived concrete member.
        // To avoid visiting an overridden superclass member, we skip members
        // we've seen, and visit starting from the class, then mixins in
        // reverse order, then superclasses.
        if (!member.isStatic &&
            !member.isAbstract &&
            seenConcreteMembers.add(member.name)) {
          members.add(member);
        }
      }
    }
    return members;
  }

  /// Find all covariance checks on parameters/type parameters needed for
  /// soundness given a set of concrete [members] and a set of unsafe generic
  /// [covariantInterfaces] that may allow those members to be called in an
  /// unsound way.
  ///
  /// See [_findCovariantChecksForMember] for more information and an exmaple.
  Set<Element> _findCovariantChecks(Iterable<ExecutableElement> members,
      Iterable<ClassElement> covariantInterfaces,
      [Set<Element> covariantChecks]) {
    covariantChecks ??= _createCovariantCheckSet();
    if (members.isEmpty) return covariantChecks;

    for (var iface in covariantInterfaces) {
      var unsafeSupertype = _getCovariantUpperBound(rules, iface);
      for (var m in members) {
        _findCovariantChecksForMember(m, unsafeSupertype, covariantChecks);
      }
    }
    return covariantChecks;
  }

  /// Given a [member] and a covariant [unsafeSupertype], determine if any
  /// type formals or parameters of this member need a check because of the
  /// unsoundness in the unsafe covariant supertype.
  ///
  /// For example:
  ///
  ///     class C<T> {
  ///       m(T t) {}
  ///       g<S extends T>() => <S>[];
  ///     }
  ///     class D extends C<num> {
  ///       m(num n) {}
  ///       g<R extends num>() => <R>[];
  ///     }
  ///     main() {
  ///        C<Object> c = new C<int>();
  ///        c.m('hi');     // must throw for soundness
  ///        c.g<String>(); // must throw for soundness
  ///
  ///        c = new D();
  ///        c.m('hi');     // must throw for soundness
  ///        c.g<String>(); // must throw for soundness
  ///     }
  ///
  /// We've already found `C<Object>` is a potentially unsafe covariant generic
  /// supertpe, and we call this method to see if any members need a check
  /// because of `C<Object>`.
  ///
  /// In this example, we will call this method with:
  /// - `C<T>.m` and `C<Object>`, finding that `t` needs a check.
  /// - `C<T>.g` and `C<Object>`, finding that `S` needs a check.
  /// - `D.m`    and `C<Object>`, finding that `n` needs a check.
  /// - `D.g`    and `C<Object>`, finding that `R` needs a check.
  ///
  /// Given `C<T>.m` and `C<Object>`, we search for covariance checks like this
  /// (`*` short for `dynamic`):
  /// - get the type of `C<Object>.m`: `(Object) -> *`
  /// - get the type of `C<T>.m`:      `(T) -> *`
  /// - perform a subtype check `(T) -> * <: (Object) -> *`,
  ///   and record any parameters/type formals that violate soundess.
  /// - that checks `Object <: T`, which is false, thus we need a check on
  ///   parameter `t` of `C<T>.m`
  ///
  /// Another example is `D.g` and `C<Object>`:
  /// - get the type of `C<Object>.m`: `<S extends Object>() -> *`
  /// - get the type of `D.g`:         `<R extends num>() -> *`
  /// - perform a subtype check
  ///   `<S extends Object>() -> * <: <R extends num>() -> *`,
  ///   and record any parameters/type formals that violate soundess.
  /// - that checks the type formal bound of `S` and `R` asserting
  ///   `Object <: num`, which is false, thus we need a check on type formal `R`
  ///   of `D.g`.
  void _findCovariantChecksForMember(ExecutableElement member,
      InterfaceType unsafeSupertype, Set<Element> covariantChecks) {
    var f2 = _getMemberType(unsafeSupertype, member);
    if (f2 == null) return;
    var f1 = member.type;

    // Find parameter or type formal checks that we need to ensure `f2 <: f1`.
    //
    // The static type system allows this subtyping, but it is not sound without
    // these runtime checks.
    var fresh = FunctionTypeImpl.relateTypeFormals(f1, f2, (b2, b1, p2, p1) {
      if (!rules.isSubtypeOf(b2, b1)) covariantChecks.add(p1);
      return true;
    });
    if (fresh != null) {
      f1 = f1.instantiate(fresh);
      f2 = f2.instantiate(fresh);
    }
    FunctionTypeImpl.relateParameters(f1.parameters, f2.parameters, (p1, p2) {
      if (!rules.isOverrideSubtypeOfParameter(p1, p2)) covariantChecks.add(p1);
      return true;
    });
  }

  static Set<Element> _createCovariantCheckSet() {
    return new LinkedHashSet(
        equals: _equalMemberElements, hashCode: _hashCodeMemberElements);
  }

  /// When finding superclass covariance checks, we need to track the
  /// substituted member/parameter type, but we don't want this type to break
  /// equality, because [Member] does not implement equality/hashCode, so
  /// instead we jump to the declaring element.
  static bool _equalMemberElements(Element x, Element y) {
    x = x is Member ? x.baseElement : x;
    y = y is Member ? y.baseElement : y;
    return x == y;
  }

  static int _hashCodeMemberElements(Element x) {
    x = x is Member ? x.baseElement : x;
    return x.hashCode;
  }

  /// Find all generic interfaces that are implemented by [type], including
  /// [type] itself if it is generic.
  ///
  /// This represents the complete set of unsafe covariant interfaces that could
  /// be used to call members of [type].
  ///
  /// Because we're going to instantiate these to their upper bound, we don't
  /// have to track type parameters.
  static Set<ClassElement> _findAllGenericInterfaces(InterfaceType type) {
    var visited = new HashSet<ClassElement>();
    var genericSupertypes = new Set<ClassElement>();

    void visitTypeAndSupertypes(InterfaceType type) {
      var element = type.element;
      if (visited.add(element)) {
        if (element.typeParameters.isNotEmpty) {
          genericSupertypes.add(element);
        }
        var supertype = element.supertype;
        if (supertype != null) visitTypeAndSupertypes(supertype);
        element.mixins.forEach(visitTypeAndSupertypes);
        element.interfaces.forEach(visitTypeAndSupertypes);
      }
    }

    visitTypeAndSupertypes(type);

    return genericSupertypes;
  }

  /// Checks that most-derived concrete members on this class correctly override
  /// all reachable interfaces, and reports errors if all interfaces are not
  /// correctly implemented.
  ///
  /// This checks the soundness property: for all interfaces implemented by this
  /// class (including inherited interfaces), we ensure that calls through that
  /// interface will be sound.
  void _checkAllInterfaceOverrides(Declaration node, ClassElement element) {
    var interfaces = _collectInterfacesToCheck(element.type);
    var visitedClasses = new Set<InterfaceType>();
    var visitedMembers = new HashSet<String>();

    // Checks all most-derived concrete members on this `type`. We skip over
    // members that are already `visitedMembers`, because they were overridden
    // and we've already checked that member.
    //
    // Because of that, it is important we visit types in the order that they
    // will override members.
    // If checkingMixin is true, then we are checking [type] in a mixin position
    // and hence should consider its own mixins and superclass as abstract.
    void checkType(InterfaceType type, AstNode location,
        {bool checkingMixin: false}) {
      // Skip `Object` because we don't need to check those members here.
      // (because `Object` is the root of everything, it will be checked in
      // _checkSuperOverrides for all classes).
      if (type == null || type.isObject || !visitedClasses.add(type)) return;

      // Check `member` against all `interfaces`.
      void checkOverride(ExecutableElement member, [AstNode loc]) {
        if (!visitedMembers.add(member.name)) return;
        for (var interface in interfaces) {
          if (_checkMemberOverride(member, interface, loc ?? location) ==
              false) {
            // Only report one error per member for interfaces.
            // TODO(jmesserly): this is for backwards compatibility. Remove it?
            break;
          }
        }
      }

      // When we're checking the class declaration node we started from, we
      // can use a more precise error location for reporting override errors.
      //
      // Otherwise, we'll use the `extends` or `with` clause.
      var isRootClass = identical(location, node);

      // Check direct overrides on the class.
      if (isRootClass) {
        _checkClassMembers(node, checkOverride);
      } else {
        _checkTypeMembers(type, checkOverride);
      }

      // If we are currently checking a mixin, then its own mixins and
      // superclass are abstract, and we should not check their members.
      // This should only happen when super mixins is enabled, and we
      // don't do proper checking for super mixins (we don't check that
      // the contract implied by the mixin declaration is satisfied by
      // the mixin use), but this prevents us from erroneously
      // rejecting some super mixin patterns.
      // If this is a mixin application (class A = Object with B)
      // however, then we do still need to treat the mixin as concrete.
      if (!checkingMixin || type.element.isMixinApplication) {
        // Check mixin members against interfaces.
        //
        // We visit mixins in reverse order to reflect how they override
        // eachother.
        for (int i = type.mixins.length - 1; i >= 0; i--) {
          checkType(type.mixins[i],
              isRootClass ? _withClause(node).mixinTypes[i] : location,
              checkingMixin: true);
        }

        // Check members on the superclass.
        checkType(type.superclass,
            isRootClass ? _extendsErrorLocation(node) : location,
            checkingMixin: checkingMixin);
      }
    }

    checkType(element.type, node);
  }

  /// Gets the set of all interfaces on [type] that should be checked to see
  /// if type's members are overriding them correctly.
  ///
  /// In particular, we need to check these overrides for the definitions in
  /// the class itself and each its superclasses (and mixins).
  /// If a superclass (or mixin) is concrete, then we can skip its transitive
  /// interfaces, but if it is abstract we must check them. For example, in:
  ///
  ///     B extends C implements G
  ///     A extends B with E, F implements H, I
  ///
  /// we need to check the following interfaces:
  ///
  ///     C against G, H, and I
  ///     B against G, H, and I
  ///     E against H and I // no check against G because B is a concrete class
  ///     F against H and I
  ///     A against H and I
  Set<InterfaceType> _collectInterfacesToCheck(InterfaceType type) {
    var interfaces = new Set<InterfaceType>();
    void collectInterfaces(InterfaceType t) {
      if (t == null || t.isObject) return;
      if (!interfaces.add(t)) return;
      collectInterfaces(t.superclass);
      t.mixins.forEach(collectInterfaces);
      t.interfaces.forEach(collectInterfaces);
    }

    // Check all interfaces reachable from the `implements` clause in the
    // current class against definitions here and in superclasses.
    type.interfaces.forEach(collectInterfaces);

    // Also collect interfaces from any abstract mixins or superclasses.
    //
    // For a concrete mixin/superclass, we'll check that we override the
    // concrete members in _checkSuperOverrides and
    // _checkMixinApplicationOverrides. But for abstract classes, we need to
    // consider any abstract members it got from its interfaces.
    for (var s in _getSuperclasses(type, (t) => t.element.isAbstract)) {
      s.interfaces.forEach(collectInterfaces);
    }
    return interfaces;
  }

  /// Visits each member on the class [node] and calls [checkMember] with the
  /// corresponding instance element and AST node (for error reporting).
  ///
  /// See also [_checkTypeMembers], which is used when the class AST node is not
  /// available.
  void _checkClassMembers(Declaration node,
      void checkMember(ExecutableElement member, ClassMember location)) {
    for (var member in _classMembers(node)) {
      if (member is FieldDeclaration) {
        if (member.isStatic) {
          continue;
        }
        for (var variable in member.fields.variables) {
          var element = variable.element as PropertyInducingElement;
          checkMember(element.getter, member);
          if (!variable.isFinal && !variable.isConst) {
            checkMember(element.setter, member);
          }
        }
      } else if (member is MethodDeclaration) {
        if (member.isStatic) {
          continue;
        }
        checkMember(member.element, member);
      } else {
        assert(member is ConstructorDeclaration);
      }
    }
  }

  /// Visits the [type] and calls [checkMember] for each instance member.
  ///
  /// See also [_checkClassMembers], which should be used when the class AST
  /// node is available to allow for better error locations
  void _checkTypeMembers(
      InterfaceType type, void checkMember(ExecutableElement member)) {
    void checkHelper(ExecutableElement e) {
      if (!e.isStatic) checkMember(e);
    }

    type.methods.forEach(checkHelper);
    type.accessors.forEach(checkHelper);
  }

  /// Check overrides from mixin applications themselves. For example, in:
  ///
  ///      A extends B with E, F
  ///
  ///  we check:
  ///
  ///      B & E against B (equivalently how E overrides B)
  ///      B & E & F against B & E (equivalently how F overrides both B and E)
  void _checkMixinApplicationOverrides(Declaration node, ClassElement element) {
    var superclass = element.type.superclass;
    var mixins = element.type.mixins;

    // Check overrides from applying mixins
    for (int i = 0; i < mixins.length; i++) {
      var current = mixins[i];
      var location = _withClause(node).mixinTypes[i];
      var superclasses = mixins.sublist(0, i).reversed.toList()
        ..add(superclass);

      _checkTypeMembers(current, (m) {
        for (var s in superclasses) {
          if (_checkConcreteMemberOverride(m, s, location)) break;
        }
      });
    }
  }

  /// Gets the member corresponding to [member] on [type], and returns `null`
  /// if no member was found, or a boolean value to indicate whether the
  /// override is valid.
  ///
  /// The [location] is a node where the error is reported. For example, a
  /// bad override of a method in a class with respect to its superclass is
  /// reported directly at the method declaration. However, invalid overrides
  /// from base classes to interfaces, mixins to the base they are applied to,
  /// or mixins to interfaces are reported at the class declaration, since the
  /// base class or members on their own were not incorrect, only combining them
  /// with the interface was problematic. For example, these are example error
  /// locations in these cases:
  ///
  ///     error: base class introduces an invalid override. The type of B.foo is
  ///     not a subtype of E.foo:
  ///       class A extends B implements E { ... }
  ///               ^^^^^^^^^
  ///
  ///     error: mixin introduces an invalid override. The type of C.foo is not
  ///     a subtype of E.foo:
  ///       class A extends B with C implements E { ... }
  ///                              ^
  ///
  /// When checking for overrides from a type and it's super types, [node] is
  /// the AST node that defines [member]. This is used to determine whether the
  /// type of the element could be inferred from the types in the super classes.
  bool _checkMemberOverride(
      ExecutableElement member, InterfaceType type, AstNode location) {
    assert(!member.isStatic);

    FunctionType subType = _elementType(member);
    FunctionType baseType = _getMemberType(type, member);
    if (baseType == null) return null;

    if (!rules.isOverrideSubtypeOf(subType, baseType)) {
      ErrorCode errorCode;
      var parent = location?.parent;
      if (location is ExtendsClause ||
          parent is ClassTypeAlias && parent.superclass == location) {
        errorCode = StrongModeCode.INVALID_METHOD_OVERRIDE_FROM_BASE;
      } else if (parent is WithClause) {
        errorCode = StrongModeCode.INVALID_METHOD_OVERRIDE_FROM_MIXIN;
      } else {
        errorCode = StrongModeCode.INVALID_METHOD_OVERRIDE;
      }

      _checker._recordMessage(location, errorCode,
          [member.enclosingElement.name, member.name, subType, type, baseType]);
      return false;
    }
    return true;
  }

  /// Checks that a member override from a superclass (i.e. a concrete member)
  /// is correct, reporting an error if needed, and returns `true` if we should
  /// keep searching up the superclass chain.
  bool _checkConcreteMemberOverride(
      ExecutableElement member, InterfaceType type, AstNode location) {
    _checkFieldOverride(member, type, location);
    // Stop if a member was found, and we have no covariant parameters.
    // If we have covariant parameters, we need to keep searching.
    return _checkMemberOverride(member, type, location) != null &&
        member.parameters.every((p) => !p.isCovariant);
  }

  void _checkFieldOverride(
      Element member, InterfaceType type, AstNode location) {
    if (member is PropertyAccessorElement) {
      // Disallow overriding a non-virtual field.
      var field = _getMemberField(type, member);
      if (field != null && !field.isVirtual) {
        FunctionType subType = _elementType(member);
        FunctionType baseType = _getMemberType(type, member);
        _checker._recordMessage(
            location, StrongModeCode.INVALID_FIELD_OVERRIDE, [
          member.enclosingElement.name,
          member.name,
          subType,
          type,
          baseType
        ]);
      }
    }
  }

  /// Check overrides between a class and its superclasses and mixins. For
  /// example, in:
  ///
  ///      A extends B with E, F
  ///
  /// we check A against B, B super classes, E, and F.
  ///
  /// Internally we avoid reporting errors twice and we visit classes bottom up
  /// to ensure we report the most immediate invalid override first. For
  /// example, in the following code we'll report that `Test` has an invalid
  /// override with respect to `Parent` (as opposed to an invalid override with
  /// respect to `Grandparent`):
  ///
  ///     class Grandparent {
  ///         m(A a) {}
  ///     }
  ///     class Parent extends Grandparent {
  ///         m(A a) {}
  ///     }
  ///     class Test extends Parent {
  ///         m(B a) {} // invalid override
  ///     }
  void _checkSuperOverrides(Declaration node, ClassElement element) {
    var superclasses = _getSuperclasses(element.type);
    _checkClassMembers(node, (member, loc) {
      for (var s in superclasses) {
        if (_checkConcreteMemberOverride(member, s, loc)) break;
      }
    });
  }

  /// Collects all superclasses of [type], including any mixin application
  /// classes.
  ///
  /// The search can be pruned by passing a [visitSuperclasses] function and
  /// having it return `false` for types that should not be further explored.
  Iterable<InterfaceType> _getSuperclasses(InterfaceType type,
      [bool visitSuperclasses(InterfaceType t)]) {
    var superclasses = new Set<InterfaceType>();
    visit(InterfaceType t) {
      if ((visitSuperclasses == null || visitSuperclasses(t)) &&
          superclasses.add(t)) {
        t.mixins.reversed.forEach(visit);
        var s = t.superclass;
        if (s != null && !s.isObject) visit(s);
      }
    }

    type.mixins.reversed.forEach(visit);
    var s = type.superclass;
    if (s != null && !s.isObject) visit(s);

    // Make sure we record Object last, and not when we visit our mixins.
    if (!type.isObject) visit(rules.typeProvider.objectType);
    return superclasses;
  }

  /// If node is a [ClassDeclaration] returns its members, otherwise if node is
  /// a [ClassTypeAlias] this returns an empty list.
  Iterable<ClassMember> _classMembers(Declaration node) {
    return node is ClassDeclaration ? node.members : [];
  }

  /// If node is a [ClassDeclaration] returns its members, otherwise if node is
  /// a [ClassTypeAlias] this returns an empty list.
  AstNode _extendsErrorLocation(Declaration node) {
    return node is ClassDeclaration
        ? node.extendsClause
        : (node as ClassTypeAlias).superclass;
  }

  /// If node is a [ClassDeclaration] returns its members, otherwise if node is
  /// a [ClassTypeAlias] this returns an empty list.
  WithClause _withClause(Declaration node) {
    return node is ClassDeclaration
        ? node.withClause
        : (node as ClassTypeAlias).withClause;
  }
}

class _TopLevelInitializerValidator extends RecursiveAstVisitor<Null> {
  final CodeChecker _codeChecker;
  final String _name;

  _TopLevelInitializerValidator(this._codeChecker, this._name);

  void validateHasType(AstNode n, PropertyAccessorElement e) {
    if (e.hasImplicitReturnType) {
      var variable = e.variable as VariableElementImpl;
      TopLevelInferenceError error = variable.typeInferenceError;
      if (error != null) {
        if (error.kind == TopLevelInferenceErrorKind.dependencyCycle) {
          _codeChecker._recordMessage(
              n, StrongModeCode.TOP_LEVEL_CYCLE, [_name, error.arguments]);
        } else {
          _codeChecker._recordMessage(
              n, StrongModeCode.TOP_LEVEL_IDENTIFIER_NO_TYPE, [_name, e.name]);
        }
      }
    }
  }

  void validateIdentifierElement(AstNode n, Element e,
      {bool isMethodCall: false}) {
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
    var functionType = node.function.staticType;
    if (node.typeArguments == null &&
        functionType is FunctionType &&
        functionType.typeFormals.isNotEmpty) {
      // Type inference might depend on the parameters
      super.visitFunctionExpressionInvocation(node);
    }
  }

  @override
  visitIndexExpression(IndexExpression node) {
    // Nothing to validate.
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    var constructor = node.staticElement;
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
  visitMapLiteral(MapLiteral node) {
    if (node.typeArguments == null) {
      super.visitMapLiteral(node);
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
