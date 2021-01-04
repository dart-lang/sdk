// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import '../../base/common.dart';

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/field_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';

import '../fasta_codes.dart'
    show
        messagePatchDeclarationMismatch,
        messagePatchDeclarationOrigin,
        noLength,
        templateConflictsWithMember,
        templateConflictsWithSetter,
        templateExtensionMemberConflictsWithObjectMember;

import '../problems.dart';

import '../scope.dart';

import 'source_library_builder.dart';

const String extensionThisName = '#this';

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
      int endOffset,
      Extension referenceFrom)
      : _extension = new Extension(
            name: name,
            fileUri: parent.fileUri,
            typeParameters:
                TypeVariableBuilder.typeParametersFromBuilders(typeParameters),
            reference: referenceFrom?.reference)
          ..fileOffset = nameOffset,
        super(metadata, modifiers, name, parent, nameOffset, scope,
            typeParameters, onType);

  @override
  SourceLibraryBuilder get library => super.library;

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
        } else if (declaration is MemberBuilderImpl) {
          MemberBuilderImpl memberBuilder = declaration;
          memberBuilder.buildMembers(libraryBuilder,
              (Member member, BuiltMemberKind memberKind) {
            if (addMembersToLibrary &&
                !memberBuilder.isPatch &&
                !memberBuilder.isDuplicate) {
              ExtensionMemberKind kind;
              switch (memberKind) {
                case BuiltMemberKind.Constructor:
                case BuiltMemberKind.RedirectingFactory:
                case BuiltMemberKind.Field:
                case BuiltMemberKind.Method:
                  unhandled(
                      "${member.runtimeType}:${memberKind}",
                      "buildMembers",
                      declaration.charOffset,
                      declaration.fileUri);
                  break;
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
                case BuiltMemberKind.ExtensionTearOff:
                  kind = ExtensionMemberKind.TearOff;
                  break;
              }
              assert(kind != null);
              Reference memberReference;
              if (member is Field) {
                libraryBuilder.library.addField(member);
                memberReference = member.getterReference;
              } else if (member is Procedure) {
                libraryBuilder.library.addProcedure(member);
                memberReference = member.reference;
              } else {
                unhandled("${member.runtimeType}", "buildBuilders",
                    member.fileOffset, member.fileUri);
              }
              extension.members.add(new ExtensionMemberDescriptor(
                  name: new Name(memberBuilder.name, libraryBuilder.library),
                  member: memberReference,
                  isStatic: declaration.isStatic,
                  kind: kind));
            }
          });
        } else {
          unhandled("${declaration.runtimeType}", "buildBuilders",
              declaration.charOffset, declaration.fileUri);
        }
        declaration = declaration.next;
      } while (declaration != null);
    }

    scope.forEach(buildBuilders);

    scope.forEachLocalSetter((String name, MemberBuilder setter) {
      Builder member = scopeBuilder[name];
      if (member == null) {
        // Setter without getter.
        return;
      }
      bool conflict = member.isDeclarationInstanceMember !=
          setter.isDeclarationInstanceMember;
      if (member.isField) {
        if (!member.isConst && !member.isFinal) {
          // Setter with writable field.
          conflict = true;
        }
      } else if (member.isRegularMethod) {
        // Setter with method.
        conflict = true;
      }
      if (conflict) {
        addProblem(templateConflictsWithMember.withArguments(name),
            setter.charOffset, noLength);
        // TODO(ahe): Context argument to previous message?
        addProblem(templateConflictsWithSetter.withArguments(name),
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
      scope.forEachLocalMember((String name, Builder member) {
        Builder memberPatch =
            patch.scope.lookupLocalMember(name, setter: false);
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });
      scope.forEachLocalSetter((String name, Builder member) {
        Builder memberPatch = patch.scope.lookupLocalMember(name, setter: true);
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

  void checkTypesInOutline(TypeEnvironment typeEnvironment) {
    library.checkBoundsInTypeParameters(
        typeEnvironment, extension.typeParameters, fileUri);

    // Check on clause.
    if (_extension.onType != null) {
      library.checkBoundsInType(_extension.onType, typeEnvironment,
          onType.fileUri, onType.charOffset);
    }

    forEach((String name, Builder builder) {
      if (builder is SourceFieldBuilder) {
        // Check fields.
        library.checkTypesInField(builder, typeEnvironment);
      } else if (builder is ProcedureBuilder) {
        // Check procedures
        library.checkTypesInProcedureBuilder(builder, typeEnvironment);
        if (builder.isGetter) {
          Builder setterDeclaration =
              scope.lookupLocalMember(builder.name, setter: true);
          if (setterDeclaration != null) {
            library.checkGetterSetterTypes(
                builder, setterDeclaration, typeEnvironment);
          }
        }
      } else {
        assert(false, "Unexpected member: $builder.");
      }
    });
  }
}
