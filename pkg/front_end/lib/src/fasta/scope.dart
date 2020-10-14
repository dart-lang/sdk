// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scope;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/core_types.dart';

import 'builder/builder.dart';
import 'builder/extension_builder.dart';
import 'builder/library_builder.dart';
import 'builder/member_builder.dart';
import 'builder/name_iterator.dart';
import 'builder/type_variable_builder.dart';
import 'kernel/body_builder.dart' show JumpTarget;
import 'kernel/class_hierarchy_builder.dart' show ClassMember;

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
  Map<String, Builder> _local;

  /// Setters declared in this scope.
  Map<String, MemberBuilder> _setters;

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
  Set<ExtensionBuilder> _extensions;

  /// The scope that this scope is nested within, or `null` if this is the top
  /// level scope.
  Scope _parent;

  final String classNameOrDebugName;

  MutableScope(this._local, this._setters, this._extensions, this._parent,
      this.classNameOrDebugName) {
    assert(classNameOrDebugName != null);
  }

  Scope get parent => _parent;

  String toString() => "Scope($classNameOrDebugName, ${_local.keys})";
}

class Scope extends MutableScope {
  /// Indicates whether an attempt to declare new names in this scope should
  /// succeed.
  final bool isModifiable;

  Map<String, JumpTarget> labels;

  Map<String, JumpTarget> forwardDeclaredLabels;

  Map<String, int> usedNames;

  Scope(
      {Map<String, Builder> local,
      Map<String, MemberBuilder> setters,
      Set<ExtensionBuilder> extensions,
      Scope parent,
      String debugName,
      this.isModifiable: true})
      : super(local, setters = setters ?? const <String, MemberBuilder>{},
            extensions, parent, debugName);

  Scope.top({bool isModifiable: false})
      : this(
            local: <String, Builder>{},
            setters: <String, MemberBuilder>{},
            debugName: "top",
            isModifiable: isModifiable);

  Scope.immutable()
      : this(
            local: const <String, Builder>{},
            setters: const <String, MemberBuilder>{},
            debugName: "immutable",
            isModifiable: false);

  Scope.nested(Scope parent, String debugName, {bool isModifiable: true})
      : this(
            local: <String, Builder>{},
            setters: <String, MemberBuilder>{},
            parent: parent,
            debugName: debugName,
            isModifiable: isModifiable);

  Iterator<Builder> get iterator {
    return new ScopeLocalDeclarationIterator(this);
  }

  NameIterator get nameIterator {
    return new ScopeLocalDeclarationNameIterator(this);
  }

  void debug() {
    print("Locals:");
    _local.forEach((key, value) {
      print("  $key: $value (${identityHashCode(value)}) (${value.parent})");
    });
    print("Setters:");
    _setters.forEach((key, value) {
      print("  $key: $value (${identityHashCode(value)}) (${value.parent})");
    });
    print("Extensions:");
    _extensions?.forEach((v) {
      print("  $v");
    });
  }

