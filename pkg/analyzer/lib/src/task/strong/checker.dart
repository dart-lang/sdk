// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this was ported from package:dev_compiler, and needs to be
// refactored to fit into analyzer.
library analyzer.src.task.strong.checker;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart' show Token, TokenType;

import 'info.dart';
import 'rules.dart';

/// Checks for overriding declarations of fields and methods. This is used to
/// check overrides between classes and superclasses, interfaces, and mixin
/// applications.
class _OverrideChecker {
  bool _failure = false;
  final TypeRules _rules;
  final AnalysisErrorListener _reporter;

  _OverrideChecker(this._rules, this._reporter);

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
    var visited = new Set<InterfaceType>();
    do {
      visited.add(current);
      current.mixins.reversed
          .forEach((m) => _checkIndividualOverridesFromClass(node, m, seen));
      _checkIndividualOverridesFromClass(node, current.superclass, seen);
      current = current.superclass;
    } while (!current.isObject && !visited.contains(current));
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
          visited: visited, includeParents: true, errorLocation: loc);
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
          var element = variable.element as PropertyInducingElement;
          var name = element.name;
          if (seen.contains(name)) continue;
          var getter = element.getter;
          var setter = element.setter;
          bool found = _checkSingleOverride(getter, baseType, variable, member);
          if (!variable.isFinal &&
              !variable.isConst &&
              _checkSingleOverride(setter, baseType, variable, member)) {
            found = true;
          }
          if (found) seen.add(name);
        }
      } else {
        if ((member as MethodDeclaration).isStatic) continue;
        var method = (member as MethodDeclaration).element;
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
    FunctionType baseType = _getMemberType(type, element);

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
      _recordMessage(new InvalidMethodOverride(
          errorLocation, element, type, subType, baseType));
    }
    return true;
  }

  void _recordMessage(StaticInfo info) {
    if (info == null) return;
    var error = info.toAnalysisError();
    if (error.errorCode.errorSeverity == ErrorSeverity.ERROR) _failure = true;
    _reporter.onError(error);
  }
}

/// Checks the body of functions and properties.
class CodeChecker extends RecursiveAstVisitor {
  final TypeRules rules;
  final AnalysisErrorListener reporter;
  final _OverrideChecker _overrideChecker;
  final bool _hints;

  bool _failure = false;
  bool get failure => _failure || _overrideChecker._failure;

  void reset() {
    _failure = false;
    _overrideChecker._failure = false;
  }

  CodeChecker(TypeRules rules, AnalysisErrorListener reporter,
      {bool hints: false})
      : rules = rules,
        reporter = reporter,
        _hints = hints,
        _overrideChecker = new _OverrideChecker(rules, reporter);

