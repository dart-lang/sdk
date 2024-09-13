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
import '../fragment/fragment.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_enum_builder.dart';
import 'source_extension_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart';
import 'source_type_alias_builder.dart';

sealed class _Added {
  _AddBuilder getAddBuilder(Builder parent);
}

class _AddedBuilder implements _Added {
  final _AddBuilder builder;

  _AddedBuilder(this.builder);

  @override
  _AddBuilder getAddBuilder(Builder parent) => builder;
}

class _AddedFragment implements _Added {
  final Fragment fragment;

  _AddedFragment(this.fragment);

  @override
  _AddBuilder getAddBuilder(Builder parent) {
    Fragment fragment = this.fragment;
    switch (fragment) {
      case TypedefFragment():
        SourceTypeAliasBuilder typedefBuilder = new SourceTypeAliasBuilder(
            metadata: fragment.metadata,
            name: fragment.name,
            typeVariables: fragment.typeVariables,
            type: fragment.type,
            enclosingLibraryBuilder: parent as SourceLibraryBuilder,
            fileUri: fragment.fileUri,
            fileOffset: fragment.fileOffset,
            reference: fragment.reference);
        fragment.builder = typedefBuilder;
        return new _AddBuilder(fragment.name, typedefBuilder, fragment.fileUri,
            fragment.fileOffset);
      case ExtensionFragment():
        SourceExtensionBuilder extensionBuilder = new SourceExtensionBuilder(
            metadata: fragment.metadata,
            modifiers: fragment.modifiers,
            extensionName: fragment.extensionName,
            typeParameters: fragment.typeParameters,
            onType: fragment.onType,
            typeParameterScope: fragment.typeParameterScope,
            nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
            enclosingLibraryBuilder: parent as SourceLibraryBuilder,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            reference: fragment.reference);
        fragment.builder = extensionBuilder;
        fragment.bodyScope.declarationBuilder = extensionBuilder;
        return new _AddBuilder(fragment.name, extensionBuilder,
            fragment.fileUri, fragment.fileOffset);
      case ExtensionTypeFragment():
        List<SourceFieldBuilder>? primaryConstructorFields =
            fragment.primaryConstructorFields;
        SourceFieldBuilder? representationFieldBuilder;
        if (primaryConstructorFields != null &&
            primaryConstructorFields.isNotEmpty) {
          representationFieldBuilder = primaryConstructorFields.first;
        }
        SourceExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
            new SourceExtensionTypeDeclarationBuilder(
                metadata: fragment.metadata,
                modifiers: fragment.modifiers,
                name: fragment.name,
                typeParameters: fragment.typeParameters,
                interfaceBuilders: fragment.interfaces,
                typeParameterScope: fragment.typeParameterScope,
                nameSpaceBuilder: fragment.toDeclarationNameSpaceBuilder(),
                enclosingLibraryBuilder: parent as SourceLibraryBuilder,
                constructorReferences: fragment.constructorReferences,
                fileUri: fragment.fileUri,
                startOffset: fragment.startOffset,
                nameOffset: fragment.nameOffset,
                endOffset: fragment.endOffset,
                indexedContainer: fragment.indexedContainer,
                representationFieldBuilder: representationFieldBuilder);
        fragment.builder = extensionTypeDeclarationBuilder;
        fragment.bodyScope.declarationBuilder = extensionTypeDeclarationBuilder;
        return new _AddBuilder(fragment.name, extensionTypeDeclarationBuilder,
            fragment.fileUri, fragment.fileOffset);
    }
  }
}

class LibraryNameSpaceBuilder {
  final Map<String, List<Builder>> augmentations = {};

  final Map<String, List<Builder>> setterAugmentations = {};

  List<_Added> _added = [];

  void addBuilder(
      String name, Builder declaration, Uri fileUri, int charOffset) {
    _added.add(new _AddedBuilder(
        new _AddBuilder(name, declaration, fileUri, charOffset)));
  }

  void addFragment(Fragment fragment) {
    _added.add(new _AddedFragment(fragment));
  }

  void includeBuilders(LibraryNameSpaceBuilder other) {
    _added.addAll(other._added);
  }