  /// Patch up the scope, using the two replacement maps to replace builders in
  /// scope. The replacement maps maps from old LibraryBuilder to map, mapping
  /// from name to new (replacement) builder.
  void patchUpScope(Map<LibraryBuilder, Map<String, Builder>> replacementMap,
      Map<LibraryBuilder, Map<String, Builder>> replacementMapSetters) {
    // In the following we refer to non-setters as 'getters' for brevity.
    //
    // We have to replace all getters and setters in [_locals] and [_setters]
    // with the corresponding getters and setters in [replacementMap]
    // and [replacementMapSetters].
    //
    // Since field builders can be replaced by getter and setter builders and
    // vice versa when going from source to dill builder and back, we might not
    // have a 1-to-1 relationship between the existing and replacing builders.
    //
    // For this reason we start by collecting the names of all getters/setters
    // that need (some) replacement. Afterwards we go through these names
    // handling both getters and setters at the same time.
    Set<String> replacedNames = {};
    _local.forEach((String name, Builder builder) {
      if (replacementMap.containsKey(builder.parent)) {
        replacedNames.add(name);
      }
    });
    _setters.forEach((String name, Builder builder) {
      if (replacementMapSetters.containsKey(builder.parent)) {
        replacedNames.add(name);
      }
    });
    if (replacedNames.isNotEmpty) {
      for (String name in replacedNames) {
        // We start be collecting the relation between an existing getter/setter
        // and the getter/setter that will replace it. This information is used
        // below to handle all the different cases that can occur.
        Builder existingGetter = _local[name];
        LibraryBuilder replacementLibraryBuilderFromGetter;
        Builder replacementGetterFromGetter;
        Builder replacementSetterFromGetter;
        if (existingGetter != null &&
            replacementMap.containsKey(existingGetter.parent)) {
          replacementLibraryBuilderFromGetter = existingGetter.parent;
          replacementGetterFromGetter =
              replacementMap[replacementLibraryBuilderFromGetter][name];
          replacementSetterFromGetter =
              replacementMapSetters[replacementLibraryBuilderFromGetter][name];
        }
        Builder existingSetter = _setters[name];
        LibraryBuilder replacementLibraryBuilderFromSetter;
        Builder replacementGetterFromSetter;
        Builder replacementSetterFromSetter;
        if (existingSetter != null &&
            replacementMap.containsKey(existingSetter.parent)) {
          replacementLibraryBuilderFromSetter = existingSetter.parent;
          replacementGetterFromSetter =
              replacementMap[replacementLibraryBuilderFromSetter][name];
          replacementSetterFromSetter =
              replacementMapSetters[replacementLibraryBuilderFromSetter][name];
        }

        if (existingGetter == null) {
          // No existing getter.
          if (replacementGetterFromSetter != null) {
            // We might have had one implicitly from the setter. Use it here,
            // if so. (This is currently not possible, but added to match the
            // case for setters below.)
            _local[name] = replacementGetterFromSetter;
          }
        } else if (existingGetter.parent ==
            replacementLibraryBuilderFromGetter) {
          // The existing getter should be replaced.
          if (replacementGetterFromGetter != null) {
            // With a new getter.
            _local[name] = replacementGetterFromGetter;
          } else {
            // With `null`, i.e. removed. This means that the getter is
            // implicitly available through the setter. (This is currently not
            // possible, but handled here to match the case for setters below).
            _local.remove(name);
          }
        } else {
          // Leave the getter in - it wasn't replaced.
        }
        if (existingSetter == null) {
          // No existing setter.
          if (replacementSetterFromGetter != null) {
            // We might have had one implicitly from the getter. Use it here,
            // if so.
            _setters[name] = replacementSetterFromGetter;
          }
        } else if (existingSetter.parent ==
            replacementLibraryBuilderFromSetter) {
          // The existing setter should be replaced.
          if (replacementSetterFromSetter != null) {
            // With a new setter.
            _setters[name] = replacementSetterFromSetter;
          } else {
            // With `null`, i.e. removed. This means that the setter is
            // implicitly available through the getter. This happens when the
            // getter is a field builder for an assignable field.
            _setters.remove(name);
          }
        } else {
          // Leave the setter in - it wasn't replaced.
        }
      }
    }
    if (_extensions != null) {
      bool needsPatching = false;
      for (ExtensionBuilder extensionBuilder in _extensions) {
        if (replacementMap.containsKey(extensionBuilder.parent)) {
          needsPatching = true;
          break;
        }
      }
      if (needsPatching) {
        Set<ExtensionBuilder> extensionsReplacement =
            new Set<ExtensionBuilder>();
        for (ExtensionBuilder extensionBuilder in _extensions) {
          if (replacementMap.containsKey(extensionBuilder.parent)) {
            assert(replacementMap[extensionBuilder.parent]
                    [extensionBuilder.name] !=
                null);
            extensionsReplacement.add(
                replacementMap[extensionBuilder.parent][extensionBuilder.name]);
            break;
          } else {
            extensionsReplacement.add(extensionBuilder);
          }
        }
        _extensions.clear();
        extensionsReplacement.addAll(extensionsReplacement);
      }
    }
  }

  Scope copyWithParent(Scope parent, String debugName) {
    return new Scope(
        local: super._local,
        setters: super._setters,
        extensions: _extensions,
        parent: parent,
        debugName: debugName,
        isModifiable: isModifiable);
  }

  /// Don't use this. Use [becomePartOf] instead.
  void set parent(_) => unsupported("parent=", -1, null);

