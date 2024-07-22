// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/builder.dart';
import '../kernel/body_builder.dart' show JumpTarget;
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

  /// Create a special scope for use by labeled statements. This scope doesn't
  /// introduce a new scope for local variables, only for labels. This deals
  /// with corner cases like this:
  ///
  ///     L: var x;
  ///     x = 42;
  ///     print("The answer is $x.");
  LocalScope createNestedLabelScope();

  Iterable<Builder> get localMembers;

  Builder? lookupLocalMember(String name, {required bool setter});

  /// Declares that the meaning of [name] in this scope is [builder].
  ///
  /// If name was used previously in this scope, this method returns a message
  /// that can be used as context for reporting a compile-time error about
  /// [name] being used before its declared. [fileUri] is used to bind the
  /// location of this message.
  List<int>? declare(String name, Builder builder, Uri uri);

  void addLocalMember(String name, Builder member, {required bool setter});

  void declareLabel(String name, JumpTarget target);

  JumpTarget? lookupLabel(String name);

  @override
  Builder? lookup(String name, int charOffset, Uri fileUri);

  @override
  Builder? lookupSetter(String name, int charOffset, Uri uri);

  Map<String, List<int>>? get usedNames;

  SwitchScope get switchScope;
}

abstract class SwitchScope {
  Map<String, JumpTarget>? get unclaimedForwardDeclarations;
  JumpTarget? lookupLabel(String name);
  bool hasLocalLabel(String name);
  bool claimLabel(String name);
  void forwardDeclareLabel(String name, JumpTarget target);
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
  Iterable<Builder> get localMembers => _local?.values ?? const {};

  @override
  Builder? lookup(String name, int charOffset, Uri fileUri) {
    recordUse(name, charOffset);
    Builder? builder;
    if (_local != null) {
      builder = lookupIn(name, charOffset, fileUri, _local!);
      if (builder != null) return builder;
    }
    return builder ?? _parent?.lookup(name, charOffset, fileUri);
  }

  @override
  Builder? lookupLocalMember(String name, {required bool setter}) {
    return setter ? null : (_local?[name]);
  }

  @override
  Builder? lookupSetter(String name, int charOffset, Uri fileUri) {
    recordUse(name, charOffset);
    Builder? builder = lookupSetterIn(name, charOffset, fileUri, _local);
    return builder ?? _parent?.lookupSetter(name, charOffset, fileUri);
  }

  void recordUse(String name, int charOffset) {}
}

final class LocalScopeImpl extends BaseLocalScope
    with LookupScopeMixin, LocalScopeMixin, SwitchScopeMixin
    implements LocalScope, SwitchScope {
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
  Map<String, JumpTarget>? labels;

  @override
  final ScopeKind kind;

  LocalScopeImpl(this._parent, this.kind, this.classNameOrDebugName,
      {Map<String, Builder>? local})
      : _local = local;

  @override
  void addLocalMember(String name, Builder member, {required bool setter}) {
    (_local ??= {})[name] = member;
  }

  @override
  List<int>? declare(String name, Builder builder, Uri uri) {
    List<int>? previousOffsets = usedNames?[name];
    if (previousOffsets != null && previousOffsets.isNotEmpty) {
      return previousOffsets;
    }
    (_local ??= {})[name] = builder;
    return null;
  }

  @override
  void declareLabel(String name, JumpTarget target) {
    (labels ??= {})[name] = target;
  }

  @override
  SwitchScope get switchScope => this;

  @override
  void recordUse(String name, int charOffset) {
    usedNames ??= <String, List<int>>{};
    // Don't use putIfAbsent to avoid the context allocation needed
    // for the closure.
    (usedNames![name] ??= []).add(charOffset);
  }

  @override
  LocalScope createNestedLabelScope() {
    // The scopes needs to reference the same locals, so we have to eagerly
    // initialize them.
    _local ??= {};
    return new LocalScopeImpl(this, kind, "label", local: _local);
  }

  @override
  String toString() =>
      "$runtimeType(${kind}, $classNameOrDebugName, ${_local?.keys})";
}

mixin SwitchScopeMixin implements SwitchScope {
  Map<String, JumpTarget>? get labels;
  LocalScope? get _parent;

  Map<String, JumpTarget>? forwardDeclaredLabels;

  void declareLabel(String name, JumpTarget target);

  @override
  JumpTarget? lookupLabel(String name) {
    return labels?[name] ?? _parent?.lookupLabel(name);
  }

  @override
  bool hasLocalLabel(String name) =>
      labels != null && labels!.containsKey(name);

  @override
  bool claimLabel(String name) {
    if (forwardDeclaredLabels == null ||
        forwardDeclaredLabels!.remove(name) == null) {
      return false;
    }
    if (forwardDeclaredLabels!.length == 0) {
      forwardDeclaredLabels = null;
    }
    return true;
  }

  @override
  void forwardDeclareLabel(String name, JumpTarget target) {
    declareLabel(name, target);
    forwardDeclaredLabels ??= <String, JumpTarget>{};
    forwardDeclaredLabels![name] = target;
  }

  @override
  Map<String, JumpTarget>? get unclaimedForwardDeclarations {
    return forwardDeclaredLabels;
  }
}

mixin ImmutableLocalScopeMixin implements LocalScope {
  @override
  void addLocalMember(String name, Builder member, {required bool setter}) {
    throw new UnsupportedError('$runtimeType($kind).addLocalMember');
  }

  @override
  List<int>? declare(String name, Builder builder, Uri uri) {
    throw new UnsupportedError('$runtimeType($kind).declare');
  }

  @override
  void declareLabel(String name, JumpTarget target) {
    throw new UnsupportedError('$runtimeType($kind).declareLabel');
  }

  @override
  SwitchScope get switchScope {
    throw new UnsupportedError('$runtimeType($kind).switchScope');
  }

  @override
  LocalScope createNestedLabelScope() {
    throw new UnsupportedError("$runtimeType($kind).createNestedLabelScope()");
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
  JumpTarget? lookupLabel(String name) => _parent?.lookupLabel(name);

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
  JumpTarget? lookupLabel(String name) => null;

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
  Iterable<Builder> get localMembers => const [];

  @override
  Builder? lookup(String name, int charOffset, Uri fileUri) {
    return _scope.lookup(name, charOffset, fileUri);
  }

  @override
  JumpTarget? lookupLabel(String name) => null;

  @override
  Builder? lookupLocalMember(String name, {required bool setter}) => null;

  @override
  Builder? lookupSetter(String name, int charOffset, Uri uri) {
    return _scope.lookupSetter(name, charOffset, uri);
  }

  @override
  String toString() => "$runtimeType(${kind},$_scope)";
}
