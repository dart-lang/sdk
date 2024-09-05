// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../base/messages.dart';
import '../base/name_space.dart';
import '../base/problems.dart';
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/function_builder.dart';
import '../builder/member_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/type_builder.dart';
import 'name_scheme.dart';
import 'source_extension_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart';

class LibraryNameSpaceBuilder {
  final Map<String, Builder> _members = {};

  final Map<String, MemberBuilder> _setters = {};

  final Set<ExtensionBuilder> _extensions = {};

  final Map<String, List<Builder>> augmentations = {};

  final Map<String, List<Builder>> setterAugmentations = {};

  /// List of [PrefixBuilder]s for imports with prefixes.
  List<PrefixBuilder>? _prefixBuilders;

  late final NameSpace _nameSpace;

  LibraryNameSpaceBuilder() {
    _nameSpace = new NameSpaceImpl(
        getables: _members, setables: _setters, extensions: _extensions);
  }

  Iterable<Builder> get builders => [
        ..._members.values,
        ..._setters.values,
        for (Builder builder in _extensions)
          if (builder is SourceExtensionBuilder && builder.isUnnamedExtension)
            builder
      ];

  Builder addBuilder(
      SourceLibraryBuilder _parent,
      ProblemReporting _problemReporting,
      String name,
      Builder declaration,
      Uri fileUri,
      int charOffset) {
    if (declaration is SourceExtensionBuilder &&
        declaration.isUnnamedExtension) {
      declaration.parent = _parent;
      _extensions.add(declaration);
      return declaration;
    }

    if (declaration is MemberBuilder) {
      declaration.parent = _parent;
    } else if (declaration is TypeDeclarationBuilder) {
      declaration.parent = _parent;
    } else if (declaration is PrefixBuilder) {
      assert(declaration.parent == _parent);
    } else {
      return unhandled(
          "${declaration.runtimeType}", "addBuilder", charOffset, fileUri);
    }

    assert(
        !(declaration is FunctionBuilder &&
            (declaration.isConstructor || declaration.isFactory)),
        // Coverage-ignore(suite): Not run.
        "Unexpected constructor in library: $declaration.");

    Map<String, Builder> members =
        declaration.isSetter ? _setters : this._members;

    Builder? existing = members[name];

    if (existing == declaration) return declaration;

    if (declaration.next != null && declaration.next != existing) {
      unexpected(
          "${declaration.next!.fileUri}@${declaration.next!.charOffset}",
          "${existing?.fileUri}@${existing?.charOffset}",
          declaration.charOffset,
          declaration.fileUri);
    }
    declaration.next = existing;
    if (declaration is PrefixBuilder && existing is PrefixBuilder) {
      assert(existing.next is! PrefixBuilder);
      Builder? deferred;
      Builder? other;
      if (declaration.deferred) {
        deferred = declaration;
        other = existing;
      } else if (existing.deferred) {
        deferred = existing;
        other = declaration;
      }
      if (deferred != null) {
        // Coverage-ignore-block(suite): Not run.
        _problemReporting.addProblem(
            templateDeferredPrefixDuplicated.withArguments(name),
            deferred.charOffset,
            noLength,
            fileUri,
            context: [
              templateDeferredPrefixDuplicatedCause
                  .withArguments(name)
                  .withLocation(fileUri, other!.charOffset, noLength)
            ]);
      }
      existing.mergeScopes(declaration, _problemReporting, _nameSpace,
          uriOffset: new UriOffset(fileUri, charOffset));
      return existing;
    } else if (isDuplicatedDeclaration(existing, declaration)) {
      String fullName = name;
      _problemReporting.addProblem(
          templateDuplicatedDeclaration.withArguments(fullName),
          charOffset,
          fullName.length,
          declaration.fileUri!,
          context: <LocatedMessage>[
            templateDuplicatedDeclarationCause
                .withArguments(fullName)
                .withLocation(
                    existing!.fileUri!, existing.charOffset, fullName.length)
          ]);
    } else if (declaration.isExtension) {
      // We add the extension declaration to the extension scope only if its
      // name is unique. Only the first of duplicate extensions is accessible
      // by name or by resolution and the remaining are dropped for the output.
      _extensions.add(declaration as SourceExtensionBuilder);
    } else if (declaration.isAugment) {
      if (existing != null) {
        if (declaration.isSetter) {
          (setterAugmentations[name] ??= []).add(declaration);
        } else {
          (augmentations[name] ??= []).add(declaration);
        }
      } else {
        // TODO(cstefantsova): Report an error.
      }
    } else if (declaration is PrefixBuilder) {
      _prefixBuilders ??= <PrefixBuilder>[];
      _prefixBuilders!.add(declaration);
    }
    return members[name] = declaration;
  }

