// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/declaration_builders.dart';
import '../builder/variable_builder.dart';
import 'lookup_result.dart';
import 'scope.dart';

enum LocalScopeKind {
  /// Outermost immutable local scope derived from a [LookupScope].
  enclosing,

  /// Scope of pattern switch-case statements
  ///
  /// These scopes receive special treatment in that they are end-points of the
  /// scope stack in presence of multiple heads for the same case, but can have
  /// nested scopes if it's just a single head. In that latter possibility the
  /// body of the case is nested into the scope of the case head. And for switch
  /// expressions that scope includes both the head and the case expression.
  caseHead,

  /// Scope where the formal parameters of a function are declared
  formals,

  /// Scope of a `for` statement
  forStatement,

  /// Scope of a function body
  functionBody,

  /// Scope of the head of the if-case statement
  ifCaseHead,

  /// Scope of an if-element in a collection
  ifElement,

  /// Scope for the initializers of generative constructors
  initializers,

  /// Scope where the joint variables of a switch case are declared
  jointVariables,

  /// Scope where labels of labelled statements are declared
  labels,

  /// The special scope of the named function expression
  ///
  /// This scope is treated separately because the named function expressions
  /// are allowed to be recursive, and the name of that function expression
  /// should be visible in the scope of the function itself.
  namedFunctionExpression,

  /// The scope of the RHS of a binary-or pattern
  ///
  /// It is utilized for separating the branch-local variables from the joint
  /// variables of the overall binary-or pattern.
  orPatternRight,

  /// The scope of a pattern
  ///
  /// It contains the variables associated with pattern variable declarations.
  pattern,

  /// Local scope of a statement, such as the body of a while loop
  statementLocalScope,

  /// Local scope of a switch block
  switchBlock,

  /// Scope for switch cases
  ///
  /// This scope kind is used in assertion checks.
  switchCase,

  /// Scope for switch case bodies
  ///
  /// This is used to handle local variables of switch cases.
  switchCaseBody,

  /// Scope for type parameters of declarations
  typeParameters,
}

abstract class LocalScope implements LookupScope {
  LocalScopeKind get kind;

  @override
  LookupResult? lookup(String name, {int fileOffset = -1});

  LocalScope createNestedScope({required LocalScopeKind kind});

  LocalScope createNestedFixedScope({
    required Map<String, VariableBuilder> local,
    required LocalScopeKind kind,
  });

  Iterable<VariableBuilder> get localVariables;

  VariableBuilder? lookupLocalVariable(String name);

  /// Declares that the meaning of [name] in this scope is [builder].
  ///
  /// If name was used previously in this scope, this method returns the read
  /// offsets which can be used for reporting a compile-time error about
  /// [name] being used before its declared.
  List<int>? declare(String name, VariableBuilder builder);

  Map<String, List<int>>? get usedNames;
}

abstract base class BaseLocalScope implements LocalScope {
  @override
  LocalScope createNestedScope({required LocalScopeKind kind}) {
    return new LocalScopeImpl(this, kind);
  }

  @override
  LocalScope createNestedFixedScope({
    required Map<String, VariableBuilder> local,
    required LocalScopeKind kind,
  }) {
    return new FixedLocalScope(kind: kind, parent: this, local: local);
  }
}

mixin LocalScopeMixin implements LocalScope {
  LocalScope? get _parent;

  Map<String, VariableBuilder>? get _local;

  @override
  Iterable<VariableBuilder> get localVariables => _local?.values ?? const [];

  @override
  LookupResult? lookup(String name, {int fileOffset = -1}) {
    _recordUse(name, fileOffset);
    return _local?[name] ?? _parent?.lookup(name, fileOffset: fileOffset);
  }

  @override
  VariableBuilder? lookupLocalVariable(String name) {
    return _local?[name];
  }

  void _recordUse(String name, int charOffset) {}
}

