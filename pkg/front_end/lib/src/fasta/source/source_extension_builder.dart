// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;
import 'package:kernel/ast.dart';
import '../../base/common.dart';
import '../builder/declaration.dart';
import '../builder/extension_builder.dart';
import '../builder/library_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';
import '../scope.dart';
import '../kernel/kernel_builder.dart';
import '../problems.dart';
import '../fasta_codes.dart'
    show
        messagePatchDeclarationMismatch,
        messagePatchDeclarationOrigin,
        noLength,
        templateConflictsWithMember,
        templateConflictsWithMemberWarning,
        templateConflictsWithSetter,
        templateConflictsWithSetterWarning,
        templateExtensionMemberConflictsWithObjectMember;
import 'source_library_builder.dart';

class SourceExtensionBuilder extends ExtensionBuilderImpl {
  final Extension _extension;

  SourceExtensionBuilder _origin;
  SourceExtensionBuilder patchForTesting;

  SourceExtensionBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      List<TypeVariableBuilder> typeParameters,
      TypeBuilder onType,
      Scope scope,
      LibraryBuilder parent,
      int startOffset,
      int nameOffset,
      int endOffset)
      : _extension = new Extension(
            name: name,
            fileUri: parent.fileUri,
            typeParameters:
                TypeVariableBuilder.typeParametersFromBuilders(typeParameters))
          ..fileOffset = nameOffset,
        super(metadata, modifiers, name, parent, nameOffset, scope,
            typeParameters, onType);

  @override
  SourceExtensionBuilder get origin => _origin ?? this;

  Extension get extension => isPatch ? origin._extension : _extension;

  /// Builds the [Extension] for this extension build and inserts the members
  /// into the [Library] of [libraryBuilder].
  ///
  /// [addMembersToLibrary] is `true` if the extension members should be added
  /// to the library. This is `false` if the extension is in conflict with
  /// another library member. In this case, the extension member should not be
  /// added to the library to avoid name clashes with other members in the
  /// library.
  Extension build(
      SourceLibraryBuilder libraryBuilder, LibraryBuilder coreLibrary,
      {bool addMembersToLibrary}) {
    ClassBuilder objectClassBuilder =
        coreLibrary.lookupLocalMember('Object', required: true);
    void buildBuilders(String name, Builder declaration) {
      do {
        Builder objectGetter = objectClassBuilder.lookupLocalMember(name);
        Builder objectSetter =
            objectClassBuilder.lookupLocalMember(name, setter: true);
        if (objectGetter != null || objectSetter != null) {
          addProblem(
              templateExtensionMemberConflictsWithObjectMember
                  .withArguments(name),
              declaration.charOffset,
              name.length);
        }
        if (declaration.parent != this) {
          if (fileUri != declaration.parent.fileUri) {
            unexpected("$fileUri", "${declaration.parent.fileUri}", charOffset,
                fileUri);
          } else {
            unexpected(fullNameForErrors, declaration.parent?.fullNameForErrors,
                charOffset, fileUri);
          }
        } else if (declaration is FieldBuilder) {
          Field field = declaration.build(libraryBuilder);
          if (addMembersToLibrary && declaration.next == null) {
            libraryBuilder.library.addMember(field);
            extension.members.add(new ExtensionMemberDescriptor(
                name: new Name(declaration.name, libraryBuilder.library),
                member: field.reference,
                isStatic: declaration.isStatic,
                kind: ExtensionMemberKind.Field));
          }
        } else if (declaration is ProcedureBuilder) {
          Member function = declaration.build(libraryBuilder);
          if (addMembersToLibrary &&
              !declaration.isPatch &&
              declaration.next == null) {
            libraryBuilder.library.addMember(function);
            ExtensionMemberKind kind;
            switch (declaration.kind) {
              case ProcedureKind.Method:
                kind = ExtensionMemberKind.Method;
                break;
              case ProcedureKind.Getter:
                kind = ExtensionMemberKind.Getter;
                break;
              case ProcedureKind.Setter:
                kind = ExtensionMemberKind.Setter;
                break;
              case ProcedureKind.Operator:
                kind = ExtensionMemberKind.Operator;
                break;
              case ProcedureKind.Factory:
                unsupported("Extension method kind: ${declaration.kind}",
                    declaration.charOffset, declaration.fileUri);
            }
            extension.members.add(new ExtensionMemberDescriptor(
                name: new Name(declaration.name, libraryBuilder.library),
                member: function.reference,
                isStatic: declaration.isStatic,
                kind: kind));
            Procedure tearOff = declaration.extensionTearOff;
            if (tearOff != null) {
              libraryBuilder.library.addMember(tearOff);
              _extension.members.add(new ExtensionMemberDescriptor(
                  name: new Name(declaration.name, libraryBuilder.library),
                  member: tearOff.reference,
                  isStatic: false,
                  kind: ExtensionMemberKind.TearOff));
            }
          }
        } else {
          unhandled("${declaration.runtimeType}", "buildBuilders",
              declaration.charOffset, declaration.fileUri);
        }
        declaration = declaration.next;
      } while (declaration != null);
    }

    scope.forEach(buildBuilders);

    scope.setters.forEach((String name, Builder setter) {
      Builder member = scopeBuilder[name];
      if (member == null ||
          !(member.isField && !member.isFinal && !member.isConst ||
              member.isRegularMethod && member.isStatic && setter.isStatic)) {
        return;
      }
      if (member.isDeclarationInstanceMember ==
          setter.isDeclarationInstanceMember) {
        addProblem(templateConflictsWithMember.withArguments(name),
            setter.charOffset, noLength);
        // TODO(ahe): Context argument to previous message?
        addProblem(templateConflictsWithSetter.withArguments(name),
            member.charOffset, noLength);
      } else {
        addProblem(templateConflictsWithMemberWarning.withArguments(name),
            setter.charOffset, noLength);
        // TODO(ahe): Context argument to previous message?
        addProblem(templateConflictsWithSetterWarning.withArguments(name),
            member.charOffset, noLength);
      }
    });

    _extension.onType = onType?.build(libraryBuilder);

    return _extension;
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is SourceExtensionBuilder) {
      patch._origin = this;
      if (retainDataForTesting) {
        patchForTesting = patch;
      }
      scope.local.forEach((String name, Builder member) {
        Builder memberPatch = patch.scope.local[name];
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });
      scope.setters.forEach((String name, Builder member) {
        Builder memberPatch = patch.scope.setters[name];
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });

      // TODO(johnniwinther): Check that type parameters and on-type match
      // with origin declaration.
    } else {
      library.addProblem(messagePatchDeclarationMismatch, patch.charOffset,
          noLength, patch.fileUri, context: [
        messagePatchDeclarationOrigin.withLocation(
            fileUri, charOffset, noLength)
      ]);
    }
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    int count = 0;
    scope.forEach((String name, Builder declaration) {
      count += declaration.finishPatch();
    });
    return count;
  }
}
