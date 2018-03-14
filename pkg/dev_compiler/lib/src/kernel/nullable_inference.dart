// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/type_environment.dart';
import 'js_typerep.dart';
import 'kernel_helpers.dart';

/// Determines whether a given expression [isNullable].
///
/// This class can also analyze the nullability of local variables, if
/// [enterFunction] and [exitFunction] are used.
class NullableInference extends ExpressionVisitor<bool> {
  final TypeEnvironment types;
  final JSTypeRep jsTypeRep;
  final CoreTypes coreTypes;

  /// Whether `@notNull` and `@nullCheck` declarations are honored.
  ///
  /// This is set when compiling the SDK and in tests. Even when set to `false`,
  /// non-SDK code will still benefit from `@notNull` annotations declared on
  /// SDK APIs.
  ///
  /// Since `@notNull` cannot be imported by user code, this flag is only
  /// a performance optimization, so we don't spend time looking for
  /// annotations that cannot exist in user code.
  bool allowNotNullDeclarations = false;

  /// Allows `@notNull` and `@nullCheck` to be declared in `package:meta`
  /// instead of requiring a private SDK library.
  ///
  /// This is currently used by tests, in conjunction with
  /// [allowNotNullDeclarations].
  bool allowPackageMetaAnnotations = false;

  final _variableInference = new _NullableVariableInference();

  NullableInference(this.jsTypeRep)
      : types = jsTypeRep.types,
        coreTypes = jsTypeRep.coreTypes {
    _variableInference._nullInference = this;
  }

  /// Call when entering a function to enable [isNullable] to recognize local
  /// variables that cannot be null.
  void enterFunction(FunctionNode fn) => _variableInference.enterFunction(fn);

  /// Call when exiting a function to clear out the information recorded by
  /// [enterFunction].
  void exitFunction(FunctionNode fn) => _variableInference.exitFunction(fn);

  /// Returns true if [expr] can be null.
  bool isNullable(Expression expr) =>
      expr != null ? expr.accept(this) as bool : false;

  @override
  defaultExpression(Expression node) => true;

  @override
  defaultBasicLiteral(BasicLiteral node) => false;

  @override
  visitNullLiteral(NullLiteral node) => true;

  @override
  visitVariableGet(VariableGet node) {
    return _variableInference.variableIsNullable(node.variable);
  }

  @override
  visitVariableSet(VariableSet node) => isNullable(node.value);

  @override
  visitPropertyGet(PropertyGet node) => _getterIsNullable(node.interfaceTarget);

  @override
  visitPropertySet(PropertySet node) => isNullable(node.value);

  @override
  visitDirectPropertyGet(DirectPropertyGet node) =>
      _getterIsNullable(node.target);

  @override
  visitDirectPropertySet(DirectPropertySet node) => isNullable(node.value);

  @override
  visitSuperPropertyGet(SuperPropertyGet node) =>
      _getterIsNullable(node.interfaceTarget);

  @override
  visitSuperPropertySet(SuperPropertySet node) => isNullable(node.value);

  @override
  visitStaticGet(StaticGet node) => _getterIsNullable(node.target);

  @override
  visitStaticSet(StaticSet node) => isNullable(node.value);