  /// This scope becomes equivalent to [scope]. This is used for parts to
  /// become part of their library's scope.
  void becomePartOf(Scope scope) {
    assert(_parent._parent == null);
    assert(scope._parent._parent == null);
    super._local = scope._local;
    super._setters = scope._setters;
    super._parent = scope._parent;
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
      newScope._local[t.name] = t;
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
        local: _local,
        setters: _setters,
        extensions: _extensions,
        parent: _parent,
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
        lookupIn(name, charOffset, fileUri, _local, isInstanceScope);
    if (builder != null) return builder;
    builder = lookupIn(name, charOffset, fileUri, _setters, isInstanceScope);
    if (builder != null && !builder.hasProblem) {
      return new AccessErrorBuilder(name, builder, charOffset, fileUri);
    }
    if (!isInstanceScope) {
      // For static lookup, do not search the parent scope.
      return builder;
    }
    return builder ?? _parent?.lookup(name, charOffset, fileUri);
  }

  Builder lookupSetter(String name, int charOffset, Uri fileUri,
      {bool isInstanceScope: true}) {
    recordUse(name, charOffset, fileUri);
    Builder builder =
        lookupIn(name, charOffset, fileUri, _setters, isInstanceScope);
    if (builder != null) return builder;
    builder = lookupIn(name, charOffset, fileUri, _local, isInstanceScope);
    if (builder != null && !builder.hasProblem) {
      return new AccessErrorBuilder(name, builder, charOffset, fileUri);
    }
    if (!isInstanceScope) {
      // For static lookup, do not search the parent scope.
      return builder;
    }
    return builder ?? _parent?.lookupSetter(name, charOffset, fileUri);
  }

  Builder lookupLocalMember(String name, {bool setter}) {
    return setter ? _setters[name] : _local[name];
  }

  void addLocalMember(String name, Builder member, {bool setter}) {
    if (setter) {
      _setters[name] = member;
    } else {
      _local[name] = member;
    }
  }

  void forEachLocalMember(void Function(String name, Builder member) f) {
    _local.forEach(f);
  }

  void forEachLocalSetter(void Function(String name, MemberBuilder member) f) {
    _setters.forEach(f);
  }

  Iterable<Builder> get localMembers => _local.values;

  Iterable<MemberBuilder> get localSetters => _setters.values;

  bool hasLocalLabel(String name) => labels != null && labels.containsKey(name);

  void declareLabel(String name, JumpTarget target) {
    if (isModifiable) {
      labels ??= <String, JumpTarget>{};
      labels[name] = target;
    } else {
      internalProblem(
          messageInternalProblemExtendingUnmodifiableScope, -1, null);
    }
  }

  void forwardDeclareLabel(String name, JumpTarget target) {
    declareLabel(name, target);
    forwardDeclaredLabels ??= <String, JumpTarget>{};
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

  Map<String, JumpTarget> get unclaimedForwardDeclarations {
    return forwardDeclaredLabels;
  }

  Builder lookupLabel(String name) {
    return (labels == null ? null : labels[name]) ?? _parent?.lookupLabel(name);
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
      _local[name] = builder;
    } else {
      internalProblem(
          messageInternalProblemExtendingUnmodifiableScope, -1, null);
    }
    return null;
  }

  /// Adds [builder] to the extensions in this scope.
  void addExtension(ExtensionBuilder builder) {
    _extensions ??= <ExtensionBuilder>{};
    _extensions.add(builder);
  }

  /// Calls [f] for each extension in this scope and parent scopes.
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _extensions?.forEach(f);
    _parent?.forEachExtension(f);
  }

  void merge(
      Scope scope,
      Builder computeAmbiguousDeclaration(
          String name, Builder existing, Builder member)) {
    Map<String, Builder> map = _local;

    void mergeMember(String name, Builder member) {
      Builder existing = map[name];
      if (existing != null) {
        if (existing != member) {
          member = computeAmbiguousDeclaration(name, existing, member);
        }
      }
      map[name] = member;
    }

    scope._local.forEach(mergeMember);
    map = _setters;
    scope._setters.forEach(mergeMember);
  }

  void forEach(f(String name, Builder member)) {
    _local.forEach(f);
    _setters.forEach(f);
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
    int nestingLevel = (_parent?.writeOn(sink) ?? -1) + 1;
    String indent = "  " * nestingLevel;
    sink.writeln("$indent{");
    _local.forEach((String name, Builder member) {
      sink.writeln("$indent  $name");
    });
    _setters.forEach((String name, Builder member) {
      sink.writeln("$indent  $name=");
    });
    return nestingLevel;
  }

  Scope computeMixinScope() {
    List<String> names = this._local.keys.toList();
    Map<String, Builder> local = <String, Builder>{};
    bool needsCopy = false;
    for (int i = 0; i < names.length; i++) {
      String name = names[i];
      Builder declaration = this._local[name];
      if (declaration.isStatic) {
        needsCopy = true;
      } else {
        local[name] = declaration;
      }
    }
    names = this._setters.keys.toList();
    Map<String, MemberBuilder> setters = <String, MemberBuilder>{};
    for (int i = 0; i < names.length; i++) {
      String name = names[i];
      MemberBuilder declaration = this._setters[name];
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
            parent: _parent,
            debugName: classNameOrDebugName,
            isModifiable: isModifiable)
        : this;
  }
}

