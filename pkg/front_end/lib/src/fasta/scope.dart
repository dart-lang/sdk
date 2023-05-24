// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scope;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import 'builder/builder.dart';
import 'builder/class_builder.dart';
import 'builder/extension_builder.dart';
import 'builder/library_builder.dart';
import 'builder/member_builder.dart';
import 'builder/name_iterator.dart';
import 'builder/type_variable_builder.dart';
import 'fasta_codes.dart';
import 'kernel/body_builder.dart' show JumpTarget;
import 'kernel/body_builder_context.dart';
import 'kernel/hierarchy/class_member.dart' show ClassMember;
import 'kernel/kernel_helper.dart';
import 'problems.dart' show internalProblem, unsupported;
import 'source/source_class_builder.dart';
import 'source/source_extension_builder.dart';
import 'source/source_library_builder.dart';
import 'source/source_member_builder.dart';
import 'util/helpers.dart' show DelayedActionPerformer;

enum ScopeKind {
  /// Scope of pattern switch-case statements
  ///
  /// These scopes receive special treatment in that they are end-points of the
  /// scope stack in presence of multiple heads for the same case, but can have
  /// nested scopes if it's just a single head. In that latter possibility the
  /// body of the case is nested into the scope of the case head. And for switch
  /// expressions that scope includes both the head and the case expression.
  caseHead,

  /// The declaration-level scope for classes, enums, and similar declarations
  declaration,

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

  /// Top-level scope of a library
  library,

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

class MutableScope {
  /// Names declared in this scope.
  Map<String, Builder>? _local;

  /// Setters declared in this scope.
  Map<String, MemberBuilder>? _setters;

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
  Set<ExtensionBuilder>? _extensions;

  /// The scope that this scope is nested within, or `null` if this is the top
  /// level scope.
  Scope? _parent;

  final String classNameOrDebugName;

  final ScopeKind kind;

  MutableScope(this.kind, this._local, this._setters, this._extensions,
      this._parent, this.classNameOrDebugName) {
    // ignore: unnecessary_null_comparison
    assert(classNameOrDebugName != null);
  }

  Scope? get parent => _parent;

  @override
  String toString() => "Scope(${kind}, $classNameOrDebugName, ${_local?.keys})";
}

class Scope extends MutableScope {
  /// Indicates whether an attempt to declare new names in this scope should
  /// succeed.
  final bool isModifiable;

  Map<String, JumpTarget>? labels;

  Map<String, JumpTarget>? forwardDeclaredLabels;

  Map<String, int>? usedNames;

  Scope(
      {required ScopeKind kind,
      Map<String, Builder>? local,
      Map<String, MemberBuilder>? setters,
      Set<ExtensionBuilder>? extensions,
      Scope? parent,
      required String debugName,
      this.isModifiable = true})
      : super(kind, local, setters, extensions, parent, debugName);

  Scope.top({required ScopeKind kind, bool isModifiable = false})
      : this(
            kind: kind,
            local: <String, Builder>{},
            setters: <String, MemberBuilder>{},
            debugName: "top",
            isModifiable: isModifiable);

  Scope.immutable({required ScopeKind kind})
      : this(
            kind: kind,
            local: const <String, Builder>{},
            setters: const <String, MemberBuilder>{},
            debugName: "immutable",
            isModifiable: false);

  Scope.nested(Scope parent, String debugName,
      {bool isModifiable = true, required ScopeKind kind})
      : this(
            kind: kind,
            parent: parent,
            debugName: debugName,
            isModifiable: isModifiable);

  /// Returns an iterator of all members and setters mapped in this scope,
  /// including duplicate members mapped to the same name.
  ///
  /// The iterator does _not_ include the members and setters mapped in the
  /// [parent] scope.
  Iterator<Builder> get unfilteredIterator {
    return new ScopeIterator(this);
  }

  /// Returns an iterator of all members and setters mapped in this scope,
  /// including duplicate members mapped to the same name.
  ///
  /// The iterator does _not_ include the members and setters mapped in the
  /// [parent] scope.
  ///
  /// Compared to [unfilteredIterator] this iterator also gives access to the
  /// name that the builders are mapped to.
  NameIterator get unfilteredNameIterator {
    return new ScopeNameIterator(this);
  }