  NameSpace toNameSpace(
      SourceLibraryBuilder _parent, ProblemReporting _problemReporting) {
    Map<String, Builder> getables = {};

    Map<String, MemberBuilder> setables = {};

    Set<ExtensionBuilder> extensions = {};

    NameSpace nameSpace = new NameSpaceImpl(
        getables: getables, setables: setables, extensions: extensions);

    void _addBuilder(
        String name, Builder declaration, Uri fileUri, int charOffset) {
      if (declaration is SourceExtensionBuilder &&
          declaration.isUnnamedExtension) {
        declaration.parent = _parent;
        extensions.add(declaration);
        return;
      }

      if (declaration is MemberBuilder) {
        declaration.parent = _parent;
      } else if (declaration is TypeDeclarationBuilder) {
        declaration.parent = _parent;
      }
      // Coverage-ignore(suite): Not run.
      else if (declaration is PrefixBuilder) {
        assert(declaration.parent == _parent);
      } else {
        unhandled(
            "${declaration.runtimeType}", "addBuilder", charOffset, fileUri);
      }

      assert(
          !(declaration is FunctionBuilder &&
              (declaration.isConstructor || declaration.isFactory)),
          // Coverage-ignore(suite): Not run.
          "Unexpected constructor in library: $declaration.");

      Map<String, Builder> members = declaration.isSetter ? setables : getables;

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
      if (declaration is PrefixBuilder &&
          // Coverage-ignore(suite): Not run.
          existing is PrefixBuilder) {
        // Coverage-ignore-block(suite): Not run.
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
        existing.mergeScopes(declaration, _problemReporting, nameSpace,
            uriOffset: new UriOffset(fileUri, charOffset));
        return;
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
        // by name or by resolution and the remaining are dropped for the
        // output.
        extensions.add(declaration as SourceExtensionBuilder);
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
      }
      members[name] = declaration;
    }

    for (_Added added in _added) {
      _AddBuilder addBuilder = added.getAddBuilder(_parent);
      _addBuilder(addBuilder.name, addBuilder.declaration, addBuilder.fileUri,
          addBuilder.charOffset);
    }
    return nameSpace;
  }
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

abstract class DeclarationFragment {
  final Uri fileUri;
  final LookupScope typeParameterScope;
  final DeclarationBuilderScope bodyScope = new DeclarationBuilderScope();
  final List<_Added> _added = [];

  List<SourceFieldBuilder>? primaryConstructorFields;

  final List<NominalVariableBuilder>? typeParameters;

  final NominalParameterNameSpace _nominalParameterNameSpace;

  DeclarationFragment(this.fileUri, this.typeParameters,
      this.typeParameterScope, this._nominalParameterNameSpace);

  String get name;

  int get fileOffset;

  ContainerName get containerName;

  ContainerType get containerType;

  DeclarationFragmentKind get kind;

  bool declaresConstConstructor = false;

  DeclarationBuilder get builder;

  void addPrimaryConstructorField(SourceFieldBuilder builder) {
    (primaryConstructorFields ??= []).add(builder);
  }

  void addBuilder(
      String name, Builder declaration, Uri fileUri, int charOffset) {
    _added.add(new _AddedBuilder(
        new _AddBuilder(name, declaration, fileUri, charOffset)));
  }

  // Coverage-ignore(suite): Not run.
  void addFragment(Fragment fragment) {
    _added.add(new _AddedFragment(fragment));
  }

  DeclarationNameSpaceBuilder toDeclarationNameSpaceBuilder() {
    return new DeclarationNameSpaceBuilder._(
        name, _nominalParameterNameSpace, _added);
  }
}

class ClassFragment extends DeclarationFragment {
  @override
  final String name;

  final int nameOffset;

  final ClassName _className;

  SourceClassBuilder? _builder;

  ClassFragment(this.name, super.fileUri, this.nameOffset, super.typeParameters,
      super.typeParameterScope, super._nominalParameterNameSpace)
      : _className = new ClassName(name);

  @override
  int get fileOffset => nameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  SourceClassBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  // Coverage-ignore(suite): Not run.
  void set builder(SourceClassBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  ContainerName get containerName => _className;

  @override
  ContainerType get containerType => ContainerType.Class;

  @override
  // Coverage-ignore(suite): Not run.
  DeclarationFragmentKind get kind => DeclarationFragmentKind.classDeclaration;

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}

class MixinFragment extends DeclarationFragment {
  @override
  final String name;

  final int nameOffset;

  final ClassName _className;

  SourceClassBuilder? _builder;

  MixinFragment(this.name, super.fileUri, this.nameOffset, super.typeParameters,
      super.typeParameterScope, super._nominalParameterNameSpace)
      : _className = new ClassName(name);

  @override
  // Coverage-ignore(suite): Not run.
  int get fileOffset => nameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  SourceClassBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  // Coverage-ignore(suite): Not run.
  void set builder(SourceClassBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  ContainerName get containerName => _className;

  @override
  ContainerType get containerType => ContainerType.Class;

  @override
  // Coverage-ignore(suite): Not run.
  DeclarationFragmentKind get kind => DeclarationFragmentKind.mixinDeclaration;

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}

class EnumFragment extends DeclarationFragment {
  @override
  final String name;

  final int nameOffset;

  final ClassName _className;

  SourceEnumBuilder? _builder;

  EnumFragment(this.name, super.fileUri, this.nameOffset, super.typeParameters,
      super.typeParameterScope, super._nominalParameterNameSpace)
      : _className = new ClassName(name);

  @override
  // Coverage-ignore(suite): Not run.
  int get fileOffset => nameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  SourceEnumBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  // Coverage-ignore(suite): Not run.
  void set builder(SourceEnumBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  ContainerName get containerName => _className;

  @override
  ContainerType get containerType => ContainerType.Class;

  @override
  // Coverage-ignore(suite): Not run.
  DeclarationFragmentKind get kind => DeclarationFragmentKind.enumDeclaration;

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
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
  final List<_Added> _added;

  DeclarationNameSpaceBuilder.empty()
      : _name = '',
        _nominalParameterNameSpace = null,
        _added = const [];

  DeclarationNameSpaceBuilder._(
      this._name, this._nominalParameterNameSpace, this._added);

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

    for (_Added added in _added) {
      _AddBuilder addBuilder = added.getAddBuilder(parent);
      _addBuilder(
          problemReporting, getables, setables, constructors, addBuilder);
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
