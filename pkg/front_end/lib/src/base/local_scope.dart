// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/declaration_builders.dart';
import '../builder/variable_builder.dart';
import 'lookup_result.dart';
import 'scope.dart';

abstract class LocalScope implements LookupScope {
  @override
  ScopeKind get kind;

  LocalScope createNestedScope(
      {required String debugName, required ScopeKind kind});

  LocalScope createNestedFixedScope(
      {required String debugName,
      required Map<String, VariableBuilder> local,
      required ScopeKind kind});

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
  LocalScope createNestedScope(
      {required String debugName, required ScopeKind kind}) {
    return new LocalScopeImpl(this, kind, debugName);
  }

  @override
  LocalScope createNestedFixedScope(
      {required String debugName,
      required Map<String, VariableBuilder> local,
      required ScopeKind kind}) {
    return new FixedLocalScope(
        kind: kind, parent: this, local: local, debugName: debugName);
  }
}

mixin LocalScopeMixin implements LocalScope {
  LookupScope? get _parent;

  Map<String, VariableBuilder>? get _local;

  @override
  Iterable<VariableBuilder> get localVariables => _local?.values ?? const [];

  @override
  LookupResult? lookup(String name, int fileOffset, Uri fileUri) {
    _recordUse(name, fileOffset);
    return _local?[name] ?? _parent?.lookup(name, fileOffset, fileUri);
  }

  @override
  VariableBuilder? lookupLocalVariable(String name) {
    return _local?[name];
  }

  void _recordUse(String name, int charOffset) {}

  @override
  // Coverage-ignore(suite): Not run.
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _parent?.forEachExtension(f);
  }
}

final class LocalScopeImpl extends BaseLocalScope
    with LocalScopeMixin
    implements LocalScope {
  @override
  final LocalScope? _parent;

  final String _debugName;

  /// Names declared in this scope.
  @override
  Map<String, VariableBuilder>? _local;

  @override
  Map<String, List<int>>? usedNames;

  @override
  final ScopeKind kind;

  LocalScopeImpl(this._parent, this.kind, this._debugName);

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
  String toString() => "$runtimeType(${kind}, $_debugName, ${_local?.keys})";
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
  final ScopeKind kind;

  final Map<String, TypeParameterBuilder>? _local;

  final String _debugName;

  LocalTypeParameterScope(
      {required this.kind,
      LocalScope? parent,
      Map<String, TypeParameterBuilder>? local,
      required String debugName})
      : _parent = parent,
        _local = local,
        _debugName = debugName;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<VariableBuilder> get localVariables => const [];

  @override
  LookupResult? lookup(String name, int fileOffset, Uri fileUri) {
    return _local?[name] ?? _parent?.lookup(name, fileOffset, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  VariableBuilder? lookupLocalVariable(String name) => null;

  @override
  // Coverage-ignore(suite): Not run.
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _parent?.forEachExtension(f);
  }

  @override
  String toString() => "$runtimeType(${kind}, $_debugName, ${_local?.keys})";
}

final class FixedLocalScope extends BaseLocalScope
    with ImmutableLocalScopeMixin, LocalScopeMixin {
  @override
  final LocalScope? _parent;
  @override
  final ScopeKind kind;
  @override
  final Map<String, VariableBuilder>? _local;

  final String _debugName;

  FixedLocalScope(
      {required this.kind,
      LocalScope? parent,
      Map<String, VariableBuilder>? local,
      required String debugName})
      : _parent = parent,
        _local = local,
        _debugName = debugName;

  @override
  String toString() => "$runtimeType(${kind}, $_debugName, ${_local?.keys})";
}

final class FormalParameterScope extends BaseLocalScope
    with ImmutableLocalScopeMixin, LocalScopeMixin {
  @override
  final LookupScope? _parent;
  @override
  final Map<String, VariableBuilder>? _local;

  FormalParameterScope(
      {LookupScope? parent, Map<String, VariableBuilder>? local})
      : _parent = parent,
        _local = local;

  @override
  ScopeKind get kind => ScopeKind.formals;

  @override
  String toString() =>
      "$runtimeType(${kind}, formal parameter, ${_local?.keys})";
}

final class EnclosingLocalScope extends BaseLocalScope
    with ImmutableLocalScopeMixin {
  final LookupScope _scope;

  EnclosingLocalScope(this._scope);

  @override
  ScopeKind get kind => _scope.kind;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<VariableBuilder> get localVariables => const [];

  @override
  LookupResult? lookup(String name, int fileOffset, Uri fileUri) {
    return _scope.lookup(name, fileOffset, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  VariableBuilder? lookupLocalVariable(String name) => null;

  @override
  // Coverage-ignore(suite): Not run.
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _scope.forEachExtension(f);
  }

  @override
  String toString() => "$runtimeType(${kind},$_scope)";
}