class ConstructorScope {
  /// Constructors declared in this scope.
  final Map<String, MemberBuilder> local;

  final String className;

  ConstructorScope(this.className, this.local);

  void forEach(f(String name, MemberBuilder member)) {
    local.forEach(f);
  }

  Builder lookup(String name, int charOffset, Uri fileUri) {
    Builder builder = local[name];
    if (builder == null) return null;
    if (builder.next != null) {
      return new AmbiguousMemberBuilder(
          name.isEmpty ? className : name, builder, charOffset, fileUri);
    } else {
      return builder;
    }
  }

  String toString() => "ConstructorScope($className, ${local.keys})";
}

abstract class LazyScope extends Scope {
  LazyScope(Map<String, Builder> local, Map<String, MemberBuilder> setters,
      Scope parent, String debugName, {bool isModifiable: true})
      : super(
            local: local,
            setters: setters,
            parent: parent,
            debugName: debugName,
            isModifiable: isModifiable);

  /// Override this method to lazily populate the scope before access.
  void ensureScope();

  @override
  Map<String, Builder> get _local {
    ensureScope();
    return super._local;
  }

  @override
  Map<String, MemberBuilder> get _setters {
    ensureScope();
    return super._setters;
  }

  @override
  Set<ExtensionBuilder> get _extensions {
    ensureScope();
    return super._extensions;
  }
}

class ScopeBuilder {
  final Scope scope;

  ScopeBuilder(this.scope);

  void addMember(String name, Builder builder) {
    scope._local[name] = builder;
  }

  void addSetter(String name, Builder builder) {
    scope._setters[name] = builder;
  }

  void addExtension(ExtensionBuilder builder) {
    scope.addExtension(builder);
  }

  Builder operator [](String name) => scope._local[name];
}

class ConstructorScopeBuilder {
  final ConstructorScope scope;

  ConstructorScopeBuilder(this.scope);

  void addMember(String name, Builder builder) {
    scope.local[name] = builder;
  }

  MemberBuilder operator [](String name) => scope.local[name];
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

mixin ErroneousMemberBuilderMixin implements MemberBuilder {
  @override
  Member get member => null;

  @override
  Member get readTarget => null;

  @override
  Member get writeTarget => null;

  @override
  Member get invokeTarget => null;

  @override
  Iterable<Member> get exportedMembers => const [];

  bool get isNative => false;

  @override
  bool get isAssignable => false;

  @override
  bool get isExternal => false;

  @override
  bool get isAbstract => false;

  @override
  void set parent(Builder value) {
    throw new UnsupportedError('AmbiguousMemberBuilder.parent=');
  }

  @override
  LibraryBuilder get library {
    throw new UnsupportedError('AmbiguousMemberBuilder.parent=');
  }

  // TODO(johnniwinther): Remove this and create a [ProcedureBuilder] interface.
  @override
  ProcedureKind get kind => null;

  @override
  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes) {
    throw new UnsupportedError(
        'AmbiguousMemberBuilder.buildOutlineExpressions');
  }

  @override
  List<ClassMember> get localMembers => const <ClassMember>[];

  @override
  List<ClassMember> get localSetters => const <ClassMember>[];
}

class AmbiguousMemberBuilder extends AmbiguousBuilder
    with ErroneousMemberBuilderMixin {
  AmbiguousMemberBuilder(
      String name, Builder builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);
}

class ScopeLocalDeclarationIterator implements Iterator<Builder> {
  Iterator<Builder> local;
  final Iterator<Builder> setters;

  @override
  Builder current;

  ScopeLocalDeclarationIterator(Scope scope)
      : local = scope._local.values.iterator,
        setters = scope._setters.values.iterator;

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
      : localNames = scope._local.keys.iterator,
        setterNames = scope._setters.keys.iterator,
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