  @override
  visitMethodInvocation(MethodInvocation node) =>
      _invocationIsNullable(node.interfaceTarget, node.receiver);

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) =>
      _invocationIsNullable(node.target, node.receiver);

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) =>
      _invocationIsNullable(node.interfaceTarget);

  bool _invocationIsNullable(Member target, [Expression receiver]) {
    if (target == null) return true;
    if (target.name.name == 'toString' &&
        receiver != null &&
        receiver.getStaticType(types) == coreTypes.stringClass.rawType) {
      // TODO(jmesserly): `class String` in dart:core does not explicitly
      // declare `toString`, which results in a target of `Object.toString` even
      // when the reciever type is known to be `String`. So we work around it.
      // (The Analyzer backend of DDC probably has the same issue.)
      return false;
    }
    return _returnValueIsNullable(target);
  }

  bool _getterIsNullable(Member target) {
    if (target == null) return true;
    // tear-offs are not null
    if (target is Procedure && !target.isAccessor) return false;
    return _returnValueIsNullable(target);
  }

  bool _returnValueIsNullable(Member target) {
    // TODO(jmesserly): this is not a valid assumption for user-defined equality
    // but it is added to match the behavior of the Analyzer backend.
    // https://github.com/dart-lang/sdk/issues/31854
    if (target.name.name == '==') return false;

    var targetClass = target.enclosingClass;
    if (targetClass != null) {
      // Convert `int` `double` `num` `String` and `bool` to their corresponding
      // implementation class in dart:_interceptors, for example `JSString`.
      //
      // This allows us to find the `@notNull` annotation if it exists.
      var implClass = jsTypeRep.getImplementationClass(targetClass.rawType);
      if (implClass != null) {
        var member = types.hierarchy.getDispatchTarget(implClass, target.name);
        if (member != null) target = member;
      }
    }

    // If the method or function is annotated as returning a non-null value
    // then the result of the call is non-null.
    var annotations = target.annotations;
    if (annotations.isNotEmpty && annotations.any(isNotNullAnnotation)) {
      return false;
    }
    return true;
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    var target = node.target;
    if (target == types.coreTypes.identicalProcedure) return false;
    if (isInlineJS(target)) {
      var args = node.arguments.positional;
      var first = args.isNotEmpty ? args.first : null;
      if (first is StringLiteral) {
        var types = first.value;
        return types == '' ||
            types == 'var' ||
            types.split('|').contains('Null');
      }
    }
    return _invocationIsNullable(target);
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) => false;

  @override
  visitNot(Not node) => false;

  @override
  visitLogicalExpression(LogicalExpression node) => false;

  @override
  visitConditionalExpression(ConditionalExpression node) =>
      isNullable(node.then) || isNullable(node.otherwise);

  @override
  visitStringConcatenation(StringConcatenation node) => false;

  @override
  visitIsExpression(IsExpression node) => false;

  @override
  visitAsExpression(AsExpression node) => isNullable(node.operand);

  @override
  visitSymbolLiteral(SymbolLiteral node) => false;

  @override
  visitTypeLiteral(TypeLiteral node) => false;

  @override
  visitThisExpression(ThisExpression node) => false;

  @override
  visitRethrow(Rethrow node) => false;

  @override
  visitThrow(Throw node) => false;

  @override
  visitListLiteral(ListLiteral node) => false;

  @override
  visitMapLiteral(MapLiteral node) => false;

  @override
  visitAwaitExpression(AwaitExpression node) => true;

  @override
  visitFunctionExpression(FunctionExpression node) => false;

  @override
  visitConstantExpression(ConstantExpression node) {
    var c = node.constant;
    return c is PrimitiveConstant && c.value == null;
  }

  @override
  visitLet(Let node) => isNullable(node.body);

  @override
  visitInstantiation(Instantiation node) => false;

  bool isNotNullAnnotation(Expression value) =>
      _isInternalAnnotationField(value, 'notNull');

  bool isNullCheckAnnotation(Expression value) =>
      _isInternalAnnotationField(value, 'nullCheck');

  bool _isInternalAnnotationField(Expression value, String name) {
    if (value is StaticGet) {
      var t = value.target;
      if (t is Field && t.name.name == name) {
        var uri = t.enclosingLibrary.importUri;
        return uri.scheme == 'dart' && uri.pathSegments[0] == '_js_helper' ||
            allowPackageMetaAnnotations &&
                uri.scheme == 'package' &&
                uri.pathSegments[0] == 'meta';
      }
    }
    return false;
  }
}

