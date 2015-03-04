// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.checker.checker;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart' show Token, TokenType;
import 'package:logging/logging.dart' as logger;

import 'package:dev_compiler/src/info.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/report.dart' show CheckerReporter;
import 'package:dev_compiler/src/utils.dart' show getMemberType;
import 'rules.dart';

/// Checks for overriding declarations of fields and methods. This is used to
/// check overrides between classes and superclasses, interfaces, and mixin
/// applications.
class _OverrideChecker {
  bool _failure = false;
  final TypeRules _rules;
  final CheckerReporter _reporter;
  final bool _inferFromOverrides;
  _OverrideChecker(this._rules, this._reporter, CompilerOptions options)
      : _inferFromOverrides = options.inferFromOverrides;

  void check(ClassDeclaration node) {
    if (node.element.type.isObject) return;
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
      var seen = new Set<String>();
      var current = mixins[i];
      var errorLocation = node.withClause.mixinTypes[i];
      for (int j = i - 1; j >= 0; j--) {
        _checkIndividualOverridesFromType(
            current, mixins[j], errorLocation, seen);
      }
      _checkIndividualOverridesFromType(current, parent, errorLocation, seen);
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
  void _checkSuperOverrides(ClassDeclaration node) {
    var seen = new Set<String>();
    var current = node.element.type;
    do {
      current.mixins.reversed
          .forEach((m) => _checkIndividualOverridesFromClass(node, m, seen));
      _checkIndividualOverridesFromClass(node, current.superclass, seen);
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
    var localInterfaces = new Set();
    var type = node.element.type;
    type.interfaces.forEach((i) => find(i, localInterfaces));
    _checkInterfacesOverrides(node, localInterfaces, seen,
        includeParents: true);

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
    _checkInterfacesOverrides(node, superInterfaces, seen,
        includeParents: false);
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
      {bool includeParents: true, AstNode errorLocation}) {
    var node = cls is ClassDeclaration ? cls : null;
    var type = cls is InterfaceType ? cls : node.element.type;

    // Check direct overrides on [type]
    for (var interfaceType in interfaces) {
      if (node != null) {
        _checkIndividualOverridesFromClass(node, interfaceType, seen);
      } else {
        _checkIndividualOverridesFromType(
            type, interfaceType, errorLocation, seen);
      }
    }

    // Check overrides from its mixins
    for (int i = 0; i < type.mixins.length; i++) {
      var loc =
          errorLocation != null ? errorLocation : node.withClause.mixinTypes[i];
      for (var interfaceType in interfaces) {
        // We copy [seen] so we can report separately if more than one mixin or
        // the base class have an invalid override.
        _checkIndividualOverridesFromType(
            type.mixins[i], interfaceType, loc, new Set.from(seen));
      }
    }

    // Check overrides from its superclasses
    if (includeParents) {
      var parent = type.superclass;
      if (parent.isObject) return;
      var loc = errorLocation != null ? errorLocation : node.extendsClause;
      // No need to copy [seen] here because we made copies above when reporting
      // errors on mixins.
      _checkInterfacesOverrides(parent, interfaces, seen,
          includeParents: true, errorLocation: loc);
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
  _checkIndividualOverridesFromType(InterfaceType subType,
      InterfaceType baseType, AstNode errorLocation, Set<String> seen) {
    void checkHelper(ExecutableElement e) {
      if (e.isStatic) return;
      if (seen.contains(e.name)) return;
      if (_checkSingleOverride(e, baseType, null, errorLocation)) {
        seen.add(e.name);
      }
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
      ClassDeclaration node, InterfaceType baseType, Set<String> seen) {
    for (var member in node.members) {
      if (member is ConstructorDeclaration) continue;
      if (member is FieldDeclaration) {
        if (member.isStatic) continue;
        for (var variable in member.fields.variables) {
          var name = variable.element.name;
          if (seen.contains(name)) continue;
          var getter = variable.element.getter;
          var setter = variable.element.setter;
          bool found = _checkSingleOverride(getter, baseType, variable, member);
          if (!variable.isFinal &&
              _checkSingleOverride(setter, baseType, variable, member)) {
            found = true;
          }
          if (found) seen.add(name);
        }
      } else {
        assert(member is MethodDeclaration);
        if (member.isStatic) continue;
        var method = member.element;
        if (seen.contains(method.name)) continue;
        if (_checkSingleOverride(method, baseType, member, member)) {
          seen.add(method.name);
        }
      }
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
      AstNode node, AstNode errorLocation) {
    assert(!element.isStatic);

    FunctionType subType = _rules.elementType(element);
    // TODO(vsm): Test for generic
    FunctionType baseType = getMemberType(type, element);

    if (baseType == null) return false;
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
      } else {
        _recordMessage(new InvalidMethodOverride(
            errorLocation, element, type, subType, baseType));
      }
    }
    return true;
  }

  bool _isInferableOverride(ExecutableElement element, AstNode node,
      FunctionType subType, FunctionType baseType) {
    if (_inferFromOverrides || node == null) return false;
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
  bool _constantContext = false;
  bool _failure = false;
  bool get failure => _failure || _overrideChecker._failure;

  CodeChecker(
      TypeRules rules, CheckerReporter reporter, CompilerOptions options)
      : _rules = rules,
        _reporter = reporter,
        _overrideChecker = new _OverrideChecker(rules, reporter, options);

  _visitMaybeConst(AstNode n, visitNode(AstNode n)) {
    var o = _constantContext;
    if (!o) {
      if (n is VariableDeclarationList) {
        _constantContext = o || n.isConst;
      } else if (n is VariableDeclaration) {
        _constantContext = o || n.isConst;
      } else if (n is FormalParameter) {
        _constantContext = o || n.isConst;
      } else if (n is InstanceCreationExpression) {
        _constantContext = o || n.isConst;
      } else if (n is ConstructorDeclaration) {
        _constantContext = o || n.element.isConst;
      }
    }
    visitNode(n);
    _constantContext = o;
  }

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
    _visitMaybeConst(node, (node) {
      node.visitChildren(this);

      final init = node.initializers;
      for (int i = 0, last = init.length - 1; i < last; i++) {
        final node = init[i];
        if (node is SuperConstructorInvocation) {
          _recordMessage(new InvalidSuperInvocation(node));
        }
      }
    });
  }

  @override
  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    var field = node.fieldName;
    DartType staticType = _rules.elementType(field.staticElement);
    node.expression = checkAssignment(node.expression, staticType);
    node.visitChildren(this);
  }

  @override visitListLiteral(ListLiteral node) {
    var type = _rules.provider.dynamicType;
    if (node.typeArguments != null) {
      var targs = node.typeArguments.arguments;
      if (targs.length > 0) type = targs[0].type;
    }
    var elements = node.elements;
    for (int i = 0; i < elements.length; i++) {
      elements[i] = checkArgument(elements[i], type);
    }
    super.visitListLiteral(node);
  }

  @override visitMapLiteral(MapLiteral node) {
    var ktype = _rules.provider.dynamicType;
    var vtype = _rules.provider.dynamicType;
    if (node.typeArguments != null) {
      var targs = node.typeArguments.arguments;
      if (targs.length > 0) ktype = targs[0].type;
      if (targs.length > 1) vtype = targs[1].type;
    }
    var entries = node.entries;
    for (int i = 0; i < entries.length; i++) {
      var entry = entries[i];
      entry.key = checkArgument(entry.key, ktype);
      entry.value = checkArgument(entry.value, vtype);
    }
    super.visitMapLiteral(node);
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
      list[i] = checkArgument(arg, expectedType);
    }
    return true;
  }

  Expression checkArgument(Expression arg, DartType expectedType) {
    // Preserve named argument structure, so their immediate parent is the
    // method invocation.
    if (arg is NamedExpression) {
      arg.expression = checkAssignment(arg.expression, expectedType);
      return arg;
    }
    return checkAssignment(arg, expectedType);
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

  @override visitDefaultFormalParameter(DefaultFormalParameter node) {
    _visitMaybeConst(node, (node) {
      // Check that defaults have the proper subtype.
      var parameter = node.parameter;
      var parameterType = _rules.elementType(parameter.element);
      assert(parameterType != null);
      var defaultValue = node.defaultValue;
      var defaultType;
      if (defaultValue == null) {
        // TODO(vsm): Should this be null?
        defaultType = _rules.provider.bottomType;
      } else {
        defaultType = _rules.getStaticType(defaultValue);
      }

      // If defaultType is bottom, this enforces that parameterType is not
      // non-nullable.
      if (!_rules.isSubTypeOf(defaultType, parameterType)) {
        var staticInfo = (defaultValue == null)
            ? new InvalidVariableDeclaration(
                _rules, node.identifier, parameterType)
            : new StaticTypeError(_rules, defaultValue, parameterType);
        _recordMessage(staticInfo);
      }
      node.visitChildren(this);
    });
  }

  visitFieldFormalParameter(FieldFormalParameter node) {
    var element = node.element;
    var typeName = node.type;
    if (typeName != null) {
      var type = _rules.elementType(element);
      var fieldElement =
          node.identifier.staticElement as FieldFormalParameterElement;
      var fieldType = _rules.elementType(fieldElement.field);
      if (!_rules.isSubTypeOf(type, fieldType)) {
        var staticInfo =
            new InvalidParameterDeclaration(_rules, node, fieldType);
        _recordMessage(staticInfo);
      }
    }
    node.visitChildren(this);
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    _visitMaybeConst(node, (node) {
      var arguments = node.argumentList;
      var element = node.staticElement;
      if (element != null) {
        var type = _rules.elementType(node.staticElement);
        checkArgumentList(arguments, type);
      } else {
        _recordMessage(new MissingTypeError(node));
      }
      node.visitChildren(this);
    });
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    _visitMaybeConst(node, (node) {
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
          } else if (_rules.maybeNonNullableType(dartType)) {
            var element = variable.element;
            if (element is FieldElement && !element.isStatic) {
              // Initialized - possibly implicitly - during construction.
              // Handle this via a runtime check during code generation.

              // TODO(vsm): Detect statically whether this can fail and
              // report a static error (must fail) or warning (can fail).
            } else {
              var staticInfo =
                  new InvalidVariableDeclaration(_rules, variable, dartType);
              _recordMessage(staticInfo);
            }
          }
        }
      }
      node.visitChildren(this);
    });
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    _visitMaybeConst(node, super.visitVariableDeclaration);
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
    final staticInfo = _rules.checkAssignment(expr, type, _constantContext);
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
      case TokenType.STAR:
      case TokenType.TILDE_SLASH:
      case TokenType.PERCENT:
      case TokenType.PLUS_EQ:
      case TokenType.MINUS_EQ:
      case TokenType.STAR_EQ:
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
        staticInfo = _rules.checkAssignment(
            expr.rightHandSide, paramType, _constantContext);
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
