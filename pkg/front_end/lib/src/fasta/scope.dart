// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scope;

import 'builder/builder.dart' show NameIterator, TypeVariableBuilder;

import 'builder/declaration.dart';

import 'builder/extension_builder.dart';

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
  Map<String, Builder> local;

  /// Setters declared in this scope.
  Map<String, Builder> setters;

  /// The extensions declared in this scope.
  ///
  /// This includes all available extensions even if the extensions are not
  /// accessible by name because of duplicate imports.
  ///
  /// For instance:
  ///
  ///   lib1.dart:
  ///     extension Extension on String {
  ///       method1() {}
  ///       staticMethod1() {}
  ///     }
  ///   lib2.dart:
  ///     extension Extension on String {
  ///       method2() {}
  ///       staticMethod2() {}
  ///     }
  ///   main.dart:
  ///     import 'lib1.dart';
  ///     import 'lib2.dart';
  ///
  ///     main() {
  ///       'foo'.method1(); // This method is available.
  ///       'foo'.method2(); // This method is available.
  ///       // These methods are not available because Extension is ambiguous:
  ///       Extension.staticMethod1();
  ///       Extension.staticMethod2();
  ///     }
  ///
  List<ExtensionBuilder> _extensions;

  /// The scope that this scope is nested within, or `null` if this is the top
  /// level scope.
  Scope parent;

  final String classNameOrDebugName;

  MutableScope(this.local, this.setters, this._extensions, this.parent,
      this.classNameOrDebugName) {
    assert(classNameOrDebugName != null);
  }

  String toString() => "Scope($classNameOrDebugName, ${local.keys})";
}

class Scope extends MutableScope {
  /// Indicates whether an attempt to declare new names in this scope should
  /// succeed.
  final bool isModifiable;

  Map<String, Builder> labels;

  Map<String, Builder> forwardDeclaredLabels;

  Map<String, int> usedNames;

  Scope(
      {Map<String, Builder> local,
      Map<String, Builder> setters,
      List<ExtensionBuilder> extensions,
      Scope parent,
      String debugName,
      this.isModifiable: true})
      : super(local, setters = setters ?? const <String, Builder>{}, extensions,
            parent, debugName);

  Scope.top({bool isModifiable: false})
      : this(
            local: <String, Builder>{},
            setters: <String, Builder>{},
            debugName: "top",
            isModifiable: isModifiable);

  Scope.immutable()
      : this(
            local: const <String, Builder>{},
            setters: const <String, Builder>{},
            debugName: "immutable",
            isModifiable: false);

  Scope.nested(Scope parent, String debugName, {bool isModifiable: true})
      : this(
            local: <String, Builder>{},
            setters: <String, Builder>{},
            parent: parent,
            debugName: debugName,
            isModifiable: isModifiable);

  Iterator<Builder> get iterator {
    return new ScopeLocalDeclarationIterator(this);
  }

  NameIterator get nameIterator {
    return new ScopeLocalDeclarationNameIterator(this);
  }

