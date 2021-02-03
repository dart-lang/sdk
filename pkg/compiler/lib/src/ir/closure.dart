// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/src/printer.dart' as ir;
import 'package:kernel/text/ast_to_text.dart' as ir show debugNodeToString;

/// Collection of scope data collected for a single member.
class ClosureScopeModel {
  /// Collection [ScopeInfo] data for the member.
  KernelScopeInfo scopeInfo;

  /// Collected [CapturedScope] data for nodes.
  Map<ir.Node, KernelCapturedScope> capturedScopesMap =
      <ir.Node, KernelCapturedScope>{};

  /// Collected [ScopeInfo] data for nodes.
  Map<ir.LocalFunction, KernelScopeInfo> closuresToGenerate =
      <ir.LocalFunction, KernelScopeInfo>{};

  @override
  String toString() {
    return '$scopeInfo\n$capturedScopesMap\n$closuresToGenerate';
  }
}

class KernelScopeInfo {
  final Set<ir.VariableDeclaration> localsUsedInTryOrSync;
  final bool hasThisLocal;
  final Set<ir.VariableDeclaration> boxedVariables;
  // If boxedVariables is empty, this will be null, because no variables will
  // need to be boxed.
  final NodeBox capturedVariablesAccessor;

  /// The set of variables that were defined in another scope, but are used in
  /// this scope. The items in this set are either of type VariableDeclaration
  /// or TypeParameterTypeWithContext.
  Set<ir.Node /* VariableDeclaration | TypeParameterTypeWithContext */ >
      freeVariables = new Set<ir.Node>();

  /// A set of type parameters that are defined in another scope and are only
  /// used if runtime type information is checked. If runtime type information
  /// needs to be retained, all of these type variables will be added ot the
  /// freeVariables set. Whether these variables are actually used as
  /// freeVariables will be set by the time this structure is converted to a
  /// JsScopeInfo, so JsScopeInfo does not need to use them.
  Map<TypeVariableTypeWithContext, Set<VariableUse>> freeVariablesForRti =
      <TypeVariableTypeWithContext, Set<VariableUse>>{};

  /// If true, `this` is used as a free variable, in this scope. It is stored
  /// separately from [freeVariables] because there is no single
  /// `VariableDeclaration` node that represents `this`.
  bool thisUsedAsFreeVariable = false;

  /// If true, `this` is used as a free variable, in this scope if we are also
  /// performing runtime type checks. It is stored
  /// separately from [thisUsedAsFreeVariable] because we don't know at this
  /// stage if we will be needing type checks for this scope.
  Set<VariableUse> thisUsedAsFreeVariableIfNeedsRti = new Set<VariableUse>();

  KernelScopeInfo(this.hasThisLocal)
      : localsUsedInTryOrSync = new Set<ir.VariableDeclaration>(),
        boxedVariables = new Set<ir.VariableDeclaration>(),
        capturedVariablesAccessor = null;

  KernelScopeInfo.from(this.hasThisLocal, KernelScopeInfo info)
      : localsUsedInTryOrSync = info.localsUsedInTryOrSync,
        boxedVariables = info.boxedVariables,
        capturedVariablesAccessor = null;

  KernelScopeInfo.withBoxedVariables(
      this.boxedVariables,
      this.capturedVariablesAccessor,
      this.localsUsedInTryOrSync,
      this.freeVariables,
      this.freeVariablesForRti,
      this.thisUsedAsFreeVariable,
      this.thisUsedAsFreeVariableIfNeedsRti,
      this.hasThisLocal);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('KernelScopeInfo(this=$hasThisLocal,');
    sb.write('freeVriables=$freeVariables,');
    sb.write('localsUsedInTryOrSync={${localsUsedInTryOrSync.join(', ')}}');
    String comma = '';
    sb.write('freeVariablesForRti={');
    freeVariablesForRti.forEach((key, value) {
      sb.write('$comma$key:$value');
      comma = ',';
    });
    sb.write('})');
    return sb.toString();
  }
}

class KernelCapturedScope extends KernelScopeInfo {
  KernelCapturedScope(
      Set<ir.VariableDeclaration> boxedVariables,
      NodeBox capturedVariablesAccessor,
      Set<ir.VariableDeclaration> localsUsedInTryOrSync,
      Set<ir.Node /* VariableDeclaration | TypeVariableTypeWithContext */ >
          freeVariables,
      Map<TypeVariableTypeWithContext, Set<VariableUse>> freeVariablesForRti,
      bool thisUsedAsFreeVariable,
      Set<VariableUse> thisUsedAsFreeVariableIfNeedsRti,
      bool hasThisLocal)
      : super.withBoxedVariables(
            boxedVariables,
            capturedVariablesAccessor,
            localsUsedInTryOrSync,
            freeVariables,
            freeVariablesForRti,
            thisUsedAsFreeVariable,
            thisUsedAsFreeVariableIfNeedsRti,
            hasThisLocal);