  List<PrefixBuilder>? get prefixBuilders => _prefixBuilders;

  NameSpace toNameSpace() => _nameSpace;
}

class NominalParameterScope extends AbstractTypeParameterScope {
  final NominalParameterNameSpace _nameSpace;

  NominalParameterScope(super._parent, this._nameSpace);

  @override
  Builder? getTypeParameter(String name) => _nameSpace.getTypeParameter(name);
}

class NominalParameterNameSpace {
  Map<String, NominalVariableBuilder> _typeParametersByName = {};

  NominalVariableBuilder? getTypeParameter(String name) =>
      _typeParametersByName[name];

  void addTypeVariables(ProblemReporting _problemReporting,
      List<NominalVariableBuilder>? typeVariables,
      {required String? ownerName, required bool allowNameConflict}) {
    if (typeVariables == null || typeVariables.isEmpty) return;
    for (NominalVariableBuilder tv in typeVariables) {
      NominalVariableBuilder? existing = _typeParametersByName[tv.name];
      if (tv.isWildcard) continue;
      if (existing != null) {
        if (existing.kind == TypeVariableKind.extensionSynthesized) {
          // The type parameter from the extension is shadowed by the type
          // parameter from the member. Rename the shadowed type parameter.
          existing.parameter.name = '#${existing.name}';
          _typeParametersByName[tv.name] = tv;
        } else {
          _problemReporting.addProblem(messageTypeVariableDuplicatedName,
              tv.charOffset, tv.name.length, tv.fileUri,
              context: [
                templateTypeVariableDuplicatedNameCause
                    .withArguments(tv.name)
                    .withLocation(existing.fileUri!, existing.charOffset,
                        existing.name.length)
              ]);
        }
      } else {
        _typeParametersByName[tv.name] = tv;
        // Only classes and extension types and type variables can't have the
        // same name. See
        // [#29555](https://github.com/dart-lang/sdk/issues/29555) and
        // [#54602](https://github.com/dart-lang/sdk/issues/54602).
        if (tv.name == ownerName && !allowNameConflict) {
          _problemReporting.addProblem(messageTypeVariableSameNameAsEnclosing,
              tv.charOffset, tv.name.length, tv.fileUri);
        }
      }
    }
  }
}

enum DeclarationFragmentKind {
  classDeclaration,
  mixinDeclaration,
  enumDeclaration,
  extensionDeclaration,
  extensionTypeDeclaration,
}

sealed class DeclarationFragment {
  final int nameOffset;
  final LookupScope typeParameterScope;
  final DeclarationBuilderScope bodyScope = new DeclarationBuilderScope();
  final List<_AddBuilder> _addedBuilders = [];

  List<SourceFieldBuilder>? primaryConstructorFields;

  final List<NominalVariableBuilder>? typeParameters;

  DeclarationFragment(
      this.nameOffset, this.typeParameters, this.typeParameterScope);

  String get name;

  ContainerName get containerName;

  ContainerType get containerType;

  DeclarationFragmentKind get kind;

  bool declaresConstConstructor = false;

  void addPrimaryConstructorField(SourceFieldBuilder builder) {
    (primaryConstructorFields ??= []).add(builder);
  }

  void addBuilder(
      String name, Builder declaration, Uri fileUri, int charOffset) {
    _addedBuilders.add(new _AddBuilder(name, declaration, fileUri, charOffset));
  }

