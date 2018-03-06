// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scope;

import 'builder/builder.dart' show Builder, TypeVariableBuilder;

import 'fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        messageInternalProblemExtendingUnmodifiableScope,
        templateAccessError,
        templateDuplicatedName,
        templatePreviousUseOfName;

import 'problems.dart' show internalProblem, unsupported;

class MutableScope {
  /// Names declared in this scope.
  Map<String, Builder> local;

  /// Setters declared in this scope.
  Map<String, Builder> setters;

  /// The scope that this scope is nested within, or `null` if this is the top
  /// level scope.
  Scope parent;

  final String debugName;

  MutableScope(this.local, this.setters, this.parent, this.debugName) {
    assert(debugName != null);
  }

  String toString() => "Scope($debugName, ${local.keys})";
}

class Scope extends MutableScope {
  /// Indicates whether an attempt to declare new names in this scope should
  /// succeed.
  final bool isModifiable;

  Map<String, Builder> labels;

  Map<String, Builder> forwardDeclaredLabels;

  Map<String, int> usedNames;

  Scope(Map<String, Builder> local, Map<String, Builder> setters, Scope parent,
      String debugName, {this.isModifiable: true})
      : super(local, setters = setters ?? const <String, Builder>{}, parent,
            debugName);

  Scope.top({bool isModifiable: false})
      : this(<String, Builder>{}, <String, Builder>{}, null, "top",
            isModifiable: isModifiable);

  Scope.immutable()
      : this(const <String, Builder>{}, const <String, Builder>{}, null,
            "immutable",
            isModifiable: false);

  Scope.nested(Scope parent, String debugName, {bool isModifiable: true})
      : this(<String, Builder>{}, null, parent, debugName,
            isModifiable: isModifiable);

  /// Don't use this. Use [becomePartOf] instead.
  void set local(_) => unsupported("local=", -1, null);

  /// Don't use this. Use [becomePartOf] instead.
  void set setters(_) => unsupported("setters=", -1, null);

  /// Don't use this. Use [becomePartOf] instead.
  void set parent(_) => unsupported("parent=", -1, null);

  /// This scope becomes equivalent to [scope]. This is used for parts to
  /// become part of their library's scope.
  void becomePartOf(Scope scope) {
    assert(parent.parent == null);
    assert(scope.parent.parent == null);
    super.local = scope.local;
    super.setters = scope.setters;
    super.parent = scope.parent;
  }

  Scope createNestedScope(String debugName, {bool isModifiable: true}) {
    return new Scope.nested(this, debugName, isModifiable: isModifiable);
  }

  Scope withTypeVariables(List<TypeVariableBuilder> typeVariables) {
    if (typeVariables == null) return this;
    Scope newScope =
        new Scope.nested(this, "type variables", isModifiable: false);
    for (TypeVariableBuilder t in typeVariables) {
      newScope.local[t.name] = t;
    }
    return newScope;
  }

  /// Create a special scope for use by labeled staments. This scope doesn't
  /// introduce a new scope for local variables, only for labels. This deals
  /// with corner cases like this:
  ///
  ///     L: var x;
  ///     x = 42;
  ///     print("The answer is $x.");
  Scope createNestedLabelScope() {
    return new Scope(local, setters, parent, "label", isModifiable: true);
  }

  void recordUse(String name, int charOffset, Uri fileUri) {
    if (isModifiable) {
      usedNames ??= <String, int>{};
      usedNames.putIfAbsent(name, () => charOffset);
    }
  }

  Builder lookupIn(String name, int charOffset, Uri fileUri,
      Map<String, Builder> map, bool isInstanceScope) {
    Builder builder = map[name];
    if (builder == null) return null;
    if (builder.next != null) {
      return new AmbiguousBuilder(name, builder, charOffset, fileUri);
    } else if (!isInstanceScope && builder.isInstanceMember) {
      return null;
    } else {
      return builder;
    }
  }

  Builder lookup(String name, int charOffset, Uri fileUri,
      {bool isInstanceScope: true}) {
    recordUse(name, charOffset, fileUri);
    Builder builder =
        lookupIn(name, charOffset, fileUri, local, isInstanceScope);
    if (builder != null) return builder;
    builder = lookupIn(name, charOffset, fileUri, setters, isInstanceScope);
    if (builder != null && !builder.hasProblem) {
      return new AccessErrorBuilder(name, builder, charOffset, fileUri);
    }
    if (!isInstanceScope) {
      // For static lookup, do not seach the parent scope.
      return builder;
    }
    return builder ?? parent?.lookup(name, charOffset, fileUri);
  }

  Builder lookupSetter(String name, int charOffset, Uri fileUri,
      {bool isInstanceScope: true}) {
    recordUse(name, charOffset, fileUri);
    Builder builder =
        lookupIn(name, charOffset, fileUri, setters, isInstanceScope);
    if (builder != null) return builder;
    builder = lookupIn(name, charOffset, fileUri, local, isInstanceScope);
    if (builder != null && !builder.hasProblem) {
      return new AccessErrorBuilder(name, builder, charOffset, fileUri);
    }
    if (!isInstanceScope) {
      // For static lookup, do not seach the parent scope.
      return builder;
    }
    return builder ?? parent?.lookupSetter(name, charOffset, fileUri);
  }

