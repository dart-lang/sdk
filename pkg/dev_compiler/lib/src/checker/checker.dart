library ddc.src.checker.checker;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart' show Token, TokenType;
import 'package:logging/logging.dart' as logger;

import 'package:ddc/src/info.dart';
import 'package:ddc/src/report.dart' show CheckerReporter;
import 'rules.dart';

/// Checks for overriding declarations of fields and methods. This is used to
/// check overrides between classes and superclasses, interfaces, and mixin
/// applications.
class _OverrideChecker {
  bool _failure = false;
  final TypeRules _rules;
  final CheckerReporter _reporter;
  _OverrideChecker(this._rules, this._reporter);

  void check(ClassDeclaration node) {
    _checkSuperOverrides(node);
    _checkMixinApplicationOverrides(node);
    _checkAllInterfaceOverrides(node);
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
      var current = mixins[i];
      var errorLocation = node.withClause.mixinTypes[i];
      _checkIndividualOverridesFromType(current, parent, errorLocation);
      for (int j = 0; j < i; j++) {
        _checkIndividualOverridesFromType(current, mixins[j], errorLocation);
      }
    }
  }

  /// Check overrides between a class and its superclasses and mixins. For
  /// example, in:
  ///
  ///      A extends B with E, F
  ///
  ///  we check A against B, B super classes, E, and F.
  void _checkSuperOverrides(ClassDeclaration node) {
    var current = node.element.type;
    do {
      _checkIndividualOverridesFromClass(node, current.superclass);
      current.mixins
          .forEach((m) => _checkIndividualOverridesFromClass(node, m));
      current = current.superclass;
    } while (!current.isObject);
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
    var localInterfaces = new Set();
    var type = node.element.type;
    type.interfaces.forEach((i) => find(i, localInterfaces));
    for (var interfaceType in localInterfaces) {
      _checkInterfaceOverrides(node, interfaceType, includeParents: true);
    }

    // Check also how we override locally the interfaces from parent classes if
    // the parent class is abstract. Otherwise, these will be checked as
    // overrides on the concrete superclass.
    var superInterfaces = new Set();
    var parent = type.superclass;
    // TODO(sigmund): we don't seem to be reporting the analyzer error that a
    // non-abstract class is not implementing an interface. See
    // https://github.com/dart-lang/dart-dev-compiler/issues/25
    while (parent != null && parent.element.isAbstract) {
      parent.interfaces.forEach((i) => find(i, superInterfaces));
      parent = parent.superclass;
    }
    for (var interfaceType in superInterfaces) {
      _checkInterfaceOverrides(node, interfaceType, includeParents: false);
    }
  }

  /// Checks that [node] and its super classes (including mixins) correctly
  /// override [interfaceType].
  void _checkInterfaceOverrides(
      ClassDeclaration node, InterfaceType interfaceType,
      {bool includeParents}) {
    _checkIndividualOverridesFromClass(node, interfaceType);

    var type = node.element.type;
    if (includeParents) {
      var parent = type.superclass;
      var parentErrorLocation = node.extendsClause;
      while (parent != null) {
        _checkIndividualOverridesFromType(
            parent, interfaceType, parentErrorLocation);
        parent = parent.superclass;
      }
    }

    for (int i = 0; i < type.mixins.length; i++) {
      var current = type.mixins[i];
      var errorLocation = node.withClause.mixinTypes[i];
      _checkIndividualOverridesFromType(current, interfaceType, errorLocation);
    }
  }

  /// Check that individual methods and fields in [subType] correctly override
  /// the declarations in [baseType].
  ///
  /// The [errorLocation] node indicates where errors are reported, see
  /// [_checkSingleOverride] for more details.
  _checkIndividualOverridesFromType(
      InterfaceType subType, InterfaceType baseType, AstNode errorLocation) {
    void checkHelper(ExecutableElement e) {
      if (e.isStatic) return;
      _checkSingleOverride(e, baseType, null, errorLocation);
    }
    subType.methods.forEach(checkHelper);
    subType.accessors.forEach(checkHelper);
  }

  /// Check that individual methods and fields in [subType] correctly override
  /// the declarations in [baseType].
  ///
  /// The [errorLocation] node indicates where errors are reported, see
  /// [_checkSingleOverride] for more details.
  _checkIndividualOverridesFromClass(
      ClassDeclaration node, InterfaceType baseType) {
    for (var member in node.members) {
      if (member is ConstructorDeclaration) continue;
      if (member is FieldDeclaration) {
        if (member.isStatic) continue;
        for (var variable in member.fields.variables) {
          _checkSingleOverride(
              variable.element.getter, baseType, variable, member);
          if (!variable.isFinal) {
            _checkSingleOverride(
                variable.element.setter, baseType, variable, member);
          }
        }
      } else {
        assert(member is MethodDeclaration);
        if (member.isStatic) continue;
        _checkSingleOverride(member.element, baseType, member, member);
      }
    }
  }

  /// Looks up the declaration that matches [member] in [type] and returns it's
  /// declared type.
  FunctionType _getMemberType(InterfaceType type, ExecutableElement member) {
    ExecutableElement baseMethod;
    String memberName = member.name;

    final isGetter = member is PropertyAccessorElement && member.isGetter;
    final isSetter = member is PropertyAccessorElement && member.isSetter;

    if (isGetter) {
      assert(!isSetter);
      // Look for getter or field.
      baseMethod = type.getGetter(memberName);
    } else if (isSetter) {
      baseMethod = type.getSetter(memberName);
    } else {
      baseMethod = type.getMethod(memberName);
    }
    if (baseMethod == null) return null;
    return _rules.elementType(baseMethod);
  }

  /// Checks that [element] correctly overrides its corresponding member in
  /// [type].
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
  void _checkSingleOverride(ExecutableElement element, InterfaceType type,
      AstNode node, AstNode errorLocation) {
    assert(!element.isStatic);

    FunctionType subType = _rules.elementType(element);
    // TODO(vsm): Test for generic
    FunctionType baseType = _getMemberType(type, element);

    if (baseType != null) {
      //var result = _checkOverride(subType, baseType);
      //if (result != null) return result;
      if (!_rules.isAssignable(subType, baseType)) {
        // See whether non-assignable cases fit one of our common patterns:
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
        if (_isInferableOverride(element, node, subType, baseType)) {
          _recordMessage(new InferableOverride(errorLocation, element, type,
              subType.returnType, baseType.returnType));
          return;
        }
        _recordMessage(new InvalidMethodOverride(
            errorLocation, element, type, subType, baseType));
        return;
      }
    }
  }

  bool _isInferableOverride(ExecutableElement element, AstNode node,
      FunctionType subType, FunctionType baseType) {
    if (node == null) return false;
    final isGetter = element is PropertyAccessorElement && element.isGetter;
    if (isGetter && element.isSynthetic) {
      var field = node.parent.parent;
      return field is FieldDeclaration && field.fields.type == null;
    }

    // node is a MethodDeclaration whenever getters and setters are
    // declared explicitly. Setters declared from a field will have the
    // correct return type, so we don't need to check that separately.
    return node is MethodDeclaration &&
        node.returnType == null &&
        _rules.isFunctionSubTypeOf(subType, baseType, ignoreReturn: true);
  }

  void _recordMessage(StaticInfo info) {
    if (info == null) return;
    if (info.level >= logger.Level.SEVERE) _failure = true;
    _reporter.log(info);
  }
}