  Scope copyWithParent(Scope parent, String debugName) {
    return new Scope(
        local: super.local,
        setters: super.setters,
        extensions: _extensions,
        parent: parent,
        debugName: debugName,
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
    super._extensions = scope._extensions;
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

  /// Create a special scope for use by labeled statements. This scope doesn't
  /// introduce a new scope for local variables, only for labels. This deals
  /// with corner cases like this:
  ///
  ///     L: var x;
  ///     x = 42;
  ///     print("The answer is $x.");
  Scope createNestedLabelScope() {
    return new Scope(
        local: local,
        setters: setters,
        extensions: _extensions,
        parent: parent,
        debugName: "label",
        isModifiable: true);
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
      return new AmbiguousBuilder(name.isEmpty ? classNameOrDebugName : name,
          builder, charOffset, fileUri);
    } else if (!isInstanceScope && builder.isDeclarationInstanceMember) {
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
      // For static lookup, do not search the parent scope.
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
      // For static lookup, do not search the parent scope.
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
  /// If name was used previously in this scope, this method returns a message
  /// that can be used as context for reporting a compile-time error about
  /// [name] being used before its declared. [fileUri] is used to bind the
  /// location of this message.
  LocatedMessage declare(String name, Builder builder, Uri fileUri) {
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

  /// Adds [builder] to the extensions in this scope.
  void addExtension(ExtensionBuilder builder) {
    _extensions ??= [];
    _extensions.add(builder);
  }

  /// Calls [f] for each extension in this scope and parent scopes.
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _extensions?.forEach(f);
    parent?.forEachExtension(f);
  }

  void merge(
      Scope scope,
      Builder computeAmbiguousDeclaration(
          String name, Builder existing, Builder member)) {
    Map<String, Builder> map = local;

    void mergeMember(String name, Builder member) {
      Builder existing = map[name];
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

  Scope computeMixinScope() {
    List<String> names = this.local.keys.toList();
    Map<String, Builder> local = <String, Builder>{};
    bool needsCopy = false;
    for (int i = 0; i < names.length; i++) {
      String name = names[i];
      Builder declaration = this.local[name];
      if (declaration.isStatic) {
        needsCopy = true;
      } else {
        local[name] = declaration;
      }
    }
    names = this.setters.keys.toList();
    Map<String, Builder> setters = <String, Builder>{};
    for (int i = 0; i < names.length; i++) {
      String name = names[i];
      Builder declaration = this.setters[name];
      if (declaration.isStatic) {
        needsCopy = true;
      } else {
        setters[name] = declaration;
      }
    }
    return needsCopy
        ? new Scope(
            local: local,
            setters: setters,
            extensions: _extensions,
            parent: parent,
            debugName: classNameOrDebugName,
            isModifiable: isModifiable)
        : this;
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

  void addExtension(ExtensionBuilder builder) {
    scope.addExtension(builder);
  }

  Builder operator [](String name) => scope.local[name];
}

abstract class ProblemBuilder extends BuilderImpl {
  final String name;

  final Builder builder;

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
  AccessErrorBuilder(String name, Builder builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);

  @override
  Builder get parent => builder;

  @override
  bool get isFinal => builder.isFinal;

  @override
  bool get isField => builder.isField;

  @override
  bool get isRegularMethod => builder.isRegularMethod;

  @override
  bool get isGetter => !builder.isGetter;

  @override
  bool get isSetter => !builder.isSetter;

  @override
  bool get isDeclarationInstanceMember => builder.isDeclarationInstanceMember;

  @override
  bool get isClassInstanceMember => builder.isClassInstanceMember;

  @override
  bool get isExtensionInstanceMember => builder.isExtensionInstanceMember;

  @override
  bool get isStatic => builder.isStatic;

  @override
  bool get isTopLevel => builder.isTopLevel;

  @override
  bool get isTypeDeclaration => builder.isTypeDeclaration;

  @override
  bool get isLocal => builder.isLocal;

  @override
  Message get message => templateAccessError.withArguments(name);
}

class AmbiguousBuilder extends ProblemBuilder {
  AmbiguousBuilder(String name, Builder builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);

  @override
  Builder get parent => null;

  @override
  Message get message => templateDuplicatedDeclarationUse.withArguments(name);

  // TODO(ahe): Also provide context.

  Builder getFirstDeclaration() {
    Builder declaration = builder;
    while (declaration.next != null) {
      declaration = declaration.next;
    }
    return declaration;
  }
}

class ScopeLocalDeclarationIterator implements Iterator<Builder> {
  Iterator<Builder> local;
  final Iterator<Builder> setters;

  @override
  Builder current;

  ScopeLocalDeclarationIterator(Scope scope)
      : local = scope.local.values.iterator,
        setters = scope.setters.values.iterator;

  @override
  bool moveNext() {
    Builder next = current?.next;
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

  @override
  String name;

  ScopeLocalDeclarationNameIterator(Scope scope)
      : localNames = scope.local.keys.iterator,
        setterNames = scope.setters.keys.iterator,
        super(scope);

  @override
  bool moveNext() {
    Builder next = current?.next;
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