  DeclarationNameSpaceBuilder toDeclarationNameSpaceBuilder(
      NominalParameterNameSpace? nominalParameterNameSpace) {
    return new DeclarationNameSpaceBuilder._(
        name, nominalParameterNameSpace, _addedBuilders);
  }
}

class ClassFragment extends DeclarationFragment {
  @override
  final String name;

  final ClassName _className;

  ClassFragment(this.name, super.nameOffset, super.typeParameters,
      super.typeParameterScope)
      : _className = new ClassName(name);

  @override
  ContainerName get containerName => _className;

  @override
  ContainerType get containerType => ContainerType.Class;

  @override
  // Coverage-ignore(suite): Not run.
  DeclarationFragmentKind get kind => DeclarationFragmentKind.classDeclaration;
}

class MixinFragment extends DeclarationFragment {
  @override
  final String name;

  final ClassName _className;

  MixinFragment(this.name, super.nameOffset, super.typeParameters,
      super.typeParameterScope)
      : _className = new ClassName(name);

  @override
  ContainerName get containerName => _className;

  @override
  ContainerType get containerType => ContainerType.Class;

  @override
  // Coverage-ignore(suite): Not run.
  DeclarationFragmentKind get kind => DeclarationFragmentKind.mixinDeclaration;
}

class EnumFragment extends DeclarationFragment {
  @override
  final String name;

  final ClassName _className;

  EnumFragment(this.name, super.nameOffset, super.typeParameters,
      super.typeParameterScope)
      : _className = new ClassName(name);

  @override
  ContainerName get containerName => _className;

  @override
  ContainerType get containerType => ContainerType.Class;

  @override
  // Coverage-ignore(suite): Not run.
  DeclarationFragmentKind get kind => DeclarationFragmentKind.enumDeclaration;
}

class ExtensionFragment extends DeclarationFragment {
  final ExtensionName extensionName;

  /// The type of `this` in instance methods declared in extension declarations.
  ///
  /// Instance methods declared in extension declarations methods are extended
  /// with a synthesized parameter of this type.
  TypeBuilder? _extensionThisType;

  ExtensionFragment(String? name, super.nameOffset, super.typeParameters,
      super.typeParameterScope)
      : extensionName = name != null
            ? new FixedExtensionName(name)
            : new UnnamedExtensionName();

  @override
  String get name => extensionName.name;

  @override
  ContainerName get containerName => extensionName;

  @override
  ContainerType get containerType => ContainerType.Extension;

  @override
  // Coverage-ignore(suite): Not run.
  DeclarationFragmentKind get kind =>
      DeclarationFragmentKind.extensionDeclaration;

  /// Registers the 'extension this type' of the extension declaration prepared
  /// for by this builder.
  ///
  /// See [extensionThisType] for terminology.
  void registerExtensionThisType(TypeBuilder type) {
    assert(_extensionThisType == null,
        "Extension this type has already been set.");
    _extensionThisType = type;
  }

  /// Returns the 'extension this type' of the extension declaration prepared
  /// for by this builder.
  ///
  /// The 'extension this type' is the type mentioned in the on-clause of the
  /// extension declaration. For instance `B` in this extension declaration:
  ///
  ///     extension A on B {
  ///       B method() => this;
  ///     }
  ///
  /// The 'extension this type' is the type if `this` expression in instance
  /// methods declared in extension declarations.
  TypeBuilder get extensionThisType {
    assert(
        _extensionThisType != null,
        // Coverage-ignore(suite): Not run.
        "DeclarationBuilder.extensionThisType has not been set on $this.");
    return _extensionThisType!;
  }
}

class ExtensionTypeFragment extends DeclarationFragment {
  @override
  final String name;

  final ClassName _className;

  ExtensionTypeFragment(this.name, super.nameOffset, super.typeParameters,
      super.typeParameterScope)
      : _className = new ClassName(name);

  @override
  ContainerName get containerName => _className;

  @override
  ContainerType get containerType => ContainerType.ExtensionType;

  @override
  // Coverage-ignore(suite): Not run.
  DeclarationFragmentKind get kind =>
      DeclarationFragmentKind.extensionTypeDeclaration;
}