  /// Returns a filtered iterator of members and setters mapped in this scope.
  ///
  /// Only members of type [T] are included. If [parent] is provided, on members
  /// declared in [parent] are included. If [includeDuplicates] is `true`, all
  /// duplicates of the same name are included, otherwise, only the first
  /// declared member is included. If [includeAugmentations] is `true`, both
  /// original and augmenting/patching members are included, otherwise, only
  /// original members are included.
  Iterator<T> filteredIterator<T extends Builder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations}) {
    return new FilteredIterator<T>(unfilteredIterator,
        parent: parent,
        includeDuplicates: includeDuplicates,
        includeAugmentations: includeAugmentations);
  }

  /// Returns a filtered iterator of members and setters mapped in this scope.
  ///
  /// Only members of type [T] are included. If [parent] is provided, on members
  /// declared in [parent] are included. If [includeDuplicates] is `true`, all
  /// duplicates of the same name are included, otherwise, only the first
  /// declared member is included. If [includeAugmentations] is `true`, both
  /// original and augmenting/patching members are included, otherwise, only
  /// original members are included.
  ///
  /// Compared to [filteredIterator] this iterator also gives access to the
  /// name that the builders are mapped to.
  NameIterator<T> filteredNameIterator<T extends Builder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations}) {
    return new FilteredNameIterator<T>(unfilteredNameIterator,
        parent: parent,
        includeDuplicates: includeDuplicates,
        includeAugmentations: includeAugmentations);
  }

  void debug() {
    print("Locals:");
    _local?.forEach((key, value) {
      print("  $key: $value (${identityHashCode(value)}) (${value.parent})");
    });
    print("Setters:");
    _setters?.forEach((key, value) {
      print("  $key: $value (${identityHashCode(value)}) (${value.parent})");
    });
    print("Extensions:");
    _extensions?.forEach((v) {
      print("  $v");
    });
  }

  /// Patch up the scope, using the two replacement maps to replace builders in
  /// scope. The replacement maps from old LibraryBuilder to map, mapping
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
    _local?.forEach((String name, Builder builder) {
      if (replacementMap.containsKey(builder.parent)) {
        replacedNames.add(name);
      }
    });
    _setters?.forEach((String name, Builder builder) {
      if (replacementMapSetters.containsKey(builder.parent)) {
        replacedNames.add(name);
      }
    });
    if (replacedNames.isNotEmpty) {
      for (String name in replacedNames) {
        // We start be collecting the relation between an existing getter/setter
        // and the getter/setter that will replace it. This information is used
        // below to handle all the different cases that can occur.
        Builder? existingGetter = _local?[name];
        LibraryBuilder? replacementLibraryBuilderFromGetter;
        Builder? replacementGetterFromGetter;
        Builder? replacementSetterFromGetter;
        if (existingGetter != null &&
            replacementMap.containsKey(existingGetter.parent)) {
          replacementLibraryBuilderFromGetter =
              existingGetter.parent as LibraryBuilder;
          replacementGetterFromGetter =
              replacementMap[replacementLibraryBuilderFromGetter]![name];
          replacementSetterFromGetter =
              replacementMapSetters[replacementLibraryBuilderFromGetter]![name];
        }
        Builder? existingSetter = _setters?[name];
        LibraryBuilder? replacementLibraryBuilderFromSetter;
        Builder? replacementGetterFromSetter;
        Builder? replacementSetterFromSetter;
        if (existingSetter != null &&
            replacementMap.containsKey(existingSetter.parent)) {
          replacementLibraryBuilderFromSetter =
              existingSetter.parent as LibraryBuilder;
          replacementGetterFromSetter =
              replacementMap[replacementLibraryBuilderFromSetter]![name];
          replacementSetterFromSetter =
              replacementMapSetters[replacementLibraryBuilderFromSetter]![name];
        }

        if (existingGetter == null) {
          // No existing getter.
          if (replacementGetterFromSetter != null) {
            // We might have had one implicitly from the setter. Use it here,
            // if so. (This is currently not possible, but added to match the
            // case for setters below.)
            (_local ??= {})[name] = replacementGetterFromSetter;
          }
        } else if (existingGetter.parent ==
            replacementLibraryBuilderFromGetter) {
          // The existing getter should be replaced.
          if (replacementGetterFromGetter != null) {
            // With a new getter.
            (_local ??= {})[name] = replacementGetterFromGetter;
          } else {
            // With `null`, i.e. removed. This means that the getter is
            // implicitly available through the setter. (This is currently not
            // possible, but handled here to match the case for setters below).
            _local?.remove(name);
          }
        } else {
          // Leave the getter in - it wasn't replaced.
        }
        if (existingSetter == null) {
          // No existing setter.
          if (replacementSetterFromGetter != null) {
            // We might have had one implicitly from the getter. Use it here,
            // if so.
            (_setters ??= {})[name] =
                replacementSetterFromGetter as MemberBuilder;
          }
        } else if (existingSetter.parent ==
            replacementLibraryBuilderFromSetter) {
          // The existing setter should be replaced.
          if (replacementSetterFromSetter != null) {
            // With a new setter.
            (_setters ??= {})[name] =
                replacementSetterFromSetter as MemberBuilder;
          } else {
            // With `null`, i.e. removed. This means that the setter is
            // implicitly available through the getter. This happens when the
            // getter is a field builder for an assignable field.
            _setters?.remove(name);
          }
        } else {
          // Leave the setter in - it wasn't replaced.
        }
      }
    }
    if (_extensions != null) {
      bool needsPatching = false;
      for (ExtensionBuilder extensionBuilder in _extensions!) {
        if (replacementMap.containsKey(extensionBuilder.parent)) {
          needsPatching = true;
          break;
        }
      }
      if (needsPatching) {
        Set<ExtensionBuilder> extensionsReplacement =
            new Set<ExtensionBuilder>();
        for (ExtensionBuilder extensionBuilder in _extensions!) {
          if (replacementMap.containsKey(extensionBuilder.parent)) {
            assert(replacementMap[extensionBuilder.parent]![
                    extensionBuilder.name] !=
                null);
            extensionsReplacement.add(
                replacementMap[extensionBuilder.parent]![extensionBuilder.name]
                    as ExtensionBuilder);
            break;
          } else {
            extensionsReplacement.add(extensionBuilder);
          }
        }
        _extensions!.clear();
        extensionsReplacement.addAll(extensionsReplacement);
      }
    }
  }

  Scope copyWithParent(Scope parent, String debugName) {
    return new Scope(
        kind: kind,
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
    assert(_parent!._parent == null);
    assert(scope._parent!._parent == null);
    super._local = scope._local;
    super._setters = scope._setters;
    super._parent = scope._parent;
    super._extensions = scope._extensions;
  }

  Scope createNestedScope(
      {required String debugName,
      bool isModifiable = true,
      required ScopeKind kind}) {
    return new Scope.nested(this, debugName,
        isModifiable: isModifiable, kind: kind);
  }

  Scope withTypeVariables(List<TypeVariableBuilder>? typeVariables) {
    if (typeVariables == null) return this;
    Scope newScope = new Scope.nested(this, "type variables",
        isModifiable: false, kind: ScopeKind.typeParameters);
    for (TypeVariableBuilder t in typeVariables) {
      (newScope._local ??= {})[t.name] = t;
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
    // The scopes needs to reference the same locals and setters so we have to
    // eagerly initialize them.
    _local ??= {};
    _setters ??= {};
    return new Scope(
        kind: ScopeKind.labels,
        local: _local,
        setters: _setters,
        extensions: _extensions,
        parent: _parent,
        debugName: "label",
        isModifiable: true);
  }

  void recordUse(String name, int charOffset) {
    if (isModifiable) {
      usedNames ??= <String, int>{};
      // Don't use putIfAbsent to avoid the context allocation needed
      // for the closure.
      usedNames![name] ??= charOffset;
    }
  }

  Builder? lookupIn(String name, int charOffset, Uri fileUri,
      Map<String, Builder> map, bool isInstanceScope) {
    Builder? builder = map[name];
    if (builder == null) return null;
    if (builder.next != null) {
      return new AmbiguousBuilder(name.isEmpty ? classNameOrDebugName : name,
          builder, charOffset, fileUri);
    } else if (!isInstanceScope && builder.isDeclarationInstanceMember) {
      return null;
    } else if (builder is MemberBuilder && builder.isConflictingSetter) {
      // TODO(johnniwinther): Use a variant of [AmbiguousBuilder] for this case.
      return null;
    } else {
      return builder;
    }
  }

  /// Lookup a member with [name] in the scope.
  Builder? lookup(String name, int charOffset, Uri fileUri,
      {bool isInstanceScope = true}) {
    recordUse(name, charOffset);
    Builder? builder;
    if (_local != null) {
      builder = lookupIn(name, charOffset, fileUri, _local!, isInstanceScope);
      if (builder != null) return builder;
    }
    if (_setters != null) {
      builder = lookupIn(name, charOffset, fileUri, _setters!, isInstanceScope);
      if (builder != null && !builder.hasProblem) {
        return new AccessErrorBuilder(name, builder, charOffset, fileUri);
      }
      if (!isInstanceScope) {
        // For static lookup, do not search the parent scope.
        return builder;
      }
    }
    return builder ?? _parent?.lookup(name, charOffset, fileUri);
  }

  Builder? lookupSetter(String name, int charOffset, Uri fileUri,
      {bool isInstanceScope = true}) {
    recordUse(name, charOffset);
    Builder? builder;
    if (_setters != null) {
      builder = lookupIn(name, charOffset, fileUri, _setters!, isInstanceScope);
      if (builder != null) return builder;
    }
    if (_local != null) {
      builder = lookupIn(name, charOffset, fileUri, _local!, isInstanceScope);
      if (builder != null && !builder.hasProblem) {
        return new AccessErrorBuilder(name, builder, charOffset, fileUri);
      }
      if (!isInstanceScope) {
        // For static lookup, do not search the parent scope.
        return builder;
      }
    }
    return builder ?? _parent?.lookupSetter(name, charOffset, fileUri);
  }

  Builder? lookupLocalMember(String name, {required bool setter}) {
    return setter ? (_setters?[name]) : (_local?[name]);
  }

  void addLocalMember(String name, Builder member, {required bool setter}) {
    if (setter) {
      (_setters ??= {})[name] = member as MemberBuilder;
    } else {
      (_local ??= {})[name] = member;
    }
  }

  void forEachLocalMember(void Function(String name, Builder member) f) {
    _local?.forEach(f);
  }

  void forEachLocalSetter(void Function(String name, MemberBuilder member) f) {
    _setters?.forEach(f);
  }

  ExtensionBuilder? lookupLocalUnnamedExtension(Uri fileUri, int offset) {
    if (_extensions != null) {
      for (ExtensionBuilder extension in _extensions!) {
        if (extension.fileUri == fileUri && extension.charOffset == offset) {
          return extension;
        }
      }
    }
    return null;
  }

  void forEachLocalExtension(void Function(ExtensionBuilder member) f) {
    _extensions?.forEach(f);
  }

  Iterable<Builder> get localMembers => _local?.values ?? const {};

  Iterable<MemberBuilder> get localSetters => _setters?.values ?? const {};

  bool hasLocalLabel(String name) =>
      labels != null && labels!.containsKey(name);

  void declareLabel(String name, JumpTarget target) {
    if (isModifiable) {
      labels ??= <String, JumpTarget>{};
      labels![name] = target;
    } else {
      internalProblem(
          messageInternalProblemExtendingUnmodifiableScope, -1, null);
    }
  }

  void forwardDeclareLabel(String name, JumpTarget target) {
    declareLabel(name, target);
    forwardDeclaredLabels ??= <String, JumpTarget>{};
    forwardDeclaredLabels![name] = target;
  }

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

  Map<String, JumpTarget>? get unclaimedForwardDeclarations {
    return forwardDeclaredLabels;
  }

  JumpTarget? lookupLabel(String name) {
    return labels?[name] ?? _parent?.lookupLabel(name);
  }

  /// Declares that the meaning of [name] in this scope is [builder].
  ///
  /// If name was used previously in this scope, this method returns a message
  /// that can be used as context for reporting a compile-time error about
  /// [name] being used before its declared. [fileUri] is used to bind the
  /// location of this message.
  LocatedMessage? declare(String name, Builder builder, Uri fileUri) {
    if (isModifiable) {
      int? offset = usedNames?[name];
      if (offset != null) {
        return templateDuplicatedNamePreviouslyUsedCause
            .withArguments(name)
            .withLocation(fileUri, offset, name.length);
      }
      (_local ??= {})[name] = builder;
    } else {
      internalProblem(
          messageInternalProblemExtendingUnmodifiableScope, -1, null);
    }
    return null;
  }

  /// Adds [builder] to the extensions in this scope.
  void addExtension(ExtensionBuilder builder) {
    _extensions ??= <ExtensionBuilder>{};
    _extensions!.add(builder);
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
    Map<String, Builder> map = const {};

    void mergeMember(String name, Builder member) {
      Builder? existing = map[name];
      if (existing != null) {
        if (existing != member) {
          member = computeAmbiguousDeclaration(name, existing, member);
        }
      }
      map[name] = member;
    }

    if (scope._local != null) {
      map = _local ??= {};
      scope._local?.forEach(mergeMember);
    }
    if (scope._setters != null) {
      map = _setters ??= {};
      scope._setters?.forEach(mergeMember);
    }
    if (scope._extensions != null) {
      (_extensions ??= {}).addAll(scope._extensions!);
    }
  }

  void forEach(f(String name, Builder member)) {
    _local?.forEach(f);
    _setters?.forEach(f);
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
    _local?.forEach((String name, Builder member) {
      sink.writeln("$indent  $name");
    });
    _setters?.forEach((String name, Builder member) {
      sink.writeln("$indent  $name=");
    });
    return nestingLevel;
  }
}

class ConstructorScope {
  /// Constructors declared in this scope.
  final Map<String, MemberBuilder> _local;

  final String className;

  ConstructorScope(this.className, this._local);

  MemberBuilder? lookup(String name, int charOffset, Uri fileUri) {
    MemberBuilder? builder = _local[name];
    if (builder == null) return null;
    if (builder.next != null) {
      return new AmbiguousMemberBuilder(
          name.isEmpty ? className : name, builder, charOffset, fileUri);
    } else {
      return builder;
    }
  }

  MemberBuilder? lookupLocalMember(String name) {
    return _local[name];
  }

  void addLocalMember(String name, MemberBuilder builder) {
    _local[name] = builder;
  }

  void addLocalMembers(Map<String, MemberBuilder> map) {
    _local.addAll(map);
  }

  /// Returns an iterator of all constructors mapped in this scope,
  /// including duplicate constructors mapped to the same name.
  Iterator<MemberBuilder> get unfilteredIterator =>
      new ConstructorScopeIterator(this);

  /// Returns an iterator of all constructors mapped in this scope,
  /// including duplicate constructors mapped to the same name.
  ///
  /// Compared to [unfilteredIterator] this iterator also gives access to the
  /// name that the builders are mapped to.
  NameIterator<MemberBuilder> get unfilteredNameIterator =>
      new ConstructorScopeNameIterator(this);

  /// Returns a filtered iterator of constructors mapped in this scope.
  ///
  /// Only members of type [T] are included. If [parent] is provided, on members
  /// declared in [parent] are included. If [includeDuplicates] is `true`, all
  /// duplicates of the same name are included, otherwise, only the first
  /// declared member is included. If [includeAugmentations] is `true`, both
  /// original and augmenting/patching members are included, otherwise, only
  /// original members are included.
  Iterator<T> filteredIterator<T extends MemberBuilder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations}) {
    return new FilteredIterator<T>(unfilteredIterator,
        parent: parent,
        includeDuplicates: includeDuplicates,
        includeAugmentations: includeAugmentations);
  }

  /// Returns a filtered iterator of constructors mapped in this scope.
  ///
  /// Only members of type [T] are included. If [parent] is provided, on members
  /// declared in [parent] are included. If [includeDuplicates] is `true`, all
  /// duplicates of the same name are included, otherwise, only the first
  /// declared member is included. If [includeAugmentations] is `true`, both
  /// original and augmenting/patching members are included, otherwise, only
  /// original members are included.
  ///
  /// Compared to [filteredIterator] this iterator also gives access to the
  /// name that the builders are mapped to.
  NameIterator<T> filteredNameIterator<T extends MemberBuilder>(
      {Builder? parent,
      required bool includeDuplicates,
      required bool includeAugmentations}) {
    return new FilteredNameIterator<T>(unfilteredNameIterator,
        parent: parent,
        includeDuplicates: includeDuplicates,
        includeAugmentations: includeAugmentations);
  }

  @override
  String toString() => "ConstructorScope($className, ${_local.keys})";
}

