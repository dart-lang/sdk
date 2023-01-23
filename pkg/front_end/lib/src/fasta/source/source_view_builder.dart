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
  final View _view;

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
      SourceLibraryBuilder parent,
      int startOffset,
      int nameOffset,
      int endOffset,
      View? referenceFrom,
      this.representationFieldBuilder)
      : _view = new View(
            name: name,
            fileUri: parent.fileUri,
            typeParameters:
                TypeVariableBuilder.typeParametersFromBuilders(typeParameters),
            reference: referenceFrom?.reference)
          ..fileOffset = nameOffset,
        super(metadata, modifiers, name, parent, nameOffset, scope);

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
  View get view => isPatch ? origin._view : _view;

  @override
  Annotatable get annotatable => view;

  /// Builds the [View] for this view builder and inserts the members
  /// into the [Library] of [libraryBuilder].
  ///
  /// [addMembersToLibrary] is `true` if the view members should be added
  /// to the library. This is `false` if the view is in conflict with
  /// another library member. In this case, the view member should not be
  /// added to the library to avoid name clashes with other members in the
  /// library.
  View build(LibraryBuilder coreLibrary, {required bool addMembersToLibrary}) {
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
    _view.representationType = representationType;

    buildInternal(coreLibrary, addMembersToLibrary: addMembersToLibrary);

    return _view;
  }

  @override
  void addMemberDescriptorInternal(SourceMemberBuilder memberBuilder,
      Member member, BuiltMemberKind memberKind, Reference memberReference) {
    String name = memberBuilder.name;
    ViewMemberKind kind;
    switch (memberKind) {
      case BuiltMemberKind.Constructor:
      case BuiltMemberKind.RedirectingFactory:
      case BuiltMemberKind.Field:
      case BuiltMemberKind.Method:
        unhandled("${member.runtimeType}:${memberKind}", "buildMembers",
            memberBuilder.charOffset, memberBuilder.fileUri);
      case BuiltMemberKind.ExtensionField:
      case BuiltMemberKind.LateIsSetField:
        kind = ViewMemberKind.Field;
        break;
      case BuiltMemberKind.ExtensionMethod:
        kind = ViewMemberKind.Method;
        break;
      case BuiltMemberKind.ExtensionGetter:
      case BuiltMemberKind.LateGetter:
        kind = ViewMemberKind.Getter;
        break;
      case BuiltMemberKind.ExtensionSetter:
      case BuiltMemberKind.LateSetter:
        kind = ViewMemberKind.Setter;
        break;
      case BuiltMemberKind.ExtensionOperator:
        kind = ViewMemberKind.Operator;
        break;
      case BuiltMemberKind.ExtensionTearOff:
        kind = ViewMemberKind.TearOff;
        break;
    }
    // ignore: unnecessary_null_comparison
    assert(kind != null);
    view.members.add(new ViewMemberDescriptor(
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
