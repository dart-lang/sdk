// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/source/source_builder_mixins.dart';
import 'package:kernel/ast.dart';

import '../../base/common.dart';
import '../builder/builder.dart';
import '../builder/library_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';
import '../builder/view_builder.dart';
import '../fasta_codes.dart'
    show
        messagePatchDeclarationMismatch,
        messagePatchDeclarationOrigin,
        noLength;
import '../problems.dart';
import '../scope.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';

class SourceViewBuilder extends ViewBuilderImpl
    with SourceDeclarationBuilderMixin {
  final InlineClass _view;

  SourceViewBuilder? _origin;
  SourceViewBuilder? patchForTesting;

  MergedClassMemberScope? _mergedScope;

  @override
  final List<TypeVariableBuilder>? typeParameters;

  final SourceFieldBuilder? representationFieldBuilder;

  SourceViewBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String name,
      this.typeParameters,
      Scope scope,
      ConstructorScope constructorScope,
      SourceLibraryBuilder parent,
      int startOffset,
      int nameOffset,
      int endOffset,
      InlineClass? referenceFrom,
      this.representationFieldBuilder)
      : _view = new InlineClass(
            name: name,
            fileUri: parent.fileUri,
            typeParameters:
                TypeVariableBuilder.typeParametersFromBuilders(typeParameters),
            reference: referenceFrom?.reference)
          ..fileOffset = nameOffset,
        super(metadata, modifiers, name, parent, nameOffset, scope,
            constructorScope);

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  @override
  SourceViewBuilder get origin => _origin ?? this;

  // TODO(johnniwinther): Add merged scope for views.
  MergedClassMemberScope get mergedScope => _mergedScope ??= isPatch
      ? origin.mergedScope
      : throw new UnimplementedError("SourceViewBuilder.mergedScope");

  @override
  InlineClass get view => isPatch ? origin._view : _view;

  @override
  Annotatable get annotatable => view;

  /// Builds the [InlineClass] for this view builder and inserts the members
  /// into the [Library] of [libraryBuilder].
  ///
  /// [addMembersToLibrary] is `true` if the view members should be added
  /// to the library. This is `false` if the view is in conflict with
  /// another library member. In this case, the view member should not be
  /// added to the library to avoid name clashes with other members in the
  /// library.
  InlineClass build(LibraryBuilder coreLibrary,
      {required bool addMembersToLibrary}) {
    DartType representationType;
    if (representationFieldBuilder != null) {
      TypeBuilder typeBuilder = representationFieldBuilder!.type;
      if (typeBuilder.isExplicit) {
        representationType =
            typeBuilder.build(libraryBuilder, TypeUse.fieldType);
      } else {
        representationType = const DynamicType();
      }
    } else {
      representationType = const InvalidType();
    }
    _view.declaredRepresentationType = representationType;

    buildInternal(coreLibrary, addMembersToLibrary: addMembersToLibrary);

    return _view;
  }

  @override
  void addMemberDescriptorInternal(SourceMemberBuilder memberBuilder,
      Member member, BuiltMemberKind memberKind, Reference memberReference) {
    String name = memberBuilder.name;
    InlineClassMemberKind kind;
    switch (memberKind) {
      case BuiltMemberKind.Constructor:
      case BuiltMemberKind.RedirectingFactory:
      case BuiltMemberKind.Field:
      case BuiltMemberKind.Method:
      case BuiltMemberKind.ExtensionMethod:
      case BuiltMemberKind.ExtensionGetter:
      case BuiltMemberKind.ExtensionSetter:
      case BuiltMemberKind.ExtensionOperator:
      case BuiltMemberKind.ExtensionTearOff:
        unhandled("${member.runtimeType}:${memberKind}", "buildMembers",
            memberBuilder.charOffset, memberBuilder.fileUri);
      case BuiltMemberKind.ExtensionField:
      case BuiltMemberKind.LateIsSetField:
        kind = InlineClassMemberKind.Field;
        break;
      case BuiltMemberKind.ViewConstructor:
        kind = InlineClassMemberKind.Constructor;
        break;
      case BuiltMemberKind.ViewMethod:
        kind = InlineClassMemberKind.Method;
        break;
      case BuiltMemberKind.ViewGetter:
      case BuiltMemberKind.LateGetter:
        kind = InlineClassMemberKind.Getter;
        break;
      case BuiltMemberKind.ViewSetter:
      case BuiltMemberKind.LateSetter:
        kind = InlineClassMemberKind.Setter;
        break;
      case BuiltMemberKind.ViewOperator:
        kind = InlineClassMemberKind.Operator;
        break;
      case BuiltMemberKind.ViewTearOff:
        kind = InlineClassMemberKind.TearOff;
        break;
      case BuiltMemberKind.ViewFactory:
        kind = InlineClassMemberKind.Factory;
        break;
    }
    // ignore: unnecessary_null_comparison
    assert(kind != null);
    view.members.add(new InlineClassMemberDescriptor(
        name: new Name(name, libraryBuilder.library),
        member: memberReference,
        isStatic: memberBuilder.isStatic,
        kind: kind));
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is SourceViewBuilder) {
      patch._origin = this;
      if (retainDataForTesting) {
        patchForTesting = patch;
      }
      scope.forEachLocalMember((String name, Builder member) {
        Builder? memberPatch =
            patch.scope.lookupLocalMember(name, setter: false);
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });
      scope.forEachLocalSetter((String name, Builder member) {
        Builder? memberPatch =
            patch.scope.lookupLocalMember(name, setter: true);
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });

      // TODO(johnniwinther): Check that type parameters and on-type match
      // with origin declaration.
    } else {
      libraryBuilder.addProblem(messagePatchDeclarationMismatch,
          patch.charOffset, noLength, patch.fileUri, context: [
        messagePatchDeclarationOrigin.withLocation(
            fileUri, charOffset, noLength)
      ]);
    }
  }

  // TODO(johnniwinther): Implement representationType.
  @override
  DartType get representationType => throw new UnimplementedError();
}