abstract class LazyScope extends Scope {
  LazyScope(Map<String, Builder> local, Map<String, MemberBuilder> setters,
      Scope? parent, String debugName,
      {bool isModifiable = true, required ScopeKind kind})
      : super(
            kind: kind,
            local: local,
            setters: setters,
            parent: parent,
            debugName: debugName,
            isModifiable: isModifiable);

  /// Override this method to lazily populate the scope before access.
  void ensureScope();

  @override
  Map<String, Builder>? get _local {
    ensureScope();
    return super._local;
  }

  @override
  Map<String, MemberBuilder>? get _setters {
    ensureScope();
    return super._setters;
  }

  @override
  Set<ExtensionBuilder>? get _extensions {
    ensureScope();
    return super._extensions;
  }
}

abstract class ProblemBuilder extends BuilderImpl {
  final String name;

  final Builder builder;

  @override
  final int charOffset;

  @override
  final Uri fileUri;

  ProblemBuilder(this.name, this.builder, this.charOffset, this.fileUri);

  @override
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
  Builder? get parent => builder.parent;

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
  bool get isInlineClassInstanceMember => builder.isInlineClassInstanceMember;

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
  Builder? get parent => null;

  @override
  Message get message => templateDuplicatedDeclarationUse.withArguments(name);