  @override
  void visitComment(Comment node) {
    // skip, no need to do typechecking inside comments (they may contain
    // comment references which would require resolution).
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _overrideChecker.check(node);
    super.visitClassDeclaration(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var token = node.operator;
    if (token.type != TokenType.EQ) {
      _checkCompoundAssignment(node);
    } else {
      DartType staticType = _getStaticType(node.leftHandSide);
      checkAssignment(node.rightHandSide, staticType);
    }
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
        _recordMessage(new InvalidSuperInvocation(node));
      }
    }
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    var field = node.fieldName;
    var element = field.staticElement;
    DartType staticType = rules.elementType(element);
    checkAssignment(node.expression, staticType);
    node.visitChildren(this);
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    // Check that the expression is an Iterable.
    var expr = node.iterable;
    var iterableType = node.awaitKeyword != null
        ? rules.provider.streamType
        : rules.provider.iterableType;
    var loopVariable = node.identifier != null
        ? node.identifier
        : node.loopVariable?.identifier;
    if (loopVariable != null) {
      var iteratorType = loopVariable.staticType;
      var checkedType = iterableType.substitute4([iteratorType]);
      checkAssignment(expr, checkedType);
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
  void visitIfStatement(IfStatement node) {
    checkBoolean(node.condition);
    node.visitChildren(this);
  }

  @override
  void visitDoStatement(DoStatement node) {
    checkBoolean(node.condition);
    node.visitChildren(this);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    checkBoolean(node.condition);
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
  void visitListLiteral(ListLiteral node) {
    var type = rules.provider.dynamicType;
    if (node.typeArguments != null) {
      var targs = node.typeArguments.arguments;
      if (targs.length > 0) type = targs[0].type;
    }
    var elements = node.elements;
    for (int i = 0; i < elements.length; i++) {
      checkArgument(elements[i], type);
    }
    super.visitListLiteral(node);
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    var ktype = rules.provider.dynamicType;
    var vtype = rules.provider.dynamicType;
    if (node.typeArguments != null) {
      var targs = node.typeArguments.arguments;
      if (targs.length > 0) ktype = targs[0].type;
      if (targs.length > 1) vtype = targs[1].type;
    }
    var entries = node.entries;
    for (int i = 0; i < entries.length; i++) {
      var entry = entries[i];
      checkArgument(entry.key, ktype);
      checkArgument(entry.value, vtype);
    }
    super.visitMapLiteral(node);
  }

  // Check invocations
  void checkArgumentList(ArgumentList node, FunctionType type) {
    NodeList<Expression> list = node.arguments;
    int len = list.length;
    for (int i = 0; i < len; ++i) {
      Expression arg = list[i];
      ParameterElement element = arg.staticParameterElement;
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
      DartType expectedType = rules.elementType(element);
      if (expectedType == null) expectedType = rules.provider.dynamicType;
      checkArgument(arg, expectedType);
    }
  }

  void checkArgument(Expression arg, DartType expectedType) {
    // Preserve named argument structure, so their immediate parent is the
    // method invocation.
    if (arg is NamedExpression) {
      arg = (arg as NamedExpression).expression;
    }
    checkAssignment(arg, expectedType);
  }

  void checkFunctionApplication(
      Expression node, Expression f, ArgumentList list) {
    if (rules.isDynamicCall(f)) {
      // If f is Function and this is a method invocation, we should have
      // gotten an analyzer error, so no need to issue another error.
      _recordDynamicInvoke(node, f);
    } else {
      checkArgumentList(list, rules.getTypeAsCaller(f));
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    var target = node.realTarget;
    if (rules.isDynamicTarget(target) &&
        !_isObjectMethod(node, node.methodName)) {
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
      DynamicInvoke.set(node.methodName, true);
    } else {
      checkFunctionApplication(node, node.methodName, node.argumentList);
    }
    node.visitChildren(this);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    checkFunctionApplication(node, node.function, node.argumentList);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var type = node.staticElement.type;
    checkArgumentList(node.argumentList, type);
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

  void _checkReturnOrYield(Expression expression, AstNode node,
      {bool yieldStar: false}) {
    var body = node.getAncestor((n) => n is FunctionBody);
    var type = rules.getExpectedReturnType(body, yieldStar: yieldStar);
    if (type == null) {
      // We have a type mismatch: the async/async*/sync* modifier does
      // not match the return or yield type.  We should have already gotten an
      // analyzer error in this case.
      return;
    }
    // TODO(vsm): Enforce void or dynamic (to void?) when expression is null.
    if (expression != null) checkAssignment(expression, type);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _checkReturnOrYield(node.expression, node);
    node.visitChildren(this);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _checkReturnOrYield(node.expression, node);
    node.visitChildren(this);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _checkReturnOrYield(node.expression, node, yieldStar: node.star != null);
    node.visitChildren(this);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    var target = node.realTarget;
    if (rules.isDynamicTarget(target) &&
        !_isObjectProperty(target, node.propertyName)) {
      _recordDynamicInvoke(node, target);
    }
    node.visitChildren(this);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final target = node.prefix;
    if (rules.isDynamicTarget(target) &&
        !_isObjectProperty(target, node.identifier)) {
      _recordDynamicInvoke(node, target);
    }
    node.visitChildren(this);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    // Check that defaults have the proper subtype.
    var parameter = node.parameter;
    var parameterType = rules.elementType(parameter.element);
    assert(parameterType != null);
    var defaultValue = node.defaultValue;
    if (defaultValue != null) {
      checkAssignment(defaultValue, parameterType);
    }

    node.visitChildren(this);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var element = node.element;
    var typeName = node.type;
    if (typeName != null) {
      var type = rules.elementType(element);
      var fieldElement =
          node.identifier.staticElement as FieldFormalParameterElement;
      var fieldType = rules.elementType(fieldElement.field);
      if (!rules.isSubTypeOf(type, fieldType)) {
        var staticInfo =
            new InvalidParameterDeclaration(rules, node, fieldType);
        _recordMessage(staticInfo);
      }
    }
    node.visitChildren(this);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var arguments = node.argumentList;
    var element = node.staticElement;
    if (element != null) {
      var type = rules.elementType(node.staticElement);
      checkArgumentList(arguments, type);
    }
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
      var dartType = getType(type);
      for (VariableDeclaration variable in node.variables) {
        var initializer = variable.initializer;
        if (initializer != null) {
          checkAssignment(initializer, dartType);
        }
      }
    }
    node.visitChildren(this);
  }

  void _checkRuntimeTypeCheck(AstNode node, TypeName typeName) {
    var type = getType(typeName);
    if (!rules.isGroundType(type)) {
      _recordMessage(new NonGroundTypeCheckInfo(node, type));
    }
  }

  @override
  void visitAsExpression(AsExpression node) {
    // We could do the same check as the IsExpression below, but that is
    // potentially too conservative.  Instead, at runtime, we must fail hard
    // if the Dart as and the DDC as would return different values.
    node.visitChildren(this);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _checkRuntimeTypeCheck(node, node.type);
    node.visitChildren(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.type == TokenType.BANG) {
      checkBoolean(node.operand);
    } else {
      _checkUnary(node);
    }
    node.visitChildren(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _checkUnary(node);
    node.visitChildren(this);
  }

  void _checkUnary(/*PrefixExpression|PostfixExpression*/ node) {
    var op = node.operator;
    if (op.isUserDefinableOperator ||
        op.type == TokenType.PLUS_PLUS ||
        op.type == TokenType.MINUS_MINUS) {
      if (rules.isDynamicTarget(node.operand)) {
        _recordDynamicInvoke(node, node.operand);
      }
      // For ++ and --, even if it is not dynamic, we still need to check
      // that the user defined method accepts an `int` as the RHS.
      // We assume Analyzer has done this already.
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var op = node.operator;
    if (op.isUserDefinableOperator) {
      if (rules.isDynamicTarget(node.leftOperand)) {
        // Dynamic invocation
        // TODO(vsm): Move this logic to the resolver?
        if (op.type != TokenType.EQ_EQ && op.type != TokenType.BANG_EQ) {
          _recordDynamicInvoke(node, node.leftOperand);
        }
      } else {
        var element = node.staticElement;
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
  void visitConditionalExpression(ConditionalExpression node) {
    checkBoolean(node.condition);
    node.visitChildren(this);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    var target = node.realTarget;
    if (rules.isDynamicTarget(target)) {
      _recordDynamicInvoke(node, target);
    } else {
      var element = node.staticElement;
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
    }
    node.visitChildren(this);
  }

  DartType getType(TypeName name) {
    return (name == null) ? rules.provider.dynamicType : name.type;
  }

  /// Analyzer checks boolean conversions, but we need to check too, because
  /// it uses the default assignability rules that allow `dynamic` and `Object`
  /// to be assigned to bool with no message.
  void checkBoolean(Expression expr) =>
      checkAssignment(expr, rules.provider.boolType);

  void checkAssignment(Expression expr, DartType type) {
    if (expr is ParenthesizedExpression) {
      checkAssignment(expr.expression, type);
    } else {
      _recordMessage(rules.checkAssignment(expr, type));
    }
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
        if (t1 == rules.provider.intType &&
            t2 == rules.provider.intType) return t1;
        if (t1 == rules.provider.doubleType &&
            t2 == rules.provider.doubleType) return t1;
        // This particular combo is not spelled out in the spec, but all
        // implementations and analyzer seem to follow this.
        if (t1 == rules.provider.doubleType &&
            t2 == rules.provider.intType) return t1;
    }
    return normalReturnType;
  }

  void _checkCompoundAssignment(AssignmentExpression expr) {
    var op = expr.operator.type;
    assert(op.isAssignmentOperator && op != TokenType.EQ);
    var methodElement = expr.staticElement;
    if (methodElement == null) {
      // Dynamic invocation
      _recordDynamicInvoke(expr, expr.leftHandSide);
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
      var rhsType = _getStaticType(expr.rightHandSide);
      var lhsType = _getStaticType(expr.leftHandSide);
      var returnType = _specializedBinaryReturnType(
          op, lhsType, rhsType, functionType.returnType);

      if (!rules.isSubTypeOf(returnType, lhsType)) {
        final numType = rules.provider.numType;
        // Try to fix up the numerical case if possible.
        if (rules.isSubTypeOf(lhsType, numType) &&
            rules.isSubTypeOf(lhsType, rhsType)) {
          // This is also slightly different from spec, but allows us to keep
          // compound operators in the int += num and num += dynamic cases.
          staticInfo = DownCast.create(
              rules, expr.rightHandSide, Coercion.cast(rhsType, lhsType));
          rhsType = lhsType;
        } else {
          // Static type error
          staticInfo = new StaticTypeError(rules, expr, lhsType);
        }
        _recordMessage(staticInfo);
      }

      // Check the rhs type
      if (staticInfo is! CoercionInfo) {
        var paramType = paramTypes.first;
        staticInfo = rules.checkAssignment(expr.rightHandSide, paramType);
        _recordMessage(staticInfo);
      }
    }
  }

  bool _isObjectGetter(Expression target, SimpleIdentifier id) {
    PropertyAccessorElement element =
        rules.provider.objectType.element.getGetter(id.name);
    return (element != null && !element.isStatic);
  }

  bool _isObjectMethod(Expression target, SimpleIdentifier id) {
    MethodElement element =
        rules.provider.objectType.element.getMethod(id.name);
    return (element != null && !element.isStatic);
  }

  bool _isObjectProperty(Expression target, SimpleIdentifier id) {
    return _isObjectGetter(target, id) || _isObjectMethod(target, id);
  }

  DartType _getStaticType(Expression expr) {
    return expr.staticType ?? rules.provider.dynamicType;
  }

  void _recordDynamicInvoke(AstNode node, AstNode target) {
    if (_hints) {
      reporter.onError(new DynamicInvoke(rules, node).toAnalysisError());
    }
    // TODO(jmesserly): we may eventually want to record if the whole operation
    // (node) was dynamic, rather than the target, but this is an easier fit
    // with what we used to do.
    DynamicInvoke.set(target, true);
  }

  void _recordMessage(StaticInfo info) {
    if (info == null) return;
    var error = info.toAnalysisError();

    var severity = error.errorCode.errorSeverity;
    if (severity == ErrorSeverity.ERROR) _failure = true;
    if (severity != ErrorSeverity.INFO || _hints) {
      reporter.onError(error);
    }

    if (info is CoercionInfo) {
      // TODO(jmesserly): if we're run again on the same AST, we'll produce the
      // same annotations. This should be harmless. This might go away once
      // CodeChecker is integrated better with analyzer, as it will know that
      // checking has already been performed.
      // assert(CoercionInfo.get(info.node) == null);
      CoercionInfo.set(info.node, info);
    }
  }
}

/// Looks up the declaration that matches [member] in [type] and returns it's
/// declared type.
FunctionType _getMemberType(InterfaceType type, ExecutableElement member) =>
    _memberTypeGetter(member)(type);

typedef FunctionType _MemberTypeGetter(InterfaceType type);

_MemberTypeGetter _memberTypeGetter(ExecutableElement member) {
  String memberName = member.name;
  final isGetter = member is PropertyAccessorElement && member.isGetter;
  final isSetter = member is PropertyAccessorElement && member.isSetter;

  FunctionType f(InterfaceType type) {
    ExecutableElement baseMethod;
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
  ;
  return f;
}
