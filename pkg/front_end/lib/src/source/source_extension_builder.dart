// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/problems.dart';
import '../base/scope.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/extension/declaration.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/kernel_helper.dart';
import 'name_scheme.dart';
import 'name_space_builder.dart';
import 'source_builder_mixins.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';
import 'source_type_parameter_builder.dart';

class SourceExtensionBuilder extends ExtensionBuilderImpl
    with SourceDeclarationBuilderBaseMixin, SourceDeclarationBuilderMixin {
  @override
  final SourceLibraryBuilder libraryBuilder;

  final int _nameOffset;

  @override
  final Uri fileUri;

  final Modifiers _modifiers;

  late final Extension _extension;

  final DeclarationNameSpaceBuilder _nameSpaceBuilder;

  late final DeclarationNameSpace _nameSpace;
  late final List<SourceMemberBuilder> _constructorBuilders;
  late final List<SourceMemberBuilder> _memberBuilders;

  @override
  final List<SourceNominalParameterBuilder>? typeParameters;

  @override
  final TypeBuilder onType;

  final ExtensionName extensionName;

  final Reference _reference;

  /// The `extension` declaration that introduces this extension. Subsequent
  /// extensions of the same name must be augmentations.
  final ExtensionDeclaration _introductory;

  final List<ExtensionDeclaration> _augmentations;

  new({
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required this.fileUri,
    required int startOffset,
    required int nameOffset,
    required int endOffset,
    required Modifiers modifiers,
    required this.extensionName,
    required this.typeParameters,
    required DeclarationNameSpaceBuilder nameSpaceBuilder,
    required ExtensionDeclaration introductory,
    required List<ExtensionDeclaration> augmentations,
    required Reference? reference,
    required this.onType,
  }) : _introductory = introductory,
       _augmentations = augmentations,
       _reference = reference ?? new Reference(),
       _nameOffset = nameOffset,
       libraryBuilder = enclosingLibraryBuilder,
       _modifiers = modifiers,
       _nameSpaceBuilder = nameSpaceBuilder {
    // TODO(johnniwinther): Move this to the [build] once augmentations are
    // handled through fragments.
    _extension =
        new Extension(
            name: extensionName.name,
            fileUri: fileUri,
            typeParameters:
                SourceNominalParameterBuilder.typeParametersFromBuilders(
                  typeParameters,
                ),
            reference: _reference,
          )
          ..isUnnamedExtension = extensionName.isUnnamedExtension
          ..fileOffset = _nameOffset;
    extensionName.attachExtension(_extension);
  }

  @override
  Iterator<SourceMemberBuilder> get unfilteredMembersIterator =>
      _memberBuilders.iterator;

  @override
  Iterator<T> filteredMembersIterator<T extends MemberBuilder>({
    required bool includeDuplicates,
  }) => new FilteredIterator<T>(
    _memberBuilders.iterator,
    includeDuplicates: includeDuplicates,
  );

  @override
  Iterator<SourceMemberBuilder> get unfilteredConstructorsIterator =>
      _constructorBuilders.iterator;

  @override
  Iterator<T> filteredConstructorsIterator<T extends MemberBuilder>({
    required bool includeDuplicates,
  }) => new FilteredIterator<T>(
    _constructorBuilders.iterator,
    includeDuplicates: includeDuplicates,
  );

  @override
  int get fileOffset => _nameOffset;

  @override
  String get name => extensionName.name;

  @override
  DeclarationNameSpace get nameSpace => _nameSpace;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isStatic => _modifiers.isStatic;

  @override
  void buildScopes(LibraryBuilder coreLibrary) {
    _constructorBuilders = [];
    _memberBuilders = [];
    _nameSpace = _nameSpaceBuilder.buildNameSpace(
      loader: libraryBuilder.loader,
      problemReporting: libraryBuilder,
      enclosingLibraryBuilder: libraryBuilder,
      declarationBuilder: this,
      indexedLibrary: libraryBuilder.indexedLibrary,
      // Extensions do not have a corresponding [IndexedContainer] since their
      // members are stored in the enclosing library.
      indexedContainer: null,
      containerType: ContainerType.Extension,
      containerName: extensionName,
      constructorBuilders: _constructorBuilders,
      memberBuilders: _memberBuilders,
      typeParameterFactory: libraryBuilder.typeParameterFactory,
    );
  }

  @override
  SourceLibraryBuilder get parent => libraryBuilder;

  bool get isUnnamedExtension => extensionName.isUnnamedExtension;

  @override
  Reference get reference => _reference;

  @override
  Extension get extension => _extension;

  BodyBuilderContext _createBodyBuilderContext() {
    return new ExtensionBodyBuilderContext(this);
  }

  /// Builds the [Extension] for this extension build and inserts the members
  /// into the [Library] of [libraryBuilder].
  ///
  /// [addMembersToLibrary] is `true` if the extension members should be added
  /// to the library. This is `false` if the extension is in conflict with
  /// another library member. In this case, the extension member should not be
  /// added to the library to avoid name clashes with other members in the
  /// library.
  Extension build(
    LibraryBuilder coreLibrary, {
    required bool addMembersToLibrary,
  }) {
    _extension.onType = onType.build(libraryBuilder, TypeUse.extensionOnType);

    buildInternal(coreLibrary, addMembersToLibrary: addMembersToLibrary);
    return _extension;
  }

  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    BodyBuilderContext bodyBuilderContext = _createBodyBuilderContext();
    _introductory.buildOutlineExpressions(
      libraryBuilder: libraryBuilder,
      extension: extension,
      classHierarchy: classHierarchy,
      bodyBuilderContext: bodyBuilderContext,
    );
    for (ExtensionDeclaration augmentation in _augmentations) {
      augmentation.buildOutlineExpressions(
        libraryBuilder: libraryBuilder,
        extension: extension,
        classHierarchy: classHierarchy,
        bodyBuilderContext: bodyBuilderContext,
      );
    }

    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(
          libraryBuilder,
          bodyBuilderContext,
          classHierarchy,
        );
      }
    }

    Iterator<SourceMemberBuilder> iterator = filteredMembersIterator(
      includeDuplicates: false,
    );
    while (iterator.moveNext()) {
      iterator.current.buildOutlineExpressions(
        classHierarchy,
        delayedDefaultValueCloners,
      );
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void addMemberInternal(
    SourceMemberBuilder memberBuilder,
    BuiltMemberKind memberKind,
    Member member,
    Member? tearOff,
  ) {
    unhandled(
      "${memberBuilder.runtimeType}:${memberKind}",
      "addMemberInternal",
      memberBuilder.fileOffset,
      memberBuilder.fileUri,
    );
  }

  @override
  void addMemberDescriptorInternal(
    SourceMemberBuilder memberBuilder,
    BuiltMemberKind memberKind,
    Reference memberReference,
    Reference? tearOffReference,
  ) {
    String name = memberBuilder.name;
    ExtensionMemberKind kind;
    bool isInternalImplementation = false;
    switch (memberKind) {
      case BuiltMemberKind.Constructor:
      case BuiltMemberKind.RedirectingFactory:
      case BuiltMemberKind.Factory:
      case BuiltMemberKind.Field:
      case BuiltMemberKind.Method:
      case BuiltMemberKind.ExtensionTypeConstructor:
      case BuiltMemberKind.ExtensionTypeMethod:
      case BuiltMemberKind.ExtensionTypeGetter:
      case BuiltMemberKind.ExtensionTypeSetter:
      case BuiltMemberKind.ExtensionTypeOperator:
      case BuiltMemberKind.ExtensionTypeFactory:
      case BuiltMemberKind.ExtensionTypeRedirectingFactory:
      case BuiltMemberKind.ExtensionTypeRepresentationField:
        // Coverage-ignore(suite): Not run.
        unhandled(
          "$memberBuilder(${memberBuilder.runtimeType}):${memberKind}",
          "addMemberDescriptorInternal",
          memberBuilder.fileOffset,
          memberBuilder.fileUri,
        );
      case BuiltMemberKind.ExtensionField:
        kind = ExtensionMemberKind.Field;
        break;
      case BuiltMemberKind.LateBackingField:
      case BuiltMemberKind.LateIsSetField:
        isInternalImplementation = true;
        kind = ExtensionMemberKind.Field;
        break;
      case BuiltMemberKind.ExtensionMethod:
        kind = ExtensionMemberKind.Method;
        break;
      case BuiltMemberKind.ExtensionGetter:
      case BuiltMemberKind.LateGetter:
        kind = ExtensionMemberKind.Getter;
        break;
      case BuiltMemberKind.ExtensionSetter:
      case BuiltMemberKind.LateSetter:
        kind = ExtensionMemberKind.Setter;
        break;
      case BuiltMemberKind.ExtensionOperator:
        kind = ExtensionMemberKind.Operator;
        break;
    }
    extension.memberDescriptors.add(
      new ExtensionMemberDescriptor(
        name: new Name(name, libraryBuilder.library),
        memberReference: memberReference,
        tearOffReference: tearOffReference,
        isStatic: memberBuilder.isStatic,
        isInternalImplementation: isInternalImplementation,
        kind: kind,
      ),
    );
  }

  @override
  int resolveConstructors(SourceLibraryBuilder library) {
    return 0;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isMixinClass => false;
}