  // TODO(ahe): Also provide context.

  Builder getFirstDeclaration() {
    Builder declaration = builder;
    while (declaration.next != null) {
      declaration = declaration.next!;
    }
    return declaration;
  }
}

mixin ErroneousMemberBuilderMixin implements SourceMemberBuilder {
  @override
  MemberDataForTesting? get dataForTesting => null;

  @override
  Member get member => throw new UnsupportedError('$runtimeType.member');

  @override
  Member? get readTarget => null;

  @override
  Member? get writeTarget => null;

  @override
  Member? get invokeTarget => null;

  @override
  Iterable<Member> get exportedMembers => const [];

  @override
  bool get isNative => false;

  @override
  bool get isAssignable => false;

  @override
  bool get isExternal => false;

  @override
  bool get isAbstract => false;

  @override
  bool get isConflictingSetter => false;

  @override
  bool get isConflictingAugmentationMember => false;

  @override
  void set isConflictingAugmentationMember(bool value) {
    throw new UnsupportedError('$runtimeType.isConflictingAugmentationMember=');
  }

  @override
  void set parent(Builder? value) {
    throw new UnsupportedError('$runtimeType.parent=');
  }

  @override
  ClassBuilder get classBuilder {
    throw new UnsupportedError('$runtimeType.classBuilder');
  }

  @override
  SourceLibraryBuilder get libraryBuilder {
    throw new UnsupportedError('$runtimeType.library');
  }

  // TODO(johnniwinther): Remove this and create a [ProcedureBuilder] interface.
  @override
  ProcedureKind? get kind => null;

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    throw new UnsupportedError('$runtimeType.buildOutlineExpressions');
  }

  @override
  void buildOutlineNodes(void Function(Member, BuiltMemberKind) f) {
    assert(false, "Unexpected call to $runtimeType.buildOutlineNodes.");
  }

  @override
  int buildBodyNodes(void Function(Member, BuiltMemberKind) f) {
    assert(false, "Unexpected call to $runtimeType.buildBodyNodes.");
    return 0;
  }

  @override
  List<ClassMember> get localMembers => const <ClassMember>[];

  @override
  List<ClassMember> get localSetters => const <ClassMember>[];

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    assert(false, "Unexpected call to $runtimeType.checkVariance.");
  }

  @override
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment) {
    assert(false, "Unexpected call to $runtimeType.checkVariance.");
  }

  @override
  bool get isAugmentation {
    throw new UnsupportedError('$runtimeType.isAugmentation');
  }

  @override
  AugmentSuperTarget? get augmentSuperTarget {
    throw new UnsupportedError('$runtimeType.augmentSuperTarget}');
  }

  @override
  BodyBuilderContext get bodyBuilderContext {
    throw new UnsupportedError(
        '$runtimeType.bodyBuilderContextForAnnotations}');
  }
}

