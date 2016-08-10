// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this was ported from package:dev_compiler, and needs to be
// refactored to fit into analyzer.
library analyzer.src.task.strong.checker;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show TokenType;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/error.dart' show StrongModeCode;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/type_system.dart';

import 'ast_properties.dart';

bool isKnownFunction(Expression expression) {
  var element = _getKnownElement(expression);
  // First class functions and static methods, where we know the original
  // declaration, will have an exact type, so we know a downcast will fail.
  return element is FunctionElement ||
      element is MethodElement && element.isStatic;
}

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
    Expression expression, TypeSystem typeSystem, TypeProvider typeProvider) {
  DartType type = expression.staticType ?? DynamicTypeImpl.instance;
  if (typeSystem is StrongTypeSystemImpl &&
      type is FunctionType &&
      _hasStrictArrow(expression)) {
    // Remove fuzzy arrow if possible.
    return typeSystem.functionTypeToConcreteType(typeProvider, type);
  }
  return type;
}

bool _hasStrictArrow(Expression expression) {
  var element = _getKnownElement(expression);
  return element is FunctionElement || element is MethodElement;
}

Element _getKnownElement(Expression expression) {
  if (expression is ParenthesizedExpression) {
    expression = (expression as ParenthesizedExpression).expression;
  }
  if (expression is FunctionExpression) {
    return expression.element;
  } else if (expression is PropertyAccess) {
    return expression.propertyName.staticElement;
  } else if (expression is Identifier) {
    return expression.staticElement;
  }
  return null;
}

DartType _elementType(Element e) {
  if (e == null) {
    // Malformed code - just return dynamic.
    return DynamicTypeImpl.instance;
  }
  return (e as dynamic).type;
}