  bool hasLocalLabel(String name) => labels != null && labels.containsKey(name);

  void declareLabel(String name, Builder target) {
    if (isModifiable) {
      labels ??= <String, Builder>{};
      labels[name] = target;
    } else {
      internalProblem(
          messageInternalProblemExtendingUnmodifiableScope, -1, null);
    }
  }

  void forwardDeclareLabel(String name, Builder target) {
    declareLabel(name, target);
    forwardDeclaredLabels ??= <String, Builder>{};
    forwardDeclaredLabels[name] = target;
  }

  bool claimLabel(String name) {
    if (forwardDeclaredLabels == null ||
        forwardDeclaredLabels.remove(name) == null) return false;
    if (forwardDeclaredLabels.length == 0) {
      forwardDeclaredLabels = null;
    }
    return true;
  }

  Map<String, Builder> get unclaimedForwardDeclarations {
    return forwardDeclaredLabels;
  }

  Builder lookupLabel(String name) {
    return (labels == null ? null : labels[name]) ?? parent?.lookupLabel(name);
  }

  /// Declares that the meaning of [name] in this scope is [builder].
  ///
  /// If name was used previously in this scope, this method returns an error
  /// that should be reported as a compile-time error. The position of this
  /// error is given by [charOffset] and [fileUri].
  LocatedMessage declare(
      String name, Builder builder, int charOffset, Uri fileUri) {
    if (isModifiable) {
      if (usedNames?.containsKey(name) ?? false) {
        return templatePreviousUseOfName
            .withArguments(name)
            .withLocation(fileUri, usedNames[name], name.length);
      }
      recordUse(name, charOffset, fileUri);
      local[name] = builder;
    } else {
      internalProblem(
          messageInternalProblemExtendingUnmodifiableScope, -1, null);
    }
    return null;
  }

  void merge(Scope scope,
      buildAmbiguousBuilder(String name, Builder existing, Builder member)) {
    Map<String, Builder> map = local;

    void mergeMember(String name, Builder member) {
      Builder existing = map[name];
      if (existing != null) {
        if (existing != member) {
          member = buildAmbiguousBuilder(name, existing, member);
        }
      }
      map[name] = member;
    }

    scope.local.forEach(mergeMember);
    map = setters;
    scope.setters.forEach(mergeMember);
  }

  void forEach(f(String name, Builder member)) {
    local.forEach(f);
    setters.forEach(f);
  }

  String get debugString {
    StringBuffer buffer = new StringBuffer();
    int nestingLevel = writeOn(buffer);
    for (int i = nestingLevel; i >= 0; i--) {
      buffer.writeln("${'  ' * i}}");
    }
    return "$buffer";
  }

  int writeOn(StringSink sink) {
    int nestingLevel = (parent?.writeOn(sink) ?? -1) + 1;
    String indent = "  " * nestingLevel;
    sink.writeln("$indent{");
    local.forEach((String name, Builder member) {
      sink.writeln("$indent  $name");
    });
    setters.forEach((String name, Builder member) {
      sink.writeln("$indent  $name=");
    });
    return nestingLevel;
  }
}

class ScopeBuilder {
  final Scope scope;

  ScopeBuilder(this.scope);

  void addMember(String name, Builder builder) {
    scope.local[name] = builder;
  }

  void addSetter(String name, Builder builder) {
    scope.setters[name] = builder;
  }

  Builder operator [](String name) => scope.local[name];
}

abstract class ProblemBuilder extends Builder {
  final String name;

  final Builder builder;

  ProblemBuilder(this.name, this.builder, int charOffset, Uri fileUri)
      : super(null, charOffset, fileUri);

  get target => null;

  bool get hasProblem => true;

  Message get message;

  @override
  String get fullNameForErrors => name;
}

/// Represents a [builder] that's being accessed incorrectly. For example, an
/// attempt to write to a final field, or to read from a setter.
class AccessErrorBuilder extends ProblemBuilder {
  AccessErrorBuilder(String name, Builder builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);

  Builder get parent => builder;

  bool get isFinal => builder.isFinal;

  bool get isField => builder.isField;

  bool get isRegularMethod => builder.isRegularMethod;

  bool get isGetter => !builder.isGetter;

  bool get isSetter => !builder.isSetter;

  bool get isInstanceMember => builder.isInstanceMember;

  bool get isStatic => builder.isStatic;

  bool get isTopLevel => builder.isTopLevel;

  bool get isTypeDeclaration => builder.isTypeDeclaration;

  bool get isLocal => builder.isLocal;

  Message get message => templateAccessError.withArguments(name);
}

class AmbiguousBuilder extends ProblemBuilder {
  AmbiguousBuilder(String name, Builder builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);

  Message get message => templateDuplicatedName.withArguments(name);
}
