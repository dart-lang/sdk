// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/declaration_builders.dart';
import '../builder/member_builder.dart';
import '../builder/type_builder.dart';
import 'package:kernel/ast.dart';

import '../scope.dart';
import 'dill_class_builder.dart';
import 'dill_extension_type_member_builder.dart';
import 'dill_library_builder.dart';
import 'dill_member_builder.dart';

class DillExtensionTypeDeclarationBuilder
    extends ExtensionTypeDeclarationBuilderImpl
    with DillClassMemberAccessMixin {
  final ExtensionTypeDeclaration _extensionTypeDeclaration;

  List<NominalVariableBuilder>? _typeParameters;

  List<TypeBuilder>? _interfaceBuilders;

  TypeBuilder? _declaredRepresentationTypeBuilder;

  DillExtensionTypeDeclarationBuilder(
      this._extensionTypeDeclaration, DillLibraryBuilder parent)
      : super(
            /*metadata builders*/
            null,
            /* modifiers*/
            0,
            _extensionTypeDeclaration.name,
            parent,
            _extensionTypeDeclaration.fileOffset,
            new Scope(
                kind: ScopeKind.declaration,
                local: <String, MemberBuilder>{},
                setters: <String, MemberBuilder>{},
                parent: parent.scope,
                debugName: "extension type ${_extensionTypeDeclaration.name}",
                isModifiable: false),
            new ConstructorScope(
                _extensionTypeDeclaration.name, <String, MemberBuilder>{})) {
    for (Procedure procedure in _extensionTypeDeclaration.procedures) {
      String name = procedure.name.text;
      switch (procedure.kind) {
        case ProcedureKind.Factory:
          throw new UnsupportedError(
              "Unexpected procedure kind in extension type declaration: "
              "$procedure (${procedure.kind}).");
        case ProcedureKind.Setter:
          scope.addLocalMember(name, new DillSetterBuilder(procedure, this),
              setter: true);
          break;
        case ProcedureKind.Getter:
          scope.addLocalMember(name, new DillGetterBuilder(procedure, this),
              setter: false);
          break;
        case ProcedureKind.Operator:
          scope.addLocalMember(name, new DillOperatorBuilder(procedure, this),
              setter: false);
          break;
        case ProcedureKind.Method:
          scope.addLocalMember(name, new DillMethodBuilder(procedure, this),
              setter: false);
          break;
      }
    }
    for (ExtensionTypeMemberDescriptor descriptor
        in _extensionTypeDeclaration.memberDescriptors) {
      Name name = descriptor.name;
      switch (descriptor.kind) {
        case ExtensionTypeMemberKind.Method:
          if (descriptor.isStatic) {
            Procedure procedure = descriptor.memberReference.asProcedure;
            scope.addLocalMember(
                name.text,
                new DillExtensionTypeStaticMethodBuilder(
                    procedure, descriptor, this),
                setter: false);
          } else {
            Procedure procedure = descriptor.memberReference.asProcedure;
            Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
            assert(tearOff != null, "No tear found for ${descriptor}");
            scope.addLocalMember(
                name.text,
                new DillExtensionTypeInstanceMethodBuilder(
                    procedure, descriptor, this, tearOff!),
                setter: false);
          }
          break;
        case ExtensionTypeMemberKind.Getter:
          Procedure procedure = descriptor.memberReference.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionTypeGetterBuilder(procedure, descriptor, this),
              setter: false);
          break;
        case ExtensionTypeMemberKind.Field:
          Field field = descriptor.memberReference.asField;
          scope.addLocalMember(name.text,
              new DillExtensionTypeFieldBuilder(field, descriptor, this),
              setter: false);
          break;
        case ExtensionTypeMemberKind.Setter:
          Procedure procedure = descriptor.memberReference.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionTypeSetterBuilder(procedure, descriptor, this),
              setter: true);
          break;
        case ExtensionTypeMemberKind.Operator:
          Procedure procedure = descriptor.memberReference.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionTypeOperatorBuilder(procedure, descriptor, this),
              setter: false);
          break;
        case ExtensionTypeMemberKind.Constructor:
          Procedure procedure = descriptor.memberReference.asProcedure;
          Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
          constructorScope.addLocalMember(
              name.text,
              new DillExtensionTypeConstructorBuilder(
                  procedure, tearOff, descriptor, this));
          break;
        case ExtensionTypeMemberKind.Factory:
        case ExtensionTypeMemberKind.RedirectingFactory:
          Procedure procedure = descriptor.memberReference.asProcedure;
          Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
          constructorScope.addLocalMember(
              name.text,
              new DillExtensionTypeFactoryBuilder(
                  procedure, tearOff, descriptor, this));
          break;
      }
    }
  }

  @override
  DillLibraryBuilder get libraryBuilder => parent as DillLibraryBuilder;

  @override
  DartType get declaredRepresentationType =>
      _extensionTypeDeclaration.declaredRepresentationType;

  @override
  TypeBuilder? get declaredRepresentationTypeBuilder =>
      _declaredRepresentationTypeBuilder ??=
          libraryBuilder.loader.computeTypeBuilder(declaredRepresentationType);

  @override
  ExtensionTypeDeclaration get extensionTypeDeclaration =>
      _extensionTypeDeclaration;

  @override
  List<NominalVariableBuilder>? get typeParameters {
    List<NominalVariableBuilder>? typeVariables = _typeParameters;
    if (typeVariables == null &&
        _extensionTypeDeclaration.typeParameters.isNotEmpty) {
      typeVariables = _typeParameters =
          computeTypeVariableBuilders(_extensionTypeDeclaration.typeParameters);
    }
    return typeVariables;
  }

  @override
  List<TypeBuilder>? get interfaceBuilders {
    if (_extensionTypeDeclaration.implements.isEmpty) return null;
    List<TypeBuilder>? interfaceBuilders = _interfaceBuilders;
    if (interfaceBuilders == null) {
      interfaceBuilders = _interfaceBuilders = new List<TypeBuilder>.generate(
          _extensionTypeDeclaration.implements.length,
          (int i) => libraryBuilder.loader
              .computeTypeBuilder(_extensionTypeDeclaration.implements[i]),
          growable: false);
    }
    return interfaceBuilders;
  }
}