class _AddBuilder {
  final String name;
  final Builder declaration;
  final Uri fileUri;
  final int charOffset;

  _AddBuilder(this.name, this.declaration, this.fileUri, this.charOffset);
}

class DeclarationNameSpaceBuilder {
  final String _name;
  final NominalParameterNameSpace? _nominalParameterNameSpace;
  final List<_AddBuilder> _addedBuilders;

  DeclarationNameSpaceBuilder.empty()
      : _name = '',
        _nominalParameterNameSpace = null,
        _addedBuilders = const [];

  DeclarationNameSpaceBuilder._(
      this._name, this._nominalParameterNameSpace, this._addedBuilders);

  void _addBuilder(
      ProblemReporting problemReporting,
      Map<String, Builder> getables,
      Map<String, MemberBuilder> setables,
      Map<String, MemberBuilder> constructors,
      _AddBuilder addBuilder) {
    String name = addBuilder.name;
    Builder declaration = addBuilder.declaration;
    Uri fileUri = addBuilder.fileUri;
    int charOffset = addBuilder.charOffset;

    bool isConstructor = declaration is FunctionBuilder &&
        (declaration.isConstructor || declaration.isFactory);
    if (!isConstructor && name == _name) {
      problemReporting.addProblem(
          messageMemberWithSameNameAsClass, charOffset, noLength, fileUri);
    }
    Map<String, Builder> members = isConstructor
        ? constructors
        : (declaration.isSetter ? setables : getables);

    Builder? existing = members[name];

    if (existing == declaration) return;

    if (declaration.next != null &&
        // Coverage-ignore(suite): Not run.
        declaration.next != existing) {
      unexpected(
          "${declaration.next!.fileUri}@${declaration.next!.charOffset}",
          "${existing?.fileUri}@${existing?.charOffset}",
          declaration.charOffset,
          declaration.fileUri);
    }
    declaration.next = existing;
    if (isDuplicatedDeclaration(existing, declaration)) {
      String fullName = name;
      if (isConstructor) {
        if (name.isEmpty) {
          fullName = _name;
        } else {
          fullName = "${_name}.$name";
        }
      }
      problemReporting.addProblem(
          templateDuplicatedDeclaration.withArguments(fullName),
          charOffset,
          fullName.length,
          declaration.fileUri!,
          context: <LocatedMessage>[
            templateDuplicatedDeclarationCause
                .withArguments(fullName)
                .withLocation(
                    existing!.fileUri!, existing.charOffset, fullName.length)
          ]);
    } else if (declaration.isAugment) {
      // Coverage-ignore-block(suite): Not run.
      if (existing != null) {
        if (declaration.isSetter) {
          // TODO(johnniwinther): Collection augment setables.
        } else {
          // TODO(johnniwinther): Collection augment getables.
        }
      } else {
        // TODO(cstefantsova): Report an error.
      }
    }
    members[name] = declaration;
  }

  void checkTypeVariableConflict(ProblemReporting _problemReporting,
      String name, Builder member, Uri fileUri) {
    if (_nominalParameterNameSpace != null) {
      NominalVariableBuilder? tv =
          _nominalParameterNameSpace.getTypeParameter(name);
      if (tv != null) {
        _problemReporting.addProblem(
            templateConflictsWithTypeVariable.withArguments(name),
            member.charOffset,
            name.length,
            fileUri,
            context: [
              messageConflictsWithTypeVariableCause.withLocation(
                  tv.fileUri!, tv.charOffset, name.length)
            ]);
      }
    }
  }

