// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scope;

import 'builder/builder.dart'
    show Declaration, NameIterator, TypeVariableBuilder;

import 'fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        messageInternalProblemExtendingUnmodifiableScope,
        templateAccessError,
        templateDuplicatedDeclarationUse,
        templateDuplicatedNamePreviouslyUsedCause;

import 'problems.dart' show internalProblem, unsupported;

class MutableScope {
  /// Names declared in this scope.
  Map<String, Declaration> local;

  /// Setters declared in this scope.
  Map<String, Declaration> setters;

  /// The scope that this scope is nested within, or `null` if this is the top
  /// level scope.
  Scope parent;

  final String classNameOrDebugName;

  MutableScope(
      this.local, this.setters, this.parent, this.classNameOrDebugName) {
    assert(classNameOrDebugName != null);
  }

  String toString() => "Scope($classNameOrDebugName, ${local.keys})";
}

class Scope extends MutableScope {
  /// Indicates whether an attempt to declare new names in this scope should
  /// succeed.
  final bool isModifiable;

  Map<String, Declaration> labels;

  Map<String, Declaration> forwardDeclaredLabels;

  Map<String, int> usedNames;

  Scope(Map<String, Declaration> local, Map<String, Declaration> setters,
      Scope parent, String debugName, {this.isModifiable: true})
      : super(local, setters = setters ?? const <String, Declaration>{}, parent,
            debugName);

  Scope.top({bool isModifiable: false})
      : this(<String, Declaration>{}, <String, Declaration>{}, null, "top",
            isModifiable: isModifiable);

  Scope.immutable()
      : this(const <String, Declaration>{}, const <String, Declaration>{}, null,
            "immutable",
            isModifiable: false);

  Scope.nested(Scope parent, String debugName, {bool isModifiable: true})
      : this(
            <String, Declaration>{}, <String, Declaration>{}, parent, debugName,
            isModifiable: isModifiable);

  Iterator<Declaration> get iterator {
    return new ScopeLocalDeclarationIterator(this);
  }

  NameIterator get nameIterator {
    return new ScopeLocalDeclarationNameIterator(this);
  }

  Scope copyWithParent(Scope parent, String debugName) {
    return new Scope(super.local, super.setters, parent, debugName,
        isModifiable: isModifiable);
  }

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

  Declaration lookupIn(String name, int charOffset, Uri fileUri,
      Map<String, Declaration> map, bool isInstanceScope) {
    Declaration builder = map[name];
    if (builder == null) return null;
    if (builder.next != null) {
      return new AmbiguousBuilder(name.isEmpty ? classNameOrDebugName : name,
          builder, charOffset, fileUri);
    } else if (!isInstanceScope && builder.isInstanceMember) {
      return null;
    } else {
      return builder;
    }
  }