  // Loops through the free variables of an existing KernelCapturedScope and
  // creates a new KernelCapturedScope that only captures type variables.
  KernelCapturedScope.forSignature(KernelCapturedScope scope)
      : this(
            _empty,
            null,
            _empty,
            scope.freeVariables.where(
                (ir.Node variable) => variable is TypeVariableTypeWithContext),
            scope.freeVariablesForRti,
            scope.thisUsedAsFreeVariable,
            scope.thisUsedAsFreeVariableIfNeedsRti,
            scope.hasThisLocal);

  // Silly hack because we don't have const sets.
  static final Set<ir.VariableDeclaration> _empty = new Set();

  bool get requiresContextBox => boxedVariables.isNotEmpty;
}

class KernelCapturedLoopScope extends KernelCapturedScope {
  final List<ir.VariableDeclaration> boxedLoopVariables;

  KernelCapturedLoopScope(
      Set<ir.VariableDeclaration> boxedVariables,
      NodeBox capturedVariablesAccessor,
      this.boxedLoopVariables,
      Set<ir.VariableDeclaration> localsUsedInTryOrSync,
      Set<ir.Node /* VariableDeclaration | TypeVariableTypeWithContext */ >
          freeVariables,
      Map<TypeVariableTypeWithContext, Set<VariableUse>> freeVariablesForRti,
      bool thisUsedAsFreeVariable,
      Set<VariableUse> thisUsedAsFreeVariableIfNeedsRti,
      bool hasThisLocal)
      : super(
            boxedVariables,
            capturedVariablesAccessor,
            localsUsedInTryOrSync,
            freeVariables,
            freeVariablesForRti,
            thisUsedAsFreeVariable,
            thisUsedAsFreeVariableIfNeedsRti,
            hasThisLocal);

  bool get hasBoxedLoopVariables => boxedLoopVariables.isNotEmpty;
}

/// A local variable to disambiguate between a variable that has been captured
/// from one scope to another. This is the ir.Node version that corresponds to
/// [BoxLocal].
class NodeBox {
  final String name;
  final ir.TreeNode executableContext;
  NodeBox(this.name, this.executableContext);
}

enum VariableUseKind {
  /// An explicit variable use.
  ///
  /// For type variable this is an explicit as-cast, an is-test or a type
  /// literal.
  explicit,

  /// A type variable used in the type of a local variable.
  localType,

  /// A type variable used in an implicit cast.
  implicitCast,

  /// A type variable passed as the type argument of a list literal.
  listLiteral,

  /// A type variable passed as the type argument of a set literal.
  setLiteral,

  /// A type variable passed as the type argument of a map literal.
  mapLiteral,

  /// A type variable passed as a type argument to a constructor.
  constructorTypeArgument,

  /// A type variable passed as a type argument to a static method.
  staticTypeArgument,

  /// A type variable passed as a type argument to an instance method.
  instanceTypeArgument,

  /// A type variable passed as a type argument to a local function.
  localTypeArgument,

  /// A type variable in a parameter type of a member.
  memberParameter,

  /// A type variable in a parameter type of a local function.
  localParameter,

  /// A type variable used in a return type of a member.
  memberReturnType,

  /// A type variable used in a return type of a local function.
  localReturnType,

  /// A type variable in a field type.
  fieldType,

  /// A type argument of an generic instantiation.
  instantiationTypeArgument,
}

class VariableUse {
  final VariableUseKind kind;
  final ir.Member member;
  final ir.LocalFunction localFunction;
  final ir.MethodInvocation invocation;
  final ir.Instantiation instantiation;

  const VariableUse._simple(this.kind)
      : this.member = null,
        this.localFunction = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.memberParameter(this.member)
      : this.kind = VariableUseKind.memberParameter,
        this.localFunction = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.localParameter(this.localFunction)
      : this.kind = VariableUseKind.localParameter,
        this.member = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.memberReturnType(this.member)
      : this.kind = VariableUseKind.memberReturnType,
        this.localFunction = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.localReturnType(this.localFunction)
      : this.kind = VariableUseKind.localReturnType,
        this.member = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.constructorTypeArgument(this.member)
      : this.kind = VariableUseKind.constructorTypeArgument,
        this.localFunction = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.staticTypeArgument(this.member)
      : this.kind = VariableUseKind.staticTypeArgument,
        this.localFunction = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.instanceTypeArgument(this.invocation)
      : this.kind = VariableUseKind.instanceTypeArgument,
        this.member = null,
        this.localFunction = null,
        this.instantiation = null;

  VariableUse.localTypeArgument(this.localFunction, this.invocation)
      : this.kind = VariableUseKind.localTypeArgument,
        this.member = null,
        this.instantiation = null;