class AmbiguousMemberBuilder extends AmbiguousBuilder
    with ErroneousMemberBuilderMixin {
  AmbiguousMemberBuilder(
      String name, Builder builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);
}

/// Iterator over builders mapped in a [Scope], including duplicates for each
/// directly mapped builder.
class ScopeIterator implements Iterator<Builder> {
  Iterator<Builder>? local;
  Iterator<Builder>? setters;
  Iterator<Builder>? extensions;

  Builder? _current;

  ScopeIterator(Scope scope)
      : local = scope._local?.values.iterator,
        setters = scope._setters?.values.iterator,
        extensions = scope._extensions?.iterator;

  @override
  bool moveNext() {
    Builder? next = _current?.next;
    if (next != null) {
      _current = next;
      return true;
    }
    if (local != null) {
      if (local!.moveNext()) {
        _current = local!.current;
        return true;
      }
      local = null;
    }
    if (setters != null) {
      if (setters!.moveNext()) {
        _current = setters!.current;
        return true;
      }
      setters = null;
    }
    if (extensions != null) {
      while (extensions!.moveNext()) {
        Builder extension = extensions!.current;
        // Named extensions have already been included throw [local] so we skip
        // them here.
        if (extension is SourceExtensionBuilder &&
            extension.isUnnamedExtension) {
          _current = extension;
          return true;
        }
      }
      extensions = null;
    }
    _current = null;
    return false;
  }

  @override
  Builder get current {
    return _current ?? (throw new StateError('No element'));
  }
}

/// Iterator over builders mapped in a [Scope], including duplicates for each
/// directly mapped builder.
///
/// Compared to [ScopeIterator] this iterator also gives
/// access to the name that the builders are mapped to.
class ScopeNameIterator extends ScopeIterator implements NameIterator<Builder> {
  Iterator<String>? localNames;
  Iterator<String>? setterNames;

  String? _name;

  ScopeNameIterator(Scope scope)
      : localNames = scope._local?.keys.iterator,
        setterNames = scope._setters?.keys.iterator,
        super(scope);

  @override
  bool moveNext() {
    Builder? next = _current?.next;
    if (next != null) {
      _current = next;
      return true;
    }
    if (local != null) {
      if (local!.moveNext()) {
        localNames!.moveNext();
        _current = local!.current;
        _name = localNames!.current;
        return true;
      }
      local = null;
      localNames = null;
    }
    if (setters != null) {
      if (setters!.moveNext()) {
        setterNames!.moveNext();
        _current = setters!.current;
        _name = setterNames!.current;
        return true;
      }
      setters = null;
      setterNames = null;
    }
    if (extensions != null) {
      while (extensions!.moveNext()) {
        Builder extension = extensions!.current;
        // Named extensions have already been included throw [local] so we skip
        // them here.
        if (extension is SourceExtensionBuilder &&
            extension.isUnnamedExtension) {
          _current = extension;
          _name = extension.name;
          return true;
        }
      }
      extensions = null;
    }
    _current = null;
    _name = null;
    return false;
  }

