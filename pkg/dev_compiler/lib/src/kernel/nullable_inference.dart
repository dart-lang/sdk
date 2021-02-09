// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:collection';

import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/type_environment.dart';

import '../compiler/shared_command.dart' show SharedCompilerOptions;
import 'js_typerep.dart';
import 'kernel_helpers.dart';

/// Determines whether a given expression [isNullable].
///
/// This class can also analyze the nullability of local variables, if
/// [enterFunction] and [exitFunction] are used.
class NullableInference extends ExpressionVisitor<bool> {
  final StaticTypeContext _staticTypeContext;
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

  final _variableInference = _NullableVariableInference();

  final bool _soundNullSafety;

  NullableInference(this.jsTypeRep, this._staticTypeContext,
      {SharedCompilerOptions options})
      : coreTypes = jsTypeRep.coreTypes,
        _soundNullSafety = options?.soundNullSafety ?? false {
    _variableInference._nullInference = this;
  }

  /// Call when entering a function to enable [isNullable] to recognize local
  /// variables that cannot be null.
  void enterFunction(FunctionNode fn) {
    _variableInference.enterFunction(fn);
  }

  /// Call when exiting a function to clear out the information recorded by
  /// [enterFunction].
  void exitFunction(FunctionNode fn) {
    _variableInference.exitFunction(fn);
  }

  /// Returns true if [expr] can be null.
  bool isNullable(Expression expr) => expr != null ? expr.accept(this) : false;

  @override
  bool defaultExpression(Expression node) => true;

  @override
  bool defaultBasicLiteral(BasicLiteral node) => false;

  @override
  bool visitNullLiteral(NullLiteral node) => true;

  @override
  bool visitNullCheck(NullCheck node) {
    node.operand.accept(this);
    return false;
  }

  @override
  bool visitVariableGet(VariableGet node) {
    return _variableInference.variableIsNullable(node.variable);
  }

  @override
  bool visitVariableSet(VariableSet node) => isNullable(node.value);

  @override
  bool visitPropertyGet(PropertyGet node) =>
      _getterIsNullable(node.interfaceTarget, node);

  @override
  bool visitInstanceGet(InstanceGet node) =>
      _getterIsNullable(node.interfaceTarget, node);

  @override
  bool visitDynamicGet(DynamicGet node) => _getterIsNullable(null, node);

  @override
  bool visitInstanceTearOff(InstanceTearOff node) =>
      _getterIsNullable(node.interfaceTarget, node);

  @override
  bool visitFunctionTearOff(FunctionTearOff node) =>
      _getterIsNullable(null, node);

  @override
  bool visitPropertySet(PropertySet node) => isNullable(node.value);

  @override
  bool visitInstanceSet(InstanceSet node) => isNullable(node.value);

  @override
  bool visitDynamicSet(DynamicSet node) => isNullable(node.value);

  @override
  bool visitSuperPropertyGet(SuperPropertyGet node) =>
      _getterIsNullable(node.interfaceTarget, node);

  @override
  bool visitSuperPropertySet(SuperPropertySet node) => isNullable(node.value);

  @override
  bool visitStaticGet(StaticGet node) => _getterIsNullable(node.target, node);

  @override
  bool visitStaticTearOff(StaticTearOff node) =>
      _getterIsNullable(node.target, node);

  @override
  bool visitStaticSet(StaticSet node) => isNullable(node.value);

  @override
  bool visitMethodInvocation(MethodInvocation node) => _invocationIsNullable(
      node.interfaceTarget, node.name.text, node, node.receiver);

  @override
  bool visitInstanceInvocation(InstanceInvocation node) =>
      _invocationIsNullable(
          node.interfaceTarget, node.name.text, node, node.receiver);

  @override
  bool visitDynamicInvocation(DynamicInvocation node) =>
      _invocationIsNullable(null, node.name.text, node, node.receiver);

  @override
  bool visitFunctionInvocation(FunctionInvocation node) =>
      _invocationIsNullable(null, 'call', node, node.receiver);

  @override
  bool visitLocalFunctionInvocation(LocalFunctionInvocation node) =>
      _invocationIsNullable(null, 'call', node, VariableGet(node.variable));

