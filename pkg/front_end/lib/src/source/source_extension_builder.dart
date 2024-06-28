// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../base/common.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/type_builder.dart';
import '../codes/cfe_codes.dart'
    show
        messagePatchDeclarationMismatch,
        messagePatchDeclarationOrigin,
        noLength;
import '../kernel/body_builder_context.dart';
import '../base/problems.dart';
import '../base/scope.dart';
import 'name_scheme.dart';
import 'source_builder_mixins.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';

class SourceExtensionBuilder extends ExtensionBuilderImpl
    with SourceDeclarationBuilderMixin {
  final Extension _extension;

  SourceExtensionBuilder? _origin;
  SourceExtensionBuilder? augmentationForTesting;

  MergedClassMemberScope? _mergedScope;

  @override
  final List<NominalVariableBuilder>? typeParameters;

  @override
  final TypeBuilder onType;

  final ExtensionName extensionName;

  SourceExtensionBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      this.extensionName,
      this.typeParameters,
      this.onType,
      Scope scope,
      SourceLibraryBuilder parent,
      int startOffset,
      int nameOffset,
      int endOffset,
      Extension? referenceFrom)
      : _extension = new Extension(
            name: extensionName.name,
            fileUri: parent.fileUri,
            typeParameters: NominalVariableBuilder.typeParametersFromBuilders(
                typeParameters),
            reference: referenceFrom?.reference)
          ..isExtensionTypeDeclaration = false
          ..isUnnamedExtension = extensionName.isUnnamedExtension
          ..fileOffset = nameOffset,
        super(metadata, modifiers, extensionName.name, parent, nameOffset,
            scope) {
    extensionName.attachExtension(_extension);
  }

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  bool get isUnnamedExtension => extensionName.isUnnamedExtension;

  @override
  SourceExtensionBuilder get origin => _origin ?? this;

  // Coverage-ignore(suite): Not run.
  // TODO(johnniwinther): Add merged scope for extensions.
  MergedClassMemberScope get mergedScope => _mergedScope ??= isAugmenting
      ? origin.mergedScope
      : throw new UnimplementedError("SourceExtensionBuilder.mergedScope");

  @override
  Extension get extension => isAugmenting
      ?
      // Coverage-ignore(suite): Not run.
      origin._extension
      : _extension;

  @override
  BodyBuilderContext createBodyBuilderContext(
      {required bool inOutlineBuildingPhase,
      required bool inMetadata,
      required bool inConstFields}) {
    return new ExtensionBodyBuilderContext(this,
        inOutlineBuildingPhase: inOutlineBuildingPhase,
        inMetadata: inMetadata,
        inConstFields: inConstFields);
  }

  @override
  Annotatable get annotatable => extension;

  /// Builds the [Extension] for this extension build and inserts the members
  /// into the [Library] of [libraryBuilder].
  ///
  /// [addMembersToLibrary] is `true` if the extension members should be added
  /// to the library. This is `false` if the extension is in conflict with
  /// another library member. In this case, the extension member should not be
  /// added to the library to avoid name clashes with other members in the
  /// library.
  Extension build(LibraryBuilder coreLibrary,
      {required bool addMembersToLibrary}) {
    _extension.onType = onType.build(libraryBuilder, TypeUse.extensionOnType);

    buildInternal(coreLibrary, addMembersToLibrary: addMembersToLibrary);

    return _extension;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void addMemberInternal(SourceMemberBuilder memberBuilder,
      BuiltMemberKind memberKind, Member member, Member? tearOff) {
    unhandled("${memberBuilder.runtimeType}:${memberKind}", "addMemberInternal",
        memberBuilder.charOffset, memberBuilder.fileUri);
  }

  @override
  void addMemberDescriptorInternal(
      SourceMemberBuilder memberBuilder,
      BuiltMemberKind memberKind,
      Reference memberReference,
      Reference? tearOffReference) {
    String name = memberBuilder.name;
    ExtensionMemberKind kind;
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
            "${memberBuilder.runtimeType}:${memberKind}",
            "addMemberDescriptorInternal",
            memberBuilder.charOffset,
            memberBuilder.fileUri);
      case BuiltMemberKind.ExtensionField:
      case BuiltMemberKind.LateIsSetField:
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
    extension.memberDescriptors.add(new ExtensionMemberDescriptor(
        name: new Name(name, libraryBuilder.library),
        memberReference: memberReference,
        tearOffReference: tearOffReference,
        isStatic: memberBuilder.isStatic,
        kind: kind));
  }

  @override
  // Coverage-ignore(suite): Not run.
  void applyAugmentation(Builder augmentation) {
    if (augmentation is SourceExtensionBuilder) {
      augmentation._origin = this;
      if (retainDataForTesting) {
        augmentationForTesting = augmentation;
      }
      // TODO(johnniwinther): Check that type parameters and on-type match
      // with origin declaration.

      scope.forEachLocalMember((String name, Builder member) {
        Builder? memberAugmentation =
            augmentation.scope.lookupLocalMember(name, setter: false);
        if (memberAugmentation != null) {
          member.applyAugmentation(memberAugmentation);
        }
      });
      scope.forEachLocalSetter((String name, Builder member) {
        Builder? memberAugmentation =
            augmentation.scope.lookupLocalMember(name, setter: true);
        if (memberAugmentation != null) {
          member.applyAugmentation(memberAugmentation);
        }
      });
    } else {
      libraryBuilder.addProblem(messagePatchDeclarationMismatch,
          augmentation.charOffset, noLength, augmentation.fileUri, context: [
        messagePatchDeclarationOrigin.withLocation(
            fileUri, charOffset, noLength)
      ]);
    }
  }
}