  @override
  String get name {
    return _name ?? (throw new StateError('No element'));
  }
}

/// Iterator over builders mapped in a [ConstructorScope], including duplicates
/// for each directly mapped builder.
class ConstructorScopeIterator implements Iterator<MemberBuilder> {
  Iterator<MemberBuilder> local;

  MemberBuilder? _current;

  ConstructorScopeIterator(ConstructorScope scope)
      : local = scope._local.values.iterator;

  @override
  bool moveNext() {
    MemberBuilder? next = _current?.next as MemberBuilder?;
    if (next != null) {
      _current = next;
      return true;
    }
    if (local.moveNext()) {
      _current = local.current;
      return true;
    }
    return false;
  }

  @override
  MemberBuilder get current {
    return _current ?? (throw new StateError('No element'));
  }
}

/// Iterator over builders mapped in a [ConstructorScope], including duplicates
/// for each directly mapped builder.
///
/// Compared to [ConstructorScopeIterator] this iterator also gives
/// access to the name that the builders are mapped to.
class ConstructorScopeNameIterator extends ConstructorScopeIterator
    implements NameIterator<MemberBuilder> {
  final Iterator<String> localNames;

  String? _name;

  ConstructorScopeNameIterator(ConstructorScope scope)
      : localNames = scope._local.keys.iterator,
        super(scope);

  @override
  bool moveNext() {
    MemberBuilder? next = _current?.next as MemberBuilder?;
    if (next != null) {
      _current = next;
      return true;
    }
    if (local.moveNext()) {
      localNames.moveNext();
      _current = local.current;
      _name = localNames.current;
      return true;
    }
    _current = null;
    _name = null;
    return false;
  }

  @override
  String get name {
    return _name ?? (throw new StateError('No element'));
  }
}

/// Filtered builder [Iterator].
class FilteredIterator<T extends Builder> implements Iterator<T> {
  final Iterator<Builder> _iterator;
  final Builder? parent;
  final bool includeDuplicates;
  final bool includeAugmentations;

  FilteredIterator(this._iterator,
      {required this.parent,
      required this.includeDuplicates,
      required this.includeAugmentations});

  bool _include(Builder element) {
    if (parent != null && element.parent != parent) return false;
    if (!includeDuplicates &&
        (element.isDuplicate || element.isConflictingAugmentationMember)) {
      return false;
    }
    if (!includeAugmentations && element.isPatch) return false;
    return element is T;
  }

  @override
  T get current => _iterator.current as T;

  @override
  bool moveNext() {
    while (_iterator.moveNext()) {
      Builder candidate = _iterator.current;
      if (_include(candidate)) {
        return true;
      }
    }
    return false;
  }
}

/// Filtered [NameIterator].
///
/// Compared to [FilteredIterator] this iterator also gives
/// access to the name that the builders are mapped to.
class FilteredNameIterator<T extends Builder> implements NameIterator<T> {
  final NameIterator<Builder> _iterator;
  final Builder? parent;
  final bool includeDuplicates;
  final bool includeAugmentations;

  FilteredNameIterator(this._iterator,
      {required this.parent,
      required this.includeDuplicates,
      required this.includeAugmentations});

  bool _include(Builder element) {
    if (parent != null && element.parent != parent) return false;
    if (!includeDuplicates &&
        (element.isDuplicate || element.isConflictingAugmentationMember)) {
      return false;
    }
    if (!includeAugmentations && element.isPatch) return false;
    return element is T;
  }

  @override
  T get current => _iterator.current as T;

  @override
  String get name => _iterator.name;

  @override
  bool moveNext() {
    while (_iterator.moveNext()) {
      Builder candidate = _iterator.current;
      if (_include(candidate)) {
        return true;
      }
    }
    return false;
  }
}

extension IteratorExtension<T extends Builder> on Iterator<T> {
  void forEach(void Function(T) f) {
    while (moveNext()) {
      f(current);
    }
  }

  List<T> toList() {
    List<T> list = [];
    while (moveNext()) {
      list.add(current);
    }
    return list;
  }

  Iterator<T> join(Iterator<T> other) {
    return new IteratorSequence<T>([this, other]);
  }
}

extension NameIteratorExtension<T extends Builder> on NameIterator<T> {
  void forEach(void Function(String, T) f) {
    while (moveNext()) {
      f(name, current);
    }
  }
}

abstract class MergedScope<T extends Builder> {
  final T _origin;
  final Scope _originScope;
  Map<T, Scope> _augmentationScopes = {};

  MergedScope(this._origin, this._originScope);

  SourceLibraryBuilder get originLibrary;