  @override
  bool visitEqualsNull(EqualsNull node) => false;

  @override
  bool visitEqualsCall(EqualsCall node) => false;

  @override
  bool visitSuperMethodInvocation(SuperMethodInvocation node) =>
      _invocationIsNullable(node.interfaceTarget, node.name.text, node);

  bool _invocationIsNullable(
      Member target, String name, InvocationExpression node,
      [Expression receiver]) {
    // TODO(jmesserly): this is not a valid assumption for user-defined equality
    // but it is added to match the behavior of the Analyzer backend.
    // https://github.com/dart-lang/sdk/issues/31854
    if (name == '==') return false;
    if (_staticallyNonNullable(node.getStaticType(_staticTypeContext))) {
      return false;
    }
    if (target == null) return true; // dynamic call
    if (target.name.text == 'toString' &&
        receiver != null &&
        receiver.getStaticType(_staticTypeContext) ==
            coreTypes.stringLegacyRawType) {
      // TODO(jmesserly): `class String` in dart:core does not explicitly
      // declare `toString`, which results in a target of `Object.toString` even
      // when the receiver type is known to be `String`. So we work around it.
      // (The Analyzer backend of DDC probably has the same issue.)
      return false;
    }
    return _returnValueIsNullable(target);
  }

  bool _getterIsNullable(Member target, Expression node) {
    if (_staticallyNonNullable(node.getStaticType(_staticTypeContext))) {
      return false;
    }
    if (target == null) return true;
    // tear-offs are not null
    if (target is Procedure && !target.isAccessor) return false;
    return _returnValueIsNullable(target);
  }

  bool _staticallyNonNullable(DartType type) =>
      _soundNullSafety &&
      type != null &&
      type.nullability == Nullability.nonNullable;