  Declaration lookup(String name, int charOffset, Uri fileUri,
      {bool isInstanceScope: true}) {
    recordUse(name, charOffset, fileUri);
    Declaration builder =
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

  Declaration lookupSetter(String name, int charOffset, Uri fileUri,
      {bool isInstanceScope: true}) {
    recordUse(name, charOffset, fileUri);
    Declaration builder =
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

  void declareLabel(String name, Declaration target) {
    if (isModifiable) {
      labels ??= <String, Declaration>{};
      labels[name] = target;
    } else {
      internalProblem(
          messageInternalProblemExtendingUnmodifiableScope, -1, null);
    }
  }

  void forwardDeclareLabel(String name, Declaration target) {
    declareLabel(name, target);
    forwardDeclaredLabels ??= <String, Declaration>{};
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

  Map<String, Declaration> get unclaimedForwardDeclarations {
    return forwardDeclaredLabels;
  }

  Declaration lookupLabel(String name) {
    return (labels == null ? null : labels[name]) ?? parent?.lookupLabel(name);
  }

  /// Declares that the meaning of [name] in this scope is [builder].
  ///
  /// If name was used previously in this scope, this method returns a message
  /// that can be used as context for reporting a compile-time error about
  /// [name] being used before its declared. [fileUri] is used to bind the
  /// location of this message.
  LocatedMessage declare(String name, Declaration builder, Uri fileUri) {
    if (isModifiable) {
      if (usedNames?.containsKey(name) ?? false) {
        return templateDuplicatedNamePreviouslyUsedCause
            .withArguments(name)
            .withLocation(fileUri, usedNames[name], name.length);
      }
      local[name] = builder;
    } else {
      internalProblem(
          messageInternalProblemExtendingUnmodifiableScope, -1, null);
    }
    return null;
  }

  void merge(
      Scope scope,
      Declaration computeAmbiguousDeclaration(
          String name, Declaration existing, Declaration member)) {
    Map<String, Declaration> map = local;

    void mergeMember(String name, Declaration member) {
      Declaration existing = map[name];
      if (existing != null) {
        if (existing != member) {
          member = computeAmbiguousDeclaration(name, existing, member);
        }
      }
      map[name] = member;
    }

    scope.local.forEach(mergeMember);
    map = setters;
    scope.setters.forEach(mergeMember);
  }

  void forEach(f(String name, Declaration member)) {
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
    local.forEach((String name, Declaration member) {
      sink.writeln("$indent  $name");
    });
    setters.forEach((String name, Declaration member) {
      sink.writeln("$indent  $name=");
    });
    return nestingLevel;
  }

  Scope computeMixinScope() {
    List<String> names = this.local.keys.toList();
    Map<String, Declaration> local = <String, Declaration>{};
    bool needsCopy = false;
    for (int i = 0; i < names.length; i++) {
      String name = names[i];
      Declaration declaration = this.local[name];
      if (declaration.isStatic) {
        needsCopy = true;
      } else {
        local[name] = declaration;
      }
    }
    names = this.setters.keys.toList();
    Map<String, Declaration> setters = <String, Declaration>{};
    for (int i = 0; i < names.length; i++) {
      String name = names[i];
      Declaration declaration = this.setters[name];
      if (declaration.isStatic) {
        needsCopy = true;
      } else {
        setters[name] = declaration;
      }
    }
    return needsCopy
        ? new Scope(local, setters, parent, classNameOrDebugName,
            isModifiable: isModifiable)
        : this;
  }
}

class ScopeBuilder {
  final Scope scope;

  ScopeBuilder(this.scope);

  void addMember(String name, Declaration builder) {
    scope.local[name] = builder;
  }

  void addSetter(String name, Declaration builder) {
    scope.setters[name] = builder;
  }

  Declaration operator [](String name) => scope.local[name];
}

abstract class ProblemBuilder extends Declaration {
  final String name;

  final Declaration builder;

  final int charOffset;

  final Uri fileUri;

  ProblemBuilder(this.name, this.builder, this.charOffset, this.fileUri);

  get target => null;

  bool get hasProblem => true;

  Message get message;

  @override
  String get fullNameForErrors => name;
}

/// Represents a [builder] that's being accessed incorrectly. For example, an
/// attempt to write to a final field, or to read from a setter.
class AccessErrorBuilder extends ProblemBuilder {
  AccessErrorBuilder(
      String name, Declaration builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);

  Declaration get parent => builder;

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
  AmbiguousBuilder(
      String name, Declaration builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);

  Declaration get parent => null;

  Message get message => templateDuplicatedDeclarationUse.withArguments(name);

  // TODO(ahe): Also provide context.

  Declaration getFirstDeclaration() {
    Declaration declaration = builder;
    while (declaration.next != null) {
      declaration = declaration.next;
    }
    return declaration;
  }
}

class ScopeLocalDeclarationIterator implements Iterator<Declaration> {
  Iterator<Declaration> local;
  final Iterator<Declaration> setters;
  Declaration current;

  ScopeLocalDeclarationIterator(Scope scope)
      : local = scope.local.values.iterator,
        setters = scope.setters.values.iterator;

  bool moveNext() {
    Declaration next = current?.next;
    if (next != null) {
      current = next;
      return true;
    }
    if (local != null) {
      if (local.moveNext()) {
        current = local.current;
        return true;
      }
      local = null;
    }
    if (setters.moveNext()) {
      current = setters.current;
      return true;
    } else {
      current = null;
      return false;
    }
  }
}

class ScopeLocalDeclarationNameIterator extends ScopeLocalDeclarationIterator
    implements NameIterator {
  Iterator<String> localNames;
  final Iterator<String> setterNames;

  String name;

  ScopeLocalDeclarationNameIterator(Scope scope)
      : localNames = scope.local.keys.iterator,
        setterNames = scope.setters.keys.iterator,
        super(scope);

  bool moveNext() {
    Declaration next = current?.next;
    if (next != null) {
      current = next;
      return true;
    }
    if (local != null) {
      if (local.moveNext()) {
        localNames.moveNext();
        current = local.current;
        name = localNames.current;
        return true;
      }
      localNames = null;
    }
    if (setters.moveNext()) {
      setterNames.moveNext();
      current = setters.current;
      name = setterNames.current;
      return true;
    } else {
      current = null;
      return false;
    }
  }
}