/// A visitor that determines which local variables cannot be null using
/// flow-insensitive inference.
///
/// The entire body of a function (including any local functions) is visited
/// recursively, and we collect variables that are tentatively believed to be
/// not-null. If the assumption turns out to be incorrect (based on a later
/// assignment of a nullable value), we remove it from the not-null set, along
/// with any variable it was assigned to.
///
/// This does not track nullable locals, so we can avoid doing work on any
/// variables that have already been determined to be nullable.
///
// TODO(jmesserly): Introduce flow analysis.
class _NullableVariableInference extends RecursiveVisitor<void> {
  NullableInference _nullInference;

  /// Variables that are currently believed to be not-null.
  final _notNullLocals = new HashSet<VariableDeclaration>.identity();

  /// For each variable currently believed to be not-null ([_notNullLocals]),
  /// this collects variables that it is assigned to, so we update them if we
  /// later determine that the variable can be null.
  final _assignedTo =
      new HashMap<VariableDeclaration, List<VariableDeclaration>>.identity();

  /// All functions that have been analyzed with [analyzeFunction].
  ///
  /// In practice this will include the outermost function (typically a
  /// [Procedure]) as well as an local functions it contains.
  final _functions = new HashSet<FunctionNode>.identity();

  /// The current variable we are setting/initializing, so we can track if it
  /// is [_assignedTo] from another variable.
  VariableDeclaration _variableAssignedTo;

  void enterFunction(FunctionNode node) {
    if (_functions.contains(node)) return; // local function already analyzed.
    visitFunctionNode(node);
    _assignedTo.clear();
  }

  void exitFunction(FunctionNode node) {
    var removed = _functions.remove(node);
    assert(removed);
    if (_functions.isEmpty) _notNullLocals.clear();
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    _notNullLocals.add(node.variable);
    node.function?.accept(this);
  }

  @override
  visitFunctionNode(FunctionNode node) {
    _functions.add(node);
    if (_nullInference.allowNotNullDeclarations) {
      visitList(node.positionalParameters, this);
      visitList(node.namedParameters, this);
    }
    node.body?.accept(this);
  }

  @override
  visitCatch(Catch node) {
    // The stack trace variable is not nullable, but the exception can be.
    var stackTrace = node.stackTrace;
    if (stackTrace != null) _notNullLocals.add(stackTrace);
    super.visitCatch(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (_nullInference.allowNotNullDeclarations) {
      var annotations = node.annotations;
      if (annotations.isNotEmpty &&
          (annotations.any(_nullInference.isNotNullAnnotation) ||
              annotations.any(_nullInference.isNullCheckAnnotation))) {
        _notNullLocals.add(node);
      }
    }
    var initializer = node.initializer;
    if (initializer != null) {
      var savedVariable = _variableAssignedTo;
      _variableAssignedTo = node;

      if (!_nullInference.isNullable(initializer)) _notNullLocals.add(node);

      _variableAssignedTo = savedVariable;
    }
    initializer?.accept(this);
  }

  @override
  visitVariableGet(VariableGet node) {}

  @override
  visitVariableSet(VariableSet node) {
    var variable = node.variable;
    var value = node.value;
    if (_notNullLocals.contains(variable)) {
      var savedVariable = _variableAssignedTo;
      _variableAssignedTo = variable;

      if (_nullInference.isNullable(node.value)) {
        markNullable(VariableDeclaration v) {
          _notNullLocals.remove(v);
          _assignedTo.remove(v)?.forEach(markNullable);
        }

        markNullable(variable);
      }

      _variableAssignedTo = savedVariable;
    }
    value.accept(this);
  }

  bool variableIsNullable(VariableDeclaration variable) {
    if (_notNullLocals.contains(variable)) {
      if (_variableAssignedTo != null) {
        _assignedTo.putIfAbsent(variable, () => []).add(_variableAssignedTo);
      }
      return false;
    }
    return true;
  }
}
