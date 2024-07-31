// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import 'scope.dart';

abstract class LocalScope implements LookupScope {
  @override
  ScopeKind get kind;

  LocalScope createNestedScope(
      {required String debugName, required ScopeKind kind});

  LocalScope createNestedFixedScope(
      {required String debugName,
      required Map<String, Builder> local,
      required ScopeKind kind});

  Iterable<Builder> get localVariables;

  Builder? lookupLocalVariable(String name);

  /// Declares that the meaning of [name] in this scope is [builder].
  ///
  /// If name was used previously in this scope, this method returns the read
  /// offsets which can be used for reporting a compile-time error about
  /// [name] being used before its declared.
  List<int>? declare(String name, Builder builder);

  void addLocalVariable(String name, Builder builder);

  @override
  Builder? lookupGetable(String name, int charOffset, Uri fileUri);

  @override
  Builder? lookupSetable(String name, int charOffset, Uri uri);

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
      required Map<String, Builder> local,
      required ScopeKind kind}) {
    return new FixedLocalScope(
        kind: kind, parent: this, local: local, debugName: debugName);
  }
}

mixin LocalScopeMixin implements LookupScopeMixin, LocalScope {
  LookupScope? get _parent;

  Map<String, Builder>? get _local;

  @override
  String get classNameOrDebugName;

  @override
  Iterable<Builder> get localVariables => _local?.values ?? const {};

  @override
  Builder? lookupGetable(String name, int charOffset, Uri fileUri) {
    _recordUse(name, charOffset);
    Builder? builder;
    if (_local != null) {
      builder = lookupGetableIn(name, charOffset, fileUri, _local!);
      if (builder != null) return builder;
    }
    return builder ?? _parent?.lookupGetable(name, charOffset, fileUri);
  }

  @override
  Builder? lookupLocalVariable(String name) {
    return _local?[name];
  }

  @override
  Builder? lookupSetable(String name, int charOffset, Uri fileUri) {
    _recordUse(name, charOffset);
    Builder? builder = lookupSetableIn(name, charOffset, fileUri, _local);
    return builder ?? _parent?.lookupSetable(name, charOffset, fileUri);
  }

  void _recordUse(String name, int charOffset) {}

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _parent?.forEachExtension(f);
  }
}

final class LocalScopeImpl extends BaseLocalScope
    with LookupScopeMixin, LocalScopeMixin
    implements LocalScope {
  @override
  final LocalScope? _parent;

  @override
  final String classNameOrDebugName;

  /// Names declared in this scope.
  @override
  Map<String, Builder>? _local;

  @override
  Map<String, List<int>>? usedNames;

  @override
  final ScopeKind kind;

  LocalScopeImpl(this._parent, this.kind, this.classNameOrDebugName);

  @override
  void addLocalVariable(String name, Builder builder) {
    (_local ??= {})[name] = builder;
  }

  @override
  List<int>? declare(String name, Builder builder) {
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
  String toString() =>
      "$runtimeType(${kind}, $classNameOrDebugName, ${_local?.keys})";
}

mixin ImmutableLocalScopeMixin implements LocalScope {
  @override
  void addLocalVariable(String name, Builder builder) {
    throw new UnsupportedError('$runtimeType($kind).addLocalMember');
  }

  @override
  List<int>? declare(String name, Builder builder) {
    throw new UnsupportedError('$runtimeType($kind).declare');
  }

  @override
  Map<String, List<int>>? get usedNames => null;
}

final class FixedLocalScope extends BaseLocalScope
    with LookupScopeMixin, ImmutableLocalScopeMixin, LocalScopeMixin {
  @override
  final LocalScope? _parent;
  @override
  final ScopeKind kind;
  @override
  final Map<String, Builder>? _local;

  final String _debugName;

  FixedLocalScope(
      {required this.kind,
      LocalScope? parent,
      Map<String, Builder>? local,
      required String debugName})
      : _parent = parent,
        _local = local,
        _debugName = debugName;

  @override
  String get classNameOrDebugName => _debugName;

  @override
  String toString() =>
      "$runtimeType(${kind}, $classNameOrDebugName, ${_local?.keys})";
}

final class FormalParameterScope extends BaseLocalScope
    with LookupScopeMixin, ImmutableLocalScopeMixin, LocalScopeMixin {
  @override
  final LookupScope? _parent;
  @override
  final Map<String, Builder>? _local;

  FormalParameterScope({LookupScope? parent, Map<String, Builder>? local})
      : _parent = parent,
        _local = local;

  @override
  ScopeKind get kind => ScopeKind.formals;

  @override
  String get classNameOrDebugName => "formal parameter";

  @override
  String toString() =>
      "$runtimeType(${kind}, $classNameOrDebugName, ${_local?.keys})";
}

final class EnclosingLocalScope extends BaseLocalScope
    with ImmutableLocalScopeMixin {
  final LookupScope _scope;

  EnclosingLocalScope(this._scope);

  @override
  ScopeKind get kind => _scope.kind;

  @override
  Iterable<Builder> get localVariables => const [];

  @override
  Builder? lookupGetable(String name, int charOffset, Uri fileUri) {
    return _scope.lookupGetable(name, charOffset, fileUri);
  }

  @override
  Builder? lookupLocalVariable(String name) => null;

  @override
  Builder? lookupSetable(String name, int charOffset, Uri uri) {
    return _scope.lookupSetable(name, charOffset, uri);
  }

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _scope.forEachExtension(f);
  }

  @override
  String toString() => "$runtimeType(${kind},$_scope)";
}
