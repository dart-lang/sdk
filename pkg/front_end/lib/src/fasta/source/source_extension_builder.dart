// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;
import 'package:kernel/ast.dart';
import '../builder/declaration.dart';
import '../builder/extension_builder.dart';
import '../builder/library_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';
import '../scope.dart';
import 'source_library_builder.dart';
import '../kernel/kernel_builder.dart';

import '../problems.dart';

import '../fasta_codes.dart'
    show
        noLength,
        templateConflictsWithMember,
        templateConflictsWithMemberWarning,
        templateConflictsWithSetter,
        templateConflictsWithSetterWarning;

class SourceExtensionBuilder extends ExtensionBuilder {
  final Extension _extension;

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

  Extension get extension => _extension;

  Extension build(
      SourceLibraryBuilder libraryBuilder, LibraryBuilder coreLibrary) {
    void buildBuilders(String name, Builder declaration) {
      do {
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
          libraryBuilder.library.addMember(field);
          _extension.members.add(new ExtensionMemberDescriptor(
              name: new Name(declaration.name, libraryBuilder.library),
              member: field.reference,
              isStatic: declaration.isStatic,
              kind: ExtensionMemberKind.Field));
        } else if (declaration is ProcedureBuilder) {
          Member function = declaration.build(libraryBuilder);
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
          _extension.members.add(new ExtensionMemberDescriptor(
              name: new Name(declaration.name, libraryBuilder.library),
              member: function.reference,
              isStatic: declaration.isStatic,
              isExternal: declaration.isExternal,
              kind: kind));
          Procedure tearOff = declaration.extensionTearOff;
          if (tearOff != null) {
            libraryBuilder.library.addMember(tearOff);
            _extension.members.add(new ExtensionMemberDescriptor(
                name: new Name(declaration.name, libraryBuilder.library),
                member: tearOff.reference,
                isStatic: false,
                isExternal: false,
                kind: ExtensionMemberKind.TearOff));
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
}