final class LocalScopeImpl extends BaseLocalScope
    with LocalScopeMixin
    implements LocalScope {
  @override
  final LocalScope? _parent;

  /// Names declared in this scope.
  @override
  Map<String, VariableBuilder>? _local;

  @override
  Map<String, List<int>>? usedNames;

  @override
  final LocalScopeKind kind;

  LocalScopeImpl(this._parent, this.kind);

  @override
  List<int>? declare(String name, VariableBuilder builder) {
    List<int>? previousOffsets = usedNames?[name];
    if (previousOffsets != null && previousOffsets.isNotEmpty) {
      return previousOffsets;
    }
    (_local ??= {})[name] = builder;
    return null;
  }

  @override
  void _recordUse(String name, int charOffset) {
    usedNames ??= <String, List<int>>{};
    // Don't use putIfAbsent to avoid the context allocation needed
    // for the closure.
    (usedNames![name] ??= []).add(charOffset);
  }

  @override
  String toString() => "$runtimeType(${kind}, ${_local?.keys})";
}

mixin ImmutableLocalScopeMixin implements LocalScope {
  @override
  List<int>? declare(String name, VariableBuilder builder) {
    throw new UnsupportedError('$runtimeType($kind).declare');
  }

  @override
  // Coverage-ignore(suite): Not run.
  Map<String, List<int>>? get usedNames => null;
}

final class LocalTypeParameterScope extends BaseLocalScope
    with ImmutableLocalScopeMixin {
  final LocalScope? _parent;

  @override
  final LocalScopeKind kind;

  final Map<String, TypeParameterBuilder>? _local;

  LocalTypeParameterScope({
    required this.kind,
    LocalScope? parent,
    Map<String, TypeParameterBuilder>? local,
  }) : _parent = parent,
       _local = local;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<VariableBuilder> get localVariables => const [];

  @override
  LookupResult? lookup(String name, {int fileOffset = -1}) {
    return _local?[name] ?? _parent?.lookup(name, fileOffset: fileOffset);
  }

  @override
  // Coverage-ignore(suite): Not run.
  VariableBuilder? lookupLocalVariable(String name) => null;

  @override
  String toString() => "$runtimeType(${kind}, ${_local?.keys})";
}

final class FixedLocalScope extends BaseLocalScope
    with ImmutableLocalScopeMixin, LocalScopeMixin {
  @override
  final LocalScope? _parent;
  @override
  final LocalScopeKind kind;
  @override
  final Map<String, VariableBuilder>? _local;

  FixedLocalScope({
    required this.kind,
    LocalScope? parent,
    Map<String, VariableBuilder>? local,
  }) : _parent = parent,
       _local = local;

  @override
  String toString() => "$runtimeType(${kind}, ${_local?.keys})";
}

final class FormalParameterScope extends BaseLocalScope
    with ImmutableLocalScopeMixin, LocalScopeMixin {
  @override
  final LocalScope? _parent;
  @override
  final Map<String, VariableBuilder>? _local;

  FormalParameterScope({
    required LookupScope parent,
    Map<String, VariableBuilder>? local,
  }) : _parent = new EnclosingLocalScope(parent),
       _local = local;

  @override
  LocalScopeKind get kind => LocalScopeKind.formals;

  @override
  String toString() =>
      "$runtimeType(${kind}, formal parameter, ${_local?.keys})";
}

final class EnclosingLocalScope extends BaseLocalScope
    with ImmutableLocalScopeMixin {
  final LookupScope _scope;

  EnclosingLocalScope(this._scope);

  @override
  LocalScopeKind get kind => LocalScopeKind.enclosing;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<VariableBuilder> get localVariables => const [];

  @override
  LookupResult? lookup(String name, {int fileOffset = -1}) {
    return _scope.lookup(name);
  }

  @override
  // Coverage-ignore(suite): Not run.
  VariableBuilder? lookupLocalVariable(String name) => null;

  @override
  String toString() => "$runtimeType(${kind},$_scope)";
}