  VariableUse.instantiationTypeArgument(this.instantiation)
      : this.kind = VariableUseKind.instantiationTypeArgument,
        this.member = null,
        this.localFunction = null,
        this.invocation = null;

  static const VariableUse explicit =
      const VariableUse._simple(VariableUseKind.explicit);

  static const VariableUse localType =
      const VariableUse._simple(VariableUseKind.localType);

  static const VariableUse implicitCast =
      const VariableUse._simple(VariableUseKind.implicitCast);

  static const VariableUse listLiteral =
      const VariableUse._simple(VariableUseKind.listLiteral);

  static const VariableUse setLiteral =
      const VariableUse._simple(VariableUseKind.setLiteral);

  static const VariableUse mapLiteral =
      const VariableUse._simple(VariableUseKind.mapLiteral);

  static const VariableUse fieldType =
      const VariableUse._simple(VariableUseKind.fieldType);

  @override
  int get hashCode =>
      kind.hashCode * 11 +
      member.hashCode * 13 +
      localFunction.hashCode * 17 +
      invocation.hashCode * 19 +
      instantiation.hashCode * 23;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! VariableUse) return false;
    return kind == other.kind &&
        member == other.member &&
        localFunction == other.localFunction &&
        invocation == other.invocation &&
        instantiation == other.instantiation;
  }

  @override
  String toString() => 'VariableUse(kind=$kind,member=$member,'
      'localFunction=$localFunction,invocation=$invocation,'
      'instantiation=$instantiation)';
}

enum TypeVariableKind { cls, method, local, function }

/// A fake ir.Node that holds the TypeParameterType as well as the context in
/// which it occurs.
class TypeVariableTypeWithContext implements ir.Node {
  final ir.Node context;
  final ir.TypeParameterType type;
  final TypeVariableKind kind;
  final ir.TreeNode typeDeclaration;

  /// [context] can be either an ir.Member or a ir.FunctionDeclaration or
  /// ir.FunctionExpression.
  factory TypeVariableTypeWithContext(
      ir.TypeParameterType type, ir.TreeNode context) {
    TypeVariableKind kind;
    ir.TreeNode typeDeclaration = type.parameter.parent;
    if (typeDeclaration == null) {
      // We have a function type variable, like `T` in `void Function<T>(int)`.
      kind = TypeVariableKind.function;
    } else if (typeDeclaration is ir.Class) {
      // We have a class type variable, like `T` in `class Class<T> { ... }`.
      kind = TypeVariableKind.cls;
    } else if (typeDeclaration.parent is ir.Member) {
      ir.Member member = typeDeclaration.parent;
      if (member is ir.Constructor ||
          (member is ir.Procedure && member.isFactory)) {
        // We have a synthesized generic method type variable for a class type
        // variable.
        // TODO(johnniwinther): Handle constructor/factory type variables as
        // method type variables.
        kind = TypeVariableKind.cls;
        typeDeclaration = member.enclosingClass;
      } else {
        // We have a generic method type variable, like `T` in
        // `m<T>() { ... }`.
        kind = TypeVariableKind.method;
        typeDeclaration = typeDeclaration.parent;
        context = typeDeclaration;
      }
    } else {
      // We have a generic local function type variable, like `T` in
      // `m() { local<T>() { ... } ... }`.
      assert(typeDeclaration.parent is ir.LocalFunction,
          "Unexpected type declaration: $typeDeclaration");
      kind = TypeVariableKind.local;
      typeDeclaration = typeDeclaration.parent;
      context = typeDeclaration;
    }
    return new TypeVariableTypeWithContext.internal(
        type, context, kind, typeDeclaration);
  }

  TypeVariableTypeWithContext.internal(
      this.type, this.context, this.kind, this.typeDeclaration);

  @override
  R accept<R>(ir.Visitor<R> v) {
    throw new UnsupportedError('TypeVariableTypeWithContext.accept');
  }

  @override
  visitChildren(ir.Visitor v) {
    throw new UnsupportedError('TypeVariableTypeWithContext.visitChildren');
  }

  @override
  int get hashCode => type.hashCode;

  @override
  bool operator ==(other) {
    if (other is! TypeVariableTypeWithContext) return false;
    return type == other.type && context == other.context;
  }

  @override
  String toString() => 'TypeVariableTypeWithContext(${toStringInternal()})';

  @override
  String toStringInternal() =>
      'type=${type.toStringInternal()},context=${context.toStringInternal()},'
      'kind=$kind,typeDeclaration=${typeDeclaration.toStringInternal()}';

  @override
  String toText(ir.AstTextStrategy strategy) => type.toText(strategy);

  @override
  void toTextInternal(ir.AstPrinter printer) => type.toTextInternal(printer);

  @override
  String leakingDebugToString() => ir.debugNodeToString(this);
}