  DeclarationNameSpace buildNameSpace(
      ProblemReporting problemReporting, IDeclarationBuilder parent,
      {bool includeConstructors = true}) {
    Map<String, Builder> getables = {};
    Map<String, MemberBuilder> setables = {};
    Map<String, MemberBuilder> constructors = {};

    for (_AddBuilder addedBuilder in _addedBuilders) {
      _addBuilder(
          problemReporting, getables, setables, constructors, addedBuilder);
    }

    void setParent(MemberBuilder? member) {
      while (member != null) {
        member.parent = parent;
        member = member.next as MemberBuilder?;
      }
    }

    void setParentAndCheckConflicts(String name, Builder member) {
      checkTypeVariableConflict(
          problemReporting, name, member, member.fileUri!);
      setParent(member as MemberBuilder);
    }

    getables.forEach(setParentAndCheckConflicts);
    setables.forEach(setParentAndCheckConflicts);
    constructors.forEach(setParentAndCheckConflicts);

    return new DeclarationNameSpaceImpl(
        getables: getables,
        setables: setables,
        // TODO(johnniwinther): Handle constructors in extensions consistently.
        // Currently they are not part of the name space but still processed
        // for instance when inferring redirecting factories.
        constructors: includeConstructors ? constructors : null);
  }
}

enum TypeScopeKind {
  library,
  declarationTypeParameters,
  classDeclaration,
  mixinDeclaration,
  enumDeclaration,
  extensionDeclaration,
  extensionTypeDeclaration,
  memberTypeParameters,
  functionTypeParameters,
  unnamedMixinApplication,
}

class TypeScope {
  final TypeScopeKind kind;

  List<NamedTypeBuilder> _unresolvedNamedTypes = [];

  List<TypeScope> _childScopes = [];

  final LookupScope lookupScope;

  TypeScope(this.kind, this.lookupScope, [TypeScope? parent]) {
    parent?._childScopes.add(this);
  }

  void registerUnresolvedNamedType(NamedTypeBuilder namedTypeBuilder) {
    _unresolvedNamedTypes.add(namedTypeBuilder);
  }

  int resolveTypes(ProblemReporting problemReporting) {
    int typeCount = _unresolvedNamedTypes.length;
    if (_unresolvedNamedTypes.isNotEmpty) {
      for (NamedTypeBuilder namedTypeBuilder in _unresolvedNamedTypes) {
        namedTypeBuilder.resolveIn(lookupScope, namedTypeBuilder.charOffset!,
            namedTypeBuilder.fileUri!, problemReporting);
      }
      _unresolvedNamedTypes.clear();
    }
    for (TypeScope childScope in _childScopes) {
      typeCount += childScope.resolveTypes(problemReporting);
    }
    return typeCount;
  }

  bool get isEmpty => _unresolvedNamedTypes.isEmpty && _childScopes.isEmpty;

  @override
  String toString() => 'TypeScope($kind,$_unresolvedNamedTypes)';
}

class DeclarationBuilderScope implements LookupScope {
  DeclarationBuilder? _declarationBuilder;

  DeclarationBuilderScope();

  @override
  // Coverage-ignore(suite): Not run.
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _declarationBuilder?.scope.forEachExtension(f);
  }

  void set declarationBuilder(DeclarationBuilder value) {
    assert(_declarationBuilder == null,
        "declarationBuilder has already been set.");
    _declarationBuilder = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  ScopeKind get kind =>
      _declarationBuilder?.scope.kind ?? ScopeKind.declaration;

  @override
  Builder? lookupGetable(String name, int charOffset, Uri fileUri) {
    return _declarationBuilder?.scope.lookupGetable(name, charOffset, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Builder? lookupSetable(String name, int charOffset, Uri fileUri) {
    return _declarationBuilder?.scope.lookupSetable(name, charOffset, fileUri);
  }
}

bool isDuplicatedDeclaration(Builder? existing, Builder other) {
  if (existing == null) return false;
  if (other.isAugment) return false;
  Builder? next = existing.next;
  if (next == null) {
    if (existing.isGetter && other.isSetter) return false;
    if (existing.isSetter && other.isGetter) return false;
  } else {
    if (next is ClassBuilder && !next.isMixinApplication) return true;
  }
  if (existing is ClassBuilder && other is ClassBuilder) {
    // We allow multiple mixin applications with the same name. An
    // alternative is to share these mixin applications. This situation can
    // happen if you have `class A extends Object with Mixin {}` and `class B
    // extends Object with Mixin {}` in the same library.
    return !existing.isMixinApplication ||
        // Coverage-ignore(suite): Not run.
        !other.isMixinApplication;
  }
  return true;
}