  void _addBuilderToMergedScope(T parentBuilder, String name,
      Builder newBuilder, Builder? existingBuilder,
      {required bool setter}) {
    if (existingBuilder != null) {
      if (parentBuilder.isAugmentation) {
        if (newBuilder.isAugmentation) {
          existingBuilder.applyPatch(newBuilder);
        } else {
          newBuilder.isConflictingAugmentationMember = true;
          Message message;
          Message context;
          if (newBuilder is SourceMemberBuilder &&
              existingBuilder is SourceMemberBuilder) {
            if (_origin is SourceLibraryBuilder) {
              message = templateNonAugmentationLibraryMemberConflict
                  .withArguments(name);
            } else {
              message = templateNonAugmentationClassMemberConflict
                  .withArguments(name);
            }
            context = messageNonAugmentationMemberConflictCause;
          } else if (newBuilder is SourceClassBuilder &&
              existingBuilder is SourceClassBuilder) {
            message = templateNonAugmentationClassConflict.withArguments(name);
            context = messageNonAugmentationClassConflictCause;
          } else {
            if (_origin is SourceLibraryBuilder) {
              message =
                  templateNonAugmentationLibraryConflict.withArguments(name);
            } else {
              message = templateNonAugmentationClassMemberConflict
                  .withArguments(name);
            }
            context = messageNonAugmentationMemberConflictCause;
          }
          originLibrary.addProblem(
              message, newBuilder.charOffset, name.length, newBuilder.fileUri,
              context: [
                context.withLocation(existingBuilder.fileUri!,
                    existingBuilder.charOffset, name.length)
              ]);
        }
      } else {
        // Patch libraries implicitly assume matching members are patch
        // members.
        existingBuilder.applyPatch(newBuilder);
      }
    } else {
      if (newBuilder.isAugmentation) {
        Message message;
        if (newBuilder is SourceMemberBuilder) {
          if (_origin is SourceLibraryBuilder) {
            message =
                templateUnmatchedAugmentationLibraryMember.withArguments(name);
          } else {
            message =
                templateUnmatchedAugmentationClassMember.withArguments(name);
          }
        } else if (newBuilder is SourceClassBuilder) {
          message = templateUnmatchedAugmentationClass.withArguments(name);
        } else {
          message =
              templateUnmatchedAugmentationDeclaration.withArguments(name);
        }
        originLibrary.addProblem(
            message, newBuilder.charOffset, name.length, newBuilder.fileUri);
      } else {
        if (!parentBuilder.isAugmentation && !name.startsWith('_')) {
          // We special-case public members injected in patch libraries.
          // TODO(johnniwinther): Avoid this special-casing and just report the
          // error.
          _addInjectedPatchMember(name, newBuilder);
        } else {
          _originScope.addLocalMember(name, newBuilder, setter: setter);
          if (newBuilder is ExtensionBuilder) {
            _originScope.addExtension(newBuilder);
          }
          for (Scope augmentationScope in _augmentationScopes.values) {
            _addBuilderToAugmentationScope(augmentationScope, name, newBuilder,
                setter: setter);
          }
        }
      }
    }
  }

  void _addBuilderToAugmentationScope(
      Scope augmentationScope, String name, Builder member,
      {required bool setter}) {
    Builder? augmentationMember =
        augmentationScope.lookupLocalMember(name, setter: setter);
    if (augmentationMember == null) {
      augmentationScope.addLocalMember(name, member, setter: setter);
      if (member is ExtensionBuilder) {
        augmentationScope.addExtension(member);
      }
    }
  }

  void _addAugmentationScope(T parentBuilder, Scope scope) {
    // TODO(johnniwinther): Use `scope.filteredNameIterator` instead of
    // `scope.forEachLocalMember`/`scope.forEachLocalSetter`.

    // Include all augmentation scope members to the origin scope.
    scope.forEachLocalMember((String name, Builder member) {
      // In case of duplicates we use the first declaration.
      while (member.isDuplicate) {
        member = member.next!;
      }
      _addBuilderToMergedScope(parentBuilder, name, member,
          _originScope.lookupLocalMember(name, setter: false),
          setter: false);
    });
    scope.forEachLocalSetter((String name, Builder member) {
      // In case of duplicates we use the first declaration.
      while (member.isDuplicate) {
        member = member.next!;
      }
      _addBuilderToMergedScope(parentBuilder, name, member,
          _originScope.lookupLocalMember(name, setter: true),
          setter: true);
    });
    scope.forEachLocalExtension((ExtensionBuilder extensionBuilder) {
      if (extensionBuilder is SourceExtensionBuilder &&
          extensionBuilder.isUnnamedExtension) {
        _originScope.addExtension(extensionBuilder);
        for (Scope augmentationScope in _augmentationScopes.values) {
          augmentationScope.addExtension(extensionBuilder);
        }
      }
    });

    // Include all origin scope members in the augmentation scope.
    _originScope.forEachLocalMember((String name, Builder originMember) {
      _addBuilderToAugmentationScope(scope, name, originMember, setter: false);
    });
    _originScope.forEachLocalSetter((String name, Builder originMember) {
      _addBuilderToAugmentationScope(scope, name, originMember, setter: true);
    });
    _originScope.forEachLocalExtension((ExtensionBuilder extensionBuilder) {
      if (extensionBuilder is SourceExtensionBuilder &&
          extensionBuilder.isUnnamedExtension) {
        scope.addExtension(extensionBuilder);
      }
    });

    _augmentationScopes[parentBuilder] = scope;
  }

  void _addInjectedPatchMember(String name, Builder newBuilder);
}

class MergedLibraryScope extends MergedScope<SourceLibraryBuilder> {
  MergedLibraryScope(SourceLibraryBuilder origin) : super(origin, origin.scope);

  @override
  SourceLibraryBuilder get originLibrary => _origin;

  void addAugmentationScope(SourceLibraryBuilder builder) {
    _addAugmentationScope(builder, builder.scope);
  }

  @override
  void _addInjectedPatchMember(String name, Builder newBuilder) {
    assert(!name.startsWith('_'), "Unexpected private member $newBuilder");
    _exportMemberFromPatch(name, newBuilder);
  }