// Return the field on type corresponding to member, or null if none
// exists or the "field" is actually a getter/setter.
PropertyInducingElement _getMemberField(
    InterfaceType type, PropertyAccessorElement member) {
  String memberName = member.name;
  PropertyInducingElement field;
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
FunctionType _getMemberType(InterfaceType type, ExecutableElement member) =>
    _memberTypeGetter(member)(type);

_MemberTypeGetter _memberTypeGetter(ExecutableElement member) {
  String memberName = member.name;
  final isGetter = member is PropertyAccessorElement && member.isGetter;
  final isSetter = member is PropertyAccessorElement && member.isSetter;

  FunctionType f(InterfaceType type) {
    ExecutableElement baseMethod;

    if (member.isPrivate) {
      var subtypeLibrary = member.library;
      var baseLibrary = type.element.library;
      if (baseLibrary != subtypeLibrary) {
        return null;
      }
    }

    try {
      if (isGetter) {
        assert(!isSetter);
        // Look for getter or field.
        baseMethod = type.getGetter(memberName);
      } else if (isSetter) {
        baseMethod = type.getSetter(memberName);
      } else {
        baseMethod = type.getMethod(memberName);
      }
    } catch (e) {
      // TODO(sigmund): remove this try-catch block (see issue #48).
    }
    if (baseMethod == null || baseMethod.isStatic) return null;
    return baseMethod.type;
  }

  return f;
}

typedef FunctionType _MemberTypeGetter(InterfaceType type);

/// Checks the body of functions and properties.
class CodeChecker extends RecursiveAstVisitor {
  final StrongTypeSystemImpl rules;
  final TypeProvider typeProvider;
  final AnalysisErrorListener reporter;
  final AnalysisOptionsImpl _options;
  _OverrideChecker _overrideChecker;

  bool _failure = false;
  bool _hasImplicitCasts;

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
      DartType expectedType = _elementType(element);
      if (expectedType == null) expectedType = DynamicTypeImpl.instance;
      checkArgument(arg, expectedType);
    }
  }

  void checkAssignment(Expression expr, DartType type) {
    if (expr is ParenthesizedExpression) {
      checkAssignment(expr.expression, type);
    } else {
      if (_checkNonNullAssignment(expr, type)) {
        _checkDowncast(expr, type);
      }
    }
  }

  /// Analyzer checks boolean conversions, but we need to check too, because
  /// it uses the default assignability rules that allow `dynamic` and `Object`
  /// to be assigned to bool with no message.
  void checkBoolean(Expression expr) =>
      checkAssignment(expr, typeProvider.boolType);

  void checkFunctionApplication(InvocationExpression node) {
    var ft = _getTypeAsCaller(node);

    if (_isDynamicCall(node, ft)) {
      // If f is Function and this is a method invocation, we should have
      // gotten an analyzer error, so no need to issue another error.
      _recordDynamicInvoke(node, node.function);
    } else {
      checkArgumentList(node.argumentList, ft);
    }
  }

  DartType getType(TypeName name) {
    return (name == null) ? DynamicTypeImpl.instance : name.type;
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
  void visitComment(Comment node) {
    // skip, no need to do typechecking inside comments (they may contain
    // comment references which would require resolution).
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _hasImplicitCasts = false;
    node.visitChildren(this);
    setHasImplicitCasts(node, _hasImplicitCasts);
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
          _recordImplicitCast(node.iterable, iterableType, sequenceType);
          elementType = DynamicTypeImpl.instance;
        }
      }

      // If the sequence doesn't implement the interface at all, [ErrorVerifier]
      // will report the error, so ignore it here.
      if (elementType != null) {
        // Insert a cast from the sequence's element type to the loop variable's
        // if needed.
        _checkDowncast(loopVariable, _getDefiniteType(loopVariable),
            from: elementType);
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
  void visitFunctionExpression(FunctionExpression node) {
    _checkForUnsafeBlockClosureInference(node);
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    checkFunctionApplication(node);
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
      NodeList<TypeName> targs = node.typeArguments.arguments;
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
      NodeList<TypeName> targs = node.typeArguments.arguments;
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
    if (element == null && !_isObjectMethod(node, node.methodName)) {
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
      checkFunctionApplication(node);
    }
    node.visitChildren(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _checkUnary(node, node.staticElement);
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
      _checkUnary(node, node.staticElement);
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
  void visitVariableDeclarationList(VariableDeclarationList node) {
    TypeName type = node.type;
    if (type == null) {
      // No checks are needed when the type is var. Although internally the
      // typing rules may have inferred a more precise type for the variable
      // based on the initializer.
    } else {
      for (VariableDeclaration variable in node.variables) {
        var initializer = variable.initializer;
        if (initializer != null) {
          checkAssignment(initializer, type.type);
        }
      }
    }
    node.visitChildren(this);
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    if (!node.isConst &&
        !node.isFinal &&
        node.initializer == null &&
        rules.isNonNullableType(node?.element?.type)) {
      _recordMessage(
          node,
          StaticTypeWarningCode.NON_NULLABLE_FIELD_NOT_INITIALIZED,
          [node.name, node?.element?.type]);
    }
    return super.visitVariableDeclaration(node);
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

      // Check the LHS type.
      var rhsType = _getDefiniteType(expr.rightHandSide);
      var lhsType = _getDefiniteType(expr.leftHandSide);
      var returnType = rules.refineBinaryExpressionType(
          typeProvider, lhsType, op, rhsType, functionType.returnType);

      if (!rules.isSubtypeOf(returnType, lhsType)) {
        final numType = typeProvider.numType;
        // TODO(jmesserly): this seems to duplicate logic in StaticTypeAnalyzer.
        // Try to fix up the numerical case if possible.
        if (rules.isSubtypeOf(lhsType, numType) &&
            rules.isSubtypeOf(lhsType, rhsType)) {
          // This is also slightly different from spec, but allows us to keep
          // compound operators in the int += num and num += dynamic cases.
          _recordImplicitCast(expr.rightHandSide, rhsType, lhsType);
        } else {
          // TODO(jmesserly): this results in a duplicate error, because
          // ErrorVerifier also reports it.
          _recordMessage(expr, StrongModeCode.STATIC_TYPE_ERROR,
              [expr, returnType, lhsType]);
        }
      } else {
        // Check the RHS type.
        //
        // This is only needed if we didn't already need a cast, and avoids
        // emitting two messages for the same expression.
        _checkDowncast(expr.rightHandSide, paramTypes.first);
      }
    }
  }

  /// Records a [DownCast] of [expr] from [from] to [to], if there is one.
  ///
  /// If [from] is omitted, uses the static type of [expr].
  ///
  /// If [expr] does not require a downcast because it is not related to [to]
  /// or is already a subtype of it, does nothing.
  void _checkDowncast(Expression expr, DartType to, {DartType from}) {
    if (from == null) {
      from = _getDefiniteType(expr);
    }

    // We can use anything as void.
    if (to.isVoid) return;

    // fromT <: toT, no coercion needed.
    if (rules.isSubtypeOf(from, to)) return;

    // TODO(vsm): We can get rid of the second clause if we disallow
    // all sideways casts - see TODO below.
    // -------
    // Note: a function type is never assignable to a class per the Dart
    // spec - even if it has a compatible call method.  We disallow as
    // well for consistency.
    if ((from is FunctionType && rules.getCallMethodType(to) != null) ||
        (to is FunctionType && rules.getCallMethodType(from) != null)) {
      return;
    }

    // Downcast if toT <: fromT
    if (rules.isSubtypeOf(to, from)) {
      _recordImplicitCast(expr, from, to);
      return;
    }

    // TODO(vsm): Once we have generic methods, we should delete this
    // workaround.  These sideways casts are always ones we warn about
    // - i.e., we think they are likely to fail at runtime.
    // -------
    // Downcast if toT <===> fromT
    // The intention here is to allow casts that are sideways in the restricted
    // type system, but allowed in the regular dart type system, since these
    // are likely to succeed.  The canonical example is List<dynamic> and
    // Iterable<T> for some concrete T (e.g. Object).  These are unrelated
    // in the restricted system, but List<dynamic> <: Iterable<T> in dart.
    if (from.isAssignableTo(to)) {
      _recordImplicitCast(expr, from, to);
    }
  }

  void _checkFieldAccess(AstNode node, AstNode target, SimpleIdentifier field) {
    if (field.staticElement == null && !_isObjectProperty(target, field)) {
      _recordDynamicInvoke(node, target);
    }
    node.visitChildren(this);
  }

  /**
   * Check if the closure [node] is unsafe due to dartbug.com/26947.  If so,
   * issue a warning.
   *
   * TODO(paulberry): eliminate this once dartbug.com/26947 is fixed.
   */
  void _checkForUnsafeBlockClosureInference(FunctionExpression node) {
    if (node.body is! BlockFunctionBody) {
      return;
    }
    if (node.element.returnType.isDynamic) {
      return;
    }
    // Find the enclosing variable declaration whose inferred type might depend
    // on the inferred return type of the block closure (if any).
    AstNode prevAncestor = node;
    AstNode ancestor = node.parent;
    while (ancestor != null && ancestor is! VariableDeclaration) {
      if (ancestor is BlockFunctionBody) {
        // node is inside another block function body; if that block
        // function body is unsafe, we've already warned about it.
        return;
      }
      if (ancestor is InstanceCreationExpression) {
        // node appears inside an instance creation expression; we may be safe
        // if the type of the instance creation expression requires no
        // inference.
        TypeName typeName = ancestor.constructorName.type;
        if (typeName.typeArguments != null) {
          // Type arguments were explicitly specified.  We are safe.
          return;
        }
        DartType type = typeName.type;
        if (!(type is ParameterizedType && type.typeParameters.isNotEmpty)) {
          // Type is not generic.  We are safe.
          return;
        }
      }
      if (ancestor is MethodInvocation) {
        // node appears inside a method or function invocation; we may be safe
        // if the type of the method or function requires no inference.
        if (ancestor.typeArguments != null) {
          // Type arguments were explicitly specified.  We are safe.
          return;
        }
        Element methodElement = ancestor.methodName.staticElement;
        if (!(methodElement is ExecutableElement &&
            methodElement.typeParameters.isNotEmpty)) {
          // Method is not generic.  We are safe.
          return;
        }
      }
      if (ancestor is FunctionExpressionInvocation &&
          !identical(prevAncestor, ancestor.function)) {
        // node appears inside an argument to a function expression invocation;
        // we may be safe if the type of the function expression requires no
        // inference.
        if (ancestor.typeArguments != null) {
          // Type arguments were explicitly specified.  We are safe.
          return;
        }
        DartType type = ancestor.function.staticType;
        if (!(type is FunctionTypeImpl && type.typeFormals.isNotEmpty)) {
          // Type is not generic or has had its type parameters instantiated.
          // We are safe.
          return;
        }
      }
      if ((ancestor is ListLiteral && ancestor.typeArguments != null) ||
          (ancestor is MapLiteral && ancestor.typeArguments != null)) {
        // node appears inside a list or map literal with an explicit type.  We
        // are safe because no type inference is required.
        return;
      }
      prevAncestor = ancestor;
      ancestor = ancestor.parent;
    }
    if (ancestor == null) {
      // node is not inside a variable declaration, so it is safe.
      return;
    }
    VariableDeclaration decl = ancestor;
    VariableElement declElement = decl.element;
    if (!declElement.hasImplicitType) {
      // Variable declaration has an explicit type, so it's safe.
      return;
    }
    if (declElement.type.isDynamic) {
      // No type was successfully inferred for this variable, so it's safe.
      return;
    }
    if (declElement.enclosingElement is ExecutableElement) {
      // Variable declaration is inside a function or method, so it's safe.
      return;
    }
    _recordMessage(node, StrongModeCode.UNSAFE_BLOCK_CLOSURE_INFERENCE,
        [declElement.name]);
  }

  /// Checks if the assignment is valid with respect to non-nullable types.
  /// Returns `false` if a nullable expression is assigned to a variable of
  /// non-nullable type and `true` otherwise.
  bool _checkNonNullAssignment(Expression expression, DartType type) {
    var exprType = expression.staticType;
    if (rules.isNonNullableType(type) && rules.isNullableType(exprType)) {
      _recordMessage(expression, StaticTypeWarningCode.INVALID_ASSIGNMENT,
          [exprType, type]);
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

  void _checkRuntimeTypeCheck(AstNode node, TypeName typeName) {
    var type = getType(typeName);
    if (!rules.isGroundType(type)) {
      _recordMessage(node, StrongModeCode.NON_GROUND_TYPE_CHECK_INFO, [type]);
    }
  }

  void _checkUnary(
      /*PrefixExpression|PostfixExpression*/ node, Element element) {
    var op = node.operator;
    if (op.isUserDefinableOperator ||
        op.type == TokenType.PLUS_PLUS ||
        op.type == TokenType.MINUS_MINUS) {
      if (element == null) {
        _recordDynamicInvoke(node, node.operand);
      }
      // For ++ and --, even if it is not dynamic, we still need to check
      // that the user defined method accepts an `int` as the RHS.
      // We assume Analyzer has done this already.
    }
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
        // Don't validate return type of async methods.
        // They're handled by the runtime implementation.
        return null;
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

  DartType _getDefiniteType(Expression expr) =>
      getDefiniteType(expr, rules, typeProvider);

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
    if (_hasStrictArrow(call.function)) {
      return false;
    }
    return rules.anyParameterType(ft, (pt) => pt.isDynamic);
  }

  bool _isObjectGetter(Expression target, SimpleIdentifier id) {
    PropertyAccessorElement element =
        typeProvider.objectType.element.getGetter(id.name);
    return (element != null && !element.isStatic);
  }

  bool _isObjectMethod(Expression target, SimpleIdentifier id) {
    MethodElement element = typeProvider.objectType.element.getMethod(id.name);
    return (element != null && !element.isStatic);
  }

  bool _isObjectProperty(Expression target, SimpleIdentifier id) {
    return _isObjectGetter(target, id) || _isObjectMethod(target, id);
  }

  void _recordDynamicInvoke(AstNode node, Expression target) {
    _recordMessage(node, StrongModeCode.DYNAMIC_INVOKE, [node]);
    // TODO(jmesserly): we may eventually want to record if the whole operation
    // (node) was dynamic, rather than the target, but this is an easier fit
    // with what we used to do.
    if (target != null) setIsDynamicInvoke(target, true);
  }

  /// Records an implicit cast for the [expression] from [fromType] to [toType].
  ///
  /// This will emit the appropriate error/warning/hint message as well as mark
  /// the AST node.
  void _recordImplicitCast(
      Expression expression, DartType fromType, DartType toType) {
    // toT <:_R fromT => to <: fromT
    // NB: classes with call methods are subtypes of function
    // types, but the function type is not assignable to the class
    assert(toType.isSubtypeOf(fromType) || fromType.isAssignableTo(toType));

    // Inference "casts":
    if (expression is Literal || expression is FunctionExpression) {
      // fromT should be an exact type - this will almost certainly fail at
      // runtime.
      _recordMessage(expression, StrongModeCode.STATIC_TYPE_ERROR,
          [expression, fromType, toType]);
      return;
    }

    if (expression is InstanceCreationExpression) {
      ConstructorElement e = expression.staticElement;
      if (e == null || !e.isFactory) {
        // fromT should be an exact type - this will almost certainly fail at
        // runtime.

        _recordMessage(expression, StrongModeCode.STATIC_TYPE_ERROR,
            [expression, fromType, toType]);
        return;
      }
    }

    if (isKnownFunction(expression)) {
      _recordMessage(expression, StrongModeCode.STATIC_TYPE_ERROR,
          [expression, fromType, toType]);
      return;
    }

    // TODO(vsm): Change this to an assert when we have generic methods and
    // fix TypeRules._coerceTo to disallow implicit sideways casts.
    bool downCastComposite = false;
    if (!rules.isSubtypeOf(toType, fromType)) {
      assert(toType.isSubtypeOf(fromType) || fromType.isAssignableTo(toType));
      downCastComposite = true;
    }

    // Composite cast: these are more likely to fail.
    if (!rules.isGroundType(toType)) {
      // This cast is (probably) due to our different treatment of dynamic.
      // It may be more likely to fail at runtime.
      if (fromType is InterfaceType) {
        // For class types, we'd like to allow non-generic down casts, e.g.,
        // Iterable<T> to List<T>.  The intuition here is that raw (generic)
        // casts are problematic, and we should complain about those.
        var typeArgs = fromType.typeArguments;
        downCastComposite =
            typeArgs.isEmpty || typeArgs.any((t) => t.isDynamic);
      } else {
        downCastComposite = true;
      }
    }

    var parent = expression.parent;
    ErrorCode errorCode;
    if (downCastComposite) {
      errorCode = StrongModeCode.DOWN_CAST_COMPOSITE;
    } else if (fromType.isDynamic) {
      errorCode = StrongModeCode.DYNAMIC_CAST;
    } else if (parent is VariableDeclaration &&
        parent.initializer == expression) {
      errorCode = StrongModeCode.ASSIGNMENT_CAST;
    } else {
      errorCode = StrongModeCode.DOWN_CAST_IMPLICIT;
    }

    _recordMessage(expression, errorCode, [fromType, toType]);
    setImplicitCast(expression, toType);
    _hasImplicitCasts = true;
  }

  void _recordMessage(AstNode node, ErrorCode errorCode, List arguments) {
    var severity = errorCode.errorSeverity;
    if (severity == ErrorSeverity.ERROR) _failure = true;
    if (severity != ErrorSeverity.INFO || _options.strongModeHints) {
      int begin = node is AnnotatedNode
          ? node.firstTokenAfterCommentAndMetadata.offset
          : node.offset;
      int length = node.end - begin;
      var source = (node.root as CompilationUnit).element.source;
      var error =
          new AnalysisError(source, begin, length, errorCode, arguments);
      reporter.onError(error);
    }
  }
}

/// Checks for overriding declarations of fields and methods. This is used to
/// check overrides between classes and superclasses, interfaces, and mixin
/// applications.
class _OverrideChecker {
  final StrongTypeSystemImpl rules;
  final TypeProvider _typeProvider;
  final CodeChecker _checker;

  _OverrideChecker(CodeChecker checker)
      : _checker = checker,
        rules = checker.rules,
        _typeProvider = checker.typeProvider;

  void check(ClassDeclaration node) {
    if (node.element.type.isObject) return;
    _checkSuperOverrides(node);
    _checkMixinApplicationOverrides(node);
    _checkAllInterfaceOverrides(node);
  }

  /// Checks that implementations correctly override all reachable interfaces.
  /// In particular, we need to check these overrides for the definitions in
  /// the class itself and each its superclasses. If a superclass is not
  /// abstract, then we can skip its transitive interfaces. For example, in:
  ///
  ///     B extends C implements G
  ///     A extends B with E, F implements H, I
  ///
  /// we check:
  ///
  ///     C against G, H, and I
  ///     B against G, H, and I
  ///     E against H and I // no check against G because B is a concrete class
  ///     F against H and I
  ///     A against H and I
  void _checkAllInterfaceOverrides(ClassDeclaration node) {
    var seen = new Set<String>();
    // Helper function to collect all reachable interfaces.
    find(InterfaceType interfaceType, Set result) {
      if (interfaceType == null || interfaceType.isObject) return;
      if (result.contains(interfaceType)) return;
      result.add(interfaceType);
      find(interfaceType.superclass, result);
      interfaceType.mixins.forEach((i) => find(i, result));
      interfaceType.interfaces.forEach((i) => find(i, result));
    }

    // Check all interfaces reachable from the `implements` clause in the
    // current class against definitions here and in superclasses.
    var localInterfaces = new Set<InterfaceType>();
    var type = node.element.type;
    type.interfaces.forEach((i) => find(i, localInterfaces));
    _checkInterfacesOverrides(node, localInterfaces, seen,
        includeParents: true);

    // Check also how we override locally the interfaces from parent classes if
    // the parent class is abstract. Otherwise, these will be checked as
    // overrides on the concrete superclass.
    var superInterfaces = new Set<InterfaceType>();
    var parent = type.superclass;
    // TODO(sigmund): we don't seem to be reporting the analyzer error that a
    // non-abstract class is not implementing an interface. See
    // https://github.com/dart-lang/dart-dev-compiler/issues/25
    while (parent != null && parent.element.isAbstract) {
      parent.interfaces.forEach((i) => find(i, superInterfaces));
      parent = parent.superclass;
    }
    _checkInterfacesOverrides(node, superInterfaces, seen,
        includeParents: false);
  }

  /// Check that individual methods and fields in [node] correctly override
  /// the declarations in [baseType].
  ///
  /// The [errorLocation] node indicates where errors are reported, see
  /// [_checkSingleOverride] for more details.
  _checkIndividualOverridesFromClass(ClassDeclaration node,
      InterfaceType baseType, Set<String> seen, bool isSubclass) {
    for (var member in node.members) {
      if (member is FieldDeclaration) {
        if (member.isStatic) {
          continue;
        }
        for (var variable in member.fields.variables) {
          var element = variable.element as PropertyInducingElement;
          var name = element.name;
          if (seen.contains(name)) {
            continue;
          }
          var getter = element.getter;
          var setter = element.setter;
          bool found = _checkSingleOverride(
              getter, baseType, variable.name, member, isSubclass);
          if (!variable.isFinal &&
              !variable.isConst &&
              _checkSingleOverride(
                  setter, baseType, variable.name, member, isSubclass)) {
            found = true;
          }
          if (found) {
            seen.add(name);
          }
        }
      } else if (member is MethodDeclaration) {
        if (member.isStatic) {
          continue;
        }
        var method = member.element;
        if (seen.contains(method.name)) {
          continue;
        }
        if (_checkSingleOverride(
            method, baseType, member.name, member, isSubclass)) {
          seen.add(method.name);
        }
      } else {
        assert(member is ConstructorDeclaration);
      }
    }
  }

  /// Check that individual methods and fields in [subType] correctly override
  /// the declarations in [baseType].
  ///
  /// The [errorLocation] node indicates where errors are reported, see
  /// [_checkSingleOverride] for more details.
  ///
  /// The set [seen] is used to avoid reporting overrides more than once. It
  /// is used when invoking this function multiple times when checking several
  /// types in a class hierarchy. Errors are reported only the first time an
  /// invalid override involving a specific member is encountered.
  _checkIndividualOverridesFromType(
      InterfaceType subType,
      InterfaceType baseType,
      AstNode errorLocation,
      Set<String> seen,
      bool isSubclass) {
    void checkHelper(ExecutableElement e) {
      if (e.isStatic) return;
      if (seen.contains(e.name)) return;
      if (_checkSingleOverride(e, baseType, null, errorLocation, isSubclass)) {
        seen.add(e.name);
      }
    }

    subType.methods.forEach(checkHelper);
    subType.accessors.forEach(checkHelper);
  }

  /// Checks that [cls] and its super classes (including mixins) correctly
  /// overrides each interface in [interfaces]. If [includeParents] is false,
  /// then mixins are still checked, but the base type and it's transitive
  /// supertypes are not.
  ///
  /// [cls] can be either a [ClassDeclaration] or a [InterfaceType]. For
  /// [ClassDeclaration]s errors are reported on the member that contains the
  /// invalid override, for [InterfaceType]s we use [errorLocation] instead.
  void _checkInterfacesOverrides(
      cls, Iterable<InterfaceType> interfaces, Set<String> seen,
      {Set<InterfaceType> visited,
      bool includeParents: true,
      AstNode errorLocation}) {
    var node = cls is ClassDeclaration ? cls : null;
    var type = cls is InterfaceType ? cls : node.element.type;

    if (visited == null) {
      visited = new Set<InterfaceType>();
    } else if (visited.contains(type)) {
      // Malformed type.
      return;
    } else {
      visited.add(type);
    }

    // Check direct overrides on [type]
    for (var interfaceType in interfaces) {
      if (node != null) {
        _checkIndividualOverridesFromClass(node, interfaceType, seen, false);
      } else {
        _checkIndividualOverridesFromType(
            type, interfaceType, errorLocation, seen, false);
      }
    }

    // Check overrides from its mixins
    for (int i = 0; i < type.mixins.length; i++) {
      var loc = errorLocation ?? node.withClause.mixinTypes[i];
      for (var interfaceType in interfaces) {
        // We copy [seen] so we can report separately if more than one mixin or
        // the base class have an invalid override.
        _checkIndividualOverridesFromType(
            type.mixins[i], interfaceType, loc, new Set.from(seen), false);
      }
    }

    // Check overrides from its superclasses
    if (includeParents) {
      var parent = type.superclass;
      if (parent.isObject) {
        return;
      }
      var loc = errorLocation ?? node.extendsClause;
      // No need to copy [seen] here because we made copies above when reporting
      // errors on mixins.
      _checkInterfacesOverrides(parent, interfaces, seen,
          visited: visited, includeParents: true, errorLocation: loc);
    }
  }

  /// Check overrides from mixin applications themselves. For example, in:
  ///
  ///      A extends B with E, F
  ///
  ///  we check:
  ///
  ///      B & E against B (equivalently how E overrides B)
  ///      B & E & F against B & E (equivalently how F overrides both B and E)
  void _checkMixinApplicationOverrides(ClassDeclaration node) {
    var type = node.element.type;
    var parent = type.superclass;
    var mixins = type.mixins;

    // Check overrides from applying mixins
    for (int i = 0; i < mixins.length; i++) {
      var seen = new Set<String>();
      var current = mixins[i];
      var errorLocation = node.withClause.mixinTypes[i];
      for (int j = i - 1; j >= 0; j--) {
        _checkIndividualOverridesFromType(
            current, mixins[j], errorLocation, seen, true);
      }
      _checkIndividualOverridesFromType(
          current, parent, errorLocation, seen, true);
    }
  }

  /// Checks that [element] correctly overrides its corresponding member in
  /// [type]. Returns `true` if an override was found, that is, if [element] has
  /// a corresponding member in [type] that it overrides.
  ///
  /// The [errorLocation] is a node where the error is reported. For example, a
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
  /// the AST node that defines [element]. This is used to determine whether the
  /// type of the element could be inferred from the types in the super classes.
  bool _checkSingleOverride(ExecutableElement element, InterfaceType type,
      AstNode node, AstNode errorLocation, bool isSubclass) {
    assert(!element.isStatic);

    FunctionType subType = _elementType(element);
    // TODO(vsm): Test for generic
    FunctionType baseType = _getMemberType(type, element);
    if (baseType == null) return false;

    if (isSubclass && element is PropertyAccessorElement) {
      // Disallow any overriding if the base class defines this member
      // as a field.  We effectively treat fields as final / non-virtual.
      PropertyInducingElement field = _getMemberField(type, element);
      if (field != null) {
        _checker._recordMessage(
            errorLocation, StrongModeCode.INVALID_FIELD_OVERRIDE, [
          element.enclosingElement.name,
          element.name,
          subType,
          type,
          baseType
        ]);
      }
    }
    FunctionType concreteSubType = subType;
    FunctionType concreteBaseType = baseType;
    if (element is MethodElement) {
      if (concreteSubType.typeFormals.isNotEmpty) {
        if (concreteBaseType.typeFormals.isEmpty) {
          concreteSubType = rules.instantiateToBounds(concreteSubType);
        }
      }
      concreteSubType =
          rules.typeToConcreteType(_typeProvider, concreteSubType);
      concreteBaseType =
          rules.typeToConcreteType(_typeProvider, concreteBaseType);
    }
    if (!rules.isSubtypeOf(concreteSubType, concreteBaseType)) {
      // See whether non-subtype cases fit one of our common patterns:
      //
      // Common pattern 1: Inferable return type (on getters and methods)
      //   class A {
      //     int get foo => ...;
      //     String toString() { ... }
      //   }
      //   class B extends A {
      //     get foo => e; // no type specified.
      //     toString() { ... } // no return type specified.
      //   }

      ErrorCode errorCode;
      if (errorLocation is ExtendsClause) {
        errorCode = StrongModeCode.INVALID_METHOD_OVERRIDE_FROM_BASE;
      } else if (errorLocation.parent is WithClause) {
        errorCode = StrongModeCode.INVALID_METHOD_OVERRIDE_FROM_MIXIN;
      } else {
        errorCode = StrongModeCode.INVALID_METHOD_OVERRIDE;
      }

      _checker._recordMessage(errorLocation, errorCode, [
        element.enclosingElement.name,
        element.name,
        subType,
        type,
        baseType
      ]);
    }
    return true;
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
  void _checkSuperOverrides(ClassDeclaration node) {
    var seen = new Set<String>();
    var current = node.element.type;
    var visited = new Set<InterfaceType>();
    do {
      visited.add(current);
      current.mixins.reversed.forEach(
          (m) => _checkIndividualOverridesFromClass(node, m, seen, true));
      _checkIndividualOverridesFromClass(node, current.superclass, seen, true);
      current = current.superclass;
    } while (!current.isObject && !visited.contains(current));
  }
}