/// Checks the body of functions and properties.
class CodeChecker extends RecursiveAstVisitor {
  final TypeRules _rules;
  final CheckerReporter _reporter;
  final _OverrideChecker _overrideChecker;
  bool _failure = false;
  bool get failure => _failure || _overrideChecker._failure;

  CodeChecker(TypeRules rules, CheckerReporter reporter)
      : _rules = rules,
        _reporter = reporter,
        _overrideChecker = new _OverrideChecker(rules, reporter);

  visitComment(Comment node) {
    // skip, no need to do typechecking inside comments (they may contain
    // comment references which would require resolution).
  }

  visitClassDeclaration(ClassDeclaration node) {
    _overrideChecker.check(node);
    super.visitClassDeclaration(node);
  }

  visitAssignmentExpression(AssignmentExpression node) {
    var token = node.operator;
    if (token.type != TokenType.EQ) {
      _checkCompoundAssignment(node);
    } else {
      DartType staticType = _rules.getStaticType(node.leftHandSide);
      node.rightHandSide = checkAssignment(node.rightHandSide, staticType);
    }
    node.visitChildren(this);
  }

  /// Check constructor declaration to ensure correct super call placement.
  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    node.visitChildren(this);

    final init = node.initializers;
    for (int i = 0, last = init.length - 1; i < last; i++) {
      final node = init[i];
      if (node is SuperConstructorInvocation) {
        _recordMessage(new InvalidSuperInvocation(node));
      }
    }
  }

  // Check invocations
  bool checkArgumentList(ArgumentList node, FunctionType type) {
    NodeList<Expression> list = node.arguments;
    int len = list.length;
    for (int i = 0; i < len; ++i) {
      Expression arg = list[i];
      ParameterElement element = node.getStaticParameterElementFor(arg);
      if (element == null) {
        if (type.parameters.length < len) {
          // We found an argument mismatch, the analyzer will report this too,
          // so no need to insert an error for this here.
          continue;
        }
        element = type.parameters[i];
        // TODO(vsm): When can this happen?
        assert(element != null);
      }
      DartType expectedType = _rules.elementType(element);
      if (expectedType == null) expectedType = _rules.provider.dynamicType;
      list[i] = checkAssignment(arg, expectedType);
    }
    return true;
  }

  void checkFunctionApplication(
      Expression node, Expression f, ArgumentList list) {
    if (_rules.isDynamicCall(f)) {
      // TODO(vsm): For a function object, we should still be able to derive a
      // function type from it.
      _recordDynamicInvoke(node);
    } else {
      checkArgumentList(list, _rules.getStaticType(f));
    }
  }

  visitMethodInvocation(MethodInvocation node) {
    checkFunctionApplication(node, node.methodName, node.argumentList);
    node.visitChildren(this);
  }

  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    checkFunctionApplication(node, node.function, node.argumentList);
    node.visitChildren(this);
  }

  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    var type = node.staticElement.type;
    bool checked = checkArgumentList(node.argumentList, type);
    assert(checked);
    node.visitChildren(this);
  }

  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    var element = node.staticElement;
    if (element == null) {
      _recordMessage(new MissingTypeError(node));
    } else {
      var type = node.staticElement.type;
      bool checked = checkArgumentList(node.argumentList, type);
      assert(checked);
    }
    node.visitChildren(this);
  }

  AstNode _getOwnerFunction(AstNode node) {
    var parent = node.parent;
    while (parent is! FunctionExpression &&
        parent is! MethodDeclaration &&
        parent is! ConstructorDeclaration) {
      parent = parent.parent;
    }
    return parent;
  }

  FunctionType _getFunctionType(AstNode node) {
    if (node is Declaration) {
      return _rules.elementType(node.element);
    } else {
      assert(node is FunctionExpression);
      return _rules.getStaticType(node);
    }
  }

  Expression _checkReturn(Expression expression, AstNode node) {
    var type = _getFunctionType(_getOwnerFunction(node)).returnType;
    // TODO(vsm): Enforce void or dynamic (to void?) when expression is null.
    if (expression == null) return null;
    return checkAssignment(expression, type);
  }

  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    node.expression = _checkReturn(node.expression, node);
    node.visitChildren(this);
  }

  visitReturnStatement(ReturnStatement node) {
    node.expression = _checkReturn(node.expression, node);
    node.visitChildren(this);
  }

  visitPropertyAccess(PropertyAccess node) {
    if (_rules.isDynamicGet(node.realTarget)) {
      _recordDynamicInvoke(node);
    }
    node.visitChildren(this);
  }

  visitPrefixedIdentifier(PrefixedIdentifier node) {
    final target = node.prefix;
    // Check if the prefix is a library - PrefixElement denotes a library
    // access.
    if (target.staticElement is! PrefixElement && _rules.isDynamicGet(target)) {
      _recordDynamicInvoke(node);
    }
    node.visitChildren(this);
  }

  visitVariableDeclarationList(VariableDeclarationList node) {
    TypeName type = node.type;
    if (type == null) {
      // No checks are needed when the type is var. Although internally the
      // typing rules may have inferred a more precise type for the variable
      // based on the initializer.
    } else {
      var dartType = getType(type);
      for (VariableDeclaration variable in node.variables) {
        var initializer = variable.initializer;
        if (initializer != null) {
          variable.initializer = checkAssignment(initializer, dartType);
        }
      }
    }
    node.visitChildren(this);
  }

  void _checkRuntimeTypeCheck(AstNode node, TypeName typeName) {
    var type = getType(typeName);
    if (!_rules.isGroundType(type)) {
      _recordMessage(new InvalidRuntimeCheckError(node, type));
    }
  }

  visitAsExpression(AsExpression node) {
    node.visitChildren(this);
  }

  visitIsExpression(IsExpression node) {
    _checkRuntimeTypeCheck(node, node.type);
    node.visitChildren(this);
  }

  DartType getType(TypeName name) {
    return (name == null) ? _rules.provider.dynamicType : name.type;
  }

  Expression checkAssignment(Expression expr, DartType type) {
    final staticInfo = _rules.checkAssignment(expr, type);
    _recordMessage(staticInfo);
    if (staticInfo is Conversion) expr = staticInfo;
    return expr;
  }

  DartType _specializedBinaryReturnType(
      TokenType op, DartType t1, DartType t2, DartType normalReturnType) {
    // This special cases binary return types as per 16.26 and 16.27 of the
    // Dart language spec.
    switch (op) {
      case TokenType.PLUS:
      case TokenType.MINUS:
      case TokenType.AMPERSAND:
      case TokenType.TILDE_SLASH:
      case TokenType.PERCENT:
      case TokenType.PLUS_EQ:
      case TokenType.MINUS_EQ:
      case TokenType.AMPERSAND_EQ:
      case TokenType.TILDE_SLASH_EQ:
      case TokenType.PERCENT_EQ:
        if (_rules.isIntType(t1) && _rules.isIntType(t2)) return t1;
        if (_rules.isDoubleType(t1) && _rules.isDoubleType(t2)) return t1;
        // This particular combo is not spelled out in the spec, but all
        // implementations and analyzer seem to follow this.
        if (_rules.isDoubleType(t1) && _rules.isIntType(t2)) return t1;
    }
    return normalReturnType;
  }

  void _checkCompoundAssignment(AssignmentExpression expr) {
    var op = expr.operator.type;
    assert(op.isAssignmentOperator && op != TokenType.EQ);
    var methodElement = expr.staticElement;
    if (methodElement == null) {
      // Dynamic invocation
      _recordDynamicInvoke(expr);
    } else {
      // Sanity check the operator
      assert(methodElement.isOperator);
      var functionType = methodElement.type;
      var paramTypes = functionType.normalParameterTypes;
      assert(paramTypes.length == 1);
      assert(functionType.namedParameterTypes.isEmpty);
      assert(functionType.optionalParameterTypes.isEmpty);

      // Check the lhs type
      var staticInfo;
      var rhsType = _rules.getStaticType(expr.rightHandSide);
      var lhsType = _rules.getStaticType(expr.leftHandSide);
      var returnType = _specializedBinaryReturnType(
          op, lhsType, rhsType, functionType.returnType);

      if (!_rules.isSubTypeOf(returnType, lhsType)) {
        final numType = _rules.provider.numType;
        // Try to fix up the numerical case if possible.
        if (_rules.isSubTypeOf(lhsType, numType) &&
            _rules.isSubTypeOf(lhsType, rhsType)) {
          // This is also slightly different from spec, but allows us to keep
          // compound operators in the int += num and num += dynamic cases.
          staticInfo = DownCast.create(
              _rules, expr.rightHandSide, Coercion.cast(rhsType, lhsType));
          expr.rightHandSide = staticInfo;
          rhsType = lhsType;
        } else {
          // Static type error
          staticInfo = new StaticTypeError(_rules, expr, lhsType);
        }
        _recordMessage(staticInfo);
      }

      // Check the rhs type
      if (staticInfo is! Conversion) {
        var paramType = paramTypes.first;
        staticInfo = _rules.checkAssignment(expr.rightHandSide, paramType);
        _recordMessage(staticInfo);
        if (staticInfo is Conversion) expr.rightHandSide = staticInfo;
      }
    }
  }

  void _recordDynamicInvoke(AstNode node) {
    _reporter.log(new DynamicInvoke(_rules, node));
  }

  void _recordMessage(StaticInfo info) {
    if (info == null) return;
    if (info.level >= logger.Level.SEVERE) _failure = true;
    _reporter.log(info);
  }
}