  bool _returnValueIsNullable(Member target) {
    var targetClass = target.enclosingClass;
    if (targetClass != null) {
      // Convert `int` `double` `num` `String` and `bool` to their corresponding
      // implementation class in dart:_interceptors, for example `JSString`.
      //
      // This allows us to find the `@notNull` annotation if it exists.
      var implClass = jsTypeRep
          .getImplementationClass(coreTypes.legacyRawType(targetClass));
      if (implClass != null) {
        var member =
            jsTypeRep.hierarchy.getDispatchTarget(implClass, target.name);
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
  bool visitStaticInvocation(StaticInvocation node) {
    var target = node.target;
    if (target == coreTypes.identicalProcedure) {
      return false;
    }
    if (isInlineJS(target)) {
      var args = node.arguments.positional;
      var first = args.isNotEmpty ? args.first : null;
      if (first is StringLiteral) {
        var typeString = first.value;
        return typeString == '' ||
            typeString == 'var' ||
            typeString.split('|').contains('Null');
      }
    }
    return _invocationIsNullable(target, node.name.text, node);
  }

  @override
  bool visitConstructorInvocation(ConstructorInvocation node) => false;

  @override
  bool visitNot(Not node) => false;

  @override
  bool visitLogicalExpression(LogicalExpression node) => false;

  @override
  bool visitConditionalExpression(ConditionalExpression node) =>
      isNullable(node.then) || isNullable(node.otherwise);

  @override
  bool visitStringConcatenation(StringConcatenation node) => false;

  @override
  bool visitIsExpression(IsExpression node) => false;

  @override
  bool visitAsExpression(AsExpression node) =>
      _staticallyNonNullable(node.getStaticType(_staticTypeContext))
          ? false
          : isNullable(node.operand);

  @override
  bool visitSymbolLiteral(SymbolLiteral node) => false;

  @override
  bool visitTypeLiteral(TypeLiteral node) => false;

  @override
  bool visitThisExpression(ThisExpression node) => false;

  @override
  bool visitRethrow(Rethrow node) => false;

  @override
  bool visitThrow(Throw node) => false;

  @override
  bool visitListLiteral(ListLiteral node) => false;

  @override
  bool visitMapLiteral(MapLiteral node) => false;

  @override
  bool visitAwaitExpression(AwaitExpression node) =>
      !_staticallyNonNullable(node.getStaticType(_staticTypeContext));

  @override
  bool visitFunctionExpression(FunctionExpression node) => false;

  @override
  bool visitConstantExpression(ConstantExpression node) {
    var c = node.constant;
    if (c is UnevaluatedConstant) return c.expression.accept(this);
    if (c is PrimitiveConstant) return c.value == null;
    return false;
  }

  @override
  bool visitLet(Let node) => isNullable(node.body);

  @override
  bool visitBlockExpression(BlockExpression node) => isNullable(node.value);

  @override
  bool visitInstantiation(Instantiation node) => false;

  bool isNotNullAnnotation(Expression value) =>
      _isInternalAnnotationField(value, 'notNull', '_NotNull');

  bool isNullCheckAnnotation(Expression value) =>
      _isInternalAnnotationField(value, 'nullCheck', '_NullCheck');

  bool _isInternalAnnotationField(
      Expression node, String fieldName, String className) {
    if (node is ConstantExpression) {
      var constant = node.constant;
      return constant is InstanceConstant &&
          constant.classNode.name == className &&
          _isInternalSdkAnnotation(constant.classNode.enclosingLibrary);
    }
    if (node is StaticGet) {
      var t = node.target;
      return t is Field &&
          t.name.text == fieldName &&
          _isInternalSdkAnnotation(t.enclosingLibrary);
    }
    return false;
  }

  bool _isInternalSdkAnnotation(Library library) {
    var uri = library.importUri;
    return uri.scheme == 'dart' && uri.pathSegments[0] == '_js_helper' ||
        allowPackageMetaAnnotations &&
            uri.scheme == 'package' &&
            uri.pathSegments[0] == 'meta';
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
  final _notNullLocals = HashSet<VariableDeclaration>.identity();

  /// For each variable currently believed to be not-null ([_notNullLocals]),
  /// this collects variables that it is assigned to, so we update them if we
  /// later determine that the variable can be null.
  final _assignedTo =
      HashMap<VariableDeclaration, List<VariableDeclaration>>.identity();

  /// All functions that have been analyzed with [analyzeFunction].
  ///
  /// In practice this will include the outermost function (typically a
  /// [Procedure]) as well as an local functions it contains.
  final _functions = HashSet<FunctionNode>.identity();

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
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _notNullLocals.add(node.variable);
    node.function?.accept(this);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    _functions.add(node);
    if (_nullInference.allowNotNullDeclarations ||
        _nullInference._soundNullSafety) {
      visitList(node.positionalParameters, this);
      visitList(node.namedParameters, this);
    }
    node.body?.accept(this);
  }

  @override
  void visitCatch(Catch node) {
    // The stack trace variable is not nullable, but the exception can be.
    var stackTrace = node.stackTrace;
    if (stackTrace != null) _notNullLocals.add(stackTrace);
    super.visitCatch(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (_nullInference.allowNotNullDeclarations) {
      var annotations = node.annotations;
      if (annotations.isNotEmpty &&
          (annotations.any(_nullInference.isNotNullAnnotation) ||
              annotations.any(_nullInference.isNullCheckAnnotation))) {
        _notNullLocals.add(node);
      }
    }
    var initializer = node.initializer;
    if (_nullInference._soundNullSafety &&
        node.type.nullability == Nullability.nonNullable) {
      // Avoid null checks for variables when the type system guarantees they
      // can never be null.
      _notNullLocals.add(node);
    } else if (node.parent is! FunctionNode) {
      // A variable declaration with a FunctionNode as a parent is a function
      // parameter so we can't trust the initializer as a nullable check.
      if (initializer != null) {
        var savedVariable = _variableAssignedTo;
        _variableAssignedTo = node;

        if (!_nullInference.isNullable(initializer)) _notNullLocals.add(node);

        _variableAssignedTo = savedVariable;
      }
    }
    initializer?.accept(this);
  }

  @override
  void visitVariableGet(VariableGet node) {}

  @override
  void visitVariableSet(VariableSet node) {
    var variable = node.variable;
    var value = node.value;
    if (_notNullLocals.contains(variable)) {
      var savedVariable = _variableAssignedTo;
      _variableAssignedTo = variable;

      if (_nullInference.isNullable(node.value)) {
        void markNullable(VariableDeclaration v) {
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