  void _exportMemberFromPatch(String name, Builder member) {
    if (!originLibrary.importUri.isScheme("dart") ||
        !originLibrary.importUri.path.startsWith("_")) {
      originLibrary.addProblem(
          templatePatchInjectionFailed.withArguments(
              name, originLibrary.importUri),
          member.charOffset,
          noLength,
          member.fileUri);
    }
    // Platform-private libraries, such as "dart:_internal" have special
    // semantics: public members are injected into the origin library.
    // TODO(ahe): See if we can remove this special case.

    // If this member already exist in the origin library scope, it should
    // have been marked as patch.
    assert((member.isSetter &&
            _originScope.lookupLocalMember(name, setter: true) == null) ||
        (!member.isSetter &&
            _originScope.lookupLocalMember(name, setter: false) == null));
    originLibrary.addToExportScope(name, member);
  }
}

class MergedClassMemberScope extends MergedScope<SourceClassBuilder> {
  final ConstructorScope _originConstructorScope;
  Map<SourceClassBuilder, ConstructorScope> _augmentationConstructorScopes = {};

  MergedClassMemberScope(SourceClassBuilder origin)
      : _originConstructorScope = origin.constructorScope,
        super(origin, origin.scope);

  @override
  SourceLibraryBuilder get originLibrary => _origin.libraryBuilder;

  void _addAugmentationConstructorScope(
      SourceClassBuilder classBuilder, ConstructorScope constructorScope) {
    constructorScope._local
        .forEach((String name, MemberBuilder newConstructor) {
      MemberBuilder? existingConstructor =
          _originConstructorScope.lookupLocalMember(name);
      if (classBuilder.isAugmentation) {
        if (existingConstructor != null) {
          if (newConstructor.isAugmentation) {
            existingConstructor.applyPatch(newConstructor);
          } else {
            newConstructor.isConflictingAugmentationMember = true;
            originLibrary.addProblem(
                templateNonAugmentationConstructorConflict
                    .withArguments(newConstructor.fullNameForErrors),
                newConstructor.charOffset,
                noLength,
                newConstructor.fileUri,
                context: [
                  messageNonAugmentationConstructorConflictCause.withLocation(
                      existingConstructor.fileUri!,
                      existingConstructor.charOffset,
                      noLength)
                ]);
          }
        } else {
          if (newConstructor.isAugmentation) {
            originLibrary.addProblem(
                templateUnmatchedAugmentationConstructor
                    .withArguments(newConstructor.fullNameForErrors),
                newConstructor.charOffset,
                noLength,
                newConstructor.fileUri);
          } else {
            _originConstructorScope.addLocalMember(name, newConstructor);
            for (ConstructorScope augmentationConstructorScope
                in _augmentationConstructorScopes.values) {
              _addConstructorToAugmentationScope(
                  augmentationConstructorScope, name, newConstructor);
            }
          }
        }
      } else {
        if (existingConstructor != null) {
          // Patch libraries implicitly assume matching members are patch
          // members.
          existingConstructor.applyPatch(newConstructor);
        } else if (name.startsWith('_')) {
          // Members injected into patch are not part of the origin scope.
          _originConstructorScope.addLocalMember(name, newConstructor);
          for (ConstructorScope augmentationScope
              in _augmentationConstructorScopes.values) {
            _addConstructorToAugmentationScope(
                augmentationScope, name, newConstructor);
          }
        }
      }
    });
    _originConstructorScope._local
        .forEach((String name, MemberBuilder originConstructor) {
      _addConstructorToAugmentationScope(
          constructorScope, name, originConstructor);
    });
  }

  void _addConstructorToAugmentationScope(
      ConstructorScope augmentationConstructorScope,
      String name,
      MemberBuilder constructor) {
    Builder? augmentationConstructor =
        augmentationConstructorScope.lookupLocalMember(name);
    if (augmentationConstructor == null) {
      augmentationConstructorScope.addLocalMember(name, constructor);
    }
  }

  // TODO(johnniwinther): Check for conflicts between constructors and class
  //  members.
  void addAugmentationScope(SourceClassBuilder builder) {
    _addAugmentationScope(builder, builder.scope);
    _addAugmentationConstructorScope(builder, builder.constructorScope);
  }

  @override
  void _addInjectedPatchMember(String name, Builder newBuilder) {
    // Members injected into patch are not part of the origin scope.
  }
}

extension on Builder {
  bool get isAugmentation {
    Builder self = this;
    if (self is SourceLibraryBuilder) {
      return self.isAugmentation;
    } else if (self is SourceClassBuilder) {
      return self.isAugmentation;
    } else if (self is SourceMemberBuilder) {
      return self.isAugmentation;
    } else {
      return false;
    }
  }

  bool get isConflictingAugmentationMember {
    Builder self = this;
    if (self is SourceMemberBuilder) {
      return self.isConflictingAugmentationMember;
    } else if (self is SourceClassBuilder) {
      return self.isConflictingAugmentationMember;
    }
    // TODO(johnniwinther): Handle all cases here.
    return false;
  }

  void set isConflictingAugmentationMember(bool value) {
    Builder self = this;
    if (self is SourceMemberBuilder) {
      self.isConflictingAugmentationMember = value;
    } else if (self is SourceClassBuilder) {
      self.isConflictingAugmentationMember = value;
    }
    // TODO(johnniwinther): Handle all cases here.
  }
}

class IteratorSequence<T> implements Iterator<T> {
  Iterator<Iterator<T>> _iterators;

  Iterator<T>? _current;

  IteratorSequence(Iterable<Iterator<T>> iterators)
      : _iterators = iterators.iterator;

  @override
  T get current {
    if (_current != null) {
      return _current!.current;
    }
    throw new StateError("No current element");
  }

  @override
  bool moveNext() {
    if (_current != null) {
      if (_current!.moveNext()) {
        return true;
      }
      _current = null;
    }
    while (_iterators.moveNext()) {
      _current = _iterators.current;
      if (_current!.moveNext()) {
        return true;
      }
      _current = null;
    }
    return false;
  }
}
